import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

class ChatPreferenceNotifier extends StateNotifier<Map<String, String>> {
  ChatPreferenceNotifier() : super({});

  String getPreference(String userId) {
    return state[userId] ?? '24_hours';
  }

  void setPreference(String userId, String preference) {
    state = {...state, userId: preference};
  }

  Future<void> fetchPreference(String userId) async {
    final token = AppData().accessToken ?? '';
    if (token.isEmpty) return;

    try {
      final uri = Uri.parse(ApiConstants.chatPreferences)
          .replace(queryParameters: {'chat_partner': userId});

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        String? preference;

        if (body is List && body.isNotEmpty) {
          preference = body.first['deletion_preference'] as String?;
        } else if (body is Map) {
          preference = body['deletion_preference'] as String?;
        }

        if (preference != null && preference.isNotEmpty) {
          setPreference(userId, preference);
        }
      }
    } catch (_) {
      // Keep whatever is already in state (or the default) on failure.
    }
  }
}

final chatPreferenceProvider =
    StateNotifierProvider<ChatPreferenceNotifier, Map<String, String>>(
  (ref) => ChatPreferenceNotifier(),
);