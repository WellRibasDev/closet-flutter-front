import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _api = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<AuthState> login({
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'senha': senha},
      );
      return await _persistAuth(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<AuthState> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'nome': nome, 'email': email, 'senha': senha},
      );
      return await _persistAuth(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }

  Future<String?> readToken() => _tokenStorage.read();

  Future<bool> checkHealth() async {
    try {
      await ensureHealthy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Health check que propaga o erro real (útil na splash).
  Future<void> ensureHealthy() async {
    DioException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _api.dio.get<dynamic>(
          '/health',
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        final data = response.data;
        if (data is Map && data['ok'] == true) {
          return;
        }
        throw const ApiException(
          code: 'HEALTH',
          message: 'A API respondeu, mas o health check falhou.',
        );
      } on DioException catch (e) {
        lastError = e;
        if (attempt < 2) {
          await Future<void>.delayed(Duration(milliseconds: 600 * (attempt + 1)));
        }
      }
    }
    if (lastError != null) {
      _api.throwFromDio(lastError);
    }
    throw const ApiException(
      code: 'HEALTH',
      message: 'Não foi possível conectar à API. Verifique a internet.',
    );
  }

  Future<AuthState> _persistAuth(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.save(token);
    return AuthState(user: user, token: token);
  }
}
