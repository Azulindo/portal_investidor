/// A versão desta app, igual ao `version:` do pubspec.yaml (sem o "+build").
///
/// Está escrita aqui em vez de vir de um pacote (package_info_plus) para não
/// juntar mais uma dependência nativa só por isto. O teste versao_test.dart
/// falha se esta e a do pubspec deixarem de bater certo: ao subir a versão,
/// mudam-se as duas.
const String versaoApp = '1.0.0';
