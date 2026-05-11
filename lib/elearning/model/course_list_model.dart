// class CourseListModel {
//   final String id;
//   final String vendor;
//   final String vendorName;
//   final String category;
//   final String? categoryName;
//   final String title;
//   final String description;
//   final double price;
//   final String courseType;
//   final bool isPublished;
//   final bool isEnrolled;
//   final DateTime createdAt;
//   final String? thumbnail;
//   final List<CourseContent> contents;

//   CourseListModel({
//     required this.id,
//     required this.vendor,
//     required this.vendorName,
//     required this.category,
//     this.categoryName,
//     required this.title,
//     required this.description,
//     required this.price,
//     this.thumbnail,
//     required this.courseType,
//     required this.isPublished,
//     required this.isEnrolled,
//     required this.createdAt,
//     required this.contents,
//   });

//   bool get isFree => courseType == 'free';

//   factory CourseListModel.fromJson(Map<String, dynamic> json) {
//     return CourseListModel(
//       id: json['id'] ?? '',
//       vendor: json['vendor'] ?? '',
//       vendorName: json['vendor_name'] ?? '',
//       category: json['category'] ?? '',
//       categoryName: json['category_name'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
//       thumbnail: json['thumbnail'],
//       courseType: json['course_type'] ?? '',
//       isPublished: json['is_published'] ?? false,
//       isEnrolled: json['is_enrolled'] ?? false,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//       contents:
//           (json['contents'] as List?)
//               ?.map((e) => CourseContent.fromJson(e))
//               .toList() ??
//           [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'vendor': vendor,
//       'vendor_name': vendorName,
//       'category': category,
//       'category_name': categoryName,
//       'title': title,
//       'description': description,
//       'price': price.toStringAsFixed(2),
//       'thumbnail': thumbnail,
//       'course_type': courseType,
//       'is_published': isPublished,
//       'is_enrolled': isEnrolled,
//       'created_at': createdAt.toIso8601String(),
//       'contents': contents.map((e) => e.toJson()).toList(),
//     };
//   }
// }

// class CourseContent {
//   final String id;
//   final String course;
//   final String title;
//   final String instructorName;
//   final String? videoUrl;
//   final String? videoFile;
//   final String? thumbnail;
//   final double duration;
//   final String? documentUrl;
//   final String? documentFile;
//   final String courseLevel;
//   final bool? isPreview;
//   final int order;
//   final DateTime createdAt;

//   CourseContent({
//     required this.id,
//     required this.course,
//     required this.title,
//     required this.instructorName,
//     this.videoUrl,
//     this.videoFile,
//     this.thumbnail,
//     required this.duration,
//     this.documentUrl,
//     this.documentFile,
//     required this.courseLevel,
//     this.isPreview,
//     required this.order,
//     required this.createdAt,
//   });

//   factory CourseContent.fromJson(Map<String, dynamic> json) {
//     return CourseContent(
//       id: json['id'] ?? '',
//       course: json['course'] ?? '',
//       title: json['title'] ?? '',
//       instructorName: json['instructor_name'] ?? '',
//       videoUrl: json['video_url'],
//       videoFile: json['video_file'],
//       thumbnail: json['thumbnail'],
//       duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
//       documentUrl: json['document_url'],
//       documentFile: json['document_file'],
//       courseLevel: json['course_level'] ?? '',
//       isPreview: json['is_preview'] ?? false,
//       order: json['order'] ?? 0,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'course': course,
//       'title': title,
//       'instructor_name': instructorName,
//       'video_url': videoUrl,
//       'video_file': videoFile,
//       'thumbnail': thumbnail,
//       'duration': duration,
//       'document_url': documentUrl,
//       'document_file': documentFile,
//       'course_level': courseLevel,
//       'is_preview': isPreview,
//       'order': order,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }
// }

// class CourseListModel {
//   final String id;
//   final String vendor;
//   final String vendorName;
//   final String category;
//   final String? categoryName;
//   final String title;
//   final String description;
//   final double price;
//   final String courseType;
//   final bool isPublished;
//   final bool isEnrolled;
//   final DateTime createdAt;
//   final String? thumbnail;
//   final List<CourseContent> contents;

//   CourseListModel({
//     required this.id,
//     required this.vendor,
//     required this.vendorName,
//     required this.category,
//     this.categoryName,
//     required this.title,
//     required this.description,
//     required this.price,
//     this.thumbnail,
//     required this.courseType,
//     required this.isPublished,
//     required this.isEnrolled,
//     required this.createdAt,
//     required this.contents,
//   });

//   bool get isFree => courseType == 'free';

//   factory CourseListModel.fromJson(Map<String, dynamic> json) {
//     return CourseListModel(
//       id: json['id'] ?? '',
//       vendor: json['vendor'] ?? '',
//       vendorName: json['vendor_name'] ?? '',
//       category: json['category'] ?? '',
//       categoryName: json['category_name'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
//       thumbnail: json['thumbnail'],
//       courseType: json['course_type'] ?? '',
//       isPublished: json['is_published'] ?? false,
//       isEnrolled: json['is_enrolled'] ?? false,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//       contents:
//           (json['contents'] as List?)
//               ?.map((e) => CourseContent.fromJson(e))
//               .toList() ??
//           [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'vendor': vendor,
//       'vendor_name': vendorName,
//       'category': category,
//       'category_name': categoryName,
//       'title': title,
//       'description': description,
//       'price': price.toStringAsFixed(2),
//       'thumbnail': thumbnail,
//       'course_type': courseType,
//       'is_published': isPublished,
//       'is_enrolled': isEnrolled,
//       'created_at': createdAt.toIso8601String(),
//       'contents': contents.map((e) => e.toJson()).toList(),
//     };
//   }
// }

// class CourseContent {
//   final String id;
//   final String course;
//   final String title;
//   final String instructorName;
//   final String? videoUrl;
//   final String? directVideoUrl;
//   final String? videoFile;
//   final String? thumbnail;
//   final double duration;
//   final String? documentUrl;
//   final String? documentFile;
//   final String courseLevel;
//   final bool? isPreview;
//   final int order;
//   final DateTime createdAt;

//   CourseContent({
//     required this.id,
//     required this.course,
//     required this.title,
//     required this.instructorName,
//     this.videoUrl,
//     this.directVideoUrl,
//     this.videoFile,
//     this.thumbnail,
//     required this.duration,
//     this.documentUrl,
//     this.documentFile,
//     required this.courseLevel,
//     this.isPreview,
//     required this.order,
//     required this.createdAt,
//   });

//   /// Returns the best playable URL for this content.
//   ///
//   /// Priority:
//   ///   1. `video_file` / `direct_video_url` that points to a direct media file
//   ///      (.mp4, .m3u8, .webm, etc.) → use with VideoPlayerController
//   ///   2. `video_url` (embed iframe URL) → use with WebView
//   ///   3. `direct_video_url` fallback (even if it looks like an embed)
//   String? get effectiveVideoUrl {
//     // Prefer a direct file URL first (VideoPlayer-compatible)
//     final file = videoFile?.isNotEmpty == true ? videoFile : null;
//     final direct = directVideoUrl?.isNotEmpty == true ? directVideoUrl : null;
//     final embed = videoUrl?.isNotEmpty == true ? videoUrl : null;

//     // Pick whichever direct URL exists
//     final directCandidate = file ?? direct;
//     if (directCandidate != null && !_looksLikeEmbed(directCandidate)) {
//       return directCandidate;
//     }
//     // Fall back to embed URL
//     if (embed != null) return embed;
//     // Last resort: direct_video_url even if embed-like
//     return direct ?? file;
//   }

//   /// Returns true when the URL should be rendered in a WebView (iframe embed).
//   bool get isEmbedUrl {
//     final url = effectiveVideoUrl;
//     if (url == null) return false;
//     return _looksLikeEmbed(url);
//   }

//   static bool _looksLikeEmbed(String url) {
//     return url.contains('iframe.mediadelivery.net') ||
//         url.contains('/embed/') ||
//         url.contains('iframe') ||
//         url.contains('youtube.com/embed') ||
//         url.contains('youtu.be') ||
//         url.contains('vimeo.com') ||
//         url.contains('player.');
//   }

//   factory CourseContent.fromJson(Map<String, dynamic> json) {
//     return CourseContent(
//       id: json['id'] ?? '',
//       course: json['course'] ?? '',
//       title: json['title'] ?? '',
//       instructorName: json['instructor_name'] ?? '',
//       videoUrl: json['video_url'],
//       directVideoUrl: json['direct_video_url'],
//       videoFile: json['video_file'],
//       thumbnail: json['thumbnail'],
//       duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
//       documentUrl: json['document_url'],
//       documentFile: json['document_file'],
//       courseLevel: json['course_level'] ?? '',
//       isPreview: json['is_preview'] ?? false,
//       order: json['order'] ?? 0,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'course': course,
//       'title': title,
//       'instructor_name': instructorName,
//       'video_url': videoUrl,
//       'direct_video_url': directVideoUrl,
//       'video_file': videoFile,
//       'thumbnail': thumbnail,
//       'duration': duration,
//       'document_url': documentUrl,
//       'document_file': documentFile,
//       'course_level': courseLevel,
//       'is_preview': isPreview,
//       'order': order,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }
// }

// class CourseListModel {
//   final String id;
//   final String vendor;
//   final String vendorName;
//   final String category;
//   final String? categoryName;
//   final String title;
//   final String description;
//   final double price;
//   final String courseType;
//   final bool isPublished;
//   final bool isEnrolled;
//   final DateTime createdAt;
//   final String? thumbnail;
//   final List<CourseContent> contents;

//   CourseListModel({
//     required this.id,
//     required this.vendor,
//     required this.vendorName,
//     required this.category,
//     this.categoryName,
//     required this.title,
//     required this.description,
//     required this.price,
//     this.thumbnail,
//     required this.courseType,
//     required this.isPublished,
//     required this.isEnrolled,
//     required this.createdAt,
//     required this.contents,
//   });

//   bool get isFree => courseType == 'free';

//   factory CourseListModel.fromJson(Map<String, dynamic> json) {
//     return CourseListModel(
//       id: json['id'] ?? '',
//       vendor: json['vendor'] ?? '',
//       vendorName: json['vendor_name'] ?? '',
//       category: json['category'] ?? '',
//       categoryName: json['category_name'] ?? '',
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
//       thumbnail: json['thumbnail'],
//       courseType: json['course_type'] ?? '',
//       isPublished: json['is_published'] ?? false,
//       isEnrolled: json['is_enrolled'] ?? false,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//       contents:
//           (json['contents'] as List?)
//               ?.map((e) => CourseContent.fromJson(e))
//               .toList() ??
//           [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'vendor': vendor,
//       'vendor_name': vendorName,
//       'category': category,
//       'category_name': categoryName,
//       'title': title,
//       'description': description,
//       'price': price.toStringAsFixed(2),
//       'thumbnail': thumbnail,
//       'course_type': courseType,
//       'is_published': isPublished,
//       'is_enrolled': isEnrolled,
//       'created_at': createdAt.toIso8601String(),
//       'contents': contents.map((e) => e.toJson()).toList(),
//     };
//   }
// }

// class CourseContent {
//   final String id;
//   final String course;
//   final String title;
//   final String instructorName;
//   final String? videoUrl;
//   final String? videoFile;
//   final String? thumbnail;
//   final double duration;
//   final String? documentUrl;
//   final String? documentFile;
//   final String courseLevel;
//   final bool? isPreview;
//   final int order;
//   final DateTime createdAt;

//   CourseContent({
//     required this.id,
//     required this.course,
//     required this.title,
//     required this.instructorName,
//     this.videoUrl,
//     this.videoFile,
//     this.thumbnail,
//     required this.duration,
//     this.documentUrl,
//     this.documentFile,
//     required this.courseLevel,
//     this.isPreview,
//     required this.order,
//     required this.createdAt,
//   });

//   factory CourseContent.fromJson(Map<String, dynamic> json) {
//     return CourseContent(
//       id: json['id'] ?? '',
//       course: json['course'] ?? '',
//       title: json['title'] ?? '',
//       instructorName: json['instructor_name'] ?? '',
//       videoUrl: json['video_url'],
//       videoFile: json['video_file'],
//       thumbnail: json['thumbnail'],
//       duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
//       documentUrl: json['document_url'],
//       documentFile: json['document_file'],
//       courseLevel: json['course_level'] ?? '',
//       isPreview: json['is_preview'] ?? false,
//       order: json['order'] ?? 0,
//       createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'course': course,
//       'title': title,
//       'instructor_name': instructorName,
//       'video_url': videoUrl,
//       'video_file': videoFile,
//       'thumbnail': thumbnail,
//       'duration': duration,
//       'document_url': documentUrl,
//       'document_file': documentFile,
//       'course_level': courseLevel,
//       'is_preview': isPreview,
//       'order': order,
//       'created_at': createdAt.toIso8601String(),
//     };
//   }
// }

class CourseListModel {
  final String id;
  final String vendor;
  final String vendorName;
  final String category;
  final String? categoryName;
  final String title;
  final String description;
  final double price;
  final String courseType;
  final bool isPublished;
  final bool isEnrolled;
  final DateTime createdAt;
  final String? thumbnail;
  final List<CourseContent> contents;

  CourseListModel({
    required this.id,
    required this.vendor,
    required this.vendorName,
    required this.category,
    this.categoryName,
    required this.title,
    required this.description,
    required this.price,
    this.thumbnail,
    required this.courseType,
    required this.isPublished,
    required this.isEnrolled,
    required this.createdAt,
    required this.contents,
  });

  bool get isFree => courseType == 'free';

  factory CourseListModel.fromJson(Map<String, dynamic> json) {
    return CourseListModel(
      id: json['id'] ?? '',
      vendor: json['vendor'] ?? '',
      vendorName: json['vendor_name'] ?? '',
      category: json['category'] ?? '',
      categoryName: json['category_name'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      thumbnail: json['thumbnail'],
      courseType: json['course_type'] ?? '',
      isPublished: json['is_published'] ?? false,
      isEnrolled: json['is_enrolled'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      contents:
          (json['contents'] as List?)
              ?.map((e) => CourseContent.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor': vendor,
      'vendor_name': vendorName,
      'category': category,
      'category_name': categoryName,
      'title': title,
      'description': description,
      'price': price.toStringAsFixed(2),
      'thumbnail': thumbnail,
      'course_type': courseType,
      'is_published': isPublished,
      'is_enrolled': isEnrolled,
      'created_at': createdAt.toIso8601String(),
      'contents': contents.map((e) => e.toJson()).toList(),
    };
  }
}

class CourseContent {
  final String id;
  final String course;
  final String title;
  final String instructorName;
  final String? videoUrl;
  final String? directVideoUrl;
  final String? videoFile;
  final String? thumbnail;
  final double duration;
  final String? documentUrl;
  final String? documentFile;
  final String courseLevel;
  final bool? isPreview;
  final int order;
  final DateTime createdAt;

  CourseContent({
    required this.id,
    required this.course,
    required this.title,
    required this.instructorName,
    this.videoUrl,
    this.directVideoUrl,
    this.videoFile,
    this.thumbnail,
    required this.duration,
    this.documentUrl,
    this.documentFile,
    required this.courseLevel,
    this.isPreview,
    required this.order,
    required this.createdAt,
  });

  /// Returns the best playable URL for this content.
  ///
  /// Priority:
  ///   1. `video_file` — direct media file (.mp4, .m3u8, .webm …) → VideoPlayer
  ///   2. `direct_video_url` — direct media file → VideoPlayer
  ///   3. `video_url` — embed/iframe URL → WebView
  ///   4. `direct_video_url` as last resort even if it looks like an embed
  String? get effectiveVideoUrl {
    final file = videoFile?.isNotEmpty == true ? videoFile : null;
    final direct = directVideoUrl?.isNotEmpty == true ? directVideoUrl : null;
    final embed = videoUrl?.isNotEmpty == true ? videoUrl : null;

    // 1. video_file: always a real media file — highest priority
    if (file != null && !_looksLikeEmbed(file)) return file;

    // 2. direct_video_url when it is a real media file
    if (direct != null && !_looksLikeEmbed(direct)) return direct;

    // 3. embed/iframe URL (video_url)
    if (embed != null) return embed;

    // 4. last resort: direct_video_url even if it looks like an embed
    return direct ?? file;
  }

  /// Returns true when the URL should be rendered in a WebView (iframe embed).
  bool get isEmbedUrl {
    final url = effectiveVideoUrl;
    if (url == null) return false;
    return _looksLikeEmbed(url);
  }

  static bool _looksLikeEmbed(String url) {
    return url.contains('iframe.mediadelivery.net') ||
        url.contains('/embed/') ||
        url.contains('iframe') ||
        url.contains('youtube.com/embed') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com') ||
        url.contains('player.');
  }

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: json['id'] ?? '',
      course: json['course'] ?? '',
      title: json['title'] ?? '',
      instructorName: json['instructor_name'] ?? '',
      videoUrl: json['video_url'],
      directVideoUrl: json['direct_video_url'],
      videoFile: json['video_file'],
      thumbnail: json['thumbnail'],
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      documentUrl: json['document_url'],
      documentFile: json['document_file'],
      courseLevel: json['course_level'] ?? '',
      isPreview: json['is_preview'] ?? false,
      order: json['order'] ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course': course,
      'title': title,
      'instructor_name': instructorName,
      'video_url': videoUrl,
      'direct_video_url': directVideoUrl,
      'video_file': videoFile,
      'thumbnail': thumbnail,
      'duration': duration,
      'document_url': documentUrl,
      'document_file': documentFile,
      'course_level': courseLevel,
      'is_preview': isPreview,
      'order': order,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
