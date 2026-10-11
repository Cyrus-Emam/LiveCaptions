//
//  SpeechManager.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 11/30/25.
//

import Foundation
import SwiftUI
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechManager: ObservableObject {
    // Full transcript for the current segment (for debugging/optional UI)
    @Published var transcript: String = ""

    // Stable caption lines that never change once added
    @Published var captionLines: [String] = []

    // The line currently being filled with new words
    @Published var currentLine: String = ""

    @Published var isTranscribing: Bool = false

    private let audioEngine = AVAudioEngine()

    // Interruption handling
    private var interruptionObserver: Any?

    // MARK: - Language Handling

    /// The current language code for captioning, e.g. "en-US", "es-ES".
    /// This is set from the Welcome/Onboarding via @AppStorage("captionLanguageCode").
    private var languageCode: String {
        UserDefaults.standard.string(forKey: "captionLanguageCode") ?? "en-US"
    }

    /// Speech recognizer that uses the currently selected language.
    private var speechRecognizer: SFSpeechRecognizer? {
        SFSpeechRecognizer(locale: Locale(identifier: languageCode))
    }

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Incremental text tracking
    private var currentWords: [String] = []

    /// How many words in the current segment we have *fully processed*
    /// (i.e., already turned into captionLines / currentWords)
    private var processedWordCount: Int = 0

    /// We treat the last N words of each partial result as "unstable"
    /// so the recognizer has a chance to correct "fail" -> "failure", "work" -> "workers", etc.
    private let trailingUnstableWordCount = 2

    // How many words per "row" (tweak to taste)
    private let wordsPerLine = 7

    // MARK: - Init / Deinit

    init() {
        setupInterruptionObserver()
    }

    deinit {
        if let observer = interruptionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Authorization

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition denied")
                case .restricted:
                    print("Speech recognition restricted")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Unknown speech auth status")
                }
            }
        }
    }

    // MARK: - Audio Session Configuration (optimized for voice)

    private func configureAudioSessionForVoice() {
        let session = AVAudioSession.sharedInstance()

        do {
            // Best for real-time voice (enables AGC, noise reduction, beamforming)
            try session.setCategory(.playAndRecord,
                                    mode: .videoChat,
                                    options: [
                                        .allowBluetoothHFP,    // allow Bluetooth headsets / AirPods as mic
                                        .defaultToSpeaker,  // if you ever add playback
                                        .duckOthers         // gently lower other audio
                                    ])
            try session.setActive(true, options: [])
        } catch {
            print("AudioSession config error: \(error)")
        }
    }

   
    // MARK: - Interruption Handling

    private func setupInterruptionObserver() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in

            // Extract the interruption type before entering the Task.
            guard let typeValue = notification.userInfo?[
                AVAudioSessionInterruptionTypeKey
            ] as? UInt else {
                return
            }

            Task { @MainActor [weak self] in
                guard let self = self else { return }

                guard let type = AVAudioSession.InterruptionType(
                    rawValue: typeValue
                ) else {
                    return
                }

                switch type {
                case .began:
                    // Stop captioning when a call or Siri interrupts audio.
                    if self.isTranscribing {
                        self.stopTranscribing()
                    }

                case .ended:
                    // Do not automatically resume captioning.
                    break

                @unknown default:
                    break
                }
            }
        }
    }


    // MARK: - Control

    func startTranscribing() {
        guard !isTranscribing else { return }

        // Configure the audio session for voice-optimized capture
        configureAudioSessionForVoice()

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        // Remove any existing tap, then install one that always appends to the current request
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0,
                             bufferSize: 1024,
                             format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine failed to start: \(error)")
            return
        }

        isTranscribing = true

        // We keep any existing captionLines; Clear button resets them.
        processedWordCount = 0
        currentWords = currentLine.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        // Start the first recognition segment (using current languageCode)
        startRecognitionSegment()
    }

    func stopTranscribing() {
        // When user stops, finalize the current line and clean up everything
        finishCurrentLine()
        stopTranscribingInternal()
    }

    private func stopTranscribingInternal() {
        isTranscribing = false

        // Stop recognition
        recognitionTask?.cancel()
        recognitionTask = nil

        // Properly close the current request/audio stream
        request?.endAudio()
        request = nil

        // Stop audio engine
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)

        // Optionally release the audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }

    func clearTranscript() {
        // Fully reset recognizer state so old text can’t come back
        stopTranscribingInternal()

        transcript = ""
        captionLines = []
        currentLine = ""
        currentWords = []
        processedWordCount = 0
    }

    // MARK: - Segment Management (Continuous transcription)

    private func startRecognitionSegment() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            print("Speech recognizer not available for locale \(languageCode)")
            return
        }

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true

        // Let Apple automatically choose on-device vs cloud.
        self.request = newRequest

        // Reset per-segment processed count (currentWords persists across segments)
        processedWordCount = 0

        recognitionTask = recognizer.recognitionTask(with: newRequest) { [weak self] result, error in
            guard let self = self else { return }
            guard self.isTranscribing else { return }

            if let result = result {
                let full = result.bestTranscription.formattedString
                self.transcript = full

                if result.isFinal {
                    // On final result, commit *all* remaining words
                    self.handleFinalTranscript(full)
                    self.restartRecognitionSegment()
                    return
                } else {
                    // On partials, only commit "stable" words
                    self.handleNewTranscript(full)
                }
            }

            if let error = error {
                print("Speech recognition error: \(error)")
                // Try to recover by restarting the segment
                self.restartRecognitionSegment()
            }
        }
    }

    private func restartRecognitionSegment() {
        guard isTranscribing else { return }

        // IMPORTANT: do NOT endAudio here; we keep the audio stream alive.
        recognitionTask?.cancel()
        recognitionTask = nil

        request = nil

        // Start a new recognition segment (honors latest languageCode as well)
        startRecognitionSegment()
    }

    // MARK: - Incremental captioning

    private func handleNewTranscript(_ full: String) {
        // `full` is the entire transcript for the CURRENT recognition segment.
        // We only commit words that are "stable" – everything except the last
        // `trailingUnstableWordCount` words.

        let words = full.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let total = words.count

        // How many words are considered stable in this partial result?
        let stableCount = max(0, total - trailingUnstableWordCount)

        // If nothing new has become stable since last time, exit.
        guard stableCount > processedWordCount else {
            return
        }

        // New stable words are in [processedWordCount, stableCount)
        let newWords = words[processedWordCount..<stableCount]
        processedWordCount = stableCount

        // Feed new stable words into our line builder
        for word in newWords {
            currentWords.append(word)
            if currentWords.count == wordsPerLine {
                let line = currentWords.joined(separator: " ")
                captionLines.append(line)
                currentWords.removeAll()
            }
        }

        // For the "live" line, we show:
        //   - all fully stable-but-not-yet-flushed words in currentWords
        //   - plus the unstable tail (so user sees words ASAP)
        if stableCount < total {
            let unstableWords = words[stableCount..<total]
            currentLine = (currentWords + unstableWords).joined(separator: " ")
        } else {
            currentLine = currentWords.joined(separator: " ")
        }
    }

    private func handleFinalTranscript(_ full: String) {
        // On a final result, everything in `full` is stable.
        let words = full.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        let total = words.count

        guard total > processedWordCount else {
            // Nothing new to add
            return
        }

        let newWords = words[processedWordCount..<total]
        processedWordCount = total

        for word in newWords {
            currentWords.append(word)
            if currentWords.count == wordsPerLine {
                let line = currentWords.joined(separator: " ")
                captionLines.append(line)
                currentWords.removeAll()
            }
        }

        // After a final result, the "live" line is just whatever is left in currentWords
        currentLine = currentWords.joined(separator: " ")
    }

    private func finishCurrentLine() {
        if !currentWords.isEmpty {
            let line = currentWords.joined(separator: " ")
            captionLines.append(line)
            currentWords.removeAll()
        }
        currentLine = ""
    }
}
