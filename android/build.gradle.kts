plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

group = "com.trueid.sdk.flutter"
version = "1.0.0"

android {
    namespace = "com.trueid.sdk.flutter"
    compileSdk = 35

    defaultConfig {
        minSdk = 24
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

repositories {
    google()
    mavenCentral()
    maven { url = uri("https://app.trueid.info/sdk/android") }
    maven { url = uri("https://jitpack.io") }
}

dependencies {
    val localSelfieSdk = findProject(":trueid-selfie-sdk")
    if (localSelfieSdk != null) {
        add("implementation", localSelfieSdk)
    } else {
        add("implementation", "com.trueid.sdk:trueid-selfie-sdk:2.5.0")
    }
}
