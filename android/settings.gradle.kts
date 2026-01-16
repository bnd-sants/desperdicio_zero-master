pluginManagement {
    val flutterSdkPath = File("C:\\SDK e JDK\\flutter")
    settings.extra["gradle.user.home"] = file("${settings.settingsDir.parentFile}/.gradle")
    settings.extra["flutter.sdk"] = flutterSdkPath.absolutePath

    if (flutterSdkPath.exists()) {
        includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
    } else {
        throw GradleException("Flutter SDK not found at ${flutterSdkPath.absolutePath}")
    }

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    resolutionStrategy {
        eachPlugin {
            when (requested.id.name) {
                "com.android.application" -> useModule("com.android.tools.build:gradle:8.6.0")
                "com.android.library" -> useModule("com.android.tools.build:gradle:8.6.0")
                "org.jetbrains.kotlin.android" -> useVersion("2.1.0")
                "dev.flutter.flutter-gradle-plugin" -> useModule("dev.flutter:gradle:3.16.0")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.6.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")

// Configuração para melhorar o desempenho do build
gradle.projectsLoaded {
    allprojects {
        repositories {
            google()
            mavenCentral()
            maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        }
    }
}

// Memory settings should be configured in gradle.properties
