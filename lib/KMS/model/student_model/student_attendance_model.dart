class StudentAttendanceModel {
  final String id;
  final String student;
  final String studentName;
  final String classroom;
  final String classroomName;
  final String date;
  final String status;
  final String markedAt;
  final String notes;
  final String homework;
  final String approved;

  StudentAttendanceModel({
    required this.id,
    required this.student,
    required this.studentName,
    required this.classroom,
    required this.classroomName,
    required this.date,
    required this.status,
    required this.markedAt,
    required this.notes,
    required this.homework,
    required this.approved,
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      id: json['id'] as String,
      student: json['student'] as String,
      studentName: json['student_name'] as String,
      classroom: json['classroom'] as String,
      classroomName: json['classroom_name'] as String,
      date: json['date'] as String,
      status: json['status'] as String,
      markedAt: json['marked_at'] as String,
      notes: json['notes'] as String? ?? '',
      homework: json['homework'] as String? ?? '',
      approved: json['approved'] as String,
    );
  }
}