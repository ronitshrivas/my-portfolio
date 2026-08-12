// Backend DTOs for the E-learning service (http://36.253.137.34:8017).
// Student-facing shapes: courses, enrollments, notifications.

/// Prices arrive as strings ("1499.00"), so parse without a hard cast that
/// would throw and drop the whole course list.
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class Course {
  const Course({
    required this.id,
    required this.title,
    this.description = '',
    this.price = 0,
    this.courseType = 'free',
    this.isPublished = true,
    this.thumbnail,
    this.categoryId,
    this.categoryName,
    this.vendorName,
    this.contentCount = 0,
    this.enrollmentCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String courseType;
  final bool isPublished;
  final String? thumbnail;
  final String? categoryId;
  final String? categoryName;
  final String? vendorName;
  final int contentCount;
  final int enrollmentCount;

  bool get isFree => courseType.toLowerCase() == 'free' || price <= 0;

  factory Course.fromJson(Map<String, dynamic> json) {
    final category = json['category'] ?? json['category_detail'];
    return Course(
      id: json['id']?.toString() ?? '',
      title: (json['title'] ?? json['name'])?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      courseType: (json['course_type'] ?? json['type'])?.toString() ?? 'free',
      isPublished: json['is_published'] != false,
      thumbnail: json['thumbnail']?.toString(),
      categoryId: (json['category_id'] ??
              (category is Map ? category['id'] : category))
          ?.toString(),
      categoryName: category is Map
          ? category['name']?.toString()
          : json['category_name']?.toString(),
      vendorName: json['vendor_name']?.toString(),
      // The list endpoint returns a `contents` array rather than a count.
      contentCount: json['content_count'] != null
          ? _toInt(json['content_count'])
          : (json['contents'] is List ? (json['contents'] as List).length : 0),
      enrollmentCount: _toInt(json['enrollment_count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'price': price,
        'course_type': courseType,
        'is_published': isPublished,
        'thumbnail': thumbnail,
        'category_id': categoryId,
        'category_name': categoryName,
        'vendor_name': vendorName,
        'content_count': contentCount,
        'enrollment_count': enrollmentCount,
      };
}

class Enrollment {
  const Enrollment({
    required this.id,
    required this.courseId,
    this.courseTitle = '',
    this.status = '',
    this.enrolledAt,
  });

  final String id;
  final String courseId;
  final String courseTitle;
  final String status;
  final DateTime? enrolledAt;

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    final course = json['course'] ?? json['course_detail'];
    return Enrollment(
      id: json['id']?.toString() ?? '',
      courseId:
          (json['course_id'] ?? (course is Map ? course['id'] : course))
              ?.toString() ??
              '',
      courseTitle: course is Map
          ? (course['title'] ?? course['name'])?.toString() ?? ''
          : json['course_title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      enrolledAt: json['enrolled_at'] is String
          ? DateTime.tryParse(json['enrolled_at'] as String)
          : null,
    );
  }
}

class ElearningNotification {
  const ElearningNotification({
    required this.id,
    this.title = '',
    this.message = '',
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory ElearningNotification.fromJson(Map<String, dynamic> json) =>
      ElearningNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class VendorSession {
  const VendorSession({
    required this.accessToken,
    required this.refreshToken,
    this.vendorId = '',
    this.vendorName = '',
  });

  final String accessToken;
  final String refreshToken;
  final String vendorId;
  final String vendorName;

  factory VendorSession.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'];
    return VendorSession(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      vendorId: vendor is Map ? vendor['id']?.toString() ?? '' : '',
      vendorName: vendor is Map ? vendor['name']?.toString() ?? '' : '',
    );
  }
}
