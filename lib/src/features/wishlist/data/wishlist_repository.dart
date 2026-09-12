import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../wardrobe/data/models/clothing_item.dart';
import 'models/wishlist_item.dart';

class WishlistRepository {
  WishlistRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PaginatedWishlist> list({
    bool? comprado,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/desejos',
        queryParameters: {
          if (comprado != null) 'comprado': comprado.toString(),
          'page': page,
          'limit': limit,
        },
      );
      return PaginatedWishlist.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<WishlistItem> create(Map<String, dynamic> body) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/desejos',
        data: body,
      );
      return WishlistItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<WishlistItem> update(String id, Map<String, dynamic> body) async {
    try {
      final response = await _api.dio.put<Map<String, dynamic>>(
        '/desejos/$id',
        data: body,
      );
      return WishlistItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.dio.delete<Map<String, dynamic>>('/desejos/$id');
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<ClothingItem> moverParaCloset(String id) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/desejos/$id/mover',
      );
      return ClothingItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  bool isSemCategoria(Object error) {
    return error is ApiException && error.code == 'DESEJO_SEM_CATEGORIA';
  }
}
