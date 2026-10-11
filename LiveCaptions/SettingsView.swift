//
//  SettingsView.swift
//  LiveCaptions
//
//  Created by Cyrus Emam on 10/11/26.
//

import SwiftUI
import Speech
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("captionLanguageCode") private var languageCode: String = "en-US"
    @AppStorage("rotateForSpeaker") private var rotateForSpeaker: Bool = false   // ⬅ NEW

    // Called when user taps "View Getting Started Guide"
    var onShowOnboarding: () -> Void

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
                Section(header: Text("Caption Orientation")) {   // ⬅ NEW
                    Toggle("Rotate screen toward listener", isOn: $rotateForSpeaker)
                }

                // ----------------------------
                // PRIVACY & Support SECTION
                // ----------------------------
                Section(header: Text("Privacy & Support")) {

                    // Replace URLs with your actual hosted pages
                    Link(destination: URL(string: "https://sites.google.com/view/insaight/privacy-policy")!) {
                        Label("Privacy Policy", systemImage: "doc.text")
                    }

                    Link(destination: URL(string: "https://sites.google.com/view/insaight/support")!) {
                        Label("Support", systemImage: "doc.text")
                    }
                }

                // ----------------------------
                // ABOUT / ONBOARDING
                // ----------------------------
                Section(header: Text("About")) {

                    Button {
                        // Close Settings, then show onboarding in the main view
                        dismiss()
                        onShowOnboarding()
                    } label: {
                        Label("View Getting Started Guide", systemImage: "questionmark.circle")
                    }

                    Text("LiveCaptions shows spoken words as large, easy-to-read captions in real time. Designed for accessibility, clarity, and simplicity.")
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Version 1.0")
                        .foregroundColor(.secondary)
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
