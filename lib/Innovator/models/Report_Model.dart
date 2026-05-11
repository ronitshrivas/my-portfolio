class Report {
  final String id;
  final String reporterId;
  final String reporterUsername;
  final String reportedUserId;
  final String reportedUserUsername;
  final String reason;
  final String description;
  final String status;
  final String createdAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.reporterUsername,
    required this.reportedUserId,
    required this.reportedUserUsername,
    required this.reason,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      reporterId: json['reporter'],
      reporterUsername: json['reporter_username'],
      reportedUserId: json['reported_user'],
      reportedUserUsername: json['reported_user_username'],
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['_id'], email: json['email'], name: json['name']);
  }
}
