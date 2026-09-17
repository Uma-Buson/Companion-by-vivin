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

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(
                org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            )
        }
    }

    // Some plugins (e.g. webview_flutter_android) set their own Java
    // compatibility to 11 in their own build.gradle, which runs AFTER this
    // subprojects block and so overrides a plain tasks.withType<JavaCompile>
    // override here. The Kotlin jvmTarget above stays at 17, causing
    // "Inconsistent JVM Target Compatibility" build failures. Re-apply the
    // override once the subproject is evaluated so it wins as the final
    // word - evaluationDependsOn(":app") above can make some subprojects
    // already evaluated by this point, so afterEvaluate isn't always legal.
    fun Project.forceJavaCompatibilityTo17() {
        val ext = extensions.findByType(com.android.build.gradle.BaseExtension::class.java) ?: return
        // Some subprojects (e.g. this project's own :app module) already
        // have this finalized to the correct value by the time we get here
        // and throw on any further write, even to the same value - that's
        // fine to ignore, since it's already correct in that case.
        try {
            ext.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        } catch (_: Exception) {
            // Already finalized - nothing to do.
        }
    }
    if (state.executed) {
        forceJavaCompatibilityTo17()
    } else {
        afterEvaluate { forceJavaCompatibilityTo17() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
