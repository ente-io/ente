import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "io.ente.photos.screensaver"
    compileSdk = 34

    defaultConfig {
        applicationId = "io.ente.photos.screensaver"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties not found. Using debug signing for release builds.")
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        viewBinding = true
        buildConfig = true
    }

    lint {
        // These are upgrade suggestions which currently require newer AGP + compileSdk.
        disable.add("GradleDependency")
        disable.add("OldTargetApi")

        // Picasso contains NotificationAction APIs we do not use.
        disable.add("NotificationPermission")
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")

    implementation("androidx.activity:activity-ktx:1.8.2")
    implementation("androidx.preference:preference-ktx:1.2.1")
    implementation("androidx.datastore:datastore-preferences:1.0.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    implementation("io.coil-kt:coil:2.5.0")
    implementation("io.coil-kt:coil-gif:2.5.0")
    implementation("io.coil-kt:coil-svg:2.5.0")

    implementation("com.github.bumptech.glide:glide:4.16.0")
    implementation("com.squareup.picasso:picasso:2.8")

    implementation("io.github.awxkee:jxl-coder-glide:2.3.0")
    implementation("com.github.penfeizhou.android.animation:apng:3.0.5")
    implementation("com.github.penfeizhou.android.animation:awebp:3.0.5")
    implementation("com.github.penfeizhou.android.animation:avif:3.0.5")
    implementation("com.github.zjupure:webpdecoder:2.7.4.16.0")

    // Networking + crypto (ente-core via UniFFI) for Ente public albums.
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("net.java.dev.jna:jna:5.12.1@aar")
    implementation("androidx.exifinterface:exifinterface:1.3.7")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")

    // Setup via phone (QR + local HTTP form).
    implementation("org.nanohttpd:nanohttpd:2.3.1")
    implementation("com.google.zxing:core:3.5.3")
}

val rustCoreDir = rootProject.file("../../../../../rust/uniffi/core")
val jniLibsDir = layout.projectDirectory.dir("src/main/jniLibs").asFile
val rustTargetDir = rootProject.layout.buildDirectory.dir("ente-core").get().asFile

tasks.register<Exec>("buildEnteCore") {
    group = "build"
    description = "Build ente-core Rust library for Android via cargo-ndk."
    workingDir = rustCoreDir
    environment("CARGO_TARGET_DIR", rustTargetDir.absolutePath)
    commandLine(
        "cargo",
        "ndk",
        "-t",
        "armeabi-v7a",
        "-t",
        "arm64-v8a",
        "-t",
        "x86",
        "-t",
        "x86_64",
        "-o",
        jniLibsDir.absolutePath,
        "build",
        "--release",
    )
    inputs.file(File(rustCoreDir, "Cargo.toml"))
    inputs.dir(File(rustCoreDir, "src"))
    outputs.dir(jniLibsDir)
}

tasks.register<Exec>("generateEnteCoreBindings") {
    group = "build"
    description = "Regenerate UniFFI Kotlin bindings for ente-core."
    workingDir = rustCoreDir
    commandLine(
        "uniffi-bindgen",
        "generate",
        "src/core.udl",
        "--language",
        "kotlin",
        "--out-dir",
        layout.projectDirectory.dir("src/main/java").asFile.absolutePath,
        "--config",
        layout.projectDirectory.file("uniffi.toml").asFile.absolutePath,
    )
}

tasks.named("preBuild").configure {
    dependsOn("buildEnteCore")
}
