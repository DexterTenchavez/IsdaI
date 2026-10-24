plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.isda_development"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.isda_development"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // If both tflite_flutter and ultralytics_yolo ship libtensorflowlite_jni.so,
    // keep the first one found instead of failing with a duplicate-file error.
    packaging {
        jniLibs {
            pickFirsts += "**/libtensorflowlite_jni.so"
            useLegacyPackaging = true
        }
    }
}

// Fix: ultralytics_yolo (LiteRT 2.x) and tflite_flutter both ship org.tensorflow.lite.* classes.
// LiteRT 2.x already contains them, so drop the old standalone Java modules.
// tflite_flutter only uses the native .so through FFI, so it doesn't need these.
configurations.all {
    exclude(group = "com.google.ai.edge.litert", module = "litert-api")
    exclude(group = "org.tensorflow", module = "tensorflow-lite")
    exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
}

flutter {
    source = "../.."
}