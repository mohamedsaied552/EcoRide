import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'package:glider/core/errors/api_exception.dart';
import 'package:glider/core/storage/token_storage.dart';

class DioClient {
  DioClient({TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage(),
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          // Increase receive/send timeouts to accommodate large file uploads
          receiveTimeout: const Duration(minutes: 3),
          sendTimeout: const Duration(minutes: 3),
          headers: <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            // ngrok-free tunnels return an HTML interstitial ("ERR_NGROK_6024")
            // for browser requests unless this header is present. Without it,
            // Dio receives HTML and JSON decoding fails with
            // "String is not a subtype of type Map".
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          final isPublic = _isPublicEndpoint(options.path);
          if (!isPublic && token != null && token.trim().isNotEmpty) {
            options.headers['Authorization'] =
                '${AppConstants.bearerPrefix} ${token.trim()}';
          } else if (!isPublic && kDebugMode) {
            debugPrint(
              'API WARNING: Missing auth token for protected request '
              '${options.method} ${options.path}',
            );
          }
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) {
          _logError(error);
          handler.reject(_mapError(error));
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw _toApiException(error);
    }
  }

  DioException _mapError(DioException error) {
    return error;
  }

  bool _isPublicEndpoint(String path) {
    final normalized = path.split('?').first;
    return normalized == '/Auth/login' ||
        normalized == '/Auth/register' ||
        normalized == '/Auth/reset-password';
  }

  void _logRequest(RequestOptions options) {
    if (!kDebugMode) return;
    debugPrint(
      'API REQUEST: ${options.method} ${options.baseUrl}${options.path}',
    );
    if (options.queryParameters.isNotEmpty) {
      debugPrint('API QUERY: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('API BODY: ${_sanitizeBody(options.data)}');
    }
  }

  void _logResponse(Response<dynamic> response) {
    if (!kDebugMode) return;
    debugPrint(
      'API RESPONSE: ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.baseUrl}${response.requestOptions.path}',
    );
    debugPrint('API DATA: ${response.data}');
  }

  void _logError(DioException error) {
    if (!kDebugMode) return;
    debugPrint(
      'API ERROR: ${error.type} ${error.requestOptions.method} '
      '${error.requestOptions.baseUrl}${error.requestOptions.path}',
    );
    debugPrint('API ERROR RESPONSE: ${error.response?.data}');
    debugPrint('API ERROR MESSAGE: ${error.message}');
  }

  Object? _sanitizeBody(dynamic data) {
    if (data is Map<String, dynamic>) {
      final copy = Map<String, dynamic>.from(data);
      if (copy.containsKey('password')) {
        copy['password'] = '***';
      }
      if (copy.containsKey('currentPassword')) {
        copy['currentPassword'] = '***';
      }
      if (copy.containsKey('newPassword')) {
        copy['newPassword'] = '***';
      }
      if (copy.containsKey('idPhotoUrl')) {
        final value = copy['idPhotoUrl'];
        if (value is String) {
          copy['idPhotoUrl'] = '<base64 length=${value.length}>';
        }
      }
      return copy;
    }
    return data;
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'Something went wrong. Please try again.';

    if (responseData is Map<String, dynamic>) {
      final candidates = <dynamic>[
        responseData['message'],
        responseData['title'],
        responseData['error'],
        responseData['detail'],
        _extractValidationErrors(responseData),
      ];
      for (final value in candidates) {
        if (value is String && value.trim().isNotEmpty) {
          message = value;
          break;
        }
      }
    } else if (responseData is String && responseData.trim().isNotEmpty) {
      message = responseData;
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message =
              'The request took too long. Check that the API is running and try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'Unable to connect to the server.';
          break;
        case DioExceptionType.badCertificate:
          message = 'The server certificate is not trusted.';
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        case DioExceptionType.unknown:
        case DioExceptionType.badResponse:
          break;
      }
    }

    if (statusCode == 401) {
      message = 'Unauthorized. Please log in again.';
    }

    return ApiException(message, statusCode: statusCode);
  }

  String? _extractValidationErrors(Map<String, dynamic> responseData) {
    final errors = responseData['errors'];
    if (errors is Map) {
      final messages = <String>[];
      for (final value in errors.values) {
        if (value is List) {
          for (final item in value) {
            if (item is String && item.trim().isNotEmpty) {
              messages.add(item.trim());
            }
          }
        }
      }
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
    return null;
  }
}
