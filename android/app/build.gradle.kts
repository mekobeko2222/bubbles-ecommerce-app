plugins {
    id("com.android.application")
    id("kotlin-android") // For Kotlin support in Android
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // The Google Services plugin. This must be applied at the very bottom of the plugins block.
    // It processes the google-services.json file for Firebase configuration.
    id("com.google.gms.google-services")
}

android {
    // Defines the package name for your Android application.
    namespace = "com.example.bubbles_ecommerce_app" // Make sure this matches your Firebase project setup
    // Specifies the Android API level against which your app will be compiled.
    compileSdk = flutter.compileSdkVersion
    // Specifies the NDK (Native Development Kit) version to use for native code compilation.
    // THIS IS THE LINE TO FIX THE NDK VERSION MISMATCH ERROR.
    // Set it to the specific version required by the plugins.
    ndkVersion = "27.0.12077973" // <--- UPDATED: Hardcoded NDK version as per plugin requirement

    compileOptions {
        // Sets the Java source and target compatibility to Java 11.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Sets the JVM target version for Kotlin compilation to Java 11.
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // The unique application ID for your app (e.g., com.yourcompany.yourapp).
        // This MUST match the package name you entered in Firebase Console.
        applicationId = "com.example.bubbles_ecommerce_app"
        // The minimum Android API level required to run your app.
        // UPDATED: Increased to 33 for FCM and notification support
        minSdk = 33
        // The Android API level your app is designed to run on, for compatibility behaviors.
        targetSdk = flutter.targetSdkVersion
        // An integer value that represents the version of the application code.
        versionCode = flutter.versionCode
        // A string value that represents the user-friendly version name.
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Configuration for the release build of your app.
            // For production, you would set up your own signing config here.
            // Using debug keys for now for simpler release builds during development.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // Specifies the path to your Flutter project root relative to this Gradle file.
    source = "../.."
}

// This is the 'dependencies' block where you add all your project's external libraries.
dependencies {
    // Import the Firebase BOM (Bill of Materials) to manage Firebase library versions.
    // This ensures all Firebase libraries use compatible versions.
    implementation(platform("com.google.firebase:firebase-bom:33.13.0")) // Use the latest BOM version from Firebase docs

    // Add specific Firebase products you need.
    // These versions are managed by the BOM above, so you don't specify them here.
    implementation("com.google.firebase:firebase-analytics-ktx") // For Firebase Analytics (recommended)
    implementation("com.google.firebase:firebase-auth-ktx")     // For Firebase Authentication
    implementation("com.google.firebase:firebase-firestore-ktx") // For Cloud Firestore database
    implementation("com.google.firebase:firebase-storage-ktx")   // For Firebase Storage (for images)

    // FCM Dependencies - ADDED FOR PUSH NOTIFICATIONS
    implementation("com.google.firebase:firebase-messaging-ktx") // For Firebase Cloud Messaging

    // Kotlin standard library for Android
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
}