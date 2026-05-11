import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_rating_model.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_shared_widget.dart';

final _approvalFilterProvider = StateProvider<String>((ref) => 'ALL');

class CoordinatorAttendanceApprovalScreen extends ConsumerWidget {
  const CoordinatorAttendanceApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(coordinatorAttendanceProvider);
    final filter = ref.watch(_approvalFilterProvider);

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
          'Attendance Approval',
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
              onTap: () => ref.refresh(coordinatorAttendanceProvider),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          attendanceAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data:
                (data) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      CoordinatorMiniStat(
                        label: 'Total',
                        value: '${data.total}',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      CoordinatorMiniStat(
                        label: 'Pending',
                        value: '${data.pending}',
                        color: const Color(0xFFFFB347),
                      ),
                      const SizedBox(width: 10),
                      CoordinatorMiniStat(
                        label: 'Approved',
                        value:
                            '${data.attendances.where((a) => a.isApproved).length}',
                        color: Colors.greenAccent.shade200,
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: CoordinatorFilterChips(
                      provider: _approvalFilterProvider,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: attendanceAsync.when(
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (e, _) =>
                              Center(child: CoordinatorErrorBox(error: e)),
                      data: (data) {
                        final list =
                            filter == 'ALL'
                                ? data.attendances
                                : data.attendances
                                    .where((a) => a.status == filter)
                                    .toList();

                        if (list.isEmpty) {
                          return CoordinatorEmptyState(
                            icon:
                                filter == 'ALL'
                                    ? Icons.check_circle_rounded
                                    : Icons.filter_list_rounded,
                            message:
                                filter == 'ALL'
                                    ? 'No attendance records'
                                    : 'No ${filter.toLowerCase()} records',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final item = list[i];
                            return GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              CoordinatorAttendanceDetailScreen(
                                                item: item,
                                              ),
                                    ),
                                  ),
                              child: CoordinatorAttendanceTile(item: item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String labelForRating(double r) {
  if (r <= 0.5) return 'Terrible';
  if (r <= 1.0) return 'Very Poor';
  if (r <= 1.5) return 'Poor';
  if (r <= 2.0) return 'Below Average';
  if (r <= 2.5) return 'Average';
  if (r <= 3.0) return 'Satisfactory';
  if (r <= 3.5) return 'Good';
  if (r <= 4.0) return 'Very Good';
  if (r <= 4.5) return 'Excellent';
  return 'Outstanding';
}

String month(int m) {
  const months = [
    '',
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
  return (m >= 1 && m <= 12) ? months[m] : '';
}

Color colorForRating(double r) {
  if (r <= 1.0) return const Color(0xFFEF4444);
  if (r <= 2.0) return const Color(0xFFF97316);
  if (r <= 3.0) return const Color(0xFFEAB308);
  if (r <= 4.0) return const Color(0xFF22C55E);
  return const Color(0xFF059669);
}

class HalfStarRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;

  const HalfStarRating({this.initialRating = 0, required this.onRatingChanged});

  @override
  State<HalfStarRating> createState() => HalfStarRatingState();
}

class HalfStarRatingState extends State<HalfStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _onTap(int starIndex, bool isLeft) {
    final candidate = isLeft ? starIndex - 0.5 : starIndex.toDouble();
    final newRating = candidate < 1.0 ? 1.0 : candidate;
    setState(() => _rating = newRating);
    widget.onRatingChanged(newRating);
  }

  Widget star(int starIndex) {
    final IconData icon;
    final Color color;

    if (_rating >= starIndex) {
      icon = Icons.star_rounded;
      color = const Color(0xFFFFC107);
    } else if (_rating >= starIndex - 0.5) {
      icon = Icons.star_half_rounded;
      color = const Color(0xFFFFC107);
    } else {
      icon = Icons.star_outline_rounded;
      color = Colors.grey.shade300;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        const starWidth = 44.0;
        final localX =
            box.globalToLocal(details.globalPosition).dx -
            (starIndex - 1) * starWidth;
        _onTap(starIndex, localX < starWidth / 2);
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: color, size: 38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => star(i + 1)),
    );
  }
}

class RatingDialog extends ConsumerStatefulWidget {
  final CoordinatorAttendanceModel item;
  const RatingDialog({required this.item});

  @override
  ConsumerState<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<RatingDialog> {
  double _rating = 0;
  final _feedbackCtrl = TextEditingController();
  String? _ratingError;
  bool _isLoading = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _ratingError = 'Please select a rating to continue.');
      return;
    }
    setState(() {
      _isLoading = true;
      _ratingError = null;
    });
    try {
      await ref.read(
        ratingProvider({
          'teacher': widget.item.teacherId,
          'rating': _rating.toString(),
          'review':
              _feedbackCtrl.text.trim().isEmpty
                  ? null
                  : _feedbackCtrl.text.trim(),
        }).future,
      );
      if (mounted) Navigator.pop(context, _rating);
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        _rating == 0 ? Colors.grey.shade400 : colorForRating(_rating);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: AppStyle.primaryColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    widget.item.teacherName[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.item.teacherName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'How was this teacher\'s performance?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              children: [
                HalfStarRating(
                  onRatingChanged:
                      (r) => setState(() {
                        _rating = r;
                        _ratingError = null;
                      }),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder:
                      (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                  child:
                      _rating == 0
                          ? Text(
                            'Tap a star to rate',
                            key: const ValueKey('empty'),
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              color: Colors.grey.shade400,
                            ),
                          )
                          : Container(
                            key: ValueKey(_rating),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: labelColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: labelColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$_rating★  ·  ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: labelColor,
                                  ),
                                ),
                                Text(
                                  labelForRating(_rating),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: labelColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
                if (_ratingError != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 13,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _ratingError!,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback (optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _feedbackCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Leave a note about this teacher\'s session...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppStyle.primaryColor.withValues(alpha: 0.4),
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppStyle.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Submit Rating',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
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
  }
}

class CoordinatorAttendanceDetailScreen extends ConsumerStatefulWidget {
  final CoordinatorAttendanceModel item;
  const CoordinatorAttendanceDetailScreen({super.key, required this.item});

  @override
  ConsumerState<CoordinatorAttendanceDetailScreen> createState() =>
      _CoordinatorAttendanceDetailScreenState();
}

class _CoordinatorAttendanceDetailScreenState
    extends ConsumerState<CoordinatorAttendanceDetailScreen> {
  bool _isApprovalLoading = false;
  String? _localStatus;
  double? _submittedRating;

  String get _status => _localStatus ?? widget.item.status;

  Future<void> _act(String action, {String? reason}) async {
    setState(() => _isApprovalLoading = true);
    try {
      await ref.read(
        updateAttendanceProvider({
          'attendanceId': widget.item.id,
          'action': action,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }).future,
      );
      setState(
        () => _localStatus = action == 'approve' ? 'APPROVED' : 'REJECTED',
      );
      if (mounted) ref.refresh(coordinatorAttendanceProvider);
    } catch (_) {
      if (mounted)
        _showErrorSnack('Could not update attendance. Please try again.');
    } finally {
      if (mounted) setState(() => _isApprovalLoading = false);
    }
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    showAdaptiveDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Text(
              'Reason for Rejection',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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
                  fontSize: 13,
                ),
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
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _act('reject', reason: ctrl.text.trim());
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> openRatingDialog() async {
    final result = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(item: widget.item),
    );
    if (result != null) setState(() => _submittedRating = result);
  }

  Widget alreadyRatedCard(TeacherRatingModel existingRating) {
    final ratingValue = double.tryParse(existingRating.rating ?? '0') ?? 0;
    final nextMonth = (existingRating.month ?? 1) % 12 + 1;
    final nextYear =
        (existingRating.month ?? 1) == 12
            ? (existingRating.year ?? 0) + 1
            : (existingRating.year ?? 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorForRating(ratingValue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: colorForRating(ratingValue),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelForRating(ratingValue),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorForRating(ratingValue),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) {
                        final starNum = i + 1;
                        final IconData icon;
                        if (ratingValue >= starNum) {
                          icon = Icons.star_rounded;
                        } else if (ratingValue >= starNum - 0.5) {
                          icon = Icons.star_half_rounded;
                        } else {
                          icon = Icons.star_outline_rounded;
                        }
                        return Icon(
                          icon,
                          size: 16,
                          color: const Color(0xFFFFC107),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rated',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_clock_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'You\'ve already rated this teacher for ${existingRating.year ?? 0} ${month(existingRating.month ?? 1)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: AppStyle.primaryColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Next rating will be available on $nextYear ${month(nextMonth)}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppStyle.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget submittedCard(double submittedRating) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorForRating(submittedRating).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.star_rounded,
                color: colorForRating(submittedRating),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelForRating(submittedRating),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: colorForRating(submittedRating),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$submittedRating out of 5  ·  Rating submitted',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget ratedButton() {
    return GestureDetector(
      onTap: openRatingDialog,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: AppStyle.primaryColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppStyle.primaryColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline_rounded,
              color: AppStyle.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Rate this Teacher',
              style: TextStyle(
                color: AppStyle.primaryColor,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ratingsAsync = ref.watch(getRatingProvider);
    final isPending = _status == 'PENDING';
    final isApproved = _status == 'APPROVED';
    final statusColor =
        isPending
            ? const Color(0xFFE85D04)
            : isApproved
            ? const Color(0xFF059669)
            : Colors.red;

    return Scaffold(
      backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance Detail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppStyle.primaryColor.withValues(
                      alpha: 0.12,
                    ),
                    child: Text(
                      widget.item.teacherName[0],
                      style: TextStyle(
                        color: AppStyle.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.item.teacherName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            DetailCard(
              children: [
                DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value:
                      '${widget.item.date.day}/${widget.item.date.month}/${widget.item.date.year}',
                ),
                DetailRow(
                  icon: Icons.school_rounded,
                  label: 'School',
                  value: widget.item.schoolName,
                ),
              ],
            ),

            const SizedBox(height: 20),

            SectionHeader(
              icon: Icons.how_to_vote_rounded,
              title: 'Attendance Decision',
            ),
            const SizedBox(height: 10),

            if (_isApprovalLoading)
              const Center(child: CircularProgressIndicator())
            else if (!isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color:
                      isApproved
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isApproved
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                  ),
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
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isApproved ? 'Approved' : 'Rejected',
                        style: TextStyle(
                          color:
                              isApproved
                                  ? Colors.green.shade700
                                  : Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          fontSize: 16,
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
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Center(
                          child: Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _act('approve'),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Center(
                          child: Text(
                            'Approve',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 28),

            ratingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const SizedBox.shrink(),
              data: (ratings) {
                final existingRating =
                    ratings
                        .where((r) => r.teacherId == widget.item.teacherId)
                        .firstOrNull;

                final alreadyRated = existingRating?.isRated == true;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      icon: Icons.star_rounded,
                      title: 'Teacher Rating',
                    ),
                    const SizedBox(height: 10),
                    if (alreadyRated)
                      alreadyRatedCard(existingRating!)
                    else if (_submittedRating != null)
                      submittedCard(_submittedRating!)
                    else
                      ratedButton(),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: Colors.black45,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.07),
          ),
        ),
      ],
    );
  }
}

class DetailCard extends StatelessWidget {
  final List<Widget> children;
  const DetailCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
