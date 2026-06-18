/// Custom API exception with enhanced error information
class ApiException implements Exception {
  final String message;
  final int? errorCode;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.errorCode, this.details});

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (errorCode != null) {
      buffer.write(' (Code: $errorCode)');
    }
    return buffer.toString();
  }

  /// Create ApiException with error code
  factory ApiException.withCode(String message, int errorCode) {
    return ApiException(message, errorCode: errorCode);
  }

  /// Create ApiException with additional details
  factory ApiException.withDetails(
    String message, {
    int? errorCode,
    Map<String, dynamic>? details,
  }) {
    return ApiException(message, errorCode: errorCode, details: details);
  }
}
