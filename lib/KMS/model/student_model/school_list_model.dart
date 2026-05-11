class SchoolModel {
  final String id;
  final String name;
  final String address;
  final String createdAt;

  SchoolModel({
    required this.id,
    required this.name,
    required this.address,
    required this.createdAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class ClassroomModel {
  final String id;
  final String name;
  final String schoolId;
  final String schoolName;
  final String createdAt;

  ClassroomModel({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.schoolName,
    required this.createdAt,
  });

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      schoolId: json['school_id'] as String,
      schoolName: json['school_name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class SchoolListResponse {
  final List<SchoolModel> schools;
  final List<ClassroomModel> classrooms;

  SchoolListResponse({required this.schools, required this.classrooms});

  factory SchoolListResponse.fromJson(Map<String, dynamic> json) {
    return SchoolListResponse(
      schools: (json['schools'] as List)
          .map((e) => SchoolModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      classrooms: (json['classrooms'] as List)
          .map((e) => ClassroomModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}