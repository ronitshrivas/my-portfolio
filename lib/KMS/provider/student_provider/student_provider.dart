import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/model/student_model/homework_model.dart';
import 'package:innovator/KMS/model/student_model/student_attendance_model.dart';
import 'package:innovator/KMS/provider/student_provider/school_provider.dart';

final studentAttendanceProvider = FutureProvider<List<StudentAttendanceModel>>((
  ref,
) async {
  return ref.read(schoolServiceProvider).fetchAttendance();
});

final homeworkProvider = FutureProvider<List<HomeworkModel>>((ref) async {
  return ref.read(schoolServiceProvider).fetchHomework();
});
