import 'dart:ui';

class CoordinatorAttendanceResponse {
  final int total;
  final int pending;
  final List<CoordinatorAttendanceModel> attendances;

  CoordinatorAttendanceResponse({
    required this.total,
    required this.pending,
    required this.attendances,
  });

  factory CoordinatorAttendanceResponse.fromJson(Map<String, dynamic> json) =>
      CoordinatorAttendanceResponse(
        total: json['total'] as int,
        pending: json['pending'] as int,
        attendances: (json['attendances'] as List)
            .map((e) =>
                CoordinatorAttendanceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CoordinatorAttendanceModel {
  final String id;
  final String teacherId;
  final String teacherName;
  final DateTime date;
  final String schoolId;
  final String schoolName;
  final String status;
  final DateTime? approvedAt;

  CoordinatorAttendanceModel({
    required this.id,
    required this.teacherId,
    required this.teacherName,
    required this.date,
    required this.schoolId,
    required this.schoolName,
    required this.status,
    this.approvedAt,
  });

  factory CoordinatorAttendanceModel.fromJson(Map<String, dynamic> json) =>
      CoordinatorAttendanceModel(
        id: json['id'] as String,
        teacherId: json['teacher_id'] as String,
        teacherName: json['teacher_name'] as String,
        date: DateTime.parse(json['date'] as String),
        schoolId: json['school_id'] as String,
        schoolName: json['school_name'] as String,
        status: json['status'] as String,
        approvedAt: json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
      );

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
}

class CoordinatorInvoiceModel {
  final String id;
  final String schoolId;
  final String invoiceNumber;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String description;
  final DateTime issueDate;
  final DateTime dueDate;
  final String status;
  final String? bankQrCode;
  final DateTime createdAt;

  CoordinatorInvoiceModel({
    required this.id,
    required this.schoolId,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.description,
    required this.issueDate,
    required this.dueDate,
    required this.status,
    this.bankQrCode,
    required this.createdAt,
  });

  factory CoordinatorInvoiceModel.fromJson(Map<String, dynamic> json) =>
      CoordinatorInvoiceModel(
        id: json['id'] as String,
        schoolId: json['school_id'] as String,
        invoiceNumber: json['invoice_number'] as String,
        totalAmount: double.parse(json['total_amount'].toString()),
        paidAmount: double.parse(json['paid_amount'].toString()),
        dueAmount: double.parse(json['due_amount'].toString()),
        description: json['description'] as String,
        issueDate: DateTime.parse(json['issue_date'] as String),
        dueDate: DateTime.parse(json['due_date'] as String),
        status: json['status'] as String,
        bankQrCode: json['bank_qr_code'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isPartial => status == 'partial';

  String get statusLabel {
    switch (status) {
      case 'paid':
        return 'PAID';
      case 'partial':
        return 'PARTIAL';
      default:
        return 'PENDING';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'partial':
        return const Color(0xFFF8BD00);
      default:
        return const Color(0xFFEA580C);
    }
  }
}