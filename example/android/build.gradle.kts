allprojects {
    repositories {
        google()
        mavenCentral()
        // Uncommitted local override: 2.4.0 isn't live on app.trueid.info until
        // dev is promoted to main; this points at the locally-published artifacts.
        maven { url = uri("file:///C:/Users/micha/StudioProjects/lite_nfc_kyc/build/trueid-selfie-sdk/sdk-maven-repo") }
        // Uncommitted local override: trueid-document-sdk 1.0.0 has never been
        // published anywhere but this local repo.
        maven { url = uri("file:///C:/Users/micha/StudioProjects/lite_nfc_kyc/build/trueid-document-sdk/sdk-maven-repo") }
        maven { url = uri("https://app.trueid.info/sdk/android") }
        maven { url = uri("https://jitpack.io") }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
