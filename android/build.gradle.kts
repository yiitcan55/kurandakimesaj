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

// Plugin'lerin (receive_sharing_intent, share_plus, audio_session vb.) Java
// hedefi compileOptions ile eski bir sürüme (1.8/11) sabitliyken Kotlin hedefi
// sabitlenmediğinden KGP 2.2.20 onu Gradle JDK'sına (21) göre belirliyor ve
// modül içinde "Inconsistent JVM-target" hatası çıkıyor.
//
// Java tarafını ZORLAMIYORUZ: task'a doğrudan source/targetCompatibility yazmak
// javac'ı `--release` moduna sokup Android bootclasspath'ini (android.jar)
// düşürüyor ("package Surface does not exist" gibi hatalar). Bunun yerine her
// modülün mevcut Java hedefini okuyup Kotlin'i ona EŞİTLİYORUZ. Böylece modül
// içi tutarlılık sağlanır, android.jar'a dokunulmaz. afterEvaluate'i
// plugins.withId içinde kaydediyoruz ki AGP compileOptions'ı uyguladıktan
// SONRA çalışsın ve doğru Java hedefini okuyabilelim.
subprojects {
    plugins.withId("com.android.library") {
        project.afterEvaluate {
            val javaTarget = tasks.withType<JavaCompile>()
                .firstOrNull()?.targetCompatibility
            val kotlinTarget = when (javaTarget) {
                "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
                "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
                "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
                "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
                else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            }
            tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java)
                .configureEach {
                    compilerOptions.jvmTarget.set(kotlinTarget)
                }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
