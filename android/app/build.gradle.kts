plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.out_tracker"
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
        // 1. Jangan lupa tanda '=' di sini
        applicationId = "com.example.out_tracker"
        
        // 2. minSdk kita naikkan ke 23 untuk Firebase
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        
        // 3. Kita ubah jadi angka langsung (Hardcode) biar KTS gak rewel
        versionCode = 1
        versionName = "1.0"
        
        // 4. Obat tambahan untuk mesin database
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
