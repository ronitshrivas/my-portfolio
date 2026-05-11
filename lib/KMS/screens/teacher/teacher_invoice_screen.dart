import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_salary_slips.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/screens/teacher/teacher_salary_slips.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  DateTime? _selectedDate;
  int _visibleCount = 3;

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: AppStyle.primaryColor),
            ),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<SalarySlipModel> _filtered(List<SalarySlipModel> slips) {
    final sorted = [...slips]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedDate == null) return sorted;
    return sorted.where((s) {
      final d = s.createdAt;
      return d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final slipsAsync = ref.watch(salarySlipsProvider);

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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      _selectedDate != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color:
                          _selectedDate != null
                              ? AppStyle.primaryColor
                              : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Filter',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color:
                            _selectedDate != null
                                ? AppStyle.primaryColor
                                : Colors.white,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selectedDate != null
                    ? 'Results for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Your payroll records',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontFamily: 'InterThin',
                ),
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
              child: slipsAsync.when(
                loading: () => _buildSkeletonList(),
                error:
                    (e, _) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load salary slips',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                data: (response) {
                  final slips = _filtered(response.slips);
                  if (slips.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 52,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? 'No slips for this date'
                                : 'No salary slips yet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final visible = slips.take(_visibleCount).toList();
                  final hasMore = _visibleCount < slips.length;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: visible.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == visible.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: GestureDetector(
                            onTap: () => setState(() => _visibleCount += 3),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppStyle.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Load more  (${slips.length - _visibleCount} remaining)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: AppStyle.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return SlipCard(slip: visible[i]);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, i) => SkeletonSlipCard(index: i),
    );
  }
}
