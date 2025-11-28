# ZOFIO Music Player

**ZOFIO** is a modern, feature-rich music player application built with Flutter. Designed with a sleek, glossy dark aesthetic, it provides a premium audio experience across Android and macOS platforms.

## ✨ Features

*   **High-Quality Audio Playback**: Powered by `just_audio` for seamless and reliable playback.
*   **Background Playback**: Keep the music playing even when the app is minimized or the screen is off.
*   **Local Music Management**: Automatically scans and organizes audio files from your device storage.
*   **Smart Organization**:
    *   **All Songs**: Browse your entire library.
    *   **Folders**: Navigate your music by directory structure.
    *   **Favorites**: Quickly access your most-loved tracks.
*   **Audio Equalizer**: Fine-tune your listening experience with a built-in equalizer.
*   **Beautiful UI/UX**:
    *   **Glossy Dark Mode**: A visually stunning interface designed for modern screens.
    *   **Dynamic Themes**: Customize the look and feel with dynamic color seeding.
    *   **Responsive Design**: Optimized for both mobile and desktop (macOS) layouts.
    *   **Smooth Animations**: Bouncing scroll physics and fluid transitions.
*   **Customization**:
    *   Adjustable font sizes for better accessibility.
    *   Configurable settings to tailor the app to your preferences.

<!-- ## 📸 Screenshots

| Home Screen | Player Screen | Settings |
|:-----------:|:-------------:|:--------:|
| *(Add Screenshot)* | *(Add Screenshot)* | *(Add Screenshot)* | -->

## 🛠️ Tech Stack

*   **Framework**: [Flutter](https://flutter.dev/)
*   **Language**: [Dart](https://dart.dev/)
*   **State Management**: [Provider](https://pub.dev/packages/provider)
*   **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio)
*   **Media Query**: [on_audio_query](https://pub.dev/packages/on_audio_query)
*   **Fonts**: [Google Fonts (Outfit)](https://pub.dev/packages/google_fonts)

## 🚀 Getting Started

Follow these steps to set up the project locally.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
*   An IDE (VS Code, Android Studio, or IntelliJ) with Flutter plugins.
*   **Android**: Android Studio and a connected device/emulator.
*   **macOS**: Xcode and CocoaPods installed.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/sifat_audio.git
    cd sifat_audio
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    *   **Android:**
        ```bash
        flutter run
        ```
    *   **macOS:**
        ```bash
        flutter run -d macos
        ```

## ⚙️ Configuration

### Permissions

*   **Android**: The app requires storage permissions to access audio files. These are handled via `permission_handler`.
*   **macOS**: Ensure App Sandbox permissions are configured for file access if distributing.

## 🤝 Contributing

Contributions are welcome! If you have suggestions or find bugs, please open an issue or submit a pull request.

1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

<!-- ## 📄 License -->

<!-- This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. -->

<!-- --- -->

Built with ❤️ by Sifat
