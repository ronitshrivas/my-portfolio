import 'package:dio/dio.dart';

import 'dio_client.dart';

abstract class EcommerBaseApiService {
  final Dio _dio;

  // EcommerBaseApiService({Dio? dio}) : _dio = dio ?? DioClient.instance;
    EcommerBaseApiService({Dio? dio, bool silent = false})
      : _dio = dio ?? (silent ? DioClient.silent : DioClient.instance);

  Future<T> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get(
      endpoint,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  Future<T> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  Future<T> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  Future<T> patch<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.patch(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  Future<T> delete<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete(
      endpoint,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  Future<T> upload<T>(
    String endpoint,
    FormData formData, {
    ProgressCallback? onSendProgress,
  }) async {
    final response = await _dio.post(
      endpoint,
      data: formData,
      onSendProgress: onSendProgress,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    return response.data as T;
  }
}
