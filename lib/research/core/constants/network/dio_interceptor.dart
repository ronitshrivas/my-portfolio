import 'package:dio/dio.dart';
import 'package:innovator/KMS/core/exceptions/app_exceptions.dart';
import 'package:innovator/KMS/core/utils/toast_utils.dart';
import 'package:innovator/research/core/constants/api_constants.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final bool showToasts;

  bool _isRefreshing = false;

  AuthInterceptor(this._dio, {this.showToasts = true});

  // On Request
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  //  On Response
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  // On Error
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;

      try {
        final newToken = await _tryRefreshToken();

        if (newToken != null) {
          final retryOptions =
              err.requestOptions..headers['Authorization'] = 'Bearer $newToken';

          final retryResponse = await _dio.fetch(retryOptions);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
      } finally {
        _isRefreshing = false;
      }

      // await _onSessionExpired();
      handler.reject(err);
      return;
    }
    final exception = mapDioError(err);
    // ToastUtils.showError(exception.message);
    if (showToasts && _isUserFacingError(exception)) {
      ToastUtils.showError(exception.message);
    }

    handler.next(err);
  }

  bool _isUserFacingError(AppException exception) {
    return exception is! TimeoutException && exception is! NetworkException;
  }

  Future<String?> _tryRefreshToken() async {
    try {
      final plainDio = Dio(
        BaseOptions(
          baseUrl: ResearchApi.baseUrl,
          connectTimeout: ResearchApi.defaultTimeout,
          receiveTimeout: ResearchApi.uploadTimeout,
        ),
      );

      final response = await plainDio.post(ResearchApi.baseUrl);

      return response.data['access'] as String?;
    } catch (_) {
      return null;
    }
  }
}

AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionError:
      return NetworkException();

    case DioExceptionType.connectionTimeout:
      return TimeoutException('Connection timed out. Please try again.');

    case DioExceptionType.receiveTimeout:
      return TimeoutException('Server is taking too long to respond.');

    case DioExceptionType.sendTimeout:
      return TimeoutException('Upload timed out. Please try again.');

    case DioExceptionType.badResponse:
      return _mapStatusCode(e);

    case DioExceptionType.cancel:
      return AppException('Request was cancelled.');

    default:
      return AppException(e.message ?? 'An unexpected error occurred.');
  }
}

AppException _mapStatusCode(DioException e) {
  final code = e.response?.statusCode;
  final serverMsg = _extractServerMessage(e.response?.data);

  switch (code) {
    case 400:
      return BadRequestException(serverMsg ?? 'Invalid request.');
    case 401:
      return UnauthorizedException();
    case 403:
      return AppException('You do not have permission.', statusCode: 403);
    case 404:
      return NotFoundException(serverMsg ?? 'Not found.');
    case 408:
      return TimeoutException('Request timed out.');
    case 422:
      return BadRequestException(serverMsg ?? 'Validation error.');
    case 429:
      return AppException('Too many requests. Slow down.', statusCode: 429);
    case 500:
    case 502:
    case 503:
      return ServerException(
        serverMsg ?? 'Server error. Please try again later.',
      );
    default:
      return AppException(
        serverMsg ?? 'Request failed (HTTP $code).',
        statusCode: code,
      );
  }
}

String? _extractServerMessage(dynamic data) {
  if (data == null) return null;
  if (data is String && data.isNotEmpty) return data;
  if (data is Map) {
    for (final key in ['message', 'detail', 'error', 'msg', 'description']) {
      final val = data[key];
      if (val is String && val.isNotEmpty) return val;
    }
  }
  return null;
}
