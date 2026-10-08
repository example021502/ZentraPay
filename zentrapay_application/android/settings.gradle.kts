pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 9.0.1 is the newest AGP already present in this machine's Gradle
    // cache. It requires Gradle 9.1.0+ (see gradle/wrapper/gradle-wrapper.properties)
    // and needs android.newDsl=false + android.builtInKotlin=false in
    // gradle.properties because Flutter's Gradle plugin and the third-party
    // plugins (paystack_flutter_sdk, privy_flutter) still use the old DSL and
    // apply the Kotlin Gradle Plugin themselves.
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

include(":app")
