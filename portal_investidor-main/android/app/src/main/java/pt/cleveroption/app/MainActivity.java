package pt.cleveroption.app;

import io.flutter.embedding.android.FlutterFragmentActivity;

// Em Java e não em Kotlin de propósito: a app não tem código nativo além
// disto, e sem Kotlin no módulo da app deixa de ser preciso o Kotlin Gradle
// Plugin, que o Flutter avisa que vai deixar de funcionar (ver o AGENTS.md).
// FlutterFragmentActivity e não FlutterActivity: é o que o local_auth pede.
public class MainActivity extends FlutterFragmentActivity {
}
