plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Harus di bawah android & kotlin
}

android {
    namespace = "com.example.ai_interview"
    compileSdk = 35  // Atau gunakan flutter.compileSdkVersion jika tersedia
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.ai_interview"
		minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName		
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// Kotlin options secara terpisah (DSL versi Kotlin butuh begini)
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    kotlinOptions {
        jvmTarget = "11"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:${rootProject.extra["kotlin_version"]}")
}

flutter {
    source = "../.."
}
