class KycModel {
  final String id;
  final String? idDoc;
  final String? cv;
  final String? bankAccountNumber;
  final String? bankName;
  final String? citizenship;
  final String? nIdNumber;
  final String? photo;
  final String? address;
  final String status;
  final String? kycPercentage;
  final bool phoneVerified;
  final bool documentVerified;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;

  const KycModel({
    required this.id,
    this.idDoc,
    this.cv,
    this.bankAccountNumber,
    this.bankName,
    this.citizenship,
    this.nIdNumber,
    this.photo,
    this.address,
    required this.status,
    required this.phoneVerified,
    required this.documentVerified,
    this.submittedAt,
    this.updatedAt,
    this.approvedAt,
    this.rejectionReason,
    required this.kycPercentage,
  });

  factory KycModel.fromJson(Map<String, dynamic> json) => KycModel(
    id: json['id'] as String,
    idDoc: json['id_doc'] as String?,
    cv: json['cv'] as String?,
    bankAccountNumber: json['bank_account_number'] as String?,
    bankName: json['bank_name'] as String?,
    citizenship: json['citizenship'] as String?,
    nIdNumber: json['n_id_number'] as String?,
    photo: json['photo'] as String?,
    address: json['address'] as String?,
    kycPercentage: json['kyc_status_percentage'] as String? ?? '0%',
    status: json['status'] as String? ?? 'pending',
    phoneVerified: json['phone_verified'] as bool? ?? false,
    documentVerified: json['document_verified'] as bool? ?? false,
    submittedAt:
        json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : null,
    updatedAt:
        json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
    approvedAt:
        json['approved_at'] != null
            ? DateTime.parse(json['approved_at'] as String)
            : null,
    rejectionReason: json['rejection_reason'] as String?,
  );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
