plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter mencari artefak Android di <project-root>/build. Tanpa redirect ini,
// Gradle menaruh APK di android/app/build sehingga `flutter run` tidak dapat
// menemukan hasil assembleDebug walaupun task Gradle selesai.
val flutterBuildDirectory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(flutterBuildDirectory)

subprojects {
    val subprojectBuildDirectory = flutterBuildDirectory.dir(project.name)
    project.layout.buildDirectory.value(subprojectBuildDirectory)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
