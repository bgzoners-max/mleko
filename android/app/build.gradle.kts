import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// ---------------------------------------------------------------------------
// Potpisivanje release builda
//
// Podaci se citaju iz android/key.properties (u .gitignore-u). Ako fajl ne
// postoji, release se privremeno potpisuje debug kljucem kako bi lokalni
// `flutter run --release` radio; za distribuciju je obavezan pravi keystore,
// a build se moze zakljucati sa -PrequireReleaseSigning=true (npr. u CI-ju).
// Uputstvo: docs/ANDROID_RELEASE_SIGNING.md
// ---------------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()

if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
    val requiredKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    val missing = requiredKeys.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
    if (missing.isNotEmpty()) {
        throw GradleException(
            "android/key.properties ne sadrzi obavezne kljuceve: " +
                missing.joinToString(", ") +
                ". Uputstvo: docs/ANDROID_RELEASE_SIGNING.md"
        )
    }
}

val requireReleaseSigning = providers.gradleProperty("requireReleaseSigning")
    .map { it.equals("true", ignoreCase = true) }
    .getOrElse(false)

android {
    namespace = "com.mleko.mleko"
    // permission_handler 13.x traži Android SDK 37; flutter.compileSdkVersion je 36.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        multiDexEnabled = true
        applicationId = "com.mleko.mleko"
        minSdk = flutter.minSdkVersion  // Google Maps zahteva min 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else if (requireReleaseSigning) {
                throw GradleException(
                    "Release build zahteva android/key.properties sa pravim keystore-om. " +
                        "Uputstvo: docs/ANDROID_RELEASE_SIGNING.md"
                )
            } else {
                logger.warn(
                    "UPOZORENJE: android/key.properties ne postoji - release build se " +
                        "potpisuje DEBUG kljucem i ne moze na Google Play. " +
                        "Uputstvo: docs/ANDROID_RELEASE_SIGNING.md"
                )
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
