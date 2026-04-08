import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure

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
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            compileSdk = 36
            if (namespace.isNullOrBlank()) {
                val manifest = project.file("src/main/AndroidManifest.xml")
                val manifestText = if (manifest.exists()) manifest.readText() else ""
                val match = Regex("package=\"([^\"]+)\"").find(manifestText)
                val manifestNamespace = match?.groupValues?.get(1)
                namespace = if (!manifestNamespace.isNullOrBlank()) {
                    manifestNamespace
                } else {
                    "com.example.${project.name}"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
