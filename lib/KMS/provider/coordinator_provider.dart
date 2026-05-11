import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/coordinator_service.dart';
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_notes_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_rating_model.dart';

final coordinatorServiceProvider = Provider<CoordinatorService>(
  (_) => CoordinatorService(),
);

final coordinatorAttendanceProvider =
    FutureProvider<CoordinatorAttendanceResponse>((ref) {
      return ref.watch(coordinatorServiceProvider).getTeacherAttendances();
    });

final updateAttendanceProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String>>(
      (ref, data) => ref
          .read(coordinatorServiceProvider)
          .updateAttendance(
            attendanceId: data['attendanceId']!,
            action: data['action']!,
          ),
    );

final coordinatorInvoicesProvider =
    FutureProvider<List<CoordinatorInvoiceModel>>((ref) {
      return ref.watch(coordinatorServiceProvider).getInvoices();
    });

final teacherSessionsProvider = FutureProvider<TeacherSessionResponse>((ref) {
  return ref.watch(coordinatorServiceProvider).getTeacherSessions();
});

final verifySessionProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String?>>(
      (ref, data) => ref
          .read(coordinatorServiceProvider)
          .verifyTeacherSession(
            teacherId: data['teacherId']!,
            classroomId: data['classroomId']!,
            date: data['date']!,
            notes: data['notes']!,
            action: data['action']!,
            coordinatorNotes: data['coordinatorNotes'],
          ),
    );

final ratingProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, String?>>(
      (ref, data) => ref
          .read(coordinatorServiceProvider)
          .submitTeacherRating(
            teacherId: data['teacher']!,
            rating: double.parse(data['rating']!),
            feedback: data['review'],
          ),
    );

final getRatingProvider = FutureProvider<List<TeacherRatingModel>>(
  (ref) => ref.read(coordinatorServiceProvider).getTeacherRating(),
);
