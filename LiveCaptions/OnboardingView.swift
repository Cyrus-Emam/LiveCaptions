//
//  OnboardingView.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 12/4/25.
//

import SwiftUI
import Speech

struct OnboardingView: View {
    var onDone: () -> Void

    @State private var pageIndex: Int = 0
    @AppStorage("captionLanguageCode") private var languageCode: String = "en-US"
    @AppStorage("rotateForSpeaker") private var rotateForSpeaker: Bool = false   // NEW

    private static let supportedLocales: [Locale] = {
        let locales = Array(SFSpeechRecognizer.supportedLocales())
        return locales.sorted { lhs, rhs in
            let name1 = Locale.current.localizedString(forIdentifier: lhs.identifier) ?? lhs.identifier
            let name2 = Locale.current.localizedString(forIdentifier: rhs.identifier) ?? rhs.identifier
            return name1 < name2
        }
    }()

    private var languageDisplayName: String {
        Locale.current.localizedString(forIdentifier: languageCode) ?? languageCode
    }

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $pageIndex) {
                    // Page 0 – Intro
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: "captions.bubble.fill")
                            .font(.system(size: 64))
                        Text("Welcome to LiveCaptions")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text("See spoken words as large, easy-to-read captions in real time.")
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding()
                    .tag(0)

                    // Page 1 – Features
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()

                        Text("Made for everyday conversations")
                            .font(.title.bold())

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Big, clear text you can adjust.", systemImage: "textformat.size.larger")
                            Label("Simple Start and Stop buttons.", systemImage: "mic.circle.fill")
                            Label("Dark or light background for comfort.", systemImage: "circle.lefthalf.filled")
                            Label("Screen stays on while captioning.", systemImage: "iphone")
                        }
                        .font(.body)

                        Spacer()
                    }
                    .padding()
                    .tag(1)

                    // Page 2 – Phone placement & rotation (NEW)
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()

                        Text("Place your phone for best captions")
                            .font(.title.bold())

                        Text("For clearer captions, place your phone flat on the table with the bottom edge (charging port side) pointing toward the person speaking.")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Bottom of the phone faces the speaker.", systemImage: "arrow.up.to.line.compact")
                            Label("Screen faces up so you can still see it.", systemImage: "rectangle.portrait")
                        }
                        .font(.subheadline)

                        Divider()
                            .padding(.vertical, 8)

                        Toggle(isOn: $rotateForSpeaker) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rotate captions toward you")
                                    .font(.headline)
                                Text("Flip the captions 180° so they’re easier to read while the bottom of the phone faces the speaker.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer()
                    }
                    .padding()
                    .tag(2)

                    // Page 3 – Language + trial (moved from tag 2 → 3)
                    VStack(alignment: .leading, spacing: 16) {
                        Spacer()

                        Text("Choose your caption language")
                            .font(.title.bold())

                        Picker("Caption Language", selection: $languageCode) {
                            ForEach(Self.supportedLocales, id: \.identifier) { locale in
                                let name = Locale.current.localizedString(forIdentifier: locale.identifier) ?? locale.identifier
                                Text(name).tag(locale.identifier)
                            }
                        }
                        .pickerStyle(.menu)

                        Text("Current language: \(languageDisplayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Divider()
                            .padding(.vertical, 8)

                        Text("Free to try for 30 days")
                            .font(.headline)

                        Text("After your free trial, LiveCaptions is a one-time $4.99 purchase. No subscriptions and no ads.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                    .padding()
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Bottom navigation
                HStack {
                    if pageIndex > 0 {
                        Button("Back") {
                            withAnimation {
                                pageIndex = max(0, pageIndex - 1)
                            }
                        }
                    } else {
                        Spacer().frame(width: 60) // placeholder
                    }

                    Spacer()

                    if pageIndex < 3 {
                        Button("Next") {
                            withAnimation {
                                pageIndex = min(3, pageIndex + 1)
                            }
                        }
                        .font(.headline)
                    } else {
                        Button(action: onDone) {
                            Text("Get Started")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

