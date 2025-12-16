//
//  ContentView.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 12/16/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var speech = SpeechManager()
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @State private var fontSize: CGFloat = 40

    // Accessibility / UX state
    @AppStorage("useDarkCaptionTheme") private var useDarkCaptionTheme: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("rotateForSpeaker") private var rotateForSpeaker: Bool = false

    // For onboarding + settings
    @State private var showOnboarding: Bool = false
    @State private var showSettings: Bool = false

    // For share sheet
    @State private var showShareSheet: Bool = false
    @State private var shareText: String = ""

    // For idle timer handling
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Colors flip based on preference
        let backgroundColor = useDarkCaptionTheme ? Color.black : Color.white
        let primaryTextColor = useDarkCaptionTheme ? Color.white : Color.black
        let captionBoxColor = useDarkCaptionTheme ? Color(white: 0.10) : Color(white: 0.97)

        // Lock state
        let isLocked = !purchaseManager.isUnlocked && purchaseManager.isTrialExpired

        ZStack {
            backgroundColor
                .ignoresSafeArea()

            if isLocked {
                PaywallView(
                    primaryTextColor: primaryTextColor,
                    backgroundColor: backgroundColor
                )
            } else {
                VStack(spacing: 12) {
                    // Top bar with Share (left) and Settings (right)
                    HStack {
                        // SHARE BUTTON (top-left)
                        Button {
                            var allLines = speech.captionLines
                            if !speech.currentLine.isEmpty {
                                allLines.append(speech.currentLine)
                            }
                            shareText = allLines.joined(separator: "\n")
                            showShareSheet = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.large)
                                .foregroundColor(primaryTextColor)
                                .padding(.leading, 16)
                        }
                        .disabled(speech.captionLines.isEmpty && speech.currentLine.isEmpty)

                        Spacer()

                        // SETTINGS BUTTON (top-right)
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .imageScale(.large)
                                .foregroundColor(primaryTextColor)
                                .padding(.trailing, 16)
                        }
                    }

                    // Trial status banner (only while trial is active and not unlocked)
                    if !purchaseManager.isUnlocked,
                       let daysLeft = purchaseManager.daysRemainingInTrial {
                        TrialBanner(
                            daysLeft: daysLeft,
                            primaryTextColor: primaryTextColor
                        )
                        .padding(.horizontal, 16)
                    }

                    // SINGLE BOX WITH AUTO-SCROLL
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                let staticLines = speech.captionLines
                                let combinedLines: [String] = {
                                    if speech.currentLine.isEmpty {
                                        return staticLines
                                    } else {
                                        return staticLines + [speech.currentLine]
                                    }
                                }()

                                if combinedLines.isEmpty {
                                    Text("Waiting for speech...")
                                        .font(.system(size: fontSize, weight: .semibold))
                                        .foregroundColor(primaryTextColor.opacity(0.3))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    ForEach(combinedLines.indices, id: \.self) { idx in
                                        let line = combinedLines[idx]
                                        // Last 2 lines = live region (full color), older = faded
                                        let isRecent = idx >= combinedLines.count - 2

                                        Text(line)
                                            .font(.system(size: fontSize, weight: .semibold))
                                            .foregroundColor(
                                                isRecent
                                                ? primaryTextColor
                                                : primaryTextColor.opacity(0.35)
                                            )
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }

                                // Anchor at the bottom for auto scroll
                                Color.clear
                                    .frame(height: 1)
                                    .id("BOTTOM")
                            }
                            .padding(.horizontal, 28)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .rotationEffect(rotateForSpeaker ? .degrees(180) : .degrees(0))
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(captionBoxColor)
                                .shadow(radius: 4)
                        )
                        .padding(.horizontal, 16)
                        .onChange(of: speech.captionLines.count) { oldValue, newValue in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                        }
                        .onChange(of: speech.currentLine) { oldValue, newValue in
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("BOTTOM", anchor: .bottom)
                            }
                        }
                    }

                    // CONTROLS
                    VStack(spacing: 16) {
                        // Big, high-contrast buttons
                        VStack(spacing: 12) {
                            Button {
                                if speech.isTranscribing {
                                    speech.stopTranscribing()
                                } else {
                                    speech.startTranscribing()
                                }
                            } label: {
                                Label(
                                    speech.isTranscribing ? "Stop Captioning" : "Start Captioning",
                                    systemImage: speech.isTranscribing
                                        ? "stop.circle.fill"
                                        : "mic.circle.fill"
                                )
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue) // good contrast in both themes
                            .contentShape(Rectangle())

                            Button {
                                speech.clearTranscript()
                            } label: {
                                Label("Clear Screen", systemImage: "trash")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.bordered)
                            .tint(primaryTextColor)
                            .contentShape(Rectangle())
                        }
                        .padding(.horizontal, 24)

                        // Listening indicator (for reassurance)
                        if speech.isTranscribing {
                            Label("Listening…", systemImage: "waveform")
                                .foregroundColor(.red)
                                .font(.headline)
                        }

                        // Font size + color theme controls
                        VStack(spacing: 12) {
                            HStack {
                                Text("Text Size")
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                            }
                            .padding(.horizontal, 24)

                            HStack {
                                Text("A")
                                    .font(.system(size: 18))
                                    .foregroundColor(primaryTextColor)
                                Slider(value: $fontSize, in: 24...72)
                                Text("A")
                                    .font(.system(size: 30))
                                    .foregroundColor(primaryTextColor)
                            }
                            .padding(.horizontal, 24)

                            Toggle(isOn: $useDarkCaptionTheme) {
                                Text("Light text on dark background")
                                    .foregroundColor(primaryTextColor)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(onShowOnboarding: {
                // When user taps "View Getting Started Guide" in Settings
                showOnboarding = true
            })
            .preferredColorScheme(useDarkCaptionTheme ? .dark : .light)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [shareText])
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showOnboarding = false
            }
            .preferredColorScheme(useDarkCaptionTheme ? .dark : .light)
        }
        .onAppear {
            speech.requestAuthorization()
            // Start trial on first real use
            purchaseManager.startTrialIfNeeded()

            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        // ❗ Keep screen awake while transcribing
        .onChange(of: speech.isTranscribing) { isOn in
            UIApplication.shared.isIdleTimerDisabled = isOn
        }
        // Safety: if app leaves active state, re-enable idle timer
        .onChange(of: scenePhase) { phase in
            if phase != .active {
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

// MARK: - Trial Banner

private struct TrialBanner: View {
    let daysLeft: Int
    let primaryTextColor: Color

    var body: some View {
        HStack {
            Image(systemName: "clock")
            if daysLeft > 0 {
                Text("Free trial: \(daysLeft) day\(daysLeft == 1 ? "" : "s") left")
            } else {
                Text("Free trial ends today")
            }
            Spacer()
        }
        .font(.subheadline.weight(.semibold))
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(primaryTextColor.opacity(0.08))
        )
    }
}

// MARK: - Paywall View

private struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager

    let primaryTextColor: Color
    let backgroundColor: Color

    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Unlock LiveCaptions")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 24)

            Text("Your 30-day free trial has ended.\nUnlock LiveCaptions forever with a one-time purchase. No subscriptions, no ads, no surprises.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(primaryTextColor.opacity(0.85))
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Label("One-time payment of $4.99", systemImage: "checkmark.circle")
                Label("Unlimited live captioning", systemImage: "checkmark.circle")
                Label("Large, easy-to-read text", systemImage: "checkmark.circle")
                Label("No ads. No monthly fees.", systemImage: "checkmark.circle")
            }
            .font(.body)
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let message = errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                Button {
                    isProcessing = true
                    errorMessage = nil
                    Task {
                        await purchaseManager.purchaseLifetimeUnlock()
                        isProcessing = false
                    }
                } label: {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Unlock Forever – $4.99")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal, 32)

                Button {
                    isProcessing = true
                    errorMessage = nil
                    Task {
                        await purchaseManager.restorePurchases()
                        isProcessing = false
                    }
                } label: {
                    Text("Restore Purchase")
                        .font(.body)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.ignoresSafeArea())
    }
}

// MARK: - Share Sheet Wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {
        // nothing to update
    }
}

