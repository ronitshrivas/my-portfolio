import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:innovator/research/core/constants/api_constants.dart';
import 'dio_interceptor.dart';

class DioClient {
  static Dio? _instance;
  static Dio? _silentInstance;

  // For user-triggered API calls (shows toasts on error)
  static Dio get instance {
    _instance ??= _create(showToasts: true);
    return _instance!;
  }

  // For background polling (completely silent)
  static Dio get silent {
    _silentInstance ??= _create(showToasts: false);
    return _silentInstance!;
  }

  static Dio _create({required bool showToasts}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ResearchApi.baseUrl,
        connectTimeout:
            showToasts
                ? ResearchApi.defaultTimeout
                : const Duration(seconds: 20),
        receiveTimeout:
            showToasts
                ? ResearchApi.defaultTimeout
                : const Duration(seconds: 20),
        sendTimeout: ResearchApi.uploadTimeout,
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio, showToasts: showToasts));

    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => log('$obj'),
      ),
    );

    return dio;
  }

  static void reset() {
    _instance?.close();
    _silentInstance?.close();
    _instance = null;
    _silentInstance = null;
  }
}
