/// A failure the UI can show without exposing raw HTTP details.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
