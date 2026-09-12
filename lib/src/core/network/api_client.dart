import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

typedef UnauthorizedHandler = Future<void> Function();

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    UnauthorizedHandler? onUnauthorized,
  }) : _tokenStorage = tokenStorage,
       _onUnauthorized = onUnauthorized {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _tokenStorage.clear();
            final callback = _onUnauthorized;
            if (callback != null) {
              await callback();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio dio;
  final TokenStorage _tokenStorage;
  UnauthorizedHandler? _onUnauthorized;

  void setUnauthorizedHandler(UnauthorizedHandler handler) {
    _onUnauthorized = handler;
  }

  Never throwFromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      throw ApiException.fromResponse(response.statusCode, response.data);
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw const ApiException(
        code: 'TIMEOUT',
        message: 'A API demorou para responder. Tente novamente.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      throw const ApiException(
        code: 'CONNECTION',
        message: 'Não foi possível conectar à API. Verifique se ela está no ar.',
      );
    }
    throw ApiException(
      code: 'NETWORK',
      message: error.message ?? 'Falha de rede',
    );
  }
}
