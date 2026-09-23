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
    
    fun applyNamespace() {
        val androidExtension = extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
        if (androidExtension != null && androidExtension.namespace == null) {
            val pkgName = project.group.toString().ifEmpty {
                "com.shilpasena.plugin.${project.name.replace("-", "_")}"
            }
            androidExtension.namespace = pkgName
        }
    }

    if (state.executed) {
        applyNamespace()
    } else {
        afterEvaluate {
            applyNamespace()
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
