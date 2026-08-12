import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/models/settings_models.dart';

/// User settings — ProfileService (http://36.253.137.34:8011).
class SettingsApi {
  SettingsApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  /// Auto-creates defaults server-side and returns the current settings.
  Future<SettingsModel> getSettings() async {
    final envelope = await _client.get<SettingsModel>(
      ApiConfig.profileBaseUrl,
      '/api/settings',
      parse: (raw) => SettingsModel.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not load settings');
    }
    return data;
  }

  /// Partial update — send only the changed fields.
  Future<SettingsModel> updateSettings(Map<String, dynamic> partial) async {
    final envelope = await _client.patch<SettingsModel>(
      ApiConfig.profileBaseUrl,
      '/api/settings',
      body: partial,
      parse: (raw) => SettingsModel.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update settings');
    }
    return data;
  }

  Future<SettingsModel> resetSettings() async {
    final envelope = await _client.post<SettingsModel>(
      ApiConfig.profileBaseUrl,
      '/api/settings/reset',
      parse: (raw) => SettingsModel.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not reset settings');
    }
    return data;
  }
}
