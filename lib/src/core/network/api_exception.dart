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
    // Resposta HTML (ex.: 404 de rota ainda não deployada na Vercel).
    if (statusCode == 404) {
      return ApiException(
        code: 'NOT_FOUND',
        message: 'Recurso não encontrado na API. Verifique se o backend está atualizado.',
        statusCode: statusCode,
      );
    }
    return ApiException(
      code: 'UNKNOWN',
      message: statusCode != null
          ? 'Erro na API (HTTP $statusCode)'
          : 'Ocorreu um erro inesperado',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code): $message';
}
