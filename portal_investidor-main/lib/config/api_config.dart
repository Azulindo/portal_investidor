import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Onde está a API e como se lhe chama.
///
/// O URL base pode ser fixado na compilação, que é o que se usa para apontar
/// à API a sério:
///
///   flutter run --dart-define=API_BASE_URL=http://100.108.195.117:3000/api
///
/// Sem esse valor, cada plataforma usa o seu caminho para o "localhost" da
/// máquina de desenvolvimento: o emulador Android vê-o em 10.0.2.2, e o
/// simulador iOS, o Windows, o macOS, o Linux e a web veem-no em localhost.
/// Antes estava 10.0.2.2 em todo o lado, por isso só funcionava no emulador
/// Android.
class ApiConfig {
  /// Dados de exemplo em vez da API. Útil sem rede ou com a API em baixo.
  ///
  /// Liga-se no arranque, sem editar nada:
  ///   flutter run --dart-define=USE_MOCK=true
  ///
  /// Assim o repositório fica sempre a apontar à API a sério, e não há o
  /// risco de alguém fazer commit com os dados de exemplo ligados.
  static bool useMock = const bool.fromEnvironment('USE_MOCK');

  static const String _baseUrlDefinido = String.fromEnvironment('API_BASE_URL');

  /// O host da máquina de desenvolvimento, visto de dentro de cada plataforma.
  static String get _baseUrlLocal {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  static String get baseUrl =>
      _baseUrlDefinido.isNotEmpty ? _baseUrlDefinido : _baseUrlLocal;

  /// Tempo máximo de espera por uma resposta.
  static const Duration connectionTimeout = Duration(seconds: 10);

  // ── Endpoints ────────────────────────────────────────────────
  // Públicos (sem sessão): portfolio e details. Em details, o preço das
  // frações só vem preenchido quando se envia o token — sem ele vem null.
  static const String portfolioEndpoint = '/project/portfolio';
  static String projectDetailsEndpoint(int projectId) =>
      '/project/details?projectId=$projectId';

  // Autenticação.
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';

  // Com sessão.
  static String userEndpoint(int id) => '/user/$id';
  static const String documentListEndpoint = '/document/list';
  static const String saleOrdersEndpoint = '/document/sale-orders';

  /// Download de anexos.
  ///
  /// As rotas /document/attachment/:id/token e /document/attachment/:id estão
  /// comentadas na API ("desativado temporariamente — TODO: desenvolver esta
  /// parte mais tarde"), por isso chamá-las dá 404. Quando voltarem, é só pôr
  /// isto a true; o código do lado da app já está feito.
  static const bool downloadDeAnexosDisponivel = false;

  static String attachmentTokenEndpoint(int attachmentId) =>
      '/document/attachment/$attachmentId/token';
  static String attachmentDownloadUrl(int attachmentId, String token) =>
      '$baseUrl/document/attachment/$attachmentId?token=$token';
}
