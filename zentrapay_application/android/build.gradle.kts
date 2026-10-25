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
//
// AGP 9.0 removed the old DSL types (com.android.build.gradle.BaseExtension and
// friends) and exposes only com.android.build.api.dsl.* now. Casting to
// BaseExtension fails under AGP 9 with:
//   ClassCastException: ApplicationExtensionImpl$AgpDecorated_Decorated
//   cannot be cast to com.android.build.gradle.BaseExtension
// so resolve the extension through the new CommonExtension interface and assign
// the `compileSdk` property instead of calling the removed compileSdkVersion().
//
// NOTE: The evaluationDependsOn(":app") block below forces :app to be evaluated
// eagerly. Registering an afterEvaluate hook on an already-evaluated project
// throws under Gradle 9+ ("Cannot run Project.afterEvaluate(Action) when the
// project is already evaluated"), so skip any project that has already run.
// :app is safely skipped here — it sets its own compileSdk via
// flutter.compileSdkVersion in its build script.
subprojects {
    if (!state.executed) {
        afterEvaluate {
            val androidExtension =
                project.extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)
            androidExtension?.compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}