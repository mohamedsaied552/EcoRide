import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/core/network/dio_client.dart';

class ApiService {
  ApiService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  final DioClient _dioClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.get(
      path,
      queryParameters: queryParameters,
    );
    return _asJsonObject(response, path);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.get(
      path,
      queryParameters: queryParameters,
    );
    return _asJsonArray(response, path);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.post(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return _asJsonObject(response, path);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.put(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return _asJsonObject(response, path);
  }

  Future<Map<String, dynamic>> multipartPost(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _asJsonObject(response, path);
  }

  Future<Map<String, dynamic>> multipartPut(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(contentType: 'multipart/form-data'),
    );
    return _asJsonObject(response, path);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dioClient.delete(
      path,
      data: data,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  /// Defensive coercion of [Response.data] into a JSON object.
  ///
  /// Servers (or intermediaries like ngrok's interstitial page) sometimes
  /// return a non-JSON body even with a 200 status code. Without this guard
  /// callers see a raw `TypeError: 'String' is not a subtype of type 'Map'`
  /// which masks the real cause. Here we attempt one JSON re-parse when the
  /// body is a string, and otherwise raise a descriptive [ApiException].
  Map<String, dynamic> _asJsonObject(Response<dynamic> response, String path) {
    final body = response.data;
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.isNotEmpty &&
          (trimmed.startsWith('{') || trimmed.startsWith('['))) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          // fall through to ApiException below
        }
      }
    }
    throw ApiException(
      'Unexpected non-JSON response from server for $path.',
      statusCode: response.statusCode,
    );
  }

  List<dynamic> _asJsonArray(Response<dynamic> response, String path) {
    final body = response.data;
    if (body is List) {
      return List<dynamic>.from(body);
    }
    if (body is String) {
      final trimmed = body.trim();
      if (trimmed.startsWith('[')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return List<dynamic>.from(decoded);
          }
        } catch (_) {
          // fall through to ApiException below
        }
      }
    }
    throw ApiException(
      'Unexpected non-JSON-array response from server for $path.',
      statusCode: response.statusCode,
    );
  }
}
