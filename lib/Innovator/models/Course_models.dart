// api_models.dart
class CourseResponse {
  final int status;
  final CourseData? data;
  final String? error;
  final String message;

  CourseResponse({
    required this.status,
    this.data,
    this.error,
    required this.message,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    return CourseResponse(
      status: json['status'] ?? 0,
      data: json['data'] != null ? CourseData.fromJson(json['data']) : null,
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

class CourseData {
  final List<Course> courses;
  final Pagination pagination;

  CourseData({
    required this.courses,
    required this.pagination,
  });

  factory CourseData.fromJson(Map<String, dynamic> json) {
    return CourseData(
      courses: (json['courses'] as List? ?? [])
          .map((e) => Course.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Course {
  final String id;
  final String title;
  final String description;
  final Price price;
  final String? thumbnail;
  final String? overviewVideo;
  final String? overviewVideoDuration;
  final int? overviewVideoDurationSeconds;
  final List<Lesson> lessons;
  final Instructor instructor;
  final Author author;
  final String level;
  final String duration;
  final int durationSeconds;
  final String language;
  final List<String> tags;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final List<String> targetAudience;
  final bool isPublished;
  final int enrollmentCount;
  final Rating rating;
  final CourseSettings settings;
  final ContentStatistics? contentStatistics;
  final ComputedTotals? computedTotals;
  final String createdAt;
  final String updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.thumbnail,
    this.overviewVideo,
    this.overviewVideoDuration,
    this.overviewVideoDurationSeconds,
    required this.lessons,
    required this.instructor,
    required this.author,
    required this.level,
    required this.duration,
    required this.durationSeconds,
    required this.language,
    required this.tags,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.targetAudience,
    required this.isPublished,
    required this.enrollmentCount,
    required this.rating,
    required this.settings,
    this.contentStatistics,
    this.computedTotals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: Price.fromJson(json['price'] ?? {}),
      thumbnail: json['thumbnail'],
      overviewVideo: json['overviewVideo'],
      overviewVideoDuration: json['overviewVideoDuration'],
      overviewVideoDurationSeconds: json['overviewVideoDurationSeconds'],
      lessons: (json['lessons'] as List? ?? [])
          .map((e) => Lesson.fromJson(e))
          .toList(),
      instructor: Instructor.fromJson(json['instructor'] ?? {}),
      author: Author.fromJson(json['author'] ?? {}),
      level: json['level'] ?? 'beginner',
      duration: json['duration'] ?? '00:00:00',
      durationSeconds: json['durationSeconds'] ?? 0,
      language: json['language'] ?? 'English',
      tags: List<String>.from(json['tags'] ?? []),
      prerequisites: List<String>.from(json['prerequisites'] ?? []),
      learningOutcomes: List<String>.from(json['learningOutcomes'] ?? []),
      targetAudience: List<String>.from(json['targetAudience'] ?? []),
      isPublished: json['isPublished'] ?? false,
      enrollmentCount: json['enrollmentCount'] ?? 0,
      rating: Rating.fromJson(json['rating'] ?? {}),
      settings: CourseSettings.fromJson(json['settings'] ?? {}),
      contentStatistics: json['contentStatistics'] != null 
          ? ContentStatistics.fromJson(json['contentStatistics']) 
          : null,
      computedTotals: json['computedTotals'] != null 
          ? ComputedTotals.fromJson(json['computedTotals']) 
          : null,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

class Price {
  final double usd;
  final double npr;
  final String? id;

  Price({
    required this.usd,
    required this.npr,
    this.id,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      usd: (json['usd'] ?? 0).toDouble(),
      npr: (json['npr'] ?? 0).toDouble(),
      id: json['_id'],
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String description;
  final int sortOrder;
  final String duration;
  final int durationSeconds;
  final bool isPublished;
  final List<Note> notes;
  final List<Video> videos;
  final LessonMetadata metadata;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.duration,
    required this.durationSeconds,
    required this.isPublished,
    required this.notes,
    required this.videos,
    required this.metadata,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sortOrder'] ?? 1,
      duration: json['duration'] ?? '00:00:00',
      durationSeconds: json['durationSeconds'] ?? 0,
      isPublished: json['isPublished'] ?? false,
      notes: (json['notes'] as List? ?? [])
          .map((e) => Note.fromJson(e))
          .toList(),
      videos: (json['videos'] as List? ?? [])
          .map((e) => Video.fromJson(e))
          .toList(),
      metadata: LessonMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class LessonMetadata {
  final int estimatedTime;
  final String difficulty;
  final int totalVideos;
  final int totalNotes;

  LessonMetadata({
    required this.estimatedTime,
    required this.difficulty,
    required this.totalVideos,
    required this.totalNotes,
  });

  factory LessonMetadata.fromJson(Map<String, dynamic> json) {
    return LessonMetadata(
      estimatedTime: json['estimatedTime'] ?? 0,
      difficulty: json['difficulty'] ?? 'beginner',
      totalVideos: json['totalVideos'] ?? 0,
      totalNotes: json['totalNotes'] ?? 0,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String description;
  final String fileUrl;
  final String fileType;
  final bool premium;
  final NoteMetadata metadata;

  Note({
    required this.id,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileType,
    required this.premium,
    required this.metadata,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'] ?? 'pdf',
      premium: json['premium'] ?? false,
      metadata: NoteMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class NoteMetadata {
  final int downloadCount;

  NoteMetadata({
    required this.downloadCount,
  });

  factory NoteMetadata.fromJson(Map<String, dynamic> json) {
    return NoteMetadata(
      downloadCount: json['downloadCount'] ?? 0,
    );
  }
}

class Video {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnail;
  final String duration;
  final int sortOrder;
  final VideoMetadata metadata;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnail,
    required this.duration,
    required this.sortOrder,
    required this.metadata,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'],
      duration: json['duration'] ?? '00:00:00',
      sortOrder: json['sortOrder'] ?? 1,
      metadata: VideoMetadata.fromJson(json['metadata'] ?? {}),
    );
  }
}

class VideoMetadata {
  final String quality;
  final String fileSize;
  final int viewCount;
  final int durationSeconds;
  final int width;
  final int height;
  final String aspectRatio;
  final int bitrate;
  final String codec;
  final String format;
  final String uploadedAt;

  VideoMetadata({
    required this.quality,
    required this.fileSize,
    required this.viewCount,
    required this.durationSeconds,
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.bitrate,
    required this.codec,
    required this.format,
    required this.uploadedAt,
  });

  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      quality: json['quality'] ?? '1080p',
      fileSize: json['fileSize'] ?? '0',
      viewCount: json['viewCount'] ?? 0,
      durationSeconds: json['durationSeconds'] ?? 0,
      width: json['width'] ?? 1920,
      height: json['height'] ?? 1080,
      aspectRatio: json['aspectRatio'] ?? '16:9',
      bitrate: json['bitrate'] ?? 0,
      codec: json['codec'] ?? 'h264',
      format: json['format'] ?? 'mp4',
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }
}

class Instructor {
  final String name;
  final String bio;
  final List<String> credentials;

  Instructor({
    required this.name,
    required this.bio,
    required this.credentials,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      name: json['name'] ?? 'Unknown',
      bio: json['bio'] ?? '',
      credentials: List<String>.from(json['credentials'] ?? []),
    );
  }
}

class Author {
  final String email;
  final String id;
  final String phone;

  Author({
    required this.email,
    required this.id,
    required this.phone,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      email: json['email'] ?? '',
      id: json['_id'] ?? '',
      phone: json['phone'] ?? 'Not provided',
    );
  }
}

class Rating {
  final double average;
  final int count;

  Rating({
    required this.average,
    required this.count,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      average: (json['average'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
    );
  }
}

class CourseSettings {
  final bool allowDownloads;
  final bool certificateEnabled;

  CourseSettings({
    required this.allowDownloads,
    required this.certificateEnabled,
  });

  factory CourseSettings.fromJson(Map<String, dynamic> json) {
    return CourseSettings(
      allowDownloads: json['allowDownloads'] ?? true,
      certificateEnabled: json['certificateEnabled'] ?? true,
    );
  }
}

class ContentStatistics {
  final int totalLessons;
  final int totalLessonVideos;
  final int totalLessonNotes;
  final int totalCourseVideos;
  final int totalCoursePDFs;
  final int totalVideos;
  final int totalPDFs;
  final bool hasOverviewVideo;
  final String? overviewVideoDuration;

  ContentStatistics({
    required this.totalLessons,
    required this.totalLessonVideos,
    required this.totalLessonNotes,
    required this.totalCourseVideos,
    required this.totalCoursePDFs,
    required this.totalVideos,
    required this.totalPDFs,
    required this.hasOverviewVideo,
    this.overviewVideoDuration,
  });

  factory ContentStatistics.fromJson(Map<String, dynamic> json) {
    return ContentStatistics(
      totalLessons: json['totalLessons'] ?? 0,
      totalLessonVideos: json['totalLessonVideos'] ?? 0,
      totalLessonNotes: json['totalLessonNotes'] ?? 0,
      totalCourseVideos: json['totalCourseVideos'] ?? 0,
      totalCoursePDFs: json['totalCoursePDFs'] ?? 0,
      totalVideos: json['totalVideos'] ?? 0,
      totalPDFs: json['totalPDFs'] ?? 0,
      hasOverviewVideo: json['hasOverviewVideo'] ?? false,
      overviewVideoDuration: json['overviewVideoDuration'],
    );
  }
}

class ComputedTotals {
  final int totalDurationSeconds;
  final int totalVideoCount;
  final int totalPDFCount;
  final int totalContentCount;

  ComputedTotals({
    required this.totalDurationSeconds,
    required this.totalVideoCount,
    required this.totalPDFCount,
    required this.totalContentCount,
  });

  factory ComputedTotals.fromJson(Map<String, dynamic> json) {
    return ComputedTotals(
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      totalVideoCount: json['totalVideoCount'] ?? 0,
      totalPDFCount: json['totalPDFCount'] ?? 0,
      totalContentCount: json['totalContentCount'] ?? 0,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final bool hasMore;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.hasMore,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 0,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      hasMore: json['hasMore'] ?? false,
    );
  }
}

// Course Detail Response
class CourseDetailResponse {
  final int status;
  final CourseDetailData data;
  final String? error;
  final String message;

  CourseDetailResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailResponse(
      status: json['status'] ?? 0,
      data: CourseDetailData.fromJson(json['data'] ?? {}),
      error: json['error'],
      message: json['message'] ?? '',
    );
  }
}

class CourseDetailData {
  final Course course;
  final List<Lesson> lessons;
  final List<dynamic> courseVideos;
  final List<dynamic> coursePDFs;
  final List<dynamic> allLessonVideos;
  final List<dynamic> allLessonNotes;
  final Lesson? selectedLesson;

  CourseDetailData({
    required this.course,
    required this.lessons,
    required this.courseVideos,
    required this.coursePDFs,
    required this.allLessonVideos,
    required this.allLessonNotes,
    this.selectedLesson,
  });

  factory CourseDetailData.fromJson(Map<String, dynamic> json) {
    return CourseDetailData(
      course: Course.fromJson(json['course'] ?? {}),
      lessons: (json['lessons'] as List? ?? [])
          .map((e) => Lesson.fromJson(e))
          .toList(),
      courseVideos: json['courseVideos'] ?? [],
      coursePDFs: json['coursePDFs'] ?? [],
      allLessonVideos: json['allLessonVideos'] ?? [],
      allLessonNotes: json['allLessonNotes'] ?? [],
      selectedLesson: null,
    );
  }
}

// Parent Category Model
class ParentCategory {
  final String id;
  final String name;
  final String icon;
  final String color;
  final CategoryStatistics statistics;

  ParentCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.statistics,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#F48706',
      statistics: CategoryStatistics.fromJson(json['statistics'] ?? {}),
    );
  }
}

class CategoryStatistics {
  final int courses;
  final int subcategories;

  CategoryStatistics({
    required this.courses,
    required this.subcategories,
  });

  factory CategoryStatistics.fromJson(Map<String, dynamic> json) {
    return CategoryStatistics(
      courses: json['courses'] ?? 0,
      subcategories: json['subcategories'] ?? 0,
    );
  }
}