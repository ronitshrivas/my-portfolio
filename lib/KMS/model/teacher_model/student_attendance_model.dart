class StudentAttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String classroomId;
  final String classroomName;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final String status; 
  final String markedBy;
  final DateTime markedAt;
  final String approved; 
  final String? approvedBy;
  final DateTime? approvedAt;
  final String notes;
  final String? homework;

  StudentAttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classroomId,
    required this.classroomName,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedAt,
    required this.approved,
    this.approvedBy,
    this.approvedAt,
    required this.notes,
    this.homework,
  });

  bool get isPresent =>
      status == 'present' || status == 'present_with_homework';
  bool get isPresentWithHomework => status == 'present_with_homework';

  factory StudentAttendanceRecord.fromJson(Map<String, dynamic> json) =>
      StudentAttendanceRecord(
        id: json['id'],
        studentId: json['student'],
        studentName: json['student_name'] ?? '',
        classroomId: json['classroom'],
        classroomName: json['classroom_name'] ?? '',
        teacherId: json['teacher'],
        teacherName: json['teacher_name'] ?? '',
        date: DateTime.parse(json['date']),
        status: json['status'] ?? 'absent',
        markedBy: json['marked_by'],
        markedAt: DateTime.parse(json['marked_at']),
        approved: json['approved'] ?? 'PENDING',
        approvedBy: json['approved_by'],
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'])
            : null,
        notes: json['notes'] ?? '',
        homework: json['homework'],
      );
}