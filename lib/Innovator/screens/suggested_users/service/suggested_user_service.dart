import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/screens/suggested_users/model/suggested_users_model.dart';

import '../../../constant/api_constants.dart';

class SuggestedUserService {
  static final Dio _dio = Dio();

  Future<SuggestionResponse> suggestedUser() async {
    try {
      final token = AppData().accessToken;

      final response = await _dio.get(
        ApiConstants.fetchsuggestionusers,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return SuggestionResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      throw Exception('Unexpected status code: ${response.statusCode}');
    } on DioException catch (e) {
      log('SuggestedUserService DioException: ${e.message}');
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Connection timed out. Please try again.');
        case DioExceptionType.connectionError:
          throw Exception('No internet connection.');
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode;
          if (code == 401)
            throw Exception('Unauthorized. Please log in again.');
          if (code == 404) throw Exception('Endpoint not found.');
          throw Exception('Server error ($code).');
        default:
          throw Exception('Something went wrong. Please try again.');
      }
    } on FormatException catch (e) {
      log('SuggestedUserService FormatException: $e');
      throw Exception('Failed to parse suggested users response.');
    } catch (e) {
      log('SuggestedUserService Unknown: $e');
      throw Exception('Failed to load suggested users.');
    }
  }
}
