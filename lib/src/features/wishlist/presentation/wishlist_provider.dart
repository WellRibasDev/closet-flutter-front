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

class WishlistNotifier extends AsyncNotifier<List<WishlistItem>> {
  WishlistRepository get _repo => ref.read(wishlistRepositoryProvider);

  @override
  Future<List<WishlistItem>> build() async {
    // Reconstrói ao trocar de conta (token muda no login/logout).
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

  Future<void> create(Map<String, dynamic> body) async {
    await _repo.create(body);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((e) => e.id != id).toList());
    }
  }

  Future<ClothingItem> moverParaCloset(String id, {String? categoria}) async {
    if (categoria != null && categoria.isNotEmpty) {
      await _repo.update(id, {'categoria': categoria});
    }

    try {
      final roupa = await _repo.moverParaCloset(id);
      await refresh();
      ref.invalidate(wardrobeProvider);
      return roupa;
    } on ApiException catch (e) {
      if (e.code == 'DESEJO_SEM_CATEGORIA') {
        rethrow;
      }
      rethrow;
    }
  }
}
