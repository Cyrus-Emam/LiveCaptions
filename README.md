# LiveCaptions

**Real-time captions for more inclusive conversations.**

LiveCaptions is an iPhone accessibility app created by **Cyrus Emam** to make spoken conversations easier to follow for people who are hard of hearing, especially older adults.

## Why I built it

Both of my grandmothers have difficulty hearing. At family gatherings, I noticed that they were participating less in conversations, even when using hearing aids. I wanted to help them stay connected to the people around them.

I was inspired by how closed captions make television easier to understand. LiveCaptions brings a similar idea to in-person conversations: spoken words appear as large, readable text on an iPhone screen.

## Features

- **Live speech-to-text captions:** Displays recognized speech as the conversation happens.
- **Adjustable text size:** A large-text interface designed for readability.
- **High-contrast appearance:** Option to switch between light and dark caption themes.
- **Conversation-friendly display:** Option to rotate the caption text 180 degrees for face-to-face use.
- **Readable transcript:** Recent captions are emphasized while older lines appear lighter, with automatic scrolling.
- **Simple controls:** Start or stop captioning, clear the screen, and share the transcript.
- **First-run guide:** An introduction to help new users get started.

> **Language support:** Speech recognition capabilities depend on the languages supported and configured in the installed version of the app and on the device. Multilingual accessibility is an important design goal; verify the current build's available languages before describing specific language support.

## Built with

- **Swift** and **SwiftUI** for the iPhone interface and app behavior
- **Apple speech recognition APIs** for live transcription
- **Xcode** for development and testing
- **Git and GitHub** for version control

## Design and engineering challenges

**Keeping captions easy to follow.** Live transcription changes as speech is recognized. I iterated on the presentation of recent and older text to make the conversation easier to read.

**Designing for older adults.** I prioritized legible typography, high contrast, and straightforward controls rather than a complex interface.

**Supporting face-to-face use.** I explored device positioning and display orientation so captions can be read in different conversation setups. Rotating the display does not, by itself, change microphone direction or guarantee better audio capture.

**Considering multilingual families.** My grandmothers' language backgrounds motivated me to explore multilingual speech recognition and its device-dependent limitations.

## Getting started

1. Open the `LiveCaptions.xcodeproj` project in Xcode.
2. Select an iPhone device as the run destination.
3. Build and run the app.
4. Grant microphone and speech-recognition permissions when prompted.
5. Tap **Start Captioning** and speak near the phone.

The competition version is intended to allow access to captioning without a payment or trial screen.

## Privacy and limitations

LiveCaptions needs microphone and speech-recognition permissions to transcribe speech. Speech recognition accuracy can vary with background noise, speaker clarity, language, and device capabilities. The app is an accessibility aid, not a replacement for hearing aids or professional captioning services.

Before making public privacy claims, review the exact behavior of the current speech-recognition implementation and any applicable Apple services.

## Development process and AI assistance

I identified the problem through observing my grandmothers, researched accessibility solutions and iPhone capabilities, defined the requirements, and iterated on the design through testing.

I used **ChatGPT as a development assistant** to explore Swift and SwiftUI examples, consider implementation approaches, and troubleshoot code. I reviewed and tested suggestions and directed the app's requirements, design, and validation. AI assistance was part of my development workflow.

## Project status

LiveCaptions is a working iPhone project being prepared for the **Congressional App Challenge**. Features and language availability should be verified against the latest build.

## Author

**Cyrus Emam**  
Student developer  
GitHub: [@Cyrus-Emam](https://github.com/Cyrus-Emam)
