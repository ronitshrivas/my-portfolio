import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/student_model/homework_model.dart';
import 'package:innovator/KMS/provider/student_provider/student_provider.dart';

//Filter Enums
enum StatusFilter { all, withHW, present, absent }

enum DateFilter { all, today, thisWeek, thisMonth, custom }

//Main Screen

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  StatusFilter _statusFilter = StatusFilter.all;
  DateFilter _dateFilter = DateFilter.all;
  DateTimeRange? _customRange;
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    ref.invalidate(homeworkProvider);
    try {
      await ref.read(homeworkProvider.future);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(homeworkProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Homework',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          (_isRefreshing || homeworkAsync is AsyncLoading)
              ? const _SkeletonLoading()
              : homeworkAsync.when(
                loading: () => const _SkeletonLoading(),
                error:
                    (err, _) => _ErrorView(
                      message: 'Failed to load homework.',
                      onRetry: () => ref.invalidate(homeworkProvider),
                    ),
                data: (list) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppStyle.primaryColor,
                    child: Column(
                      children: [
                        _FilterBar(
                          statusFilter: _statusFilter,
                          dateFilter: _dateFilter,
                          customRange: _customRange,
                          onStatusChanged:
                              (f) => setState(() => _statusFilter = f),
                          onDateFilterChanged:
                              (d, range) => setState(() {
                                _dateFilter = d;
                                _customRange = range;
                              }),
                        ),
                        Expanded(
                          child: _HomeworkList(
                            list: list,
                            statusFilter: _statusFilter,
                            dateFilter: _dateFilter,
                            customRange: _customRange,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

//Filter Bar
class _FilterBar extends StatelessWidget {
  final StatusFilter statusFilter;
  final DateFilter dateFilter;
  final DateTimeRange? customRange;
  final ValueChanged<StatusFilter> onStatusChanged;
  final void Function(DateFilter, DateTimeRange?) onDateFilterChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.dateFilter,
    required this.customRange,
    required this.onStatusChanged,
    required this.onDateFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(StatusFilter.all, 'All'),
                const SizedBox(width: 8),
                _buildStatusChip(StatusFilter.withHW, 'With HW'),
                const SizedBox(width: 8),
                _buildStatusChip(StatusFilter.present, 'Present'),
                const SizedBox(width: 8),
                _buildStatusChip(StatusFilter.absent, 'Absent'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date filter
          _DateFilterRow(
            dateFilter: dateFilter,
            customRange: customRange,
            onChanged: onDateFilterChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(StatusFilter filter, String label) {
    final isSelected = statusFilter == filter;
    final color = _filterColor(filter);
    return GestureDetector(
      onTap: () => onStatusChanged(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(38) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Color _filterColor(StatusFilter filter) {
    switch (filter) {
      case StatusFilter.all:
        return AppStyle.primaryColor;
      case StatusFilter.withHW:
        return Colors.blue;
      case StatusFilter.present:
        return Colors.green;
      case StatusFilter.absent:
        return Colors.red;
    }
  }
}

//Date Filter Row

class _DateFilterRow extends StatefulWidget {
  final DateFilter dateFilter;
  final DateTimeRange? customRange;
  final void Function(DateFilter, DateTimeRange?) onChanged;

  const _DateFilterRow({
    required this.dateFilter,
    required this.customRange,
    required this.onChanged,
  });

  @override
  State<_DateFilterRow> createState() => _DateFilterRowState();
}

class _DateFilterRowState extends State<_DateFilterRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          widget.customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppStyle.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppStyle.primaryColor,
              ),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _controller.text = '${_fmt(picked.start)} – ${_fmt(picked.end)}';
      widget.onChanged(DateFilter.custom, picked);
    }
  }

  DateTime? _parseDate(String s) {
    final parts = s.trim().split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(s.trim());
  }

  void _onTextSubmit(String value) {
    final parts = value.split('–').map((e) => e.trim()).toList();
    if (parts.length == 2) {
      final start = _parseDate(parts[0]);
      final end = _parseDate(parts[1]);
      if (start != null && end != null) {
        widget.onChanged(
          DateFilter.custom,
          DateTimeRange(start: start, end: end),
        );
        return;
      }
    } else if (parts.length == 1 && parts[0].isNotEmpty) {
      final d = _parseDate(parts[0]);
      if (d != null) {
        widget.onChanged(DateFilter.custom, DateTimeRange(start: d, end: d));
        return;
      }
    }
    _controller.clear();
    widget.onChanged(DateFilter.all, null);
  }

  void _selectQuick(DateFilter f) {
    _controller.clear();
    widget.onChanged(f, null);
  }

  @override
  Widget build(BuildContext context) {
    final isCustom = widget.dateFilter == DateFilter.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _quickChip(DateFilter.all, 'All Time'),
              const SizedBox(width: 8),
              _quickChip(DateFilter.today, 'Today'),
              const SizedBox(width: 8),
              _quickChip(DateFilter.thisWeek, 'This Week'),
              const SizedBox(width: 8),
              _quickChip(DateFilter.thisMonth, 'This Month'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Text input + calendar button row
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _controller,
                  onSubmitted: _onTextSubmit,
                  onChanged: (v) {
                    if (v.isEmpty) widget.onChanged(DateFilter.all, null);
                  },
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'dd/mm/yyyy  –  dd/mm/yyyy',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_calendar_outlined,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 10,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppStyle.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d/\-–\s]')),
                    LengthLimitingTextInputFormatter(23),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Calendar picker button
            GestureDetector(
              onTap: _pickDateRange,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isCustom ? AppStyle.primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        isCustom ? AppStyle.primaryColor : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: isCustom ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            // Clear button — only when custom active
            if (isCustom) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  _controller.clear();
                  widget.onChanged(DateFilter.all, null);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFFE57373),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _quickChip(DateFilter filter, String label) {
    final isSelected = widget.dateFilter == filter;
    return GestureDetector(
      onTap: () => _selectQuick(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppStyle.primaryColor.withAlpha(30)
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppStyle.primaryColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppStyle.primaryColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

//Homework List

class _HomeworkList extends StatelessWidget {
  final List<HomeworkModel> list;
  final StatusFilter statusFilter;
  final DateFilter dateFilter;
  final DateTimeRange? customRange;

  const _HomeworkList({
    required this.list,
    required this.statusFilter,
    required this.dateFilter,
    required this.customRange,
  });

  List<HomeworkModel> get _filtered {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<HomeworkModel> result =
        list.where((hw) {
          DateTime? d;
          try {
            d = DateTime.parse(hw.date);
          } catch (_) {
            return true;
          }
          final date = DateTime(d.year, d.month, d.day);
          switch (dateFilter) {
            case DateFilter.all:
              return true;
            case DateFilter.today:
              return date == today;
            case DateFilter.thisWeek:
              final weekStart = today.subtract(
                Duration(days: today.weekday - 1),
              );
              final weekEnd = weekStart.add(const Duration(days: 6));
              return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
            case DateFilter.thisMonth:
              return d.year == now.year && d.month == now.month;
            case DateFilter.custom:
              if (customRange == null) return true;
              final start = DateTime(
                customRange!.start.year,
                customRange!.start.month,
                customRange!.start.day,
              );
              final end = DateTime(
                customRange!.end.year,
                customRange!.end.month,
                customRange!.end.day,
              );
              return !date.isBefore(start) && !date.isAfter(end);
          }
        }).toList();

    if (statusFilter == StatusFilter.all) return result;
    final statusKey = switch (statusFilter) {
      StatusFilter.withHW => 'present_with_homework',
      StatusFilter.present => 'present',
      StatusFilter.absent => 'absent',
      StatusFilter.all => '',
    };
    return result.where((hw) => hw.status == statusKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const _EmptyView(message: 'No homework found.');
    }
    final grouped = _groupByMonth(filtered);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final entry = grouped[index];
        return _SectionGroup(label: entry.label, items: entry.items);
      },
    );
  }

  List<_Group> _groupByMonth(List<HomeworkModel> items) {
    final map = <String, List<HomeworkModel>>{};
    for (final hw in items) {
      final key = _monthKey(hw.date);
      map.putIfAbsent(key, () => []).add(hw);
    }
    return map.entries
        .map((e) => _Group(label: e.key, items: e.value))
        .toList();
  }

  String _monthKey(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return 'Unknown';
    }
  }
}

class _Group {
  final String label;
  final List<HomeworkModel> items;
  _Group({required this.label, required this.items});
}

//Section Group

class _SectionGroup extends StatelessWidget {
  final String label;
  final List<HomeworkModel> items;

  const _SectionGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((hw) => _HomeworkCard(homework: hw)),
        const SizedBox(height: 8),
      ],
    );
  }
}

//Homework Card

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel homework;

  const _HomeworkCard({required this.homework});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(homework.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: statusColor, width: 4)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFF9800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(homework.date),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        homework.classroomName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: homework.status, color: statusColor),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Assignment',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  homework.homework,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'By ${homework.teacherName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const months = [
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
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present_with_homework':
        return Colors.blue;
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

//Status Badge
class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  String get _label {
    switch (status) {
      case 'present_with_homework':
        return 'With HW';
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

//Skeleton Loading
class _SkeletonLoading extends StatefulWidget {
  const _SkeletonLoading();

  @override
  State<_SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<_SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _skeletonLabel(),
            _skeletonCard(),
            _skeletonCard(),
            const SizedBox(height: 8),
            _skeletonLabel(),
            _skeletonCard(),
            _skeletonCard(),
            _skeletonCard(),
          ],
        );
      },
    );
  }

  Widget _skeletonLabel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: _shimmerBox(width: 100, height: 13, radius: 6),
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFE0E0E0), width: 4),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                _shimmerBox(width: 38, height: 38, radius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(width: 120, height: 14, radius: 6),
                      const SizedBox(height: 6),
                      _shimmerBox(width: 70, height: 11, radius: 5),
                    ],
                  ),
                ),
                _shimmerBox(width: 60, height: 24, radius: 20),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 80, height: 11, radius: 5),
                const SizedBox(height: 8),
                _shimmerBox(width: double.infinity, height: 13, radius: 6),
                const SizedBox(height: 5),
                _shimmerBox(width: 200, height: 13, radius: 6),
                const SizedBox(height: 12),
                _shimmerBox(width: 110, height: 11, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Opacity(
      opacity: _animation.value,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

//Error View
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

//Empty View
class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
