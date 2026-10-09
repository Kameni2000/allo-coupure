import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // AJOUTE LA LIGNE SUIVANTE
    id("com.google.gms.google-services")
}

val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
     keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.example.allo_coupure"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ Ajoute ceci
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.allo_coupure"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }
    // AJOUTE CETTE SECTION
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = file(keyProperties["storeFile"] as String?)
            storePassword = keyProperties["storePassword"] as String?
        }
    }
    

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
           
            signingConfig = signingConfigs.getByName("release")

            firebaseCrashlytics {
            nativeSymbolUploadEnabled = true
        }
        }

        
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Import BoM Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") 
    // Firebase Messaging (obligatoire pour les notifications)
    implementation("com.google.firebase:firebase-messaging")

    // Crashlytics pour suivre les crashs sur les appareils
    implementation("com.google.firebase:firebase-crashlytics")
    
}
