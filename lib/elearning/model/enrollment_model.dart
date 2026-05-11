class EnrollmentModel {
  final String id;
  final String student;
  final String course;
  final String courseTitle;
  final String status;
  final bool isEnrolled;
  final DateTime enrolledAt;

  EnrollmentModel({
    required this.id,
    required this.student,
    required this.course,
    required this.courseTitle,
    required this.status,
    required this.isEnrolled,
    required this.enrolledAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'],
      student: json['student'],
      course: json['course'],
      courseTitle: json['course_title'],
      status: json['status'],
      isEnrolled: json['is_enrolled'] ?? false,
      enrolledAt: DateTime.parse(json['enrolled_at']),
    );
  }
}