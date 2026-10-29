/// Mock REST API settings.
///
/// The default points at a CrudCrud `visitors` resource. Override it at build
/// time when you create your own endpoint:
///
/// flutter run --dart-define=API_BASE_URL=https://crudcrud.com/api/your-id
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static const String _defaultBaseUrl =
      'https://crudcrud.com/api/c21a2bccad2f47c182433093c92a54dd';

  static bool get isConfigured =>
      !baseUrl.contains('REPLACE_WITH_YOUR_PROJECT');
}
