class TeacherAttendanceRecord {
  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime checkIn;
  final DateTime? checkOut;
  final String schoolId;
  final String schoolName;
  final String status;
  final DateTime? supervisedAt;
  final String? supervisedBy;
  final double? totalHours;

  const TeacherAttendanceRecord({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.checkIn,
    this.checkOut,
    required this.schoolId,
    required this.schoolName,
    required this.status,
    this.supervisedAt,
    this.supervisedBy,
    this.totalHours,
  });

  factory TeacherAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return TeacherAttendanceRecord(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String,
      status: json['status'] as String,
      supervisedAt: json['supervised_at'] != null
          ? DateTime.parse(json['supervised_at'] as String)
          : null,
      supervisedBy: json['supervised_by'] as String?,
      totalHours: json['total_hours'] != null
          ? (json['total_hours'] as num).toDouble()
          : null,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}