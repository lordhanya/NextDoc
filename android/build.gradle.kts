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

    // Flutter plugins (isar_flutter_libs 3.1.0+1) hardcode compileSdk=30,
    // which can't resolve android:attr/lStar from AndroidX on API 31+.
    // afterEvaluate runs after the plugin's own build.gradle, so ours wins.
    afterEvaluate {
        val androidExt = project.extensions.findByName("android")
        if (androidExt is LibraryExtension) {
            androidExt.compileSdk = 35
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
