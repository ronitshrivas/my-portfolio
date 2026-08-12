import 'package:dio/dio.dart';

import '../../models/api_response.dart';
import '../../services/auth_session.dart';
import '../config/api_config.dart';

/// Dio-based network layer for every backend service.
///
/// Keeps the same [ApiEnvelope] return shape the old `ApiClient` used, so
/// feature services can adopt it with minimal changes. One Dio instance per
/// process keeps the connection pool warm; a Bearer token is attached
/// automatically from [AuthSession].
class DioClient {
  DioClient._(this._dio);

  static final DioClient shared = DioClient._(_build());

  final Dio _dio;

  /// A bare Dio used only for the token-refresh call, so refreshing never runs
  /// through the auth interceptor (which would recurse) or the retry logic.
  final Dio _refreshDio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      validateStatus: (_) => true,
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Shared in-flight refresh so concurrent 401s trigger exactly one refresh.
  Future<bool>? refreshInFlight;

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.receiveTimeout,
        // Never throw on status codes; we inspect them ourselves.
        validateStatus: (_) => true,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['auth'] != false) {
            final token = AuthSession.instance.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }

  /// Exchanges the stored refresh token for a fresh access + refresh token.
  ///
  /// Concurrent callers share a single request. Returns true when the session
  /// was renewed, false when there is no refresh token or the server rejects it
  /// (e.g. the refresh token itself has expired).
  Future<bool> refreshTokens() {
    return refreshInFlight ??= _performRefresh().whenComplete(() {
      refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = AuthSession.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshDio.post<dynamic>(
        '${ApiConfig.authBaseUrl}/api/auth/token/refresh',
        data: {'refreshToken': refreshToken},
      );

      // ignore: avoid_print
      print('[Auth] refresh HTTP ${response.statusCode} body=${response.data}');
      final body = response.data;
      if (body is! Map || body['success'] != true) return false;

      final data = body['data'];
      if (data is! Map) return false;

      final access = data['accessToken']?.toString() ?? '';
      final refresh = data['refreshToken']?.toString() ?? '';
      if (access.isEmpty) return false;

      final session = AuthSession.instance;
      await session.save(
        accessToken: access,
        refreshToken: refresh.isNotEmpty ? refresh : refreshToken,
        userId: session.userId ?? '',
        username: session.username ?? '',
        email: session.email ?? '',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ApiEnvelope<T>> get<T>(
    String baseUrl,
    String path, {
    Map<String, dynamic>? query,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) =>
      _send('GET', baseUrl, path, query: query, parse: parse, auth: auth);

  Future<ApiEnvelope<T>> post<T>(
    String baseUrl,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) =>
      _send('POST', baseUrl, path,
          body: body, query: query, parse: parse, auth: auth);

  Future<ApiEnvelope<T>> put<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) =>
      _send('PUT', baseUrl, path, body: body, parse: parse, auth: auth);

  Future<ApiEnvelope<T>> patch<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) =>
      _send('PATCH', baseUrl, path, body: body, parse: parse, auth: auth);

  Future<ApiEnvelope<T>> delete<T>(
    String baseUrl,
    String path, {
    Object? body,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) =>
      _send('DELETE', baseUrl, path, body: body, parse: parse, auth: auth);

  /// Multipart upload (posts, avatars, research papers, product images…).
  Future<ApiEnvelope<T>> upload<T>(
    String baseUrl,
    String path, {
    required FormData formData,
    String method = 'POST',
    T Function(Object? raw)? parse,
    bool auth = true,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await sendWithRetry(
        auth: auth,
        request: () => _dio.request<dynamic>(
          '$baseUrl$path',
          data: formData,
          onSendProgress: onSendProgress,
          options: Options(method: method, extra: {'auth': auth}),
        ),
      );
      return _toEnvelope<T>(response, parse);
    } on DioException catch (e) {
      throw ApiException(_dioMessage(e), statusCode: e.response?.statusCode);
    }
  }

  Future<ApiEnvelope<T>> _send<T>(
    String method,
    String baseUrl,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    T Function(Object? raw)? parse,
    bool auth = true,
  }) async {
    try {
      final response = await sendWithRetry(
        auth: auth,
        request: () => _dio.request<dynamic>(
          '$baseUrl$path',
          data: body,
          queryParameters: query,
          options: Options(method: method, extra: {'auth': auth}),
        ),
      );
      return _toEnvelope<T>(response, parse);
    } on DioException catch (e) {
      throw ApiException(_dioMessage(e), statusCode: e.response?.statusCode);
    }
  }

  /// Runs [request]; on a 401 for an authed request, refreshes the session once
  /// and replays the request with the new token. Non-auth requests, and
  /// requests that already 401'd after a refresh, pass straight through.
  Future<Response<dynamic>> sendWithRetry({
    required bool auth,
    required Future<Response<dynamic>> Function() request,
  }) async {
    final response = await request();
    if (response.statusCode != 401 || !auth) return response;

    // ignore: avoid_print
    print('[Auth] 401 on ${response.requestOptions.uri} — attempting refresh');
    final refreshed = await refreshTokens();
    // ignore: avoid_print
    print('[Auth] refresh success=$refreshed');
    if (!refreshed) return response;

    // One retry only — the interceptor picks up the new token automatically.
    final retried = await request();
    // ignore: avoid_print
    print('[Auth] retry status=${retried.statusCode} '
        'url=${retried.requestOptions.uri}');
    return retried;
  }

  ApiEnvelope<T> _toEnvelope<T>(
    Response<dynamic> response,
    T Function(Object? raw)? parse,
  ) {
    final status = response.statusCode ?? 0;
    final data = response.data;

    // Reaches here only when a refresh already failed (or the retried request
    // still came back 401), so the refresh token is truly dead — end the
    // session so the app routes back to login.
    if (status == 401) {
      AuthSession.instance.clear();
      throw ApiException('Session expired. Please sign in again.',
          statusCode: 401);
    }

    // Envelope response: { success, message, data, errors }.
    if (data is Map<String, dynamic> && data.containsKey('success')) {
      final envelope = ApiEnvelope<T>.fromJson(data, parse);
      if (status >= 400 && !envelope.success) {
        throw ApiException(
          envelope.message ?? 'Request failed ($status)',
          statusCode: status,
          errors: envelope.errors,
        );
      }
      return envelope;
    }

    // Bare payload (some services return raw lists/objects).
    if (status >= 400) {
      throw ApiException('Request failed ($status)', statusCode: status);
    }
    return ApiEnvelope<T>(
      success: true,
      data: parse == null ? data as T? : parse(data),
    );
  }

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Please try again.';
      case DioExceptionType.connectionError:
        return 'No connection to the server. Check your network.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
