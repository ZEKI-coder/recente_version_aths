plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 Google services Gradle plugin pour Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.recente_version_aths"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.recente_version_aths"
        // 🔥 minSdk doit être au minimum 21 pour Firebase
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // 🔥 Support MultiDex pour Firebase
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 🔥 Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // 🔥 Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // 🔥 Firebase Auth (pas besoin de spécifier la version grâce au BoM)
    implementation("com.google.firebase:firebase-auth")

    // 🔥 Cloud Firestore
    implementation("com.google.firebase:firebase-firestore")

    // 🔥 Support MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
}