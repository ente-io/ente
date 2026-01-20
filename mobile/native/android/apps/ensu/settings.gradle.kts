pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "ensu"
include(":app-ui", ":domain", ":data", ":crypto-auth-core", ":rust")

project(":rust").projectDir = file("../../packages/rust")
