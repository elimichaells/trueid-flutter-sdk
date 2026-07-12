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

// Local-only override so this example builds against the sibling native
// module checkouts before they're live on the hosted Maven repo. Not
// committed — remove before packaging a release build.
val liteNfcKycRoot = file("../../../lite_nfc_kyc")
if (liteNfcKycRoot.exists()) {
    listOf(
        "trueid-core",
        "trueid-nia-sdk",
        "trueid-hosted-sdk",
        "trueid-nfc-sdk",
        "trueid-document-sdk",
    ).forEach { module ->
        include(":$module")
        project(":$module").projectDir = file("$liteNfcKycRoot/$module")
    }
}
