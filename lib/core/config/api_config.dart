/// Base URLs for every Innovator backend service.
///
/// Swagger references:
///   Auth      8010   Profile   8011   Feed      8012
///   Chat      8014   Search    8015
///   Ecommerce 8016   Elearning 8017   Events    8018   Research 8019
class ApiConfig {
  ApiConfig._();

  static const _host = 'http://36.253.137.34';

  // Innovator (social) services.
  static const authBaseUrl = '$_host:8010';
  static const profileBaseUrl = '$_host:8011';
  static const feedBaseUrl = '$_host:8012';
  static const chatBaseUrl = '$_host:8014';
  static const searchBaseUrl = '$_host:8015';

  // Other product areas.
  static const ecommerceBaseUrl = '$_host:8016';
  static const elearningBaseUrl = '$_host:8017';
  static const eventsBaseUrl = '$_host:8018';
  static const researchBaseUrl = '$_host:8019';

  /// Fail fast on hung sockets so the UI can retry.
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 20);

  /// Default feed page size — fewer round trips without oversized payloads.
  static const feedPageSize = 15;

  /// How long local caches stay valid (categories, profile, etc.).
  static const cacheTtl = Duration(minutes: 8);

  /// Google Cloud **Web** OAuth client ID (used as `serverClientId`).
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: googleServerClientIdFallback,
  );

  static const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: googleClientIdFallback,
  );

  static const googleServerClientIdFallback =
      '565447947765-2n94vokrmnc8p6c8k4c8as3krqc8qmgk.apps.googleusercontent.com';

  static const googleClientIdFallback = '';
}
