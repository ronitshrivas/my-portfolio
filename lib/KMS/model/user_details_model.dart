class UserDetailsModel {
  final String id;
  final String username;
  final String email;
  final String role;
  final bool isActive;
  final bool isStaff;
  final String dateJoined;
  UserDetailsModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.isActive,
    required this.isStaff,
    required this.dateJoined,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      id: json['id'] ?? '',
      username: json['username'] ?? "",
      email: json['email']??'',
      role: json['role']??'',
      isActive: json['isActive']??false,
      isStaff: json['isStaff']??false,
      dateJoined: json['dateJoined']??'',
    );
  }
}
