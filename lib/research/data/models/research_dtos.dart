// Backend DTOs for the Research service (http://36.253.137.34:8019).
// Note: this service serves paths without an /api prefix.

class ResearchPaper {
  const ResearchPaper({
    required this.id,
    this.email = '',
    this.title = '',
    this.description = '',
    this.fileUrl = '',
    this.type = 'free',
    this.price = 0,
    this.status = '',
    this.paymentStatus = '',
    this.khaltiPidx,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String email;
  final String title;
  final String description;
  final String fileUrl;
  final String type;
  final double price;
  final String status;
  final String paymentStatus;
  final String? khaltiPidx;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPaid => type.toLowerCase() == 'paid';
  bool get isPaymentComplete => paymentStatus.toLowerCase() == 'completed';

  factory ResearchPaper.fromJson(Map<String, dynamic> json) => ResearchPaper(
        id: (json['id'] as num?)?.toInt() ??
            int.tryParse(json['id']?.toString() ?? '') ??
            0,
        email: json['email']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        fileUrl: json['file_url']?.toString() ?? '',
        type: json['type']?.toString() ?? 'free',
        price: json['price'] is num
            ? (json['price'] as num).toDouble()
            : double.tryParse(json['price']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? '',
        paymentStatus: json['payment_status']?.toString() ?? '',
        khaltiPidx: json['khalti_pidx']?.toString(),
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] is String
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

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
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class ResearchDetail {
  const ResearchDetail({required this.paper, this.researchers = const []});

  final ResearchPaper paper;
  final List<ResearcherInfo> researchers;

  factory ResearchDetail.fromJson(Map<String, dynamic> json) {
    final paperJson = json['paper'] is Map
        ? Map<String, dynamic>.from(json['paper'] as Map)
        : json;
    final rawResearchers = json['researchers'];
    return ResearchDetail(
      paper: ResearchPaper.fromJson(paperJson),
      researchers: rawResearchers is List
          ? rawResearchers
              .whereType<Map>()
              .map((e) => ResearcherInfo.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class ResearcherInfo {
  const ResearcherInfo({required this.id, this.name = '', this.profilePdfUrl});

  final int id;
  final String name;
  final String? profilePdfUrl;

  factory ResearcherInfo.fromJson(Map<String, dynamic> json) => ResearcherInfo(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
        profilePdfUrl: json['profile_pdf_url']?.toString(),
      );
}

class ResearchPage {
  const ResearchPage({this.data = const [], this.page = 1, this.limit = 20});

  final List<ResearchPaper> data;
  final int page;
  final int limit;

  factory ResearchPage.fromJson(Map<String, dynamic> json) => ResearchPage(
        data: json['data'] is List
            ? (json['data'] as List)
                .whereType<Map>()
                .map((e) => ResearchPaper.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        page: (json['page'] as num?)?.toInt() ?? 1,
        limit: (json['limit'] as num?)?.toInt() ?? 20,
      );
}
