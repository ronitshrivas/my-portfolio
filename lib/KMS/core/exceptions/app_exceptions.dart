class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  AppException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class TimeoutException extends AppException {
  TimeoutException([super.message = 'Request timeout. Please try again.']);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([
    super.message = 'Session expired. Please login again. 7',
  ]) : super(statusCode: 401);
}

class BadRequestException extends AppException {
  BadRequestException([super.message = 'Invalid request'])
    : super(statusCode: 400);
}

class NotFoundException extends AppException {
  NotFoundException([super.message = 'Resource not found'])
    : super(statusCode: 404);
}

class ServerException extends AppException {
  ServerException([super.message = 'Server error. Please try again later.'])
    : super(statusCode: 500);
}

class ProfileNotFoundException extends AppException {
  ProfileNotFoundException([String? message])
    : super(message ?? 'Profile not found', statusCode: 404);
}
