import 'dart:io';

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

  Future<User> fetchMe() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/me');
      final data = response.data!;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<User> updateMe({
    String? nome,
    String? email,
    String? senhaAtual,
    String? novaSenha,
  }) async {
    try {
      final body = <String, dynamic>{
        if (nome != null) 'nome': nome,
        if (email != null && email.isNotEmpty) 'email': email,
        if (senhaAtual != null && senhaAtual.isNotEmpty) 'senhaAtual': senhaAtual,
        if (novaSenha != null && novaSenha.isNotEmpty) 'novaSenha': novaSenha,
      };
      final response = await _api.dio.put<Map<String, dynamic>>(
        '/me',
        data: body,
      );
      final data = response.data!;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<User> uploadFotoPerfil(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/me/foto',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data!;
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson != null) {
        return User.fromJson(userJson);
      }
      return fetchMe();
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

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
