import java.io.FileInputStream
import java.util.Properties

// Sem o "kotlin-android": a app não tem código Kotlin (o MainActivity é em
// Java), e o Flutter avisava que aplicar o Kotlin Gradle Plugin na app vai
// deixar de funcionar. Os plugins que usam Kotlin tratam disso nos módulos
// deles.
plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android Gradle plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase, só para as notificações push. O google-services.json não entra no
// git (o repositório é público): é descarregado da consola do Firebase e posto
// nesta pasta. Sem ele a app compila na mesma, só sem push — e o
// loja/gerar_pacote.ps1 recusa gerar o pacote final sem ele.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
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
    namespace = "pt.cleveroption.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Exigido pelo flutter_local_notifications (o aviso com som e cartão
        // quando a app está aberta).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Definitivo: mudar isto depois de publicar faz uma app nova na loja,
        // com instalacoes a zero e sem atualizacoes para quem ja a tinha.
        applicationId = "pt.cleveroption.app"
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
