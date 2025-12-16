//
//  SettingsView.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 12/4/25.
//

import SwiftUI
import Speech
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    @AppStorage("captionLanguageCode") private var languageCode: String = "en-US"
    @AppStorage("rotateForSpeaker") private var rotateForSpeaker: Bool = false

    /// Callback from ContentView to re-show onboarding
    var onShowOnboarding: () -> Void

    // Same supported locales list as OnboardingView
    static let supportedLocales: [Locale] = {
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

    private var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        if version.isEmpty && build.isEmpty {
            return ""
        } else if build.isEmpty {
            return "Version \(version)"
        } else {
            return "Version \(version) (\(build))"
        }
    }

    var body: some View {
        NavigationStack {
            Form {

                // ----------------------------
                // CAPTION LANGUAGE
                // ----------------------------
                Section(header: Text("Caption Language")) {
                    Picker("Language", selection: $languageCode) {
                        ForEach(Self.supportedLocales, id: \.identifier) { locale in
                            let name = Locale.current.localizedString(forIdentifier: locale.identifier)
                                ?? locale.identifier
                            Text(name).tag(locale.identifier)
                        }
                    }

                    Text("Current: \(languageDisplayName)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ----------------------------
                // CAPTION ORIENTATION
                // ----------------------------
                Section(header: Text("Caption Orientation")) {
                    Toggle("Rotate screen toward listener", isOn: $rotateForSpeaker)
                }

                // ----------------------------
                // UPGRADE (VISIBLE IF NOT UNLOCKED)
                // ----------------------------
                if !purchaseManager.isUnlocked {
                    Section(header: Text("Upgrade")) {
                        Button {
                            Task {
                                await purchaseManager.purchaseLifetimeUnlock()
                            }
                        } label: {
                            Text("Unlock Forever – $4.99")
                                .font(.body.weight(.semibold))
                        }

                        Button {
                            Task {
                                await purchaseManager.restorePurchases()
                            }
                        } label: {
                            Text("Restore Purchase")
                        }

                        Text("One-time purchase, no subscription or ads. Your captions stay unlocked forever, even after the free trial ends.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // ----------------------------
                // PRIVACY & SUPPORT
                // ----------------------------
                Section(header: Text("Privacy & Support")) {

                    Link(destination: URL(string: "https://sites.google.com/view/insaight/privacy-policy")!) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }

                    Link(destination: URL(string: "https://sites.google.com/view/insaight/support")!) {
                        Label("Support", systemImage: "envelope")
                    }
                }

                // ----------------------------
                // GETTING STARTED / ONBOARDING
                // ----------------------------
                Section(header: Text("Getting Started")) {
                    Button {
                        onShowOnboarding()
                    } label: {
                        Label("View Getting Started Guide", systemImage: "questionmark.circle")
                    }

                    Text("Review the quick guide to see how LiveCaptions works and how to get the best results.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // ----------------------------
                // ABOUT
                // ----------------------------
                Section(header: Text("About")) {
                    Text("LiveCaptions by InsAIght LLC")

                    if !appVersionString.isEmpty {
                        Text(appVersionString)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
