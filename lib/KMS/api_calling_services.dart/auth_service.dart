import 'dart:developer';
import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/core/constants/service/token_service.dart';

class AuthService extends BaseApiService {
  AuthService() : super(dio: DioClient.authInstance);

  final TokenService _tokenService = TokenService();
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );

    final role = response['user']?['role'] as String?;
    if (role != null && role.isNotEmpty) {
      await _tokenService.saveRole(role);
      log('Role saved: $role');
    }

    return response;
  }

  Future<Map<String, dynamic>> register({
    required String userName,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'username': userName,
        'email': email,
        'password': password,
        'role': role,
      },
    );

    await _tokenService.saveRole(role);
    log('Role saved on register: $role');

    return response;
  }

  Future<void> logout() async {
    await _tokenService.clearTokens();
    log('Logged out — tokens and role cleared');
  }

  Future<bool> isLoggedIn() async {
    return await _tokenService.hasToken();
  }

  Future<String?> getSavedRole() async {
    return await _tokenService.getRole();
  }

  Future<Map<String, dynamic>> studentLogin({
    required String username,
    required String password,
  }) async {
    final response = await post<Map<String, dynamic>>(
      ApiConstants.studentLogin,
      data: {'username': username, 'password': password},
    );

    final role = response['user_data']?['role'] as String?;
    if (role != null && role.isNotEmpty) {
      await _tokenService.saveRole(role);
      log('Role saved: $role');
    }

    return response;
  }

  // Future<Map<String, dynamic>> studentRegister({
  //   required String userName,
  //   required String fullName,
  //   required String email,
  //   required String password,
  //   required String address,
  //   required String phoneNumber,
  //   required String schoolId,
  //   required String classroomId,
  // }) async {
  //   final response = await post<Map<String, dynamic>>(
  //     ApiConstants.studentRegister,
  //     data: {
  //       'username': userName,
  //       'full_name': fullName,
  //       'email': email,
  //       'password': password,
  //       'address': address,
  //       'phone_number': phoneNumber,
  //       'school_id': schoolId,
  //       'classroom_id': classroomId,
  //       'role': 'student',
  //     },
  //   );

  //   await _tokenService.saveRole('student');
  //   log('Role saved on student register: student');

  //   return response;
  // }

  Future<Map<String, dynamic>> studentRegister({
    required String userName,
    required String fullName,
    required String email,
    required String password,
    required String address,
    required String phoneNumber,
    required String schoolId,
    String? classroomId,
  }) async {
    final Map<String, dynamic> payload = {
      'username': userName,
      'full_name': fullName,
      'email': email,
      'password': password,
      'address': address,
      'phone_number': phoneNumber,
      'school_id': schoolId,
      'role': 'student',
    };

    if (classroomId != null && classroomId.isNotEmpty) {
      payload['classroom_id'] = classroomId;
    }

    final response = await post<Map<String, dynamic>>(
      ApiConstants.studentRegister,
      data: payload,
    );

    await _tokenService.saveRole('student');
    log('Role saved on student register: student');

    return response;
  }
}
