// Top-level build file where you can add configuration options common to all sub-projects/modules.

// This 'buildscript' block defines the dependencies and repositories for the Gradle build system itself.
buildscript {
    // Define the Kotlin version for the entire project. This was key to resolving previous errors.
    val kotlin_version by extra("1.9.20") // Use 1.9.20 or the latest stable 1.9.x / 2.0.x version

    repositories {
        // Google's Maven repository, essential for AndroidX, Firebase, and Android Gradle Plugin.
        google()
        // Maven Central repository, a common source for many Java/Android libraries.
        mavenCentral()
    }
    dependencies {
        // The Android Gradle Plugin (AGP) classpath. This needs to be compatible
        // with your Flutter SDK and Android Studio version.
        classpath("com.android.tools.build:gradle:8.4.1") // Or the latest stable version (e.g., 8.5.1 if desired)

        // The Kotlin Gradle plugin classpath. This uses the 'kotlin_version' defined above.
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${kotlin_version}")

        // This is the Google Services plugin classpath. It's required for Firebase to work.
        // It reads the google-services.json file and integrates Firebase services.
        classpath("com.google.gms:google-services:4.4.2") // Use the latest recommended version from Firebase console
    }
}

// Configuration applied to all projects (modules) in your build.
allprojects {
    repositories {
        // Ensure all sub-projects also have access to Google's Maven and Maven Central repositories.
        google()
        mavenCentral()
    }
}

// Custom build directory configuration. This redirects the output of all modules
// to a single 'build' directory two levels up from the 'android' folder (i.e., in your Flutter project root).
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Apply the custom build directory configuration to all sub-projects as well.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// This line ensures that when Gradle evaluates any sub-project (like plugins),
// it first evaluates the ":app" module. This helps establish correct dependency order.
subprojects {
    project.evaluationDependsOn(":app")
}

// Defines a 'clean' task to delete all build directories, useful for fresh builds.
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
