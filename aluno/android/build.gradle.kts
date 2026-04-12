allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val buildDirOverride = System.getenv("PECI_ALUNO_BUILD_DIR")
val resolvedBuildDirPath = if (buildDirOverride.isNullOrBlank()) {
    "../build"
} else {
    buildDirOverride
}

val newBuildDir: Directory =
    rootProject.layout.projectDirectory.dir(resolvedBuildDirPath)
rootProject.layout.buildDirectory.value(newBuildDir)
subprojects {
    val rootDrive = rootProject.projectDir.absolutePath.substringBefore(':')
    val projectDrive = project.projectDir.absolutePath.substringBefore(':')
    if (rootDrive.equals(projectDrive, ignoreCase = true)) {
        val newSubprojectBuildDir: Directory = if (project.name == "app") {
            rootProject.layout.projectDirectory.dir("../build").dir(project.name)
        } else {
            newBuildDir.dir(project.name)
        }
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}