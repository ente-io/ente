import java.io.ByteArrayOutputStream

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val generatedJniLibsDir = layout.buildDirectory.dir("generated/jniLibs")

val buildRustJni by tasks.registering {
    val knownAbis = listOf("arm64-v8a", "armeabi-v7a", "x86_64")

    fun capture(vararg cmd: String): String? = runCatching {
        val out = ByteArrayOutputStream()
        exec {
            commandLine(*cmd)
            standardOutput = out
            errorOutput = ByteArrayOutputStream()
        }
        out.toString().trim()
    }.getOrNull()

    fun connectedDeviceAbi(): String? {
        val sdkRoot = System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT")
        val adb = sdkRoot?.let { "$it/platform-tools/adb" } ?: "adb"
        val serial = System.getenv("ANDROID_SERIAL")?.takeIf { it.isNotBlank() }
            ?: capture(adb, "devices")?.lines()?.drop(1)
                ?.mapNotNull { l -> l.trim().takeIf { it.endsWith("\tdevice") }?.substringBefore('\t') }
                ?.singleOrNull()
            ?: return null
        return capture(adb, "-s", serial, "shell", "getprop", "ro.product.cpu.abi")
            ?.takeIf { it in knownAbis }
    }

    fun hostAbi(): String = when (System.getProperty("os.arch")) {
        "aarch64", "arm64" -> "arm64-v8a"
        "x86_64", "amd64" -> "x86_64"
        else -> error("Unsupported host architecture: ${System.getProperty("os.arch")}")
    }

    fun requestedAbis(): List<String> {
        val isRelease = gradle.startParameter.taskNames.any {
            it.contains("Release") || it.contains("bundle", ignoreCase = true)
        }
        return if (isRelease) knownAbis
        else listOf(connectedDeviceAbi() ?: hostAbi())
    }

    fun ndkToolchain(ndkDir: java.io.File): java.io.File =
        ndkDir.resolve("toolchains/llvm/prebuilt")
            .listFiles { f -> f.isDirectory }
            ?.singleOrNull()
            ?: error("Expected exactly one NDK host toolchain in $ndkDir/toolchains/llvm/prebuilt")

    val abis = requestedAbis()

    inputs.files(fileTree(file("../../../../../rust")) { exclude("**/target/**") })
    inputs.file(file("scripts/build-rust.sh"))
    inputs.property("abis", abis)
    inputs.property("ndk", providers.provider { android.ndkDirectory.absolutePath })
    outputs.dir(generatedJniLibsDir)

    doLast {
        val ndkDir = android.ndkDirectory
        val toolchain = ndkToolchain(ndkDir)

        // Wipe every known ABI so a debug ↔ release switch doesn't leave stale
        // architectures from a previous build sitting in the APK.
        val outDir = generatedJniLibsDir.get().asFile
        knownAbis.forEach { outDir.resolve(it).deleteRecursively() }

        exec {
            workingDir = file("scripts")
            commandLine(
                "bash",
                "./build-rust.sh",
                "--toolchain", toolchain.absolutePath,
                "--out-dir", generatedJniLibsDir.get().asFile.absolutePath,
                *abis.toTypedArray(),
            )
            environment("ANDROID_NDK", ndkDir.absolutePath)
            environment("ANDROID_NDK_ROOT", ndkDir.absolutePath)
            environment("NDK_ROOT", ndkDir.absolutePath)
        }
    }
}

android {
    namespace = "io.ente.ensu.rust"
    compileSdk = 34

    defaultConfig {
        minSdk = 24
    }

    sourceSets["main"].jniLibs.setSrcDirs(listOf(generatedJniLibsDir))

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

tasks.matching { it.name.startsWith("pre") && it.name.endsWith("Build") }.configureEach {
    dependsOn(buildRustJni)
}

dependencies {
    api("net.java.dev.jna:jna:5.14.0@aar")
    api("androidx.annotation:annotation:1.7.1")
}
