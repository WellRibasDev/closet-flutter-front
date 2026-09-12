import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
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
      final response = await _api.dio.get<Map<String, dynamic>>('/health');
      return response.data?['ok'] == true;
    } on DioException {
      return false;
    }
  }

  Future<AuthState> _persistAuth(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.save(token);
    return AuthState(user: user, token: token);
  }
}
