import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart'; 
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_shared_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CoordinatorInvoiceScreen extends ConsumerStatefulWidget {
  const CoordinatorInvoiceScreen({super.key});

  @override
  ConsumerState<CoordinatorInvoiceScreen> createState() =>
      _CoordinatorInvoiceScreenState();
}

class _CoordinatorInvoiceScreenState
    extends ConsumerState<CoordinatorInvoiceScreen> {
  DateTime? _selectedDate;
  int _visibleCount = 3;

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppStyle.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  List<CoordinatorInvoiceModel> _filtered(
      List<CoordinatorInvoiceModel> invoices) {
    final sorted = [...invoices]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_selectedDate == null) return sorted;
    return sorted.where((inv) {
      final d = inv.createdAt;
      return d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(coordinatorInvoicesProvider);

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
          'Invoices',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _selectedDate != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: _selectedDate != null
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
                        color: _selectedDate != null
                            ? AppStyle.primaryColor
                            : Colors.white,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDate = null),
                        child: Icon(Icons.close_rounded,
                            size: 13, color: AppStyle.primaryColor),
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
                    : 'All invoices',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontFamily: 'Inter',
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
              child: invoicesAsync.when(
                loading: () => _buildSkeleton(),
                error: (e, _) => Center(
                  child: CoordinatorErrorBox(error: e)
                ),
                data: (invoices) {
                  final filtered = _filtered(invoices);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _selectedDate != null
                                ? 'No invoices for this date'
                                : 'No invoices yet',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.grey.shade400,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  final visible = filtered.take(_visibleCount).toList();
                  final hasMore = _visibleCount < filtered.length;

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: visible.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == visible.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _visibleCount += 3),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppStyle.primaryColor
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Load more  (${filtered.length - _visibleCount} remaining)',
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
                      return _InvoiceCard(invoice: visible[i]);
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

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, i) => _SkeletonCard(index: i),
    );
  }
}

//  Skeleton 

class _SkeletonCard extends StatefulWidget {
  final int index;
  const _SkeletonCard({required this.index});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
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
      builder: (_, __) => Opacity(
        opacity: 0.3 + 0.4 * _ctrl.value,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_box(140, 14), _box(60, 24, radius: 12)],
              ),
              const SizedBox(height: 12),
              _box(double.infinity, 10),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [_box(80, 32), _box(80, 32), _box(80, 32)],
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
            borderRadius: BorderRadius.circular(radius)),
      );
}

//  Invoice Card 

class _InvoiceCard extends StatelessWidget {
  final CoordinatorInvoiceModel invoice;
  const _InvoiceCard({required this.invoice});

  String _fmt(double v) => v.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CoordinatorInvoiceDetailScreen(invoice: invoice)),
      ),
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
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        invoice.description,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  _StatusBadge(invoice: invoice),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                      label: 'Total',
                      value: 'Rs. ${_fmt(invoice.totalAmount)}',
                      color: Colors.black87),
                  _Stat(
                      label: 'Paid',
                      value: 'Rs. ${_fmt(invoice.paidAmount)}',
                      color: Colors.green.shade600),
                  _Stat(
                      label: 'Due',
                      value: 'Rs. ${_fmt(invoice.dueAmount)}',
                      color: Colors.red.shade400,
                      isBold: true),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    'Due: ${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                    style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        color: Colors.grey.shade400),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text('View invoice',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade400)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _Stat(
      {required this.label,
      required this.value,
      required this.color,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontFamily: 'Inter')),
      const SizedBox(height: 3),
      Text(value,
          style: TextStyle(
              fontSize: 13,
              color: color,
              fontFamily: 'Inter',
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}

class _StatusBadge extends StatelessWidget {
  final CoordinatorInvoiceModel invoice;
  const _StatusBadge({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: invoice.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: invoice.statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: invoice.statusColor),
        ),
        const SizedBox(width: 6),
        Text(
          invoice.statusLabel,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: invoice.statusColor,
          ),
        ),
      ]),
    );
  }
}

//  Invoice Detail Screen 

class CoordinatorInvoiceDetailScreen extends StatefulWidget {
  final CoordinatorInvoiceModel invoice;
  const CoordinatorInvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<CoordinatorInvoiceDetailScreen> createState() =>
      _CoordinatorInvoiceDetailScreenState();
}

class _CoordinatorInvoiceDetailScreenState
    extends State<CoordinatorInvoiceDetailScreen> {
  final GlobalKey _invoiceKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  static const _darkNavy = Color(0xFF1B2A4A);

  String _fmt(double v) => v.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');

  Future<Uint8List?> _capture() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final boundary = _invoiceKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Failed to capture');

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
          '${dir.path}/invoice_${widget.invoice.invoiceNumber.replaceAll('/', '_')}.png');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Invoice saved to Downloads!',
                  style: TextStyle(fontFamily: 'Inter')),
            ]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e',
                style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
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
      if (bytes == null) throw Exception('Failed to capture');

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/invoice_${widget.invoice.invoiceNumber.replaceAll('/', '_')}.png');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Invoice ${widget.invoice.invoiceNumber}\nDue: Rs. ${_fmt(widget.invoice.dueAmount)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e',
                style: const TextStyle(fontFamily: 'Inter')),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Invoice',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _isSharing ? null : _share,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _isSharing
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppStyle.primaryColor, strokeWidth: 2))
                    : Row(children: [
                        Icon(Icons.share_rounded,
                            color: AppStyle.primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text('Share',
                            style: TextStyle(
                                color: AppStyle.primaryColor,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _isDownloading ? null : _download,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(children: [
                        Icon(Icons.download_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Download',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ]),
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
                  //  Header 
                  Container(
                    width: double.infinity,
                    color: _darkNavy,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/kms/nepatronix.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('INVOICE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            const SizedBox(height: 10),
                            _meta('Invoice No', inv.invoiceNumber),
                            const SizedBox(height: 4),
                            _meta('Issue Date',
                                '${inv.issueDate.day}/${inv.issueDate.month}/${inv.issueDate.year}'),
                            const SizedBox(height: 4),
                            _meta('Due Date',
                                '${inv.dueDate.day}/${inv.dueDate.month}/${inv.dueDate.year}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  //  Status row 
                  Container(
                    color: const Color(0xFFF5F7FA),
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoLabel('Status'),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: inv.statusColor
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  inv.statusLabel,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: inv.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoLabel('Description'),
                              const SizedBox(height: 6),
                              _infoValue(inv.description),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //  Table 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Container(
                          color: _darkNavy,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          child: Row(children: [
                            _th('Description', flex: 4),
                            _th('Amount',
                                flex: 3, align: TextAlign.right),
                          ]),
                        ),
                        _tr('Total Amount',
                            'Rs. ${_fmt(inv.totalAmount)}', false),
                        _tr('Paid Amount',
                            'Rs. ${_fmt(inv.paidAmount)}', true),
                        const SizedBox(height: 4),
                        _totalRow('Due Amount',
                            'Rs. ${_fmt(inv.dueAmount)}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //  Dashed divider 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: List.generate(
                        48,
                        (i) => Expanded(
                          child: Container(
                            height: 1,
                            color: i.isEven
                                ? Colors.grey.shade400
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  //  Notes 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes :',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        _note(inv.description),
                        _note(
                            'Payment due by ${inv.dueDate.day}/${inv.dueDate.month}/${inv.dueDate.year}.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  //  Footer 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Colors.grey.shade200)),
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

  Widget _meta(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label  :  ',
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600)),
        ],
      );

  Widget _infoLabel(String t) => Text(t,
      style: TextStyle(
          fontSize: 11,
          fontFamily: 'Inter',
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600));

  Widget _infoValue(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13, fontFamily: 'Inter', color: Colors.black87));

  Widget _th(String text, {int flex = 1, TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Text(text,
            textAlign: align,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
                fontSize: 12)),
      );

  Widget _tr(String desc, String amount, bool isEven) => Container(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(
              flex: 4,
              child: Text(desc,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.black87))),
          Expanded(
              flex: 3,
              child: Text(amount,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: Colors.black87))),
        ]),
      );

  Widget _totalRow(String label, String value) => Container(
        color: _darkNavy,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(children: [
          const Spacer(),
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          SizedBox(
            width: 110,
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ]),
      );

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Colors.grey.shade600)),
            ),
          ],
        ),
      );
}