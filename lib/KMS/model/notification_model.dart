sealed class KMSNotificationData {
  const KMSNotificationData();
   String get type;

  factory KMSNotificationData.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final hasSchoolId = json['school_id'] != null;
    final hasTeacherId = json['teacher_id'] != null;

    if (hasSchoolId) {
      return TeacherNotificationData(
        type: type,
        schoolId: json['school_id'] as String,
        classroomId: json['classroom_id'] as String,
      );
    } else if (hasTeacherId) {
      return CoordinatorNotificationData(
        type: type,
        teacherId: json['teacher_id'] as String,
        attendanceId: json['attendance_id'] as String,
      );
    } else {
      return StudentNotificationData(
        type: type,
        attendanceId: json['attendance_id'] as String,
      );
    }
  }

  Map<String, dynamic> toJson();
}

class TeacherNotificationData extends KMSNotificationData {
  final String type;
  final String schoolId;
  final String classroomId;

  const TeacherNotificationData({
    required this.type,
    required this.schoolId,
    required this.classroomId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'school_id': schoolId,
        'classroom_id': classroomId,
      };
}

class CoordinatorNotificationData extends KMSNotificationData {
  final String type;
  final String teacherId;
  final String attendanceId;

  const CoordinatorNotificationData({
    required this.type,
    required this.teacherId,
    required this.attendanceId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'teacher_id': teacherId,
        'attendance_id': attendanceId,
      };
}

class StudentNotificationData extends KMSNotificationData {
  final String type;
  final String attendanceId;

  const StudentNotificationData({
    required this.type,
    required this.attendanceId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'attendance_id': attendanceId,
      };
}


class KMSNotificationModel {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final KMSNotificationData data;

  const KMSNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory KMSNotificationModel.fromJson(Map<String, dynamic> json) {
    return KMSNotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      data: KMSNotificationData.fromJson(
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

  static List<KMSNotificationModel> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => KMSNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}