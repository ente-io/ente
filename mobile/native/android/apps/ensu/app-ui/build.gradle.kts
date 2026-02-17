import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

configurations.configureEach {
    exclude(group = "com.google.guava", module = "listenablefuture")
}

val apiEndpointOverride = (System.getenv("ENTE_API_ENDPOINT")
    ?: project.findProperty("ENTE_API_ENDPOINT") as? String)
    ?.trim()
    .orEmpty()

if (apiEndpointOverride.isNotBlank()) {
    println("ENTE_API_ENDPOINT set for build: $apiEndpointOverride")
} else {
    println("ENTE_API_ENDPOINT not set; BuildConfig.API_ENDPOINT will be empty")
}

val keystorePropsFile = rootProject.file("key.properties")
val keystoreProps = Properties()
val hasReleaseKeystore = keystorePropsFile.exists()
if (hasReleaseKeystore) {
    keystorePropsFile.inputStream().use { keystoreProps.load(it) }
}

android {
    namespace = "io.ente.ensu"
    compileSdk = 35

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(keystoreProps["storeFile"] as String)
                storePassword = keystoreProps["storePassword"] as String
                keyAlias = keystoreProps["keyAlias"] as String
                keyPassword = keystoreProps["keyPassword"] as String
            } else {
                storeFile = file("../debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    defaultConfig {
        applicationId = "io.ente.ensu"
        minSdk = 24
        targetSdk = 35
        versionCode = 18
        versionName = "0.1.3"
        buildConfigField("String", "API_ENDPOINT", "\"$apiEndpointOverride\"")
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.11"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            pickFirsts += setOf(
                "lib/arm64-v8a/libc++_shared.so",
                "lib/armeabi-v7a/libc++_shared.so",
                "lib/x86/libc++_shared.so",
                "lib/x86_64/libc++_shared.so"
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
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.02.02")

    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-text")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.navigation:navigation-compose:2.7.7")
    implementation("com.google.accompanist:accompanist-navigation-animation:0.34.0")
    implementation("app.rive:rive-android:10.2.1") {
        exclude(group = "androidx.lifecycle", module = "lifecycle-runtime-ktx")
    }

    implementation(project(":domain"))
    implementation(project(":data"))
    implementation(project(":crypto-auth-core"))

    implementation("com.github.gregcockroft:AndroidMath:v1.1.0") {
        exclude(group = "com.google.guava", module = "listenablefuture")
    }

    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
