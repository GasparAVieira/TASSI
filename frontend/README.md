# navigation_diary

A Flutter app for the TASSI navigation diary project.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Project structure

- `lib/` — main Dart source code for the app.
- `assets/` — app assets, including JSON data and other resources.
- `android/` — Android platform integration and Gradle build files.
- `ios/` — iOS platform integration and Xcode project files.
- `web/` — web support files for Flutter web builds.
- `linux/`, `macos/`, `windows/` — desktop support scaffolding.
- `test/` — widget and unit tests.
- `build/` — generated build outputs (do not commit).
- `.gitignore` — files and folders excluded from git.
- `pubspec.yaml` — Flutter package metadata, dependencies, assets.
- `pubspec.lock` — locked dependency versions.

## What is included

This repository contains a cross-platform Flutter app with support for:

- Mobile: Android and iOS
- Web
- Desktop: Linux, macOS, Windows

It also includes localized data content under `assets/data/` and a sample UI layer in `lib/`.

## Local development setup

### 1. Install Flutter

Download Flutter from https://flutter.dev/docs/get-started/install.

### 2. Install Android tooling

- Install Android Studio.
- Install the Android SDK and Android SDK Platform tools.
- In Android Studio, install:
  - Android SDK Platform 33+ (or the latest stable version)
  - Android SDK Build-Tools
  - Android SDK Command-line Tools
- Configure an Android emulator or use a physical Android device.

_AI GENERATED_

### 3. Install iOS tooling (macOS only)

- Install Xcode from the App Store.
- Open Xcode once to accept the license and install required components.
- Install CocoaPods if needed:
  ```bash
  sudo gem install cocoapods
  ```
- Run `flutter doctor` to verify iOS setup.

_AI GENERATED_

### 4. Install an editor

Recommended editors:

- Visual Studio Code with Flutter and Dart extensions
- Android Studio

### 5. Fetch packages

From the project root:

```bash
flutter pub get
```

## Running the app

### Android

Connect a device or start an emulator, then run:

```bash
flutter run
```

OR use F5 with the device connected.

### iOS

On macOS with a connected iPhone or simulator:

```bash
flutter run
```

## Phone setup

### Android device

1. Open `Settings` > `About phone`.
2. Tap `Build number` seven times to enable Developer options.
3. Open `Settings` > `System` > `Developer options`.
4. Enable `USB debugging`.
5. Connect the phone to your PC with USB.
6. Accept the trust prompt on the phone.

_AI GENERATED_

### iOS device

1. Use a Mac with Xcode installed.
2. Connect the device to the Mac.
3. Open Xcode and pair the device.
4. In the phone settings, trust the connected computer.
5. Make sure the device is registered for development if needed.

_AI GENERATED_

## Notes

- Do not commit `build/`, `.dart_tool/`, or other generated files.
- `.gitignore` is already present in the repository root to exclude build artifacts and IDE files.
- This README describes setup and structure only; no Git repository was initialized in this folder. _AI GENERATED_
