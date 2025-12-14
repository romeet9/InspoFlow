# InspoFlow 🌊
**Capture. Analyze. Organize.**

InspoFlow is a native iOS application designed for designers, developers, and creatives who live in their screenshots. It transforms your messy camera roll into a curated, searchable timeline of inspiration, powered by AI.

![Banner](https://images.unsplash.com/photo-1611162617474-5b21e879e113?q=80&w=1000&auto=format&fit=crop)

## ✨ Key Features

*   **智能 Screenshot Ingestion**: Automatically detects screenshots and organizes them into a dedicated feed.
*   **AI-Powered Analysis**: Uses **AWS Rekognition** to scan images, extracting text, detecting valid URLs, and generating smart summaries automatically.
*   **Connected Timeline**: A beautiful, continuous stream of your inspiration, grouped by time for easy browsing.
*   **Savee-Style Detail View**: A clean, minimalist interface that puts your content front and center.
*   **Living Backgrounds** (Optional): Includes a dynamic, animated gradient system for a premium aesthetic.
*   **Privacy First**: All data is stored locally on your device using **SwiftData**.

## 🛠 Tech Stack

*   **Language**: Swift 5.10
*   **UI Framework**: SwiftUI (NavigationStack, MeshGradient, Charts)
*   **Local Database**: SwiftData (Persistent caching)
*   **Cloud AI**: AWS Rekognition (Text & Label usage)
*   **Architecture**: MVVM-C with Clean Architecture principles.

## 🚀 How to Install

Since this is an open-source project without a paid Enterprise certificate, you have two options:

### Option 1: Build from Source (Recommended)
1.  Clone this repository.
2.  Open `InspoFlow.xcodeproj` in Xcode.
3.  Change the **Signing Team** to your personal Apple ID.
4.  Plug in your iPhone and hit **Run**.

### Option 2: Side-Load (AltStore)
1.  Download the latest `.ipa` from the Releases tab (if available).
2.  Use **AltStore** or **SideStore** to install it on your device.

## 🤝 Contributing
InspoFlow is open source! Feel free to fork the repo, create a feature branch, and submit a Pull Request.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
