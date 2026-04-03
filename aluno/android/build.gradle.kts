allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirOverride = System.getenv("PECI_ALUNO_BUILD_DIR")
val resolvedBuildDirPath = if (buildDirOverride.isNullOrBlank()) {
    "../../build"
} else {
    buildDirOverride
}

val newBuildDir: Directory =
    rootProject.layout.projectDirectory.dir(resolvedBuildDirPath)
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
