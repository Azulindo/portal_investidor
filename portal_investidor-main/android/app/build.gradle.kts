import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// A chave de assinatura nunca entra no repositorio: o android/.gitignore ja
// ignora o key.properties e os ficheiros .jks. Enquanto o ficheiro nao existir,
// o release assina-se com as chaves de debug, para o `flutter run --release`
// continuar a funcionar na maquina de quem nao tem a chave. Um pacote assinado
// assim serve para testar, mas a Play Console recusa-o.
val chaveProps = Properties()
val chaveFicheiro = rootProject.file("key.properties")
if (chaveFicheiro.exists()) {
    FileInputStream(chaveFicheiro).use { chaveProps.load(it) }
}
val temChaveDeAssinatura = chaveProps.getProperty("storeFile") != null

android {
    namespace = "com.cleveroption.portalinvestidor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Definitivo: mudar isto depois de publicar faz uma app nova na loja,
        // com instalacoes a zero e sem atualizacoes para quem ja a tinha.
        applicationId = "com.cleveroption.portalinvestidor"
        minSdk = flutter.minSdkVersion
        // Fixo, e nao herdado do Flutter instalado: a Google exige 36 desde
        // agosto de 2026, e uma atualizacao do Flutter nao deve poder baixa-lo
        // sem ninguem dar por isso.
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (temChaveDeAssinatura) {
            create("upload") {
                storeFile = file(chaveProps.getProperty("storeFile"))
                storePassword = chaveProps.getProperty("storePassword")
                keyAlias = chaveProps.getProperty("keyAlias")
                keyPassword = chaveProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temChaveDeAssinatura) {
                signingConfigs.getByName("upload")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
