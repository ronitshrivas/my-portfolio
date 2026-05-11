import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_kyc_model.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/screens/teacher/kyc_upload_screen.dart';
import 'package:innovator/KMS/screens/teacher/teacher_review_screen.dart';

class TeacherDashboardScreen extends ConsumerStatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  ConsumerState<TeacherDashboardScreen> createState() =>
      _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends ConsumerState<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isPaymentFlipped = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  final Map<String, bool> _checkedInMap = {};
  final Map<String, bool> _loadingMap = {};
  final Map<String, dynamic> _checkInIdMap = {};

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _togglePaymentCard() {
    setState(() {
      _isPaymentFlipped = !_isPaymentFlipped;
      _isPaymentFlipped ? _flipController.forward() : _flipController.reverse();
    });
  }

  Future<void> _handleCheckIn(String schoolId) async {
    setState(() => _loadingMap[schoolId] = true);
    try {
      final response = await ref
          .read(teacherServiceProvider)
          .checkIn(schoolId: schoolId);

      final attendanceId =
          response['id'] ?? response['_id'] ?? response['attendance_id'];

      setState(() {
        _checkedInMap[schoolId] = true;
        if (attendanceId != null) _checkInIdMap[schoolId] = attendanceId;
      });

      if (mounted) _showSnack('Checked in successfully!', isError: false);
    } catch (e) {
      if (mounted);
    } finally {
      setState(() => _loadingMap[schoolId] = false);
    }
  }

  Future<void> _handleCheckOut(String schoolId) async {
    final id = _checkInIdMap[schoolId];
    if (id == null) {
      _showSnack(
        'Cannot check out: attendance record not found. Please check in first.',
        isError: true,
      );
      return;
    }

    setState(() => _loadingMap[schoolId] = true);
    try {
      await ref.read(teacherServiceProvider).checkOut(id: id);
      setState(() {
        _checkedInMap[schoolId] = false;
        _checkInIdMap.remove(schoolId);
      });
      if (mounted) _showSnack('Checked out successfully!', isError: false);
    } catch (e) {
      if (mounted) _showSnack('Check-out failed', isError: true);
    } finally {
      setState(() => _loadingMap[schoolId] = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor:
              isError ? Colors.red.shade400 : AppStyle.primaryColor,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Watch once at the top — pass typed data down, no more dynamic
    final profileAsync = ref.watch(teacherProfileProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(teacherProfileProvider);
        ref.invalidate(kycStatusProvider);
        await ref.read(teacherProfileProvider.future);
      },
      child: CustomScrolling(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            profileAsync.when(
              loading: () => const _SkeletonGrid(),
              error: (_, __) => _buildGrid(context, null),
              data: (profile) => _buildGrid(context, profile),
            ),
            const SizedBox(height: 24),
            profileAsync.when(
              loading: () => const _AttendanceSkeleton(),
              error: (_, __) => _buildAttendanceSection(null),
              data: (profile) => _buildAttendanceSection(profile),
            ),
            const SizedBox(height: 20),
            _buildKycBanner(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Attendance Section ───────────────────────────────────────────────────

  Widget _buildAttendanceSection(TeacherProfileModel? profile) {
    final schools = profile?.earnings.schools ?? <TeacherSchoolEarning>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned Schools',
              style: AppStyle.heading2.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: AppStyle.fontFamilySecondary,
                fontSize: 18,
              ),
            ),
            if (schools.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${schools.length} School${schools.length > 1 ? 's' : ''}',
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
        const SizedBox(height: 14),
        if (schools.isEmpty)
          _AttendanceCard(
            schoolName: 'Your Assigned School',
            isCheckedIn: _checkedInMap['default'] ?? false,
            isLoading: _loadingMap['default'] ?? false,
            onCheckIn: () => _handleCheckIn('default'),
            onCheckOut: () => _handleCheckOut('default'),
          )
        else
          ...schools.map(
            (school) => _AttendanceCard(
              schoolName: school.schoolName,
              isCheckedIn: _checkedInMap[school.schoolId] ?? false,
              isLoading: _loadingMap[school.schoolId] ?? false,
              onCheckIn: () => _handleCheckIn(school.schoolId),
              onCheckOut: () => _handleCheckOut(school.schoolId),
            ),
          ),
      ],
    );
  }

  // ─── KYC Banner ───────────────────────────────────────────────────────────

  Widget _buildKycBanner(BuildContext context) {
    final kycAsync = ref.watch(kycStatusProvider);
    return kycAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) => _kycBannerTile(
            context,
            title: 'KYC Verification',
            subtitle: 'Upload your identity document to verify',
            icon: Icons.verified_user_rounded,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycUploadScreen()),
                ),
          ),
      data: (kyc) {
        if (kyc.isApproved) return const SizedBox.shrink();
        if (kyc.isPending) {
          return _kycBannerTile(
            context,
            title: 'KYC Under Review',
            subtitle: 'Your documents are being verified',
            icon: Icons.hourglass_top_rounded,
            color: Colors.blueAccent,
            onTap: () => _showKycStatusDialog(context, kyc),
          );
        }
        if (kyc.isRejected) {
          return _kycBannerTile(
            context,
            title: 'KYC Rejected',
            subtitle: kyc.rejectionReason ?? 'Please re-upload your documents',
            icon: Icons.error_rounded,
            color: Colors.red.shade400,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycUploadScreen()),
                ),
          );
        }
        return _kycBannerTile(
          context,
          title: 'KYC Verification',
          subtitle: 'Upload your identity document to verify',
          icon: Icons.verified_user_rounded,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KycUploadScreen()),
              ),
        );
      },
    );
  }

  Widget _kycBannerTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    Color? color,
    required VoidCallback onTap,
  }) {
    final bannerColor = color ?? AppStyle.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bannerColor, bannerColor.withValues(alpha: 0.78)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: bannerColor.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showKycStatusDialog(BuildContext context, KycModel kyc) {
    showAdaptiveDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            title: const Icon(
              Icons.hourglass_top_rounded,
              size: 48,
              color: Color(0xffF8BD00),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'KYC Under Review',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your documents have been submitted and are currently being reviewed. You will be notified once verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontFamily: 'Inter',
                  ),
                ),
                if (kyc.submittedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Submitted on ${kyc.submittedAt!.day} ${_monthName(kyc.submittedAt!.month)} ${kyc.submittedAt!.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyle.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  static String _monthName(int month) {
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
    return months[month - 1];
  }

  // ─── Stats Grid ───────────────────────────────────────────────────────────

  Widget _buildGrid(BuildContext context, TeacherProfileModel? profile) {
    final kycAsync = ref.watch(kycStatusProvider);

    final earnings = profile?.earnings;
    final rating = profile?.rating;

    final int schoolCount = earnings?.schools.length ?? 0;
    final int totalClasses =
        earnings?.schools.fold<int>(0, (sum, s) => sum + s.classesCount) ?? 0;
    final double totalEarnings = earnings?.totalEarnings ?? 0.0;
    final double paid = earnings?.totalPaid ?? 0.0;
    final double pending = earnings?.totalPending ?? 0.0;
    final double projected = earnings?.projectedEarnings ?? 0.0;
    final double paidPct =
        totalEarnings > 0 ? (paid / totalEarnings) * 100 : 0.0;
    final double pendingPct =
        totalEarnings > 0 ? (pending / totalEarnings) * 100 : 0.0;
    final bool noData = profile == null;

    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 10,
      ),
      children: [
        // ── Card 1: Profile / KYC Status ────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    'Profile Status',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                kycAsync.when(
                  loading: () => const SizedBox.shrink(),
                  // KYC not found → show 0% ring + prompt
                  error:
                      (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomPaint(
                              painter: const ProfileStatusCircularPercentage(
                                percentage: 0,
                              ),
                              size: Size(
                                context.screenWidth * 0.2,
                                context.screenHeight * 0.08,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'Upload KYC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  data: (kyc) {
                    final percentage =
                        double.tryParse(
                          (kyc.kycPercentage ?? '0').replaceAll('%', '').trim(),
                        ) ??
                        0.0;

                    final config = switch (kyc.status) {
                      'approved' => (
                        label: 'KYC Verified',
                        color: Colors.green,
                      ),
                      'rejected' => (label: 'KYC Rejected', color: Colors.red),
                      _ => (label: 'KYC Pending', color: Colors.blue),
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomPaint(
                            painter: ProfileStatusCircularPercentage(
                              percentage: percentage,
                            ),
                            size: Size(
                              context.screenWidth * 0.2,
                              context.screenHeight * 0.08,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: config.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                config.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  color: config.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Card 2: Assigned Schools ─────────────────────────────────────
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          color: Colors.white,
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 17,
              left: 17,
              top: 10,
              bottom: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text(
                    'Assigned Schools',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.009),
                Center(
                  child: Text(
                    noData ? '—' : '$schoolCount',
                    style: AppStyle.bodyText.copyWith(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                SizedBox(height: context.screenHeight * 0.009),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppStyle.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/kms/school.png',
                              height: 15,
                              width: 15,
                              color: AppStyle.primaryColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              noData
                                  ? 'No Classes Yet'
                                  : '$totalClasses Classes',
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
        ),

        // ── Card 3: Payment (flip card) ──────────────────────────────────
        GestureDetector(
          onTap: _togglePaymentCard,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, _) {
              final angle = _flipAnimation.value * pi;
              final showFront = angle <= pi / 2;
              return Transform(
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                alignment: Alignment.center,
                child:
                    showFront
                        ? _paymentFront(context, paidPct, pendingPct, noData)
                        : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _paymentBack(
                            context,
                            total: totalEarnings,
                            paid: paid,
                            pending: pending,
                            projected: projected,
                            noData: noData,
                          ),
                        ),
              );
            },
          ),
        ),

        // ── Card 4: Rating ───────────────────────────────────────────────
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TeacherReviewsScreen()),
              ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            color: Colors.white,
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 15,
                left: 15,
                top: 10,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Text(
                      'My Rating',
                      style: AppStyle.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: AppStyle.fontFamilySecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (noData || rating == null)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No ratings yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          rating.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(0xffF8BD00),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Star row
                    _StarRow(rating: rating.averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '${rating.totalRatings} review${rating.totalRatings == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Inter',
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Payment card faces ───────────────────────────────────────────────────

  Widget _paymentFront(
    BuildContext context,
    double paidPct,
    double pendingPct,
    bool noData,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, left: 15, top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  child: Text(
                    'Payment',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(Icons.touch_app, size: 16, color: Colors.grey),
              ],
            ),
            if (noData)
              Expanded(
                child: Center(
                  child: Text(
                    'No payment\ndata yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else if (paidPct == 0 && pendingPct == 0)
              Expanded(
                child: Center(
                  child: Text(
                    'No earnings\nrecorded yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else
              FittedBox(
                child: Row(
                  children: [
                    CustomPaint(
                      painter: PaymentPieChart(
                        paidPercentage: paidPct,
                        pendingPercentage: pendingPct,
                      ),
                      size: Size(
                        context.screenWidth * 0.2,
                        context.screenHeight * 0.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _distributionChart(const Color(0xffF8BD00), 'Pending'),
                        _distributionChart(AppStyle.primaryColor, 'Paid'),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _paymentBack(
    BuildContext context, {
    required double total,
    required double paid,
    required double pending,
    required double projected,
    required bool noData,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                  child: Text(
                    'Payment',
                    style: AppStyle.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: AppStyle.fontFamilySecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(Icons.touch_app, size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 4),
            if (noData)
              Expanded(
                child: Center(
                  child: Text(
                    'No payment\ndata yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else ...[
              _amountRow('Total', total, Colors.black),
              _amountRow('Paid', paid, AppStyle.primaryColor),
              _amountRow('Pending', pending, const Color(0xffF8BD00)),
              _amountRow('Projected', projected, Colors.blueGrey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double amount, Color color) => Padding(
    padding: const EdgeInsets.all(2.0),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Inter',
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          'Rs. ${amount.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _distributionChart(Color color, String text) => Row(
    children: [
      Container(
        width: 10,
        height: 5,
        decoration: BoxDecoration(shape: BoxShape.rectangle, color: color),
      ),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(color: Colors.black, fontSize: 14)),
    ],
  );
}

// ─── Star Row Widget ──────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 1.0
              ? Icons.star_rounded
              : fill >= 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xffF8BD00),
          size: 14,
        );
      }),
    );
  }
}

// ─── Attendance Card ──────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  final String schoolName;
  final bool isCheckedIn;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _AttendanceCard({
    required this.schoolName,
    required this.isCheckedIn,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = '${now.day} ${_monthName(now.month)} ${now.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              isCheckedIn
                  ? AppStyle.primaryColor.withValues(alpha: 0.35)
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        isCheckedIn
                            ? AppStyle.primaryColor.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color:
                        isCheckedIn
                            ? AppStyle.primaryColor
                            : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isCheckedIn
                                      ? Colors.green
                                      : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCheckedIn ? 'Active · $timeStr' : dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Inter',
                              color:
                                  isCheckedIn
                                      ? Colors.green.shade700
                                      : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            isLoading
                ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppStyle.primaryColor,
                      ),
                    ),
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isCheckedIn ? null : onCheckIn,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppStyle.primaryColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow:
                                isCheckedIn
                                    ? []
                                    : [
                                      BoxShadow(
                                        color: AppStyle.primaryColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.login_rounded,
                                color:
                                    isCheckedIn
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Check In',
                                style: TextStyle(
                                  color:
                                      isCheckedIn
                                          ? Colors.white.withValues(alpha: 0.4)
                                          : Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              if (isCheckedIn) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: isCheckedIn ? onCheckOut : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                isCheckedIn
                                    ? Colors.red.shade500
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                isCheckedIn
                                    ? null
                                    : Border.all(color: Colors.grey.shade300),
                            boxShadow:
                                isCheckedIn
                                    ? [
                                      BoxShadow(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color:
                                    isCheckedIn
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Check Out',
                                style: TextStyle(
                                  color:
                                      isCheckedIn
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
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

  String _monthName(int month) {
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
    return months[month - 1];
  }
}

// ─── Skeleton Widgets ─────────────────────────────────────────────────────────

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 110,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ],
    );
  }
}

class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid();

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder:
          (context, _) => GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            children: List.generate(4, _buildSkeletonCard),
          ),
    );
  }

  Widget _buildSkeletonCard(int index) {
    final double phase = (_ctrl.value + index * 0.2) % 1.0;
    final double opacity = 0.3 + (0.5 * (sin(phase * pi)));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Opacity(
          opacity: opacity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 90, height: 11),
              const SizedBox(height: 14),
              if (index == 0) ...[
                Center(child: _circle(52)),
              ] else if (index == 1) ...[
                Center(child: _box(width: 28, height: 18)),
                const SizedBox(height: 8),
                _box(width: 85, height: 22, radius: 11),
              ] else if (index == 2) ...[
                _box(width: double.infinity, height: 10),
                const SizedBox(height: 7),
                _box(width: double.infinity, height: 10),
                const SizedBox(height: 10),
                Center(child: _box(width: 100, height: 18, radius: 9)),
              ] else ...[
                // Rating skeleton: big number + star row
                _box(width: 48, height: 24, radius: 6),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (_) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: _circle(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _box(width: 60, height: 9),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _box({required double width, double height = 12, double radius = 6}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      shape: BoxShape.circle,
    ),
  );
}

// ─── Custom Painters ──────────────────────────────────────────────────────────

class ProfileStatusCircularPercentage extends CustomPainter {
  final double percentage;
  final Color segmentColor;

  const ProfileStatusCircularPercentage({
    required this.percentage,
    this.segmentColor = AppStyle.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 1.4, size.height / 2.5);
    final radius = min(size.width, size.height) * 0.4;
    final innerRadius = radius * 0.74;
    final paint = Paint()..style = PaintingStyle.fill;
    final double clamped = percentage.clamp(0.0, 100.0);
    final segs = [
      if (clamped > 0) _PieSegment(clamped, segmentColor),
      if (100.0 - clamped > 0)
        _PieSegment(100.0 - clamped, const Color(0xffDDFFE7)),
    ];
    final total = segs.fold(0.0, (s, e) => s + e.value);
    double start = -pi / -4.8;
    for (final seg in segs) {
      final sweep = (seg.value / total) * 2 * pi;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      start += sweep;
    }
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = const Color(0xffDDFFE7),
    );
    final tp =
        TextPainter(textDirection: TextDirection.rtl)
          ..text = TextSpan(
            text: '${clamped.toInt()}%',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          )
          ..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2.3, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(ProfileStatusCircularPercentage old) =>
      old.percentage != percentage;
}

class _PieSegment {
  final double value;
  final Color color;
  const _PieSegment(this.value, this.color);
}

class PaymentPieChart extends CustomPainter {
  final double paidPercentage;
  final double pendingPercentage;

  const PaymentPieChart({
    required this.paidPercentage,
    required this.pendingPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.48;
    final paint = Paint()..style = PaintingStyle.fill;
    final segs = [
      _PaySeg(paidPercentage, AppStyle.primaryColor),
      _PaySeg(pendingPercentage, const Color(0xffF8BD00)),
    ];
    final total = segs.fold(0.0, (s, e) => s + e.value);
    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawCircle(center, radius, paint);
      return;
    }
    double start = -pi / 2;
    for (final seg in segs) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * 2.5 * pi;
      paint.color = seg.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        true,
        paint,
      );
      final ta = start + sweep / 2.5;
      final tr = radius * 0.66;
      final tp =
          TextPainter(textDirection: TextDirection.ltr)
            ..text = TextSpan(
              text: '${seg.value.toInt()}%',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
            ..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + tr * cos(ta) - tp.width / 2,
          center.dy + tr * sin(ta) - tp.height / 2,
        ),
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(PaymentPieChart old) =>
      old.paidPercentage != paidPercentage ||
      old.pendingPercentage != pendingPercentage;
}

class _PaySeg {
  final double value;
  final Color color;
  const _PaySeg(this.value, this.color);
}
