# IsdaAI

IsdaAI is a Flutter-based mobile application for fish identification and recipe recommendations. The app uses AI models (YOLO and ONNX) to detect and classify fish species from images, then provides relevant recipe suggestions.

## Project Information

- **Version:** 1.0.0+1
- **Package Name:** isda_development
- **SDK:** Flutter/Dart ^3.11.5

## Tech Stack & Versions

| Component | Version |
|-----------|---------|
| Flutter | 3.41.7 (stable) |
| Dart | 3.11.5 |
| DevTools | 2.54.2 |
| Java (OpenJDK) | 21.0.12.1 LTS (Microsoft) |
| Rust | 1.97.0 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Gradle | 8.14 |
| Android Compile SDK | flutter.compileSdkVersion |
| Java Compatibility | 17 |

## Features

- **Fish Detection**: Uses YOLOv8 model (`yolo_fish_detector.tflite`) for fish detection
- **Fish Classification**: Uses ONNX model (`isdaai_14classes.onnx`) to classify fish species
- **Camera Integration**: Real-time fish scanning with camera
- **Recipe Recommendations**: Get recipe suggestions based on identified fish species
- **History Tracking**: Save and view scan history
- **Multi-language Support**: App supports multiple languages
- **Dark/Light Theme**: Theme switching with day/night toggle

## AI Models

The app includes the following models in `assets/models/`:
- `yolo_fish_detector.tflite` - YOLO fish detection model
- `isdaai_14classes.onnx` - Fish classification model (14 classes)
- `labels.txt` - Classification labels

## Dependencies

### Core Dependencies
- `flutter_onnxruntime: ^1.7.0` - ONNX runtime for model inference
- `camera: ^0.11.0+2` - Camera functionality
- `tflite_flutter: ^0.11.0` - TensorFlow Lite inference
- `ultralytics_yolo: ^0.6.15` - YOLO integration
- `image: ^4.2.0` - Image processing
- `image_picker: ^1.1.2` - Image selection from gallery
- `path_provider: ^2.1.6` - File system access
- `shared_preferences: ^2.5.6` - Local preferences storage
- `sqflite: ^2.4.2+1` - SQLite database for history
- `path: ^1.9.1` - Path manipulation

### Dev Dependencies
- `flutter_launcher_icons: ^0.14.4` - App icon generation
- `flutter_native_splash: ^2.4.7` - Splash screen generation

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.11.5 or higher
- [Android Studio](https://developer.android.com/studio) with Android SDK
- [Java JDK](https://adoptium.net/) 17 or higher (Java 21 recommended)
- For iOS development: Xcode (macOS only)

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd isda_development
```

2. Install dependencies
```bash
flutter pub get
```

3. Run the app
```bash
flutter run
```

### Building

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
│   ├── scan/                # Camera and scan result screens
│   └── recipes/             # Recipe recommendation screens
├── services/                # Business logic
│   ├── ai/                  # AI model services (YOLO, Classifier)
│   ├── language/            # Localization
│   ├── settings/            # App settings
│   └── storage/             # Database and storage
└── widgets/                 # Reusable UI widgets
```

## Configuration Notes

- The app excludes conflicting TensorFlow Lite dependencies in `build.gradle.kts` to resolve conflicts between `tflite_flutter` and `ultralytics_yolo`
- JNI libraries use `pickFirsts` strategy for `libtensorflowlite_jni.so`
- App uses Java 17 compatibility

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter Learning Resources](https://docs.flutter.dev/reference/learning-resources)
