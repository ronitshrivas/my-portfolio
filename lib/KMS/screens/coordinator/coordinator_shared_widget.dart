import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';


class CoordinatorFilterChips extends ConsumerWidget {
  final StateProvider<String> provider;
  const CoordinatorFilterChips({super.key, required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(provider);
    final options = ['ALL', 'PENDING', 'APPROVED', 'REJECTED'];
    final colors = {
      'ALL': AppStyle.primaryColor,
      'PENDING': const Color(0xFFE85D04),
      'APPROVED': const Color(0xFF059669),
      'REJECTED': Colors.red,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((f) {
          final isSelected = filter == f;
          final color = colors[f]!;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ref.read(provider.notifier).state = f,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade200,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class CoordinatorEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const CoordinatorEmptyState(
      {super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                  fontFamily: 'Inter')),
        ],
      ),
    );
  }
}


class CoordinatorErrorBox extends StatelessWidget {
  final Object? error;
  final String? message;

  const CoordinatorErrorBox({super.key, this.error, this.message});

  String get _message {
    if (message != null) return message!;
    if (error is DioException) return (error as DioException).error.toString();
    return error?.toString() ?? 'Something went wrong';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12)),
      child: Text(_message,
          style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.red.shade400,
              fontSize: 13)),
    );
  }
}


class CoordinatorAttendanceTile extends ConsumerStatefulWidget {
  final CoordinatorAttendanceModel item;
  const CoordinatorAttendanceTile({super.key, required this.item});

  @override
  ConsumerState<CoordinatorAttendanceTile> createState() =>
      _CoordinatorAttendanceTileState();
}

class _CoordinatorAttendanceTileState
    extends ConsumerState<CoordinatorAttendanceTile> {
  bool _isLoading = false;
  String? _localStatus;

  String get _effectiveStatus => _localStatus ?? widget.item.status;

  Future<void> _act(String action, {String? reason}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(
        updateAttendanceProvider({
          'attendanceId': widget.item.id,
          'action': action,
        }).future,
      );
      setState(() =>
          _localStatus = action == 'approve' ? 'APPROVED' : 'REJECTED');
      if (mounted) {
        ref.refresh(coordinatorAttendanceProvider);
        _snack(
          action == 'approve'
              ? 'Attendance approved!'
              : 'Attendance rejected.',
          action == 'approve' ? Colors.green : Colors.red.shade400,
          action == 'approve'
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
        );
      }
    } catch (e) {
      if (mounted)
        _snack('Failed: $e', Colors.red.shade400, Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    showAdaptiveDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text('Reason for Rejection',
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter reason (optional)...',
            hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontFamily: 'Inter',
                fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey.shade500, fontFamily: 'Inter')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _act('reject', reason: ctrl.text.trim());
            },
            child: const Text('Reject',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _effectiveStatus;
    final isPending = status == 'PENDING';
    final isApproved = status == 'APPROVED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: !isPending
            ? Border.all(
                color: isApproved
                    ? Colors.green.shade300
                    : Colors.red.shade300,
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppStyle.primaryColor.withValues(alpha: 0.12),
                  child: Text(
                    widget.item.teacherName[0],
                    style: TextStyle(
                        color: AppStyle.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item.teacherName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              fontFamily: 'Inter',
                              color: Colors.black87)),
                      Text(widget.item.schoolName,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.item.date.day}/${widget.item.date.month}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const SizedBox(
                height: 40,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (!isPending)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: isApproved ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isApproved ? 'Approved' : 'Rejected',
                        style: TextStyle(
                          color: isApproved
                              ? Colors.green.shade700
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showRejectDialog,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Center(
                          child: Text('Reject',
                              style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _act('approve'),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Center(
                          child: Text('Approve',
                              style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  fontSize: 13)),
                        ),
                      ),
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


class CoordinatorMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const CoordinatorMiniStat(
      {super.key,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Inter')),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}