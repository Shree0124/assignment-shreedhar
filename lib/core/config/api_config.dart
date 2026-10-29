/// Mock REST API settings.
///
/// Create a MockAPI.io project with a `visitors` resource, then either replace
/// [_defaultBaseUrl] or pass the root at build time:
///
/// flutter run --dart-define=API_BASE_URL=https://xxxx.mockapi.io/api/v1
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const String _defaultBaseUrl =
      'https://REPLACE_WITH_YOUR_PROJECT.mockapi.io/api/v1';

  static bool get isConfigured =>
      !baseUrl.contains('REPLACE_WITH_YOUR_PROJECT');
}
