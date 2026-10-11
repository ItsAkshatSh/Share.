buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
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
    val setBuildTools = {
        if (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library")) {
            val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
            androidExt?.buildToolsVersion("35.0.0")
        }
    }
    if (project.state.executed) {
        setBuildTools()
    } else {
        project.afterEvaluate { setBuildTools() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
