import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_salary_slips.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/screens/teacher/teacher_invoice_screen.dart';
import 'package:innovator/KMS/screens/teacher/teacher_salary_slips.dart';

class TeacherSalaryScreen extends ConsumerStatefulWidget {
  const TeacherSalaryScreen({super.key});

  @override
  ConsumerState<TeacherSalaryScreen> createState() =>
      _TeacherSalaryScreenState();
}

class _TeacherSalaryScreenState extends ConsumerState<TeacherSalaryScreen> {
  int? _selectedMonth;
  String? _selectedSchoolId;

  static const _months = [
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

  List<SalarySlipModel> _filtered(List<SalarySlipModel> slips) {
    var result = [...slips]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedMonth != null) {
      result = result.where((s) => s.month == _selectedMonth).toList();
    }
    if (_selectedSchoolId != null) {
      result = result.where((s) => s.school == _selectedSchoolId).toList();
    }
    return result;
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Filter by Month',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _monthTile('All Months', null),
                        const Divider(height: 1),
                        ...List.generate(
                          12,
                          (i) => _monthTile(_months[i], i + 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _monthTile(String label, int? month) {
    final isSelected = _selectedMonth == month;
    return ListTile(
      dense: true,
      onTap: () {
        setState(() => _selectedMonth = month);
        Navigator.pop(context);
      },
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? AppStyle.primaryColor : Colors.black87,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_rounded, color: AppStyle.primaryColor)
              : null,
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final slipsAsync = ref.watch(salarySlipsProvider);
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
          'Salary Slips',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
        actions: [
          // Month filter
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      _selectedMonth != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 13,
                      color:
                          _selectedMonth != null
                              ? AppStyle.primaryColor
                              : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedMonth != null
                          ? _months[_selectedMonth! - 1].substring(0, 3)
                          : 'Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color:
                            _selectedMonth != null
                                ? AppStyle.primaryColor
                                : Colors.white,
                      ),
                    ),
                    if (_selectedMonth != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedMonth = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: AppStyle.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Invoices button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InvoiceScreen()),
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Invoices',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: slipsAsync.when(
        loading:
            () => Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        data: (response) {
          final allSlips = response.slips;
          final filtered = _filtered(allSlips);

          final totalReceived = allSlips
              .where((s) => s.isPaid)
              .fold(0.0, (sum, s) => sum + s.netSalary);
          final totalPending = allSlips
              .where((s) => s.isPending)
              .fold(0.0, (sum, s) => sum + s.netSalary);

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Earnings Overview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppStyle.primaryColor,
                        AppStyle.primaryColor.withValues(alpha: 0.78),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppStyle.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Earnings Overview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs. ${_fmt(totalReceived)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const Text(
                        'Total Received',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryChip(
                              'Pending',
                              'Rs. ${_fmt(totalPending)}',
                              const Color(0xffF8BD00),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryChip(
                              'Total Slips',
                              '${allSlips.length}',
                              Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryChip(
                              'Paid',
                              '${allSlips.where((s) => s.isPaid).length}',
                              Colors.greenAccent.shade200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // By School
                profileAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    final schools = profile.earnings.schools;
                    if (schools.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'By School',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                color: Colors.black87,
                              ),
                            ),
                            if (_selectedSchoolId != null)
                              GestureDetector(
                                onTap:
                                    () => setState(
                                      () => _selectedSchoolId = null,
                                    ),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    color: AppStyle.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: schools.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final school = schools[i];
                              final isSelected =
                                  _selectedSchoolId == school.schoolId;
                              return GestureDetector(
                                onTap:
                                    () => setState(() {
                                      _selectedSchoolId =
                                          isSelected ? null : school.schoolId;
                                    }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 160,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppStyle.primaryColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppStyle.primaryColor
                                              : Colors.grey.shade200,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        school.schoolName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Rs. ${_fmt(school.totalEarnings)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isSelected
                                                  ? Colors.white
                                                  : AppStyle.primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Projected: Rs. ${_fmt(school.projectedEarnings)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontFamily: 'Inter',
                                          color:
                                              isSelected
                                                  ? Colors.white70
                                                  : Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Payment History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Payment History',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    if (_selectedMonth != null || _selectedSchoolId != null)
                      Text(
                        '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                if (filtered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 40,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'No slips found',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.map((slip) => SalarySlipCard(slip: slip)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

// Slip Card

class SalarySlipCard extends StatelessWidget {
  final SalarySlipModel slip;
  const SalarySlipCard({required this.slip});

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SalarySlipDetail(slip: slip),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      slip.isPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : const Color(0xffF8BD00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  slip.isPaid
                      ? Icons.receipt_long_rounded
                      : Icons.pending_actions_rounded,
                  color:
                      slip.isPaid
                          ? Colors.green.shade600
                          : const Color(0xffF8BD00),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slip.monthName} ${slip.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slip.schoolName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slip.isPaid ? 'Paid' : 'Payment Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            slip.isPaid
                                ? Colors.green.shade600
                                : Colors.orange.shade700,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${_fmt(slip.netSalary)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          slip.isPaid
                              ? Colors.green.withValues(alpha: 0.1)
                              : const Color(0xffF8BD00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slip.status,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            slip.isPaid
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InvoiceDetailScreen(slip: slip),
                          ),
                        ),
                    child: Text(
                      'View Invoice →',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        color: AppStyle.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Slip Detail Bottom Sheet

class SalarySlipDetail extends StatelessWidget {
  final SalarySlipModel slip;
  const SalarySlipDetail({required this.slip});

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slip.monthName} ${slip.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    slip.schoolName,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      slip.isPaid
                          ? Colors.green.withValues(alpha: 0.1)
                          : const Color(0xffF8BD00).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  slip.status,
                  style: TextStyle(
                    color:
                        slip.isPaid
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _row('Base Salary', 'Rs. ${_fmt(slip.baseSalary)}', Colors.black87),
          _row(
            'Commission',
            '+ Rs. ${_fmt(slip.commission)}',
            Colors.green.shade600,
          ),
          _row(
            'Adjustments',
            'Rs. ${_fmt(slip.adjustments)}',
            const Color(0xffF8BD00),
          ),
          _row('Total Classes', '${slip.totalClasses}', Colors.black54),
          _row(
            'Total Hours',
            '${slip.totalHours.toStringAsFixed(1)}h',
            Colors.black54,
          ),
          const Divider(height: 28),
          _row(
            'Net Salary',
            'Rs. ${_fmt(slip.netSalary)}',
            AppStyle.primaryColor,
            isBold: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(slip: slip),
                  ),
                );
              },
              icon: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'View Full Invoice',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
