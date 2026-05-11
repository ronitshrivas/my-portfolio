import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/model/student_model/homework_model.dart';
import 'package:innovator/KMS/model/student_model/school_list_model.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/model/student_model/student_attendance_model.dart';

class StudentService extends BaseApiService {
  StudentService() : super(dio: DioClient.authInstance);

  Future<SchoolListResponse> fetchSchoolList() async {
    final response = await get<Map<String, dynamic>>(ApiConstants.schoolList);
    return SchoolListResponse.fromJson(response);
  }

  Future<List<StudentAttendanceModel>> fetchAttendance() async {
    final response = await get<List<dynamic>>(ApiConstants.studentAttendance);
    return response
        .map((e) => StudentAttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<HomeworkModel>> fetchHomework() async {
    final response = await get<List<dynamic>>(ApiConstants.homework);
    return response
        .map((e) => HomeworkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
