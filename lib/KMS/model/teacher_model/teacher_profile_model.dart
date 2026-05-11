class TeacherProfileModel {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final TeacherRating rating;
  final TeacherEarnings earnings;

  TeacherProfileModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.rating,
    required this.earnings,
  });

  factory TeacherProfileModel.fromJson(Map<String, dynamic> json) {
    return TeacherProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      rating: TeacherRating.fromJson(json['rating'] as Map<String, dynamic>),
      earnings: TeacherEarnings.fromJson(
        json['earnings'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone_number': phoneNumber,
    'rating': rating.toJson(),
    'earnings': earnings.toJson(),
  };
}

 
class TeacherRating {
  final double averageRating;
  final int totalRatings;
  final List<TeacherSchoolRating> schools;

  TeacherRating({
    required this.averageRating,
    required this.totalRatings,
    required this.schools,
  });

  factory TeacherRating.fromJson(Map<String, dynamic> json) => TeacherRating(
    averageRating: (json['average_rating'] as num).toDouble(),
    totalRatings: json['total_ratings'] as int,
    schools:
        (json['schools'] as List)
            .map((e) => TeacherSchoolRating.fromJson(e as Map<String, dynamic>))
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'average_rating': averageRating,
    'total_ratings': totalRatings,
    'schools': schools.map((e) => e.toJson()).toList(),
  };
}

class TeacherSchoolRating {
  final String schoolId;
  final String schoolName;
  final double averageRating;
  final int ratingsCount;
  final LatestRating? latestRating;

  TeacherSchoolRating({
    required this.schoolId,
    required this.schoolName,
    required this.averageRating,
    required this.ratingsCount,
    this.latestRating,
  });

  factory TeacherSchoolRating.fromJson(Map<String, dynamic> json) =>
      TeacherSchoolRating(
        schoolId: json['school_id'] as String,
        schoolName: json['school_name'] as String,
        averageRating: (json['average_rating'] as num).toDouble(),
        ratingsCount: json['ratings_count'] as int,
        latestRating:
            json['latest_rating'] != null
                ? LatestRating.fromJson(
                  json['latest_rating'] as Map<String, dynamic>,
                )
                : null,
      );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'school_name': schoolName,
    'average_rating': averageRating,
    'ratings_count': ratingsCount,
    'latest_rating': latestRating?.toJson(),
  };
}

class LatestRating {
  final double rating;
  final String? review;
  final int month;
  final int year;
  final String coordinatorName;
  final DateTime createdAt;

  LatestRating({
    required this.rating,
    this.review,
    required this.month,
    required this.year,
    required this.coordinatorName,
    required this.createdAt,
  });

  factory LatestRating.fromJson(Map<String, dynamic> json) => LatestRating(
    rating: (json['rating'] as num).toDouble(),
    review: json['review'] as String?,
    month: json['month'] as int,
    year: json['year'] as int,
    coordinatorName: json['coordinator_name'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'review': review,
    'month': month,
    'year': year,
    'coordinator_name': coordinatorName,
    'created_at': createdAt.toIso8601String(),
  };
}

 
class TeacherEarnings {
  final double totalEarnings;
  final double totalPaid;
  final double totalPending;
  final double totalCommission;
  final double projectedEarnings;
  final List<TeacherSchoolEarning> schools;

  TeacherEarnings({
    required this.totalEarnings,
    required this.totalPaid,
    required this.totalPending,
    required this.totalCommission,
    required this.projectedEarnings,
    required this.schools,
  });

  factory TeacherEarnings.fromJson(Map<String, dynamic> json) => TeacherEarnings(
    totalEarnings: (json['total_earnings'] as num).toDouble(),
    totalPaid: (json['total_paid'] as num).toDouble(),
    totalPending: (json['total_pending'] as num).toDouble(),
    totalCommission: (json['total_commission'] as num).toDouble(),
    projectedEarnings: (json['projected_earnings'] as num).toDouble(),
    schools:
        (json['schools'] as List)
            .map(
              (e) => TeacherSchoolEarning.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'total_earnings': totalEarnings,
    'total_paid': totalPaid,
    'total_pending': totalPending,
    'total_commission': totalCommission,
    'projected_earnings': projectedEarnings,
    'schools': schools.map((e) => e.toJson()).toList(),
  };
}

class TeacherSchoolEarning {
  final String schoolId;
  final String schoolName;
  final List<TeacherClassroom> classrooms;
  final double totalEarnings;
  final double totalCommission;
  final double projectedEarnings;
  final int classesCount;

  TeacherSchoolEarning({
    required this.schoolId,
    required this.schoolName,
    required this.classrooms,
    required this.totalEarnings,
    required this.totalCommission,
    required this.projectedEarnings,
    required this.classesCount,
  });

  factory TeacherSchoolEarning.fromJson(Map<String, dynamic> json) =>
      TeacherSchoolEarning(
        schoolId: json['school_id'] as String,
        schoolName: json['school_name'] as String,
        classrooms:
            (json['classrooms'] as List? ?? [])
                .map(
                  (e) => TeacherClassroom.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
        totalEarnings: (json['total_earnings'] as num).toDouble(),
        totalCommission: (json['total_commission'] as num).toDouble(),
        projectedEarnings: (json['projected_earnings'] as num).toDouble(),
        classesCount: json['classes_count'] as int,
      );

  Map<String, dynamic> toJson() => {
    'school_id': schoolId,
    'school_name': schoolName,
    'classrooms': classrooms.map((e) => e.toJson()).toList(),
    'total_earnings': totalEarnings,
    'total_commission': totalCommission,
    'projected_earnings': projectedEarnings,
    'classes_count': classesCount,
  };
}

class TeacherClassroom {
  final String id;
  final String name;

  const TeacherClassroom({required this.id, required this.name});

  factory TeacherClassroom.fromJson(Map<String, dynamic> json) =>
      TeacherClassroom(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}