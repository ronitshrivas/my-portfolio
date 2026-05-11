
class ElearningNotificationData {
  final String type;
  final String courseId;

  const ElearningNotificationData({
    required this.type,
    required this.courseId,
  });

  factory ElearningNotificationData.fromJson(Map<String, dynamic> json) {
    return ElearningNotificationData(
      type: json['type'] as String,
      courseId: json['course_id'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'course_id': courseId,
  };
}

class ElearningNotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final ElearningNotificationData data;

  const ElearningNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory ElearningNotificationModel.fromJson(Map<String, dynamic> json) {
    return ElearningNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: ElearningNotificationData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'notification_type': notificationType,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'data': data.toJson(),
  };

   static List<ElearningNotificationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
      .map((e) => ElearningNotificationModel.fromJson(e as Map<String, dynamic>))
      .toList();
  }
}


