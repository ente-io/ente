import java.io.ByteArrayOutputStream

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

val generatedJniLibsDir = layout.buildDirectory.dir("generated/jniLibs")

fun captureOrNull(vararg command: String): String? {
    val stdout = ByteArrayOutputStream()
    return try {
        exec {
            commandLine(*command)
            standardOutput = stdout
            errorOutput = ByteArrayOutputStream()
        }
        stdout.toString().trim()
    } catch (_: Exception) {
        null
    }
}

fun adbCommand(): List<String> {
    val sdkRoot = System.getenv("ANDROID_HOME") ?: System.getenv("ANDROID_SDK_ROOT")
    val sdkAdb = sdkRoot?.let { file("$it/platform-tools/adb") }
    return when {
        sdkAdb?.canExecute() == true -> listOf(sdkAdb.absolutePath)
        else -> listOf("adb")
    }
}

fun connectedDeviceAbiOrNull(): String? {
    val adb = adbCommand()
    val serial = System.getenv("ANDROID_SERIAL")?.trim().orEmpty().ifBlank {
        val devices = captureOrNull(*(adb + listOf("devices")).toTypedArray())
            ?.lineSequence()
            ?.drop(1)
            ?.map(String::trim)
            ?.filter { it.endsWith("\tdevice") }
            ?.map { it.substringBefore('\t') }
            ?.toList()
            .orEmpty()
        if (devices.size == 1) devices[0] else ""
    }

    if (serial.isBlank()) return null

    return captureOrNull(*(adb + listOf("-s", serial, "shell", "getprop", "ro.product.cpu.abi")).toTypedArray())
        ?.trim()
        ?.takeIf { it in setOf("arm64-v8a", "armeabi-v7a", "x86_64") }
}

fun defaultLocalAbi(): String =
    when (System.getProperty("os.arch")) {
        "aarch64", "arm64" -> "arm64-v8a"
        "x86_64", "amd64" -> "x86_64"
        else -> error("Unsupported host architecture: ${System.getProperty("os.arch")}")
    }

fun requestedRustAbis(): List<String> {
    val taskNames = gradle.startParameter.taskNames
    val isReleaseBuild = taskNames.any {
        it.contains("Release") || it.contains("bundle", ignoreCase = true)
    }

    return if (isReleaseBuild) {
        listOf("arm64-v8a", "armeabi-v7a", "x86_64")
    } else {
        listOf(connectedDeviceAbiOrNull() ?: defaultLocalAbi())
    }
}

val buildRustJni by tasks.registering {
    outputs.dir(generatedJniLibsDir)
    outputs.upToDateWhen { false }

    doLast {
        val abis = requestedRustAbis()
        exec {
            workingDir = file("tool")
            commandLine(
                "bash",
                "./build_android.sh",
                "--out-dir",
                generatedJniLibsDir.get().asFile.absolutePath,
                *abis.toTypedArray(),
            )
        }
    }
}

android {
    namespace = "io.ente.ensu.rust"
    compileSdk = 34

    defaultConfig {
        minSdk = 23
    }

    sourceSets["main"].jniLibs.setSrcDirs(listOf("build/generated/jniLibs"))

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
