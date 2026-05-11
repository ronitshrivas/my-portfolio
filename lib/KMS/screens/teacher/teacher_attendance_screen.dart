import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_attendance_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      TeacherAttendanceScreenState();
}

class TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  TeacherSchoolEarning? _selectedSchool;
  DateTime? _selectedDate;

  String? get _apiDate =>
      _selectedDate == null
          ? null
          : '${_selectedDate!.year}-'
              '${_selectedDate!.month.toString().padLeft(2, '0')}-'
              '${_selectedDate!.day.toString().padLeft(2, '0')}';
  String get _dateLabel =>
      _selectedDate == null
          ? 'Pick Date'
          : '${_selectedDate!.day} ${_kMonths[_selectedDate!.month - 1]} ${_selectedDate!.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder:
          (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.light(primary: AppStyle.primaryColor),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,

        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
          
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            color: Colors.white,
          ),
        ),
      ),
      body: profileAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: AppStyle.primaryColor),
            ),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (profile) {
          final schools = profile.earnings.schools;

          if (_selectedSchool != null &&
              !schools.any((s) => s.schoolId == _selectedSchool!.schoolId)) {
            _selectedSchool = null;
          }

          return Column(
            children: [
              FilterBar(
                schools: schools,
                selectedSchool: _selectedSchool,
                dateLabel: _dateLabel,
                hasDate: _selectedDate != null,
                hasSchool: _selectedSchool != null,
                onSchoolChanged: (s) => setState(() => _selectedSchool = s),
                onDateTap: _pickDate,
                onClearDate: () => setState(() => _selectedDate = null),
                onClearSchool: () => setState(() => _selectedSchool = null),
              ),
              Expanded(
                child: RecordsBody(
                  school: _selectedSchool?.schoolName,
                  date: _apiDate,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Filter Bar

class FilterBar extends StatelessWidget {
  final List<TeacherSchoolEarning> schools;
  final TeacherSchoolEarning? selectedSchool;
  final String dateLabel;
  final bool hasDate;
  final bool hasSchool;
  final ValueChanged<TeacherSchoolEarning?> onSchoolChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final VoidCallback onClearSchool;

  const FilterBar({
    required this.schools,
    required this.selectedSchool,
    required this.dateLabel,
    required this.hasDate,
    required this.hasSchool,
    required this.onSchoolChanged,
    required this.onDateTap,
    required this.onClearDate,
    required this.onClearSchool,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          // School dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color:
                    hasSchool
                        ? AppStyle.primaryColor.withValues(alpha: 0.07)
                        : AppStyle.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      hasSchool
                          ? AppStyle.primaryColor
                          : AppStyle.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 14,
                    color: AppStyle.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<TeacherSchoolEarning?>(
                        value: selectedSchool,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppStyle.primaryColor,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        hint: Text(
                          'All Schools',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          // "All Schools" resets filter
                          const DropdownMenuItem<TeacherSchoolEarning?>(
                            value: null,
                            child: Text(
                              'All Schools',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          ...schools.map(
                            (s) => DropdownMenuItem<TeacherSchoolEarning?>(
                              value: s,
                              child: Text(
                                s.schoolName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: onSchoolChanged,
                      ),
                    ),
                  ),
                  // clear school button
                  if (hasSchool)
                    GestureDetector(
                      onTap: onClearSchool,
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: AppStyle.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Date picker button
          GestureDetector(
            onTap: onDateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color:
                    hasDate
                        ? AppStyle.primaryColor.withValues(alpha: 0.07)
                        : AppStyle.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      hasDate
                          ? AppStyle.primaryColor
                          : AppStyle.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 14,
                    color: AppStyle.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: AppStyle.primaryColor,
                    ),
                  ),
                  if (hasDate) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onClearDate,
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: AppStyle.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

 

class RecordsBody extends ConsumerWidget {
  final String? school; 
  final String? date;  

  const RecordsBody({this.school, this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final filter = (school: school, date: date);
    final attendanceAsync = ref.watch(teacherAttendanceProvider(filter));

    return RefreshIndicator(
      color: AppStyle.primaryColor,
      onRefresh: () async => ref.invalidate(teacherAttendanceProvider(filter)),
      child: attendanceAsync.when(
        loading: () => buildSkeleton(),
        error: (e, _) => _ErrorState(message: e.toString()),
        data:
            (records) =>
                records.isEmpty
                    ? _EmptyState(hasFilters: school != null || date != null)
                    : buildList(records),
      ),
    );
  }

  Widget buildList(List<TeacherAttendanceRecord> records) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SummaryRow(records: records),
              const SizedBox(height: 16),
              Text(
                '${records.length} Record${records.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              ...records.map((r) => RecordCard(record: r)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (_) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

// Summary Row

class SummaryRow extends StatelessWidget {
  final List<TeacherAttendanceRecord> records;
  const SummaryRow({required this.records});

  @override
  Widget build(BuildContext context) {
    final pending = records.where((r) => r.isPending).length;
    final approved = records.where((r) => r.isApproved).length;
    final rejected = records.where((r) => r.isRejected).length;

    return Row(
      children: [
        SummaryChip(
          label: 'Pending',
          count: pending,
          color: const Color(0xffF8BD00),
          bg: const Color(0xFFFFF8E1),
          icon: Icons.hourglass_top_rounded,
        ),
        const SizedBox(width: 10),
        SummaryChip(
          label: 'Approved',
          count: approved,
          color: AppStyle.primaryColor,
          bg: AppStyle.backgroundColor,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 10),
        SummaryChip(
          label: 'Rejected',
          count: rejected,
          color: Colors.red.shade400,
          bg: Colors.red.shade50,
          icon: Icons.cancel_rounded,
        ),
      ],
    );
  }
}

class SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color, bg;
  final IconData icon;

  const SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: color.withValues(alpha: 0.8),
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

// Record Card

class RecordCard extends StatelessWidget {
  final TeacherAttendanceRecord record;
  const RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final sc = _statusConfig(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: sc.color.withValues(alpha: 0.2), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppStyle.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: AppStyle.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.schoolName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.teacherName,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sc.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sc.icon, color: sc.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        record.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: sc.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, thickness: 1, color: Color(0xffF0F0F0)),
            const SizedBox(height: 14),

            // Times
            Row(
              children: [
                Expanded(
                  child: _TimeBlock(
                    icon: Icons.login_rounded,
                    label: 'Check In',
                    time: _fmt(record.checkIn),
                    color: AppStyle.primaryColor,
                  ),
                ),
                _vDivider,
                Expanded(
                  child: _TimeBlock(
                    icon: Icons.logout_rounded,
                    label: 'Check Out',
                    time:
                        record.checkOut != null ? _fmt(record.checkOut!) : '—',
                    color:
                        record.checkOut != null
                            ? Colors.red.shade400
                            : Colors.grey.shade400,
                  ),
                ),
                if (record.totalHours != null) ...[
                  _vDivider,
                  Expanded(
                    child: _TimeBlock(
                      icon: Icons.timer_rounded,
                      label: 'Total',
                      time: '${record.totalHours!.toStringAsFixed(1)}h',
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ],
            ),

            // Supervised by
            if (record.supervisedBy != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 13,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Supervised by ${record.supervisedBy}'.split(' (').first ,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget get _vDivider =>
      Container(height: 36, width: 1, color: const Color(0xffF0F0F0));

  String _fmt(DateTime dt) {
    final l = dt.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:'
        '${l.minute.toString().padLeft(2, '0')}';
  }

  ({Color color, Color bg, IconData icon}) _statusConfig(String status) =>
      switch (status) {
        'APPROVED' => (
          color: AppStyle.primaryColor,
          bg: AppStyle.backgroundColor,
          icon: Icons.check_circle_rounded,
        ),
        'REJECTED' => (
          color: Colors.red.shade400,
          bg: Colors.red.shade50,
          icon: Icons.cancel_rounded,
        ),
        _ => (
          // PENDING + anything else
          color: const Color(0xffF8BD00),
          bg: const Color(0xFFFFF8E1),
          icon: Icons.hourglass_top_rounded,
        ),
      };
}

class _TimeBlock extends StatelessWidget {
  final IconData icon;
  final String label, time;
  final Color color;

  const _TimeBlock({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Inter',
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// Empty & Error states

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No attendance records',
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? 'Try changing the school or date filter'
                : 'No records found',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load records',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Inter',
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Constants

const _kMonths = [
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
];
