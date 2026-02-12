plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "io.ente.ensu.rust"
    compileSdk = 34

    defaultConfig {
        minSdk = 23
    }

    sourceSets["main"].jniLibs.srcDir("src/main/jniLibs")

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    api("net.java.dev.jna:jna:5.14.0@aar")
    api("androidx.annotation:annotation:1.7.1")
}
