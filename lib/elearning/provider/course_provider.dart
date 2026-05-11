import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/elearning/api_calling_service/course_list_service.dart';
import 'package:innovator/elearning/model/course_list_model.dart';

final courseServiceProvider = Provider<CourseListService>(
  (ref) => CourseListService(),
);

final courseListProvider = FutureProvider<List<CourseListModel>>((ref) {
  return ref.read(courseServiceProvider).getCourseList();
});

final enrollmentProvider = FutureProvider<void>((ref) async {
  final enrollments = await ref.watch(courseServiceProvider).getMyEnrollments();

  final enrolledIds =
      enrollments.where((e) => e.isEnrolled).map((e) => e.course).toSet();

  ref.read(enrolledCoursesProvider.notifier).courseid(enrolledIds);
});

class EnrolledCoursesNotifier extends StateNotifier<Set<String>> {
  EnrolledCoursesNotifier() : super(const {});

  void courseid(Set<String> ids) {
    state = ids;
  }

  void enroll(String courseId) {
    if (state.contains(courseId)) return;
    state = {...state, courseId};
  }

  bool isEnrolled(String courseId) => state.contains(courseId);
}

final enrolledCoursesProvider =
    StateNotifierProvider<EnrolledCoursesNotifier, Set<String>>(
      (_) => EnrolledCoursesNotifier(),
    );

class EnrollLoadingNotifier extends StateNotifier<bool> {
  EnrollLoadingNotifier() : super(false);
  void setLoading(bool v) => state = v;
}

final enrollLoadingProvider =
    StateNotifierProvider.family<EnrollLoadingNotifier, bool, String>(
      (_, __) => EnrollLoadingNotifier(),
    );
