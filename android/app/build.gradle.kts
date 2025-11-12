plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

// Load signing properties from `key.properties` 
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rakapp.com"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Suppress unchecked warnings from third-party libraries
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:-unchecked")
    }
    
    // 16 KB page size support configuration
    packagingOptions {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module"
            )
        }
    }

    signingConfigs {
        create("release") {
            // Configure the release keystore
            storeFile = file("../../keystores/rak_keystore_new.jks")
            storePassword = "rakapp123"
            keyAlias = "rak_key"
            keyPassword = "rakapp123"
        }
    }

    defaultConfig {
        // Unique Application ID for Play Store
        applicationId = "com.rakapp.com"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex support for large apps
        multiDexEnabled = true
        
        // Prevent crashes from missing native libraries
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
        
        // Support for 16 KB page sizes (required for Android 15+)
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    lintOptions {
        isCheckReleaseBuilds = false
        isAbortOnError = false
    }

    buildTypes {
        release {
            // Always use the release signing config for release builds
            signingConfig = signingConfigs.getByName("release")
            
            // Enable minification with proper rules for targetSdk 35
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Use proguard rules that handle missing Play Core classes
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            // Keep debug builds fast by disabling optimizations
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    // AndroidX MultiDex for large apps
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
