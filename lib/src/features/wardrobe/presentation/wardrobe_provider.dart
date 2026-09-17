import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/models/clothing_item.dart';
import '../data/wardrobe_repository.dart';

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(apiClient: ref.watch(apiClientProvider));
});

class WardrobeFilters {
  const WardrobeFilters({this.categoria, this.busca = ''});

  final String? categoria;
  final String busca;

  WardrobeFilters copyWith({String? categoria, String? busca, bool clearCategoria = false}) {
    return WardrobeFilters(
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      busca: busca ?? this.busca,
    );
  }
}

class WardrobeListState {
  const WardrobeListState({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
    this.filters = const WardrobeFilters(),
  });

  final List<ClothingItem> items;
  final int page;
  final int total;
  final bool hasMore;
  final WardrobeFilters filters;

  WardrobeListState copyWith({
    List<ClothingItem>? items,
    int? page,
    int? total,
    bool? hasMore,
    WardrobeFilters? filters,
  }) {
    return WardrobeListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      filters: filters ?? this.filters,
    );
  }
}

final wardrobeProvider =
    AsyncNotifierProvider<WardrobeNotifier, WardrobeListState>(
  WardrobeNotifier.new,
);

class WardrobeNotifier extends AsyncNotifier<WardrobeListState> {
  WardrobeRepository get _repo => ref.read(wardrobeRepositoryProvider);

  WardrobeFilters _filters = const WardrobeFilters();

  @override
  Future<WardrobeListState> build() async {
    // Reconstrói ao trocar de conta (token muda no login/logout).
    final token = ref.watch(authProvider.select((s) => s.value?.token));
    _filters = const WardrobeFilters();
    if (token == null || token.isEmpty) {
      return const WardrobeListState(
        items: [],
        page: 1,
        total: 0,
        hasMore: false,
      );
    }
    return _fetch(page: 1, replace: true);
  }

  Future<WardrobeListState> _fetch({
    required int page,
    required bool replace,
  }) async {
    final result = await _repo.list(
      categoria: _filters.categoria,
      busca: _filters.busca,
      page: page,
    );

    final previous = replace
        ? <ClothingItem>[]
        : (state.value?.items ?? <ClothingItem>[]);

    return WardrobeListState(
      items: [...previous, ...result.data],
      page: result.page,
      total: result.total,
      hasMore: result.hasMore,
      filters: _filters,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: 1, replace: true),
    );
  }

  Future<void> applyFilters({String? categoria, String? busca}) async {
    _filters = WardrobeFilters(
      categoria: categoria,
      busca: busca ?? '',
    );
    await refresh();
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || state.isLoading) return;

    final next = await AsyncValue.guard(
      () => _fetch(page: current.page + 1, replace: false),
    );
    if (next.hasValue) {
      state = next;
    }
  }

  Future<ClothingItem> create({
    required Map<String, dynamic> body,
    File? foto,
  }) async {
    var item = await _repo.create(body);
    if (foto != null) {
      item = await _repo.uploadFoto(item.id, foto);
    }
    await refresh();
    return item;
  }

  Future<ClothingItem> updateItem({
    required String id,
    required Map<String, dynamic> body,
    File? foto,
  }) async {
    var item = await _repo.update(id, body);
    if (foto != null) {
      item = await _repo.uploadFoto(id, foto);
    }
    await refresh();
    return item;
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          items: current.items.where((e) => e.id != id).toList(),
          total: current.total - 1,
        ),
      );
    }
  }

  Future<ClothingItem> getById(String id) => _repo.get(id);
}

final clothingDetailProvider =
    FutureProvider.family<ClothingItem, String>((ref, id) async {
  final token = ref.watch(authProvider.select((s) => s.value?.token));
  if (token == null || token.isEmpty) {
    throw StateError('Sessão encerrada');
  }
  return ref.watch(wardrobeRepositoryProvider).get(id);
});
