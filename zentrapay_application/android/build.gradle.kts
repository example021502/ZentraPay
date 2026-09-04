allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all plugin subprojects (like privy_flutter) to compile against Android
// SDK 36. Was pinned to 35 for privy_flutter; bumped because image_picker_android
// (added for Tier-2 KYC document capture) transitively pulls in
// androidx.activity:1.13.0/androidx.core:1.18.0/androidx.navigationevent:1.0.0,
// which all require compileSdk 36+ — every subproject needs to compile against
// the same SDK level the app now does (see :app's compileSdk in its own
// build.gradle.kts) or AGP's AAR-metadata check fails the build.
// NOTE: The evaluationDependsOn(":app") block below forces :app to be evaluated
// eagerly. Registering an afterEvaluate hook on an already-evaluated project
// throws under Gradle 9+ ("Cannot run Project.afterEvaluate(Action) when the
// project is already evaluated"), so skip any project that has already run.
// :app is safely skipped here — it sets its own compileSdk via
// flutter.compileSdkVersion in its build script.
subprojects {
    if (!state.executed) {
        afterEvaluate {
            if (project.hasProperty("android")) {
                val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
                android?.compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}