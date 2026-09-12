import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'models/clothing_item.dart';

class WardrobeRepository {
  WardrobeRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PaginatedClothing> list({
    String? categoria,
    String? busca,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>(
        '/roupas',
        queryParameters: {
          if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
          if (busca != null && busca.isNotEmpty) 'busca': busca,
          'page': page,
          'limit': limit,
        },
      );
      return PaginatedClothing.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<ClothingItem> get(String id) async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('/roupas/$id');
      return ClothingItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<ClothingItem> create(Map<String, dynamic> body) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/roupas',
        data: body,
      );
      return ClothingItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<ClothingItem> update(String id, Map<String, dynamic> body) async {
    try {
      final response = await _api.dio.put<Map<String, dynamic>>(
        '/roupas/$id',
        data: body,
      );
      return ClothingItem.fromJson(response.data!);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _api.dio.delete<Map<String, dynamic>>('/roupas/$id');
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }

  Future<ClothingItem> uploadFoto(String id, File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.uri.pathSegments.last,
        ),
      });
      final response = await _api.dio.post<Map<String, dynamic>>(
        '/roupas/$id/foto',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data!;
      if (data['roupa'] is Map<String, dynamic>) {
        return ClothingItem.fromJson(data['roupa'] as Map<String, dynamic>);
      }
      return ClothingItem.fromJson(data);
    } on DioException catch (e) {
      _api.throwFromDio(e);
    }
  }
}
