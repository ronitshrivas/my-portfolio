// Backend DTOs for the Events service (http://36.253.137.34:8018).

class EventDto {
  const EventDto({
    required this.id,
    required this.title,
    this.description = '',
    this.location = '',
    this.date,
    this.createdByUsername = '',
    this.participantsCount = 0,
    this.isParticipant = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime? date;
  final String createdByUsername;
  final int participantsCount;
  final bool isParticipant;
  final DateTime? createdAt;

  factory EventDto.fromJson(Map<String, dynamic> json) => EventDto(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        date: json['date'] is String
            ? DateTime.tryParse(json['date'] as String)
            : null,
        createdByUsername: json['created_by_username']?.toString() ?? '',
        participantsCount: (json['participants_count'] as num?)?.toInt() ?? 0,
        isParticipant: json['is_participant'] == true,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'date': date?.toIso8601String(),
        'created_by_username': createdByUsername,
        'participants_count': participantsCount,
        'is_participant': isParticipant,
        'created_at': createdAt?.toIso8601String(),
      };
}
