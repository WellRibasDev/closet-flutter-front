class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final String code;
  final String message;
  final int? statusCode;

  factory ApiException.fromResponse(int? statusCode, dynamic data) {
    if (data is Map) {
      final code = data['error']?.toString() ?? 'UNKNOWN';
      final message =
          data['message']?.toString() ?? 'Ocorreu um erro inesperado';
      return ApiException(code: code, message: message, statusCode: statusCode);
    }
    return ApiException(
      code: 'UNKNOWN',
      message: 'Ocorreu um erro inesperado',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code): $message';
}
