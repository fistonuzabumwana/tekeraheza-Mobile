import 'package:dio/dio.dart';

import '../storage/storage_service.dart';
import 'api_constants.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.extra['_retry'] != true) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.extra['_retry'] = true;
              final token = await _storage.getAccessToken();
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
            await _storage.clearSession();
          }
          handler.next(error);
        },
      ),
    );
  }

  final StorageService _storage;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<bool> _tryRefreshToken() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(ApiConstants.refreshToken, data: {'refreshToken': refresh});
      final data = response.data['data'] as Map<String, dynamic>;
      final user = await _storage.getUser();
      if (user == null) return false;
      await _storage.saveSession(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: user,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  T unwrap<T>(Response response, T Function(dynamic json) fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return fromJson(body['data']);
    }
    return fromJson(body);
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response =
          await _dio.get(path, queryParameters: queryParameters);
      return unwrap(response, fromJson);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return unwrap(response, fromJson);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return unwrap(response, fromJson);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return unwrap(response, fromJson);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> postMultipart(
    String path, {
    required FormData formData,
  }) async {
    try {
      return await _dio.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final data = e.response?.data;
    String message = 'Network error';
    if (data is Map) {
      message = (data['message'] ?? data['error'] ?? message).toString();
    } else if (e.message != null) {
      message = e.message!;
    }
    return ApiException(message, statusCode: e.response?.statusCode);
  }

  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }
}
