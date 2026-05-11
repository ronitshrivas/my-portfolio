class ApiConstants {
  //Auth Base Url

  // static String get authBaseUrl => 'http://36.253.137.34:8010/api';
  // static String get baseUrl => 'http://36.253.137.34:8002/api/kms';
  static String get authBaseUrl => 'http://36.253.137.34:8010/api';
  static String get baseUrl => 'http://36.253.137.34:8002/api/kms';

  //auth EndPoints
  static String get register => '$authBaseUrl/auth/register/';
  static String get login => '$authBaseUrl/auth/sso/login/';
  static String get studentRegister => '$baseUrl/student/register/';
  static String get studentLogin => '$baseUrl/student/login/';
  //profile data
  static String get myProfile => '$baseUrl/user/me';

  //teacher endpoints
  static String get teacherProfile => '$baseUrl/teacher/profile/';
  static String get teacherKyc => '$baseUrl/teacher/kyc/upload/';
  static String get teacherKycStatus => '$baseUrl/teacher/kyc/status/';
  static String get teacherCheckIn => '$baseUrl/teacher/attendance/check-in/';
  static String teacherCheckOut(String id) =>
      '$baseUrl/teacher/attendance/$id/check-out/';
  static String get teacherClassAssignment =>
      '$baseUrl/teacher/class-assignment';
  static String get deleteTeacherClassAssignment =>
      '$baseUrl/teacher/class-assignment';
  static String get teacherSalarySlips => '$baseUrl/teacher/salary-slips';
  static String get students => '$baseUrl/students/list/';
  static String get markAttendance => '$baseUrl/attendance/mark/';
  static String get addStudents => '$baseUrl/student/create/';
  static String get studentAttendanceList => '$baseUrl/students/attendance/';
  static String teacherAttendance({String? school, String? date}) {
    final params = <String>[];
    if (school != null && school.isNotEmpty) params.add('school=$school');
    if (date != null && date.isNotEmpty) params.add('date=$date');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return '$baseUrl/teacher/attendance/$query';
  }

  static String get csvUpload => '$baseUrl/students/csv-upload/';
  //admin endpoints

  // Coordinator endpoints
  static String get getTeacherAttendance =>
      '$baseUrl/coordinator/teacher-attendance/';
  static String teacherAttendanceVerify(String attendanceId) =>
      '$baseUrl/coordinator/teacher-attendance/$attendanceId/';
  static String get coordinatorInvoices => '$baseUrl/coordinator/invoices/';
  static String get teacherNoteVerification =>
      '$baseUrl/coordinator/student-attendance/approve/';
  static String get getTeacherNotesVerification =>
      '$baseUrl/coordinator/teaching-notes/';
  static String get teacherNotes => '$baseUrl/coordinator/teaching-notes/';
  static String get teacherRating => '$baseUrl/coordinator/teacher-rating/';

  //student endpoints
  static String get schoolList => '$baseUrl/public/registration-metadata/';
  static String get homework => '$baseUrl/student/homework/';
  static String get studentAttendance => '$baseUrl/student/attendance/';
  //attendace endpoints
  static String get getAttendance => '$baseUrl/attendance/';
  static String postAttendanceApprove(String attendanceId) =>
      '$baseUrl/attendance/approve/$attendanceId/';
  static String get postAttendanceUpload => '$baseUrl/attendance/upload/';

  // notification endpoints
  static String fcmTokens = '$baseUrl/fcm-tokens/';
  static String notificationsList = '$baseUrl/notifications/';
  static String markNotificationAsRead(String notificationId) =>
      '$baseUrl/notifications/$notificationId/mark-read/';
  static String markAllNotificationsAsRead =
      '$baseUrl/notifications/mark-all-read/';

  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 60);
  static const Duration uploadTimeout = Duration(seconds: 120);
}




  // // same endpoints for the get post put and the delete
  // static String get createSchool => '$baseUrl/admin/schools/';
  // // same endpoints for the get post put and the delete
  // static String specificSchoolId(String schoolId) =>
  //     '$baseUrl/admin/schools/$schoolId';
  // static String get createCourse => '$baseUrl/admin/courses/';
  // static String courseApproval(String courseId) =>
  //     '$baseUrl/admin/courses/$courseId/';
  // static String get assignTeacher => '$baseUrl/admin/teacher-assignments/';
  // static String get getClassRoomList => '$baseUrl/admin/classrooms/';
  // static String get createClassRooms => '$baseUrl/admin/classrooms/';
  // static String get updateClassRooms => '$baseUrl/admim/classroooms/';
  // static String get deleteClassRooms => '$baseUrl/admin/classrooms/';
  // static String getSpecificClassRoomsById(String classroomId) =>
  //     '$baseUrl/admin/classrooms/$classroomId/';
  // static String updateSpecificClassRoomById(String classroomId) =>
  //     '$baseUrl/admin/classrooms/$classroomId/';
  // static String deleteSpecificClassRoomById(String classroomId) =>
  //     '$baseUrl/admin/classrooms/$classroomId/';

  // static String get teacherSchoolAssignment =>
  //     '$baseUrl/admin/teacher-school-assignment/';

  // // same endpoint for the get post and delete  the coordinator school assignment
  // static String get assignCoordinator =>
  //     '$baseUrl/admin/coordinator-school-assignment/';
  // // same endpoint for the get post and delete  the coordinator school assignment for the specific coordinator Id
  // static String assignCoordinatorById(String coordinatorId) =>
  //     '$baseUrl/admin/coordinator-school-assignment/$coordinatorId/';
  // static String get compensationRule =>
  //     '$baseUrl/admin/teacher-compensation-rules/';

  // // same end point for the get put and delete
  // static String get salarySlips => '$baseUrl/admin/salary-slips/';
  // static String salarySlipsById(String slipId) =>
  //     '$baseUrl/admin/salary-slips/$slipId/';
  // static String get salarySlipsGenerate =>
  //     '$baseUrl/admin/salary-slips/generate/';
  // static String get schoolList => '$baseUrl/admin/schools/';