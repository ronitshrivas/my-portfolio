class HomeworkModel {
  final String id;
  final String date;
  final String homework;
  final String teacherName;
  final String classroomName;
  final String status;

  HomeworkModel({
    required this.id,
    required this.date,
    required this.homework,
    required this.teacherName,
    required this.classroomName,
    required this.status,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] as String,
      date: json['date'] as String,
      homework: json['homework'] as String? ?? '',
      teacherName: json['teacher_name'] as String,
      classroomName: json['classroom_name'] as String,
      status: json['status'] as String,
    );
  }
}