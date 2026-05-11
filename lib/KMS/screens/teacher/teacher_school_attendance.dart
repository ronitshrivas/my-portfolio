import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/student_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

// Screen 1: School List

class TeacherSchoolAttendanceScreen extends ConsumerWidget {
  const TeacherSchoolAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select School',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Text(
                        'Error loading schools: $e',
                        style: const TextStyle(fontFamily: 'Inter'),
                      ),
                    ),
                data: (profile) {
                  final schools = profile.earnings.schools;
                  if (schools.isEmpty) {
                    return const Center(
                      child: Text(
                        'No schools assigned yet.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: schools.length,
                    itemBuilder: (context, i) => SchoolCard(school: schools[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SchoolCard extends StatelessWidget {
  final TeacherSchoolEarning school;
  const SchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (school.classrooms.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No classrooms assigned for this school.'),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassSelectionScreen(school: school),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: AppStyle.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.schoolName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (school.classrooms.isEmpty)
                      Text(
                        'No classrooms assigned',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontFamily: 'Inter',
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            school.classrooms
                                .map(
                                  (c) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppStyle.backgroundColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppStyle.primaryColor,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen 2: Classroom Selection

class ClassSelectionScreen extends ConsumerWidget {
  final TeacherSchoolEarning school;
  const ClassSelectionScreen({super.key, required this.school});

  String _monthName(int m) =>
      [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dateStr = '${today.day} ${_monthName(today.month)} ${today.year}';

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              school.schoolName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Select Classroom',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: school.classrooms.length,
                itemBuilder: (context, i) {
                  final classroom = school.classrooms[i];
                  return GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AttendanceMarkingScreen(
                                  schoolName: school.schoolName,
                                  schoolId: school.schoolId,
                                  classroom: classroom,
                                ),
                          ),
                        ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.class_rounded,
                              color: AppStyle.primaryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              classroom.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamily: 'Inter',
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap:
                                () => addStudentSheet(
                                  context,
                                  ref,
                                  schoolId: school.schoolId,
                                  classroomId: classroom.id,
                                  classroomName: classroom.name,
                                ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppStyle.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_add_rounded,
                                    size: 12,
                                    color: AppStyle.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Add Student',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      color: AppStyle.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void addStudentSheet(
    BuildContext context,
    WidgetRef ref, {
    required String schoolId,
    required String classroomId,
    required String classroomName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AddStudentSheet(
            schoolId: schoolId,
            classroomId: classroomId,
            classroomName: classroomName,
            onAdded: () => ref.refresh(studentsProvider),
          ),
    );
  }
}

// Screen 3: Attendance Marking

class AttendanceMarkingScreen extends ConsumerStatefulWidget {
  final String schoolName;
  final String schoolId;
  final TeacherClassroom classroom;

  const AttendanceMarkingScreen({
    super.key,
    required this.schoolName,
    required this.schoolId,
    required this.classroom,
  });

  @override
  ConsumerState<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState
    extends ConsumerState<AttendanceMarkingScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _homeworkController = TextEditingController();

  final Map<String, String> _statusMap = {};

  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _notesController.dispose();
    _homeworkController.dispose();
    super.dispose();
  }

  Future<void> _submitAttendance(List<StudentModel> students) async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please add a comment about what you taught today.',
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final futures = students.map((student) {
        final status = _statusMap[student.id] ?? 'absent';
        final isPresentWithHomework = status == 'present_with_homework';

        return ref.read(
          markAttendanceProvider({
            'student_id': student.id,
            'classroom_id': widget.classroom.id,
            'date': dateStr,
            'status': status,
            'notes': _notesController.text.trim(),
            'homework':
                isPresentWithHomework ? _homeworkController.text.trim() : '',
            'present_with_homework': isPresentWithHomework,
          }).future,
        );
      });

      await Future.wait(futures);

      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Attendance submitted successfully!'),
              ],
            ),
            backgroundColor: AppStyle.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsProvider);

    return Scaffold(
      backgroundColor: AppStyle.primaryColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.classroom.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
            Text(
              widget.schoolName,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => addStudentSheet(context),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: 'Add Student',
          ),
        ],
      ),
      body: studentsAsync.when(
        loading:
            () => whiteBody(
              child: const Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => whiteBody(
              child: Center(
                child: Text(
                  'Error loading students: $e',
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
              ),
            ),
        data: (allStudents) {
          final students =
              allStudents
                  .where((s) => s.classroomName == widget.classroom.name)
                  .toList();

          for (final s in students) {
            _statusMap.putIfAbsent(s.id, () => 'absent');
          }

          final presentCount =
              _statusMap.values
                  .where((v) => v == 'present' || v == 'present_with_homework')
                  .length;
          final absentCount = students.length - presentCount;
          final pwCount =
              _statusMap.values
                  .where((v) => v == 'present_with_homework')
                  .length;

          return whiteBody(
            child: Column(
              children: [
                // Stats Bar
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      statItem('Total', '${students.length}', Colors.black87),
                      statItem(
                        'Present',
                        '$presentCount',
                        Colors.green.shade600,
                      ),
                      statItem('Absent', '$absentCount', Colors.red.shade400),
                      statItem('With HW', '$pwCount', Colors.orange.shade600),
                    ],
                  ),
                ),

                // Student List
                Expanded(
                  child:
                      students.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No students yet',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => addStudentSheet(context),
                                  icon: Icon(
                                    Icons.person_add_rounded,
                                    color: AppStyle.primaryColor,
                                    size: 16,
                                  ),
                                  label: Text(
                                    'Add First Student',
                                    style: TextStyle(
                                      color: AppStyle.primaryColor,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final student = students[i];
                              final status = _statusMap[student.id] ?? 'absent';
                              return _StudentAttendanceTile(
                                student: student,
                                status: status,
                                onStatusChanged:
                                    (newStatus) => setState(
                                      () => _statusMap[student.id] = newStatus,
                                    ),
                              );
                            },
                          ),
                ),

                // Notes + Homework + Submit
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notes
                      const Text(
                        'What did you teach today?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g., Chapter 3: Photosynthesis, Practice problems 1–10...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Homework
                      const Text(
                        'Homework assigned',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _homeworkController,
                        maxLines: 2,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g., Chapter 1 complete all exercises...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontFamily: 'Inter',
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyle.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              _isSubmitting || _submitted
                                  ? null
                                  : () => _submitAttendance(students),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _submitted
                                        ? 'Submitted ✓'
                                        : 'Submit Attendance',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget whiteBody({required Widget child}) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFFF5F7FA),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    child: child,
  );

  Widget statItem(String label, String value, Color color) => Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade500,
          fontFamily: 'Inter',
        ),
      ),
    ],
  );

  void addStudentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AddStudentSheet(
            schoolId: widget.schoolId,
            classroomId: widget.classroom.id,
            classroomName: widget.classroom.name,
            onAdded: () => ref.refresh(studentsProvider),
          ),
    );
  }
}

// Student Attendance Tile

class _StudentAttendanceTile extends StatelessWidget {
  final StudentModel student;

  final String status;
  final ValueChanged<String> onStatusChanged;

  const _StudentAttendanceTile({
    required this.student,
    required this.status,
    required this.onStatusChanged,
  });

  bool get _isPresent =>
      status == 'present' || status == 'present_with_homework';
  bool get _isPresentWithHomework => status == 'present_with_homework';

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    if (_isPresentWithHomework) {
      borderColor = Colors.orange.withValues(alpha: 0.4);
    } else if (_isPresent) {
      borderColor = Colors.green.withValues(alpha: 0.3);
    } else {
      borderColor = Colors.red.withValues(alpha: 0.15);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  _isPresentWithHomework
                      ? Colors.orange.withValues(alpha: 0.12)
                      : _isPresent
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.shade100,
              child: Text(
                student.name[0],
                style: TextStyle(
                  color:
                      _isPresentWithHomework
                          ? Colors.orange.shade700
                          : _isPresent
                          ? Colors.green.shade700
                          : Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    student.classroomName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),

            // P / A / PW chips
            Row(
              children: [
                _AttendanceChip(
                  label: 'P',
                  isSelected: status == 'present',
                  color: Colors.green,
                  onTap: () => onStatusChanged('present'),
                ),
                const SizedBox(width: 6),
                _AttendanceChip(
                  label: 'A',
                  isSelected: status == 'absent',
                  color: Colors.red,
                  onTap: () => onStatusChanged('absent'),
                ),
                const SizedBox(width: 6),
                _AttendanceChip(
                  label: 'PW',
                  isSelected: _isPresentWithHomework,
                  color: Colors.orange,
                  onTap:
                      () => onStatusChanged(
                        _isPresentWithHomework
                            ? 'present'
                            : 'present_with_homework',
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Attendance Chip

class _AttendanceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: label == 'PW' ? 44 : 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              fontSize: label == 'PW' ? 11 : 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

// Add Student Sheet

class _AddStudentSheet extends ConsumerStatefulWidget {
  final String schoolId;
  final String classroomId;
  final String classroomName;
  final VoidCallback onAdded;

  const _AddStudentSheet({
    required this.schoolId,
    required this.classroomId,
    required this.classroomName,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a student name.'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(
        createStudentProvider({
          'name': name,
          'school': widget.schoolId,
          'classroom': widget.classroomId,
        }).future,
      );
      widget.onAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('$name added successfully!'),
              ],
            ),
            backgroundColor: AppStyle.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add student: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Add New Student',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adding to: ${widget.classroomName}',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Student Name',
                labelStyle: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.grey.shade500,
                ),
                hintText: 'e.g., Aarav Sharma',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                  fontFamily: 'Inter',
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppStyle.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyle.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submit,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'Add Student',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            fontFamily: 'Inter',
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
