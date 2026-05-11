

// class DioClient {
//   static Dio? _instance;
//   static Dio? _authInstance;
  

//   static Dio get instance {
//     _instance ??= _createDio(ElearningApi.defaultTimeout);
//     return _instance!;
//   }

//   static Dio _createDio(Duration timeout) {
//     final dio = Dio(
//       BaseOptions(
//         baseUrl: ElearningApi.baseUrl,
//         connectTimeout: timeout,
//         receiveTimeout: timeout,
//         sendTimeout: timeout,
//       ),
//     );

//     dio.interceptors.add(AuthInterceptor(dio));

//     dio.interceptors.add(
//       LogInterceptor(
//         requestBody: true,
//         responseBody: true,
//         error: true,
//         logPrint: (obj) => log('$obj'),
//       ),
//     );

//     return dio;
//   }

//   static void reset() {
//     _instance?.close();
//     _authInstance?.close();
//     _instance = null;
//     _authInstance = null;
//   }
// }

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:innovator/elearning/core/constants/api_constants.dart';
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
    final dio = Dio(BaseOptions(
      baseUrl: ElearningApi.baseUrl,
      connectTimeout: showToasts 
          ? ElearningApi.defaultTimeout 
          : const Duration(seconds: 20),  
      receiveTimeout: showToasts 
          ? ElearningApi.defaultTimeout 
          : const Duration(seconds: 20),
      sendTimeout: ElearningApi.defaultTimeout,
    ));

    dio.interceptors.add(
      AuthInterceptor(dio, showToasts: showToasts),
    );

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