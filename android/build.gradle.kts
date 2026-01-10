<<<<<<< HEAD
import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

=======
>>>>>>> origin/zeki_dev
plugins {
    // 🔥 Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.4" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

<<<<<<< HEAD
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
=======
rootProject.buildDir = "../build"
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
>>>>>>> origin/zeki_dev
}
subprojects {
    project.evaluationDependsOn(":app")
}

<<<<<<< HEAD
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
=======
tasks.register("clean", Delete) {
    delete rootProject.buildDir
>>>>>>> origin/zeki_dev
}