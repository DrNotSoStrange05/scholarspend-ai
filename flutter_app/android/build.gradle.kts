allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Global fix for plugins missing a namespace or having a legacy 'package' attribute
subprojects {
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            if (namespace == null) {
                val namespaceMap = mapOf(
                    "telephony" to "com.shounakmulay.telephony",
                    "shared_preferences_android" to "io.flutter.plugins.shared_preferences"
                )
                namespace = namespaceMap[project.name] ?: "com.example.${project.name.replace("-", "_")}"
            }
        }
    }

    // Force-remove 'package' attribute from AndroidManifest.xml for problematic plugins
    project.tasks.configureEach {
        if (name.startsWith("process") && name.endsWith("Manifest")) {
            doFirst {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val newContent = content.replace(Regex("package=\"[^\"]*\""), "")
                        manifestFile.writeText(newContent)
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
