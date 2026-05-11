import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/core/constants/network/dio_client.dart';
import 'package:innovator/KMS/model/teacher_model/student_attendance_model.dart';
import 'package:innovator/KMS/model/teacher_model/student_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_attendance_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_kyc_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_salary_slips.dart';

class TeacherService extends BaseApiService {
  TeacherService() : super(dio: DioClient.instance);

  Future<TeacherProfileModel> teacherProfile() async {
    final data = await get<Map<String, dynamic>>(ApiConstants.teacherProfile);
    final profile = TeacherProfileModel.fromJson(data);
    log(
      'Teacher: ${profile.name} | schools: ${profile.earnings.schools.length} | total earnings: ${profile.earnings.totalEarnings}',
    );
    return profile;
  }

  Future<Map<String, dynamic>> checkIn({required String schoolId}) async {
    final result = await post<Map<String, dynamic>>(
      ApiConstants.teacherCheckIn,
      data: {'school': schoolId, 'check_in': DateTime.now().toIso8601String()},
    );
    log('Check-in id: ${result['id'] ?? result['_id'] ?? 'N/A'}');
    return result;
  }

  Future<Map<String, dynamic>> checkOut({required dynamic id}) async {
    final result = await post<Map<String, dynamic>>(
      ApiConstants.teacherCheckOut(id),
      data: {'check_out': DateTime.now().toIso8601String()},
    );
    log('Check-out: $result');
    return result;
  }

  Future<Map<String, dynamic>> uploadKyc({
    required File idDoc,
    required String bankAccountNumber,
    required String bankName,
    required String citizenship,
    required File photo,
    required File cv,
    required String nIdNumber,
  }) async {
    final formData = FormData.fromMap({
      'id_doc': await MultipartFile.fromFile(
        idDoc.path,
        filename: idDoc.path.split('/').last,
      ),
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'citizenship': citizenship,
      'photo': await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      ),
      'cv': await MultipartFile.fromFile(
        cv.path,
        filename: cv.path.split('/').last,
      ),
      'n_id_number': nIdNumber,
    });
    final result = await post<Map<String, dynamic>>(
      ApiConstants.teacherKyc,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    log('Kyc upload: $result');
    return result;
  }

  Future<KycModel> checkKycStatus() async {
    final data = await get<Map<String, dynamic>>(ApiConstants.teacherKyc);
    final kyc = KycModel.fromJson(data);
    log('Kyc status: ${kyc.status}');
    return kyc;
  }

  Future<List<StudentModel>> getStudents() async {
    final data = await get<List<dynamic>>(ApiConstants.students);
    final students =
        data
            .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
            .toList();
    log('Students: ${students.length}');
    return students;
  }

  // Future<Map<String, dynamic>> markAttendance({
  //   required String studentId,
  //   required String classroomId,
  //   required String date,
  //   required String status,
  //   required String notes,
  // }) async {
  //   final result = await post<Map<String, dynamic>>(
  //     ApiConstants.markAttendance,
  //     data: {
  //       'student_id': studentId,
  //       'classroom_id': classroomId,
  //       'date': date,
  //       'status': status,
  //       'notes': notes,
  //     },
  //   );
  //   log('Attendance: $result');
  //   return result;
  // }
  Future<Map<String, dynamic>> markAttendance({
    required String studentId,
    required String classroomId,
    required String date,
    required String status,
    required String notes,
    required String homework,
    required bool presentWithHomework,
  }) async {
    final result = await post<Map<String, dynamic>>(
      ApiConstants.markAttendance,
      data: {
        'student_id': studentId,
        'classroom_id': classroomId,
        'date': date,
        'status': status,
        'notes': notes,
        'homework': homework,
        'present_with_homework': presentWithHomework,
      },
    );
    log('Attendance: $result');
    return result;
  }

  Future<Map<String, dynamic>> createStudent({
    required String name,
    required String schoolId,
    required String classroomId,
  }) async {
    final result = await post<Map<String, dynamic>>(
      ApiConstants.addStudents,
      data: {'name': name, 'school': schoolId, 'classroom': classroomId},
    );
    log('Student created: $result');
    return result;
  }

  Future<SalarySlipResponse> getSalarySlips() async {
    final data = await get<Map<String, dynamic>>(
      ApiConstants.teacherSalarySlips,
    );
    final response = SalarySlipResponse.fromJson(data);
    log('Salary slips: ${response.total} total');
    return response;
  }

  Future<List<StudentAttendanceRecord>> getStudentAttendanceList() async {
    final data = await get<List<dynamic>>(ApiConstants.studentAttendanceList);
    final list =
        data
            .map(
              (e) =>
                  StudentAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    log('Attendance records: ${list.length}');
    return list;
  }

  Future<List<TeacherAttendanceRecord>> getTeacherAttendance({
    String? school,
    String? date,
  }) async {
    final data = await get<List<dynamic>>(
      ApiConstants.teacherAttendance(school: school, date: date),
    );
    final list =
        data
            .map(
              (e) =>
                  TeacherAttendanceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList();
    log('Teacher attendance: ${list.length} records');
    return list;
  }

  Future<Map<String, dynamic>> csvUpload({required File file}) async {
    final filename = file.path.split('/').last;
    final ext = filename.split('.').last.toLowerCase();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: filename,
        contentType:
            ext == 'csv'
                ? DioMediaType('text', 'csv')
                : DioMediaType(
                  'application',
                  'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                ),
      ),
    });

    final result = await post<Map<String, dynamic>>(
      ApiConstants.csvUpload,
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );
    log('CSV upload: $result');
    return result;
  }
}
