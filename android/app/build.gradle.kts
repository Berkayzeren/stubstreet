import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.biletsokagi.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.biletsokagi.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}

// Fix for SharedPreferencesPlugin issue
tasks.register("fixGeneratedPluginRegistrant") {
    doLast {
        val registrantFile = file("$projectDir/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
        if (registrantFile.exists()) {
            var content = registrantFile.readText()
            
            // Replace SharedPreferencesPlugin with LegacySharedPreferencesPlugin
            content = content.replace(
                "new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin()",
                "new io.flutter.plugins.sharedpreferences.LegacySharedPreferencesPlugin()"
            )
            
            registrantFile.writeText(content)
            println("✅ Fixed GeneratedPluginRegistrant.java")
        }
    }
}

// Hook the fix task to run before Java compilation
tasks.whenTaskAdded {
    if (name == "compileDebugJavaWithJavac" ||
        name == "compileReleaseJavaWithJavac" ||
        name == "compileProfileJavaWithJavac") {
        dependsOn("fixGeneratedPluginRegistrant")
    }
}

// Also run after Flutter generates files
tasks.whenTaskAdded {
    if (name == "generateDebugBuildConfig" || 
        name == "generateReleaseBuildConfig" ||
        name == "generateProfileBuildConfig") {
        finalizedBy("fixGeneratedPluginRegistrant")
    }
}
