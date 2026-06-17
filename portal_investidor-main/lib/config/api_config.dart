class ApiConfig {
  // Toggle between mock data and real API
  static bool useMock = false;

  // Base URLs
  static const String baseUrlDev = 'http://100.108.195.117:3000/api';
  static const String baseUrlProd = 'http://100.108.195.117:3000/api';

  // Get the appropriate base URL based on useMock setting
  static String get baseUrl => useMock ? baseUrlDev : baseUrlProd;

  // Connection timeout for API calls
  static const Duration connectionTimeout = Duration(seconds: 10);

  // ---- Endpoints ----
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static String userEndpoint(int id) => '/user/$id';
  static const String portfolioEndpoint = '/project/portfolio';
  static String projectDetailsEndpoint(int projectId) => '/project/details?projectId=$projectId';
}
