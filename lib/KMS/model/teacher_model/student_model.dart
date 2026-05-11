class StudentModel {
  final String id;
  final String name;
  final String schoolName;
  final String classroomName;
  final String? address;
  final String? phoneNumber;
  final DateTime createdAt;
  bool isPresent;

  StudentModel({
    required this.id,
    required this.name,
    required this.schoolName,
    required this.classroomName,
    this.address,
    this.phoneNumber,
    required this.createdAt,
    this.isPresent = false,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'],
        name: json['name'],
        schoolName: json['school_name'] ?? '',
        classroomName: json['classroom_name'] ?? '',
        address: json['address'],
        phoneNumber: json['phone_number'],
        createdAt: DateTime.parse(json['created_at']),
      );
}