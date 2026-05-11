class ResearcherModel {
  final int id;
  final int paperId;
  final String name;
  final String? profilePdfUrl;
  final DateTime createdAt;

  const ResearcherModel({
    required this.id,
    required this.paperId,
    required this.name,
    this.profilePdfUrl,
    required this.createdAt,
  });

  factory ResearcherModel.fromJson(Map<String, dynamic> json) {
    return ResearcherModel(
      id: json['id'] as int,
      paperId: json['paper_id'] as int,
      name: json['name'] as String,
      profilePdfUrl: json['profile_pdf_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'paper_id': paperId,
        'name': name,
        'profile_pdf_url': profilePdfUrl,
        'created_at': createdAt.toIso8601String(),
      };
}

class ResearchPaperDetailModel {
  final int id;
  final String email;
  final String title;
  final String? description;
  final String fileUrl;
  final String type; // 'free' | 'paid'
  final double? price;
  final String status; // 'active' | 'pending'
  final String paymentStatus;
  final String? khaltiPidx;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ResearchPaperDetailModel({
    required this.id,
    required this.email,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.type,
    this.price,
    required this.status,
    required this.paymentStatus,
    this.khaltiPidx,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResearchPaperDetailModel.fromJson(Map<String, dynamic> json) {
    return ResearchPaperDetailModel(
      id: json['id'] as int,
      email: json['email'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      type: json['type'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      status: json['status'] as String,
      paymentStatus: json['payment_status'] as String,
      khaltiPidx: json['khalti_pidx'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'type': type,
        'price': price,
        'status': status,
        'payment_status': paymentStatus,
        'khalti_pidx': khaltiPidx,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class ResearchPaperDetailResponseModel {
  final ResearchPaperDetailModel paper;
  final List<ResearcherModel> researchers;

  const ResearchPaperDetailResponseModel({
    required this.paper,
    required this.researchers,
  });

  factory ResearchPaperDetailResponseModel.fromJson(
      Map<String, dynamic> json) {
    return ResearchPaperDetailResponseModel(
      paper: ResearchPaperDetailModel.fromJson(
          json['paper'] as Map<String, dynamic>),
      researchers: (json['researchers'] as List<dynamic>)
          .map((e) => ResearcherModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}