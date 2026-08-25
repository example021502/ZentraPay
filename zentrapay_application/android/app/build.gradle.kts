// Android application module configuration for Zentrapay Application.
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Configured using the Android Gradle Plugin ApplicationExtension scope.
android {
    namespace = "zentrapay.com.zentrapay_application"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildToolsVersion = "35.0.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Specify your own unique Application ID.
        applicationId = "zentrapay.com.zentrapay_application"
        // Updated minSdk to 28 to support privy_flutter plugin requirements.
        minSdk = 28
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

    packaging {
        resources {
            excludes += listOf(
                "META-INF/versions/9/OSGI-INF/MANIFEST.MF",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

// Updated Kotlin compiler options replacing the deprecated kotlinOptions block.
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}