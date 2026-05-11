import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_notes_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_rating_model.dart'
    show TeacherRatingModel;

class CoordinatorService extends BaseApiService {
  CoordinatorService() : super(dio: DioClient.instance);

  Future<CoordinatorAttendanceResponse> getTeacherAttendances() async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.getTeacherAttendance,
    );
    return CoordinatorAttendanceResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> updateAttendance({
    required String attendanceId,
    required String action,
  }) async {
    return await put<Map<String, dynamic>>(
      ApiConstants.teacherAttendanceVerify(attendanceId),
      data: {'action': action},
    );
  }

  Future<List<CoordinatorInvoiceModel>> getInvoices() async {
    final data = await get<List<dynamic>>(ApiConstants.coordinatorInvoices);
    return data
        .map((e) => CoordinatorInvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherSessionResponse> getTeacherSessions() async {
    final data = await get<Map<String, dynamic>>(ApiConstants.teacherNotes);
    return TeacherSessionResponse.fromJson(data);
  }

  Future<Map<String, dynamic>> verifyTeacherSession({
    required String teacherId,
    required String classroomId,
    required String date,
    required String notes,
    required String action,
    String? coordinatorNotes,
  }) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.getTeacherNotesVerification,
      data: {
        'teacher_id': teacherId,
        'classroom_id': classroomId,
        'date': date,
        'notes': notes,
        'action': action,
        if (coordinatorNotes != null && coordinatorNotes.isNotEmpty)
          'coordinator_notes': coordinatorNotes,
      },
    );
  }

  Future<Map<String, dynamic>> submitTeacherRating({
    required String teacherId,
    required double rating,
    String? feedback,
  }) async {
    return await post<Map<String, dynamic>>(
      ApiConstants.teacherRating,
      data: {
        'teacher': teacherId,
        'rating': rating,
        if (feedback != null && feedback.isNotEmpty) 'review': feedback,
      },
    );
  }

  Future<List<TeacherRatingModel>> getTeacherRating() async {
    final response = await get<List<dynamic>>(ApiConstants.teacherRating);
    return response
        .map((e) => TeacherRatingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
