import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.LibraryPlugin

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

    plugins.withType<LibraryPlugin> {
        configure<LibraryExtension> {
            if (namespace == null) {
                namespace = project.group?.toString()
                    ?: project.name.replace("-", "_").lowercase().let {
                        if (it.startsWith(".")) "com$it" else "com.$it"
                    }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
