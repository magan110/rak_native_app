// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.tasks.compile.JavaCompile

// Load signing properties from `key.properties` (optional, you're currently not using it)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.rakapp.com"

    // Uses the Flutter-managed compileSdk value (usually 35 on latest Flutter)
    compileSdk = flutter.compileSdkVersion

    // NDK version supporting 16 KB memory page size
    // NDK r28+ compiles with 16 KB alignment by default
    ndkVersion = "28.2.13676358"

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        // Java 11 is fine with AGP 8.x
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // New packaging block (AGP 8.x) – required for proper 16 KB support
    packaging {
        jniLibs {
            // Must be false for modern bundles – required for 16 KB page size devices
            // This ensures native libraries are uncompressed and properly aligned
            useLegacyPackaging = false
        }
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
        // Explicit release keystore config – keep your real path/passwords here
        create("release") {
            // You can also read from keystoreProperties if you prefer:
            // storeFile = file(keystoreProperties["storeFile"] as String)
            // storePassword = keystoreProperties["storePassword"] as String
            // keyAlias = keystoreProperties["keyAlias"] as String
            // keyPassword = keystoreProperties["keyPassword"] as String

            storeFile = file("../../keystores/rak_keystore_new.jks")
            storePassword = "rakapp123"
            keyAlias = "rak_key"
            keyPassword = "rakapp123"
        }
    }

    defaultConfig {
        // Unique Application ID for Play Store
        applicationId = "com.rakapp.com"

        // Use Flutter-managed minSdk / versioning
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex support for large apps
        multiDexEnabled = true

        // Restrict ABIs to these three (good practice for Play)
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }

        // 16 KB page size support: NDK r28+ compiles with 16 KB alignment by default
        // Flutter's build system and AGP 8.5.1+ handle 16 KB alignment automatically
        // All native libraries from Flutter plugins will be compiled with 16 KB alignment
        
        // Force 16KB page alignment for all native libraries
        externalNativeBuild {
            cmake {
                arguments += listOf("-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON")
            }
        }

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // Explicitly configure bundle splits
    bundle {
        language {
            // Keep all languages in a single bundle (no language split)
            enableSplit = false
        }
        density {
            // No density split
            enableSplit = false
        }
        abi {
            // ABI split is usually fine (smaller downloads per device)
            enableSplit = true
        }
    }

    // New-style lint block for AGP 8.x
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    buildTypes {
        getByName("release") {
            // Always use the release signing config for release builds
            signingConfig = signingConfigs.getByName("release")

            // Recommended for Play release builds
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            

        }

        getByName("debug") {
            // Keep debug builds fast
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Suppress unchecked warnings from third-party Java libraries
tasks.withType<JavaCompile>().configureEach {
    options.compilerArgs.add("-Xlint:-unchecked")
}

dependencies {
    // AndroidX MultiDex for large apps
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    // Path to the Flutter module
    source = "../.."
}
