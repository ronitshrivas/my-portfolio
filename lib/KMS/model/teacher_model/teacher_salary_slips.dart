class SalarySlipResponse {
  final int total;
  final List<SalarySlipModel> slips;

  SalarySlipResponse({required this.total, required this.slips});

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) =>
      SalarySlipResponse(
        total: json['total'] as int,
        slips:
            (json['slips'] as List)
                .map((e) => SalarySlipModel.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}

class SalarySlipModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final String school;
  final String schoolName;
  final int month;
  final int year;
  final double totalHours;
  final int totalClasses;
  final double baseSalary;
  final double commission;
  final double adjustments;
  final double netSalary;
  final String status;
  final bool adminOverride;
  final String? overrideNotes;
  final DateTime createdAt;

  SalarySlipModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.school,
    required this.schoolName,
    required this.month,
    required this.year,
    required this.totalHours,
    required this.totalClasses,
    required this.baseSalary,
    required this.commission,
    required this.adjustments,
    required this.netSalary,
    required this.status,
    required this.adminOverride,
    this.overrideNotes,
    required this.createdAt,
  });

  factory SalarySlipModel.fromJson(Map<String, dynamic> json) =>
      SalarySlipModel(
        id: json['id'] as String,
        teacherId: json['teacher'] as String,
        teacherName: json['teacher_name'] as String,
        school: json['school'] as String,
        schoolName: json['school_name'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        totalHours: double.parse(json['total_hours'].toString()),
        totalClasses: json['total_classes'] as int,
        baseSalary: double.parse(json['base_salary'].toString()),
        commission: double.parse(json['commission'].toString()),
        adjustments: double.parse(json['adjustments'].toString()),
        netSalary: double.parse(json['net_salary'].toString()),
        status: json['status'] as String,
        adminOverride: json['admin_override'] as bool,
        overrideNotes: json['override_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';

  String get monthName =>
      [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];
}
