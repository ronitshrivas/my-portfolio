import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:innovator/research/core/constants/pdf_cache.dart';
import 'package:innovator/research/model/research_model.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const _kBlue = Color(0xFF185FA5);
const _kOrange = Color(0xFFF48706);
const _kText = Color(0xFF1C1C1E);
const _kTextMuted = Color(0xFF8A8A8E);
const _kBorder = Color(0xFFE2E4E8);
const _kSurface = Color(0xFFF7F8FA);
const _kShimmerBase = Color(0xFFF0F0F0);
const _kShimmerHigh = Color(0xFFE4E4E4);

class ResearchGridCard extends StatelessWidget {
  final ResearchPaperModel paper;
  final String pdfUrl;

  const ResearchGridCard({super.key, required this.paper, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: PdfFirstPagePreview(pdfUrl: pdfUrl),
          ),
          Expanded(
            flex: 4,
            child: CardInfoSection(paper: paper),
          ),
        ],
      ),
    );
  }
}

class PdfFirstPagePreview extends StatefulWidget {
  final String pdfUrl;

  const PdfFirstPagePreview({super.key, required this.pdfUrl});

  @override
  State<PdfFirstPagePreview> createState() => _PdfFirstPagePreviewState();
}

class _PdfFirstPagePreviewState extends State<PdfFirstPagePreview> {
  late final Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = PdfBytesCache.fetch(widget.pdfUrl);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PdfShimmerPlaceholder();
        }

        if (snapshot.data == null) {
          return const PdfErrorPlaceholder();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: SfPdfViewer.memory(
                  snapshot.data!,
                  canShowScrollHead: false,
                  canShowScrollStatus: false,
                  enableDoubleTapZooming: false,
                  pageSpacing: 0,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0, 0, 0, 0.45),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'PDF',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PdfShimmerPlaceholder extends StatefulWidget {
  const PdfShimmerPlaceholder({super.key});

  @override
  State<PdfShimmerPlaceholder> createState() => _PdfShimmerPlaceholderState();
}

class _PdfShimmerPlaceholderState extends State<PdfShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
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
      builder: (_, __) {
        final color = Color.lerp(_kShimmerBase, _kShimmerHigh, _ctrl.value)!;
        return Container(
          color: color,
          child: Center(
            child: Icon(
              Icons.picture_as_pdf_rounded,
              size: 28,
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ),
        );
      },
    );
  }
}

class PdfErrorPlaceholder extends StatelessWidget {
  const PdfErrorPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_rounded, size: 28, color: _kTextMuted),
          SizedBox(height: 5),
          Text('Preview unavailable', style: TextStyle(fontSize: 10, color: _kTextMuted)),
        ],
      ),
    );
  }
}

class CardInfoSection extends StatelessWidget {
  final ResearchPaperModel paper;

  const CardInfoSection({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PaperTypeBadge(label: paper.type.toUpperCase(), color: _kBlue),
              if (paper.isPaid) ...[
                const SizedBox(width: 4),
                PaperTypeBadge(
                  label: 'Rs. ${paper.price.toInt()}',
                  color: _kOrange,
                ),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              paper.title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _kText,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            DateFormat('MMM d, yyyy').format(paper.createdAt),
            style: const TextStyle(fontSize: 10, color: _kTextMuted),
          ),
        ],
      ),
    );
  }
}

class PaperTypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const PaperTypeBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}