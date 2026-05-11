class TeacherRatingModel {
  final String? id;
  final String? teacherId;
  final String? teacherName;
  final String? coordinatorId;
  final String? coordinatorName;
  final String? rating;
  final String? review;
  final int? month;
  final int? year;
  final bool? isRated;

  TeacherRatingModel({
    this.id,
    this.teacherId,
    this.teacherName,
    this.coordinatorId,
    this.coordinatorName,
    this.rating,
    this.review,
    this.month,
    this.year,
    this.isRated,
  });

  factory TeacherRatingModel.fromJson(Map<String, dynamic> json) {
    return TeacherRatingModel(
      id: json['id'] ?? '',
      teacherId: json['teacher'] ?? '',
      teacherName: json['teacher_name'] ?? '',
      coordinatorId: json['coordinator'] ?? '',
      coordinatorName: json['coordinator_name'] ?? "",
      review: json['review'] ?? '',
      rating: json['rating'] ?? "",
      month: json['month'] as int?,
      year: json['year'] as int?,
      isRated: json['is_rated'] ?? false,
    );
  }
}
