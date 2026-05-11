//  import 'dart:developer';

// import 'package:dio/dio.dart';
// import 'package:innovator/KMS/core/constants/api_constants.dart'; 
// import 'dio_interceptor.dart';

// class DioClient {
//   static Dio? _instance;
//   static Dio? _authInstance;

//   static Dio get instance {
//     _instance ??= _createDio(ApiConstants.defaultTimeout);
//     return _instance!;
//   }

//   static Dio get authInstance {
//     _authInstance ??= _createDio(ApiConstants.authTimeout);
//     return _authInstance!;
//   }

//   static Dio _createDio(Duration timeout) {
//     final dio = Dio(
//       BaseOptions(
//         baseUrl: ApiConstants.baseUrl,
//         connectTimeout: timeout,
//         receiveTimeout: timeout,
//         sendTimeout: timeout,
 
//       ),
//     );

//     dio.interceptors.add(AppInterceptor());

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
import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'dio_interceptor.dart';

class DioClient {
  static Dio? _instance;
  static Dio? _authInstance;
  static Dio? _silentInstance;  

  static Dio get instance {
    _instance ??= _create(
      timeout: ApiConstants.defaultTimeout,
      showToasts: true,
    );
    return _instance!;
  }

  static Dio get authInstance {
    _authInstance ??= _create(
      timeout: ApiConstants.authTimeout,
      showToasts: true,
    );
    return _authInstance!;
  }

  static Dio get silent {
    _silentInstance ??= _create(
      timeout: const Duration(seconds: 20),
      showToasts: false,
    );
    return _silentInstance!;
  }

  static Dio _create({required Duration timeout, required bool showToasts}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
      ),
    );

    dio.interceptors.add(AppInterceptor(showToasts: showToasts)); // ✅

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
    _authInstance?.close();
    _silentInstance?.close(); 
    _instance = null;
    _authInstance = null;
    _silentInstance = null;  
  }
}