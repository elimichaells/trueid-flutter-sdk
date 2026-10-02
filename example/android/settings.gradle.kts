pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("com.android.library") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("org.jetbrains.kotlin.plugin.parcelize") version "2.2.20" apply false
}

include(":app")

// Develop against the native SDK sources in ../../../trueid-android-sdk
// when that checkout exists. Pass -PuseMavenTrueidDeps to build against the
// published artifacts on the TrueID Maven repo instead.
val trueidAndroidSdkRoot = file("../../../trueid-android-sdk")
if (trueidAndroidSdkRoot.exists() && !providers.gradleProperty("useMavenTrueidDeps").isPresent) {
    listOf(
        "trueid-core",
        "trueid-nia-sdk",
        "trueid-hosted-sdk",
        "trueid-nfc-sdk",
        "trueid-document-sdk",
    ).forEach { module ->
        include(":$module")
        project(":$module").projectDir = file("$trueidAndroidSdkRoot/$module")
    }
}
