import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_salary_slips.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

 

class SkeletonSlipCard extends StatefulWidget {
  final int index;
  const SkeletonSlipCard({required this.index});

  @override
  State<SkeletonSlipCard> createState() => _SkeletonSlipCardState();
}

class _SkeletonSlipCardState extends State<SkeletonSlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
          (_, __) => Opacity(
            opacity: 0.3 + 0.4 * _ctrl.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _box(120, 14),
                          const SizedBox(height: 6),
                          _box(80, 10),
                        ],
                      ),
                      _box(60, 28, radius: 14),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_box(70, 32), _box(70, 32), _box(50, 32)],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _box(double w, double h, {double radius = 8}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

// Slip Card

class SlipCard extends StatelessWidget {
  final SalarySlipModel slip;
  const SlipCard({required this.slip});

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slip.monthName} ${slip.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                _StatusBadge(status: slip.status),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SlipStat(
                  label: 'Base Salary',
                  value: 'Rs. ${_fmt(slip.baseSalary)}',
                  color: Colors.black87,
                ),
                SlipStat(
                  label: 'Net Salary',
                  value: 'Rs. ${_fmt(slip.netSalary)}',
                  color: AppStyle.primaryColor,
                  isBold: true,
                ),
                SlipStat(
                  label: 'Classes',
                  value: '${slip.totalClasses}',
                  color: Colors.black87,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Created: ${slip.createdAt.day}/${slip.createdAt.month}/${slip.createdAt.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'InterThin',
                    color: Colors.black87.withAlpha(100),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                    onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InvoiceDetailScreen(slip: slip)),
          ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'View invoice',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'InterThin',
                          color: Colors.black,
                        ),
                      ),
                    ],
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

class SlipStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const SlipStat({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontFamily: 'InterThin',
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'PAID';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isPaid
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPaid ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              color: isPaid ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceDetailScreen extends StatefulWidget {
  final SalarySlipModel slip;
  const InvoiceDetailScreen({super.key, required this.slip});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final GlobalKey _invoiceKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  static const _darkNavy = Color(0xFF1B2A4A);

  String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  Future<Uint8List?> _capture() async {
    try {
      // wait for asset image to fully render
      await Future.delayed(const Duration(milliseconds: 600));
      final context = _invoiceKey.currentContext;
      if (context == null) return null;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Failed to capture invoice');

      final fileName =
          'invoice_${widget.slip.monthName}_${widget.slip.year}_${widget.slip.id.substring(0, 6)}.png';

      // Save directly to Android Downloads folder — no package needed
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saved to Downloads/$fileName',
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Download failed: $e',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Failed to capture invoice');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/invoice_${widget.slip.monthName}_${widget.slip.year}.png',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Salary Slip — ${widget.slip.monthName} ${widget.slip.year}'
            '\nNet Salary: Rs. ${_fmt(widget.slip.netSalary)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Share failed: $e',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slip = widget.slip;

    return Scaffold(
      floatingActionButton: GestureDetector(
        onTap: _isSharing ? null : _share,
        child:
            _isSharing
                ? CircularProgressIndicator(
                  color: AppStyle.primaryColor,
                  strokeWidth: 2,
                )
                : Icon(
                  Icons.share_rounded,
                  color: AppStyle.primaryColor,
                  size: 40,
                ),
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoice',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            fontSize: 18,
          ),
        ),
        actions: [
          // Download button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _isDownloading ? null : _download,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    _isDownloading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Row(
                          children: [
                            Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Download',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _invoiceKey,
          child: Container(
            color: const Color(0xFFF0F2F5),
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dark navy header
                  Container(
                    width: double.infinity,
                    color: _darkNavy.withAlpha(250),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/kms/nepatronix.png',
                          width: 120,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'SALARY SLIP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _headerMeta(
                              'Slip No',
                              '#${slip.id.substring(0, 8).toUpperCase()}',
                            ),
                            const SizedBox(height: 4),
                            _headerMeta(
                              'Invoice Date',
                              '${slip.createdAt.day} ${slip.monthName} ${slip.createdAt.year}',
                            ),
                            const SizedBox(height: 4),
                            _headerMeta(
                              'Period',
                              '${slip.monthName} ${slip.year}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Info row
                  Container(
                    color: const Color(0xFFF5F7FA),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoLabel('Teacher'),
                              const SizedBox(height: 6),
                              _infoValue(slip.teacherName.toUpperCase()),
                              const SizedBox(height: 3),
                              _infoValue(
                                'Status: ${slip.status}',
                                color:
                                    slip.isPaid
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Table
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          color: _darkNavy,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              _tableHead('No.', flex: 1),
                              _tableHead('Description', flex: 4),
                              _tableHead(
                                'Details',
                                flex: 3,
                                align: TextAlign.center,
                              ),
                              _tableHead(
                                'Amount',
                                flex: 3,
                                align: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        _tableRow(
                          no: '1',
                          desc: 'Base Salary',
                          detail: '${slip.totalClasses} classes',
                          amount: 'Rs. ${_fmt(slip.baseSalary)}',
                          isEven: false,
                        ),
                        _tableRow(
                          no: '2',
                          desc: 'Commission',
                          detail: '${slip.totalHours.toStringAsFixed(1)} hrs',
                          amount: 'Rs. ${_fmt(slip.commission)}',
                          isEven: true,
                        ),
                        _tableRow(
                          no: '3',
                          desc: 'Adjustments',
                          detail: slip.adminOverride ? 'Admin override' : '—',
                          amount: 'Rs. ${_fmt(slip.adjustments)}',
                          isEven: false,
                        ),
                        const SizedBox(height: 4),
                        _totalRow(
                          'Subtotal',
                          'Rs. ${_fmt(slip.baseSalary + slip.commission)}',
                        ),
                        _totalRow(
                          'Adjustments',
                          'Rs. ${_fmt(slip.adjustments)}',
                        ),
                        _totalRow(
                          'Net Salary',
                          'Rs. ${_fmt(slip.netSalary)}',
                          highlight: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dashed divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        48,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color:
                                i.isEven
                                    ? Colors.grey.shade400
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _note('Payment is processed at the end of each month.'),
                        _note('Contact HR for any discrepancies in this slip.'),
                        if (slip.adminOverride &&
                            slip.overrideNotes != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xffF8BD00,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xffF8BD00),
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Admin Note: ${slip.overrideNotes}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                      color: Color(0xff7A6200),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Text(
                      'Thank You for Your Business',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerMeta(String label, String value) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '$label  :  ',
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          fontFamily: 'Inter',
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _infoLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontFamily: 'Inter',
      color: Colors.grey.shade500,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  Widget _infoValue(String text, {Color? color}) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontFamily: 'Inter',
      color: color ?? Colors.black87,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _tableHead(
    String text, {
    int flex = 1,
    TextAlign align = TextAlign.left,
  }) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: align,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        fontSize: 12,
      ),
    ),
  );

  Widget _tableRow({
    required String no,
    required String desc,
    required String detail,
    required String amount,
    required bool isEven,
  }) => Container(
    color: isEven ? Colors.grey.shade50 : Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            no,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            detail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Inter',
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _totalRow(String label, String value, {bool highlight = false}) =>
      Container(
        color: highlight ? _darkNavy : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                  color: highlight ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(
              width: 110,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Inter',
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  color: highlight ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _note(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'InterThin',
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    ),
  );
}
