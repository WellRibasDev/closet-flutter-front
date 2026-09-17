import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../wardrobe/data/models/clothing_item.dart';
import '../../wardrobe/presentation/wardrobe_provider.dart';
import '../data/models/wishlist_item.dart';
import '../data/wishlist_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(apiClient: ref.watch(apiClientProvider));
});

final wishlistProvider =
    AsyncNotifierProvider<WishlistNotifier, List<WishlistItem>>(
  WishlistNotifier.new,
);

final wishlistDetailProvider =
    FutureProvider.family<WishlistItem, String>((ref, id) async {
  final token = ref.watch(authProvider.select((s) => s.value?.token));
  if (token == null || token.isEmpty) {
    throw StateError('Sessão encerrada');
  }
  return ref.watch(wishlistRepositoryProvider).get(id);
});

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  WishlistRepository get _repo => ref.read(wishlistRepositoryProvider);

  @override
  Future<List<WishlistItem>> build() async {
    final token = ref.watch(authProvider.select((s) => s.value?.token));
    if (token == null || token.isEmpty) {
      return const [];
    }

    final result = await _repo.list(comprado: false);
    return result.data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.list(comprado: false);
      return result.data;
    });
  }

  Future<WishlistItem> updateItem({
    required String id,
    required Map<String, dynamic> body,
    File? foto,
  }) async {
    var item = await _repo.update(id, body);
    if (foto != null) {
      try {
        item = await _repo.uploadFoto(id, foto);
      } on ApiException catch (e) {
        // Dados já salvos; foto pode falhar se a rota ainda não estiver no ar.
        if (e.statusCode != 404) rethrow;
        await refresh();
        ref.invalidate(wishlistDetailProvider(id));
        throw ApiException(
          code: 'FOTO_UNAVAILABLE',
          message:
              'Desejo salvo, mas o upload de foto ainda não está disponível na API. Redeploy o backend.',
          statusCode: e.statusCode,
        );
      }
    }
    await refresh();
    ref.invalidate(wishlistDetailProvider(id));
    return item;
  }

  Future<WishlistItem> create({
    required Map<String, dynamic> body,
    File? foto,
  }) async {
    var item = await _repo.create(body);
    if (foto != null) {
      try {
        item = await _repo.uploadFoto(item.id, foto);
      } on ApiException catch (e) {
        if (e.statusCode != 404) rethrow;
        await refresh();
        throw ApiException(
          code: 'FOTO_UNAVAILABLE',
          message:
              'Desejo criado, mas o upload de foto ainda não está disponível na API. Redeploy o backend.',
          statusCode: e.statusCode,
        );
      }
    }
    await refresh();
    return item;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((e) => e.id != id).toList());
    }
    ref.invalidate(wishlistDetailProvider(id));
  }

  Future<ClothingItem> moverParaCloset(String id, {String? categoria}) async {
    if (categoria != null && categoria.isNotEmpty) {
      await _repo.update(id, {'categoria': categoria});
    }

    try {
      final roupa = await _repo.moverParaCloset(id);
      await refresh();
      ref.invalidate(wardrobeProvider);
      ref.invalidate(wishlistDetailProvider(id));
      return roupa;
    } on ApiException catch (e) {
      if (e.code == 'DESEJO_SEM_CATEGORIA') {
        rethrow;
      }
      rethrow;
    }
  }
}
