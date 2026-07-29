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
      id: json['id']?.toString() ?? '',
      student: json['student']?.toString() ?? '',
      course: json['course']?.toString() ?? '',
      courseTitle: json['course_title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      isEnrolled: json['is_enrolled'] as bool? ?? false,
      enrolledAt:
          DateTime.tryParse(json['enrolled_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}