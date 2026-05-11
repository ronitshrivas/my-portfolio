class TeacherSessionResponse {
  final int? totalSessions;
  final List<TeacherSessionModel>? sessions;

  TeacherSessionResponse({
    this.totalSessions,
    this.sessions,
  });

  factory TeacherSessionResponse.fromJson(Map<String, dynamic> json) =>
      TeacherSessionResponse(
        totalSessions: json['total_sessions'] as int? ?? 0,
        sessions: (json['sessions'] as List?)
            ?.map((e) =>
                TeacherSessionModel.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
      );
}

class TeacherSessionModel {
  final String? teacherId;
  final String? teacherName;
  final String? classroomId;
  final String? classroomName;
  final String? date;
  final String? notes;
  final int? studentCount;

  TeacherSessionModel({
    this.teacherId,
    this.teacherName,
    this.classroomId,
    this.classroomName,
    this.date,
    this.notes,
    this.studentCount,
  });

  factory TeacherSessionModel.fromJson(Map<String, dynamic> json) =>
      TeacherSessionModel(
        teacherId: json['teacher__id'] as String? ?? 'Unknown ID',
        teacherName: json['teacher__name'] as String? ?? 'Unknown Teacher',
        classroomId: json['classroom__id'] as String? ?? 'Unknown ID',
        classroomName: json['classroom__name'] as String? ?? 'Unknown Classroom',
        date: json['date'] as String? ?? 'No Date',
        notes: json['notes'] as String? ?? 'No Notes',
        studentCount: json['student_count'] as int? ?? 0,
      );
}