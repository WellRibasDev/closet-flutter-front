import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final token = await _repo.readToken();
    if (token == null || token.isEmpty) {
      return const AuthState();
    }
    try {
      final user = await _repo.fetchMe();
      return AuthState(user: user, token: token);
    } catch (_) {
      // Token presente mas /me falhou (API antiga / offline): mantém sessão.
      return AuthState(token: token);
    }
  }

  Future<void> login({required String email, required String senha}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.login(email: email, senha: senha),
    );
  }

  Future<void> register({
    required String nome,
    required String email,
    required String senha,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.register(nome: nome, email: email, senha: senha),
    );
  }

  Future<void> refreshMe() async {
    final current = state.value;
    if (current?.token == null) return;
    final user = await _repo.fetchMe();
    state = AsyncData(AuthState(user: user, token: current!.token));
  }

  Future<void> updateProfile({
    required String nome,
    String? email,
    String? senhaAtual,
    String? novaSenha,
    File? foto,
  }) async {
    final current = state.value;
    if (current?.token == null) {
      throw StateError('Sessão inválida');
    }

    var user = await _repo.updateMe(
      nome: nome,
      email: email,
      senhaAtual: senhaAtual,
      novaSenha: novaSenha,
    );

    if (foto != null) {
      user = await _repo.uploadFotoPerfil(foto);
    }

    state = AsyncData(AuthState(user: user, token: current!.token));
  }

  Future<void> logout() async {
    await _repo.logout();
    // Limpa estado da sessão; providers de dados observam o token e reconstroem.
    state = const AsyncData(AuthState());
  }

  Future<void> handleUnauthorized() async {
    await _repo.logout();
    state = const AsyncData(AuthState());
  }
}
