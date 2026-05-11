class ElearningApi {
  // static const String baseUrl = 'http://36.253.137.34:8003/api';
  static const String baseUrl = 'http://36.253.137.34:8003/api';

  static const String courseList = '$baseUrl/courses';
  static const String studentEnrollment = '$baseUrl/student/enrollments/';
  static const String payment = '$baseUrl/payments/initiate/';
  //  notifications
  static const String fcmTokens = '$baseUrl/fcm-tokens/';
  static const String notificationsList = '$baseUrl/notifications/';
  static String markNotificationAsRead(String notificationId) =>
      '$baseUrl/notifications/$notificationId/mark_as_read/';
  static const String markAllNotificationsAsRead =
      '$baseUrl/notifications/mark_all_as_read/';
  // time out
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 120);
}
