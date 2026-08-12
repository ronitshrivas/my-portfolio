import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/events/data/models/event_dtos.dart';

/// Events service — http://36.253.137.34:8018/swagger
class EventsApi {
  EventsApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;
  static const _base = ApiConfig.eventsBaseUrl;

  Future<List<EventDto>> events() async {
    final envelope = await _client.get<List<EventDto>>(
      _base,
      '/api/events',
      parse: (raw) => _list(raw).map((e) => EventDto.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  Future<EventDto> createEvent({
    required String title,
    String description = '',
    String location = '',
    String date = '',
    List<String> participants = const [],
  }) async {
    final envelope = await _client.post<EventDto>(
      _base,
      '/api/events',
      body: {
        'title': title,
        'description': description,
        'location': location,
        'date': date,
        'participants': participants,
      },
      parse: (raw) => EventDto.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Could not create event');
    return data;
  }

  List<Map<String, dynamic>> _list(Object? raw) {
    Object? node = raw;
    if (node is Map) {
      node = node['results'] ?? node['data'] ?? node['items'] ?? node;
    }
    if (node is! List) return const [];
    return node
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
