import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/teacher_service.dart';
import 'package:innovator/KMS/core/constants/service/token_service.dart';
import 'package:innovator/KMS/model/teacher_model/student_attendance_model.dart';
import 'package:innovator/KMS/model/teacher_model/student_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_attendance_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_kyc_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_salary_slips.dart';

final teacherServiceProvider = Provider<TeacherService>(
  (_) => TeacherService(),
);

final teacherProfileProvider = FutureProvider<TeacherProfileModel>((ref) async {
  final token = await TokenService().getAccessToken();
  if (token == null || token.isEmpty)
    throw Exception('No token — not logged in');
  return ref.watch(teacherServiceProvider).teacherProfile();
});

final kycStatusProvider = FutureProvider<KycModel>((ref) async {
  final token = await TokenService().getAccessToken();
  if (token == null || token.isEmpty)
    throw Exception('No token — not logged in');
  return ref.watch(teacherServiceProvider).checkKycStatus();
});

final checkInProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, schoolId) =>
      ref.read(teacherServiceProvider).checkIn(schoolId: schoolId),
);
final checkOutProvider = FutureProvider.family<Map<String, dynamic>, dynamic>(
  (ref, id) => ref.read(teacherServiceProvider).checkOut(id: id),
);

final kycUploadProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
      (ref, params) => ref
          .read(teacherServiceProvider)
          .uploadKyc(
            idDoc: params['idDoc'] as File,
            bankAccountNumber: params['bankAccountNumber'] as String,
            bankName: params['bankName'] as String,
            citizenship: params['citizenship'] as String,
            photo: params['photo'] as File,
            cv: params['cv'] as File,
            nIdNumber: params['nIdNumber'] as String,
          ),
    );

final studentsProvider = FutureProvider<List<StudentModel>>((ref) {
  return ref.read(teacherServiceProvider).getStudents();
});


final markAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
      (ref, params) => ref
          .read(teacherServiceProvider)
          .markAttendance(
            studentId: params['student_id'] as String,
            classroomId: params['classroom_id'] as String,
            date: params['date'] as String,
            status: params['status'] as String,
            notes: params['notes'] as String,
            homework: params['homework'] as String,
            presentWithHomework: params['present_with_homework'] as bool,
          ),
    );
final createStudentProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>(
      (ref, params) => ref
          .read(teacherServiceProvider)
          .createStudent(
            name: params['name'] as String,
            schoolId: params['school'] as String,
            classroomId: params['classroom'] as String,
          ),
    );

final salarySlipsProvider = FutureProvider<SalarySlipResponse>((ref) {
  return ref.watch(teacherServiceProvider).getSalarySlips();
});
final studentAttendanceListProvider =
    FutureProvider<List<StudentAttendanceRecord>>((ref) async {
  return ref.read(teacherServiceProvider).getStudentAttendanceList();
});

final teacherAttendanceProvider = FutureProvider.family<
    List<TeacherAttendanceRecord>, ({String? school, String? date})>(
  (ref, filter) => ref.read(teacherServiceProvider).getTeacherAttendance(
        school: filter.school,
        date: filter.date,
      ),
);

final csvUploadProvider =
    FutureProvider.family<Map<String, dynamic>, File>((ref, file) {
  return ref.read(teacherServiceProvider).csvUpload(file: file);
});

 