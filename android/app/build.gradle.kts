import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Khóa ký phát hành nằm NGOÀI repo; android/key.properties (đã .gitignore) chỉ trỏ tới nó.
// Cách tạo khóa và nội dung file: docs/RELEASE.md mục "Ký ứng dụng".
val keyPropsFile = rootProject.file("key.properties")
val keyProps = Properties().apply {
    if (keyPropsFile.exists()) FileInputStream(keyPropsFile).use { load(it) }
}

android {
    namespace = "com.phiotron.vigon"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications cần desugaring (java.time trên Android cũ).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.phiotron.vigon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyPropsFile.exists()) {
            create("release") {
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Có key.properties thì ký bằng khóa phát hành. Không có thì ký bằng khóa debug
            // để `flutter build apk --release` thử trên máy vẫn chạy; bản phát hành Play
            // (appbundle) bị chặn ở dưới khi thiếu khóa.
            signingConfig = if (keyPropsFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Không cho build bản phát hành Play bằng khóa debug (Play từ chối, và lộ khóa tạm).
gradle.taskGraph.whenReady {
    if (!keyPropsFile.exists() && allTasks.any { it.project == project && it.name == "bundleRelease" }) {
        throw GradleException(
            "Thiếu android/key.properties: chưa có khóa ký phát hành. " +
                "Xem docs/RELEASE.md, mục 'Ký ứng dụng'."
        )
    }
}
