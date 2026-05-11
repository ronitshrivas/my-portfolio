import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/student_api_calling_service.dart';
import 'package:innovator/KMS/model/student_model/school_list_model.dart';

final schoolServiceProvider = Provider<StudentService>((ref) => StudentService());

final schoolListProvider = FutureProvider<SchoolListResponse>((ref) async {
  return ref.read(schoolServiceProvider).fetchSchoolList();
});

final filteredClassroomsProvider =
    Provider.family<List<ClassroomModel>, String>((ref, schoolId) {
      final asyncValue = ref.watch(schoolListProvider);
      return asyncValue.maybeWhen(
        data:
            (data) =>
                data.classrooms.where((c) => c.schoolId == schoolId).toList(),
        orElse: () => [],
      );
    });
