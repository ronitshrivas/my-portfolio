import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/research/core/constants/api_constants.dart';
import 'package:innovator/research/core/constants/pdf_cache.dart';
import 'package:innovator/research/core/widget/research_detail_skeleton.dart';
import 'package:innovator/research/model/research_detail_model.dart';
import 'package:innovator/research/provider/research_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

const _kBlue = Color(0xFF185FA5);
const _kBlueMid = Color(0xFF378ADD);
const _kBlueSoft = Color(0xFFE8F1FB);
const _kOrange = Color(0xFFF48706);
const _kOrangeSoft = Color(0xFFFFF3E0);
const _kGreen = Color(0xFF2E7D32);
const _kGreenSoft = Color(0xFFE8F5E9);
const _kRed = Color(0xFFA32D2D);
const _kRedSoft = Color(0xFFFCEBEB);
const _kText = Color(0xFF1C1C1E);
const _kTextSub = Color(0xFF555555);
const _kTextMuted = Color(0xFF8A8A8E);
const _kSurface = Color(0xFFF7F8FA);
const _kBg = Color(0xFFF2F4F7);
const _kBorder = Color(0xFFE2E4E8);
const _kCard = Color(0xFFFFFFFF);

class ResearchDetailScreen extends ConsumerWidget {
  const ResearchDetailScreen({super.key, required this.paperId});

  final int paperId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(researchDetailProvider(paperId));

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: _kCard,
        elevation: 0,
        leading:
            Navigator.canPop(context)
                ? Container(
                  margin: const EdgeInsets.only(
                    left: 16,
                    top: 10,
                    bottom: 10,
                    right: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                )
                : null,
        title: const Text(
          'Paper Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kText,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _kBorder),
        ),
        actions: [
          if (state.data != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: IconButton(
                onPressed:
                    () =>
                        ref
                            .read(researchDetailProvider(paperId).notifier)
                            .refresh(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: _kTextMuted,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ResearchDetailState state,
  ) {
    if (state.isLoading && state.data == null) {
      return const ResearchDetailSkeleton();
    }

    if (state.error != null && state.data == null) {
      return RefreshIndicator(
        onRefresh:
            () => ref.read(researchDetailProvider(paperId).notifier).refresh(),
        color: _kBlue,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: DetailErrorView(
              message: state.error!,
              onRetry:
                  () =>
                      ref
                          .read(researchDetailProvider(paperId).notifier)
                          .refresh(),
            ),
          ),
        ),
      );
    }

    final detail = state.data!;

    return RefreshIndicator(
      onRefresh:
          () => ref.read(researchDetailProvider(paperId).notifier).refresh(),
      color: _kBlue,
      strokeWidth: 2.5,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          HeaderCard(paper: detail.paper),
          const SizedBox(height: 12),
          if (detail.paper.description != null &&
              detail.paper.description!.isNotEmpty) ...[
            DescriptionCard(description: detail.paper.description!),
            const SizedBox(height: 12),
          ],
          DetailsCard(paper: detail.paper),
          const SizedBox(height: 12),
          ResearcherCard(researchers: detail.researchers),
          const SizedBox(height: 12),
          ActionButton(paper: detail.paper),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class HeaderCard extends StatelessWidget {
  final ResearchPaperDetailModel paper;

  const HeaderCard({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kBlueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  size: 26,
                  color: _kBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paper.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      paper.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kTextMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusBadge(
                label: paper.type == 'paid' ? 'Paid' : 'Free',
                bgColor: paper.type == 'paid' ? _kOrangeSoft : _kGreenSoft,
                textColor: paper.type == 'paid' ? _kOrange : _kGreen,
                icon:
                    paper.type == 'paid'
                        ? Icons.attach_money_rounded
                        : Icons.lock_open_rounded,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: _capitalize(paper.status),
                bgColor: paper.status == 'active' ? _kGreenSoft : _kBlueSoft,
                textColor: paper.status == 'active' ? _kGreen : _kBlueMid,
                icon:
                    paper.status == 'active'
                        ? Icons.check_circle_outline_rounded
                        : Icons.hourglass_top_rounded,
              ),
              if (paper.type == 'paid' && paper.price != null) ...[
                const Spacer(),
                Text(
                  'Rs. ${paper.price!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kOrange,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class DescriptionCard extends StatelessWidget {
  final String description;

  const DescriptionCard({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: _kTextSub, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class DetailsCard extends StatelessWidget {
  final ResearchPaperDetailModel paper;

  const DetailsCard({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 14),
          DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Uploaded',
            value: _formatDate(paper.createdAt),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(height: 0.5, color: _kBorder),
          ),
          DetailRow(
            icon: Icons.update_rounded,
            label: 'Last Updated',
            value: _formatDate(paper.updatedAt),
          ),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = _kText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _kTextMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: _kTextMuted)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class ResearcherCard extends StatelessWidget {
  final List<ResearcherModel> researchers;

  const ResearcherCard({super.key, required this.researchers});

  @override
  Widget build(BuildContext context) {
    if (researchers.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Researchers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kBlueSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${researchers.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kBlueMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < researchers.length; i++) ...[
            ResearcherRow(researcher: researchers[i]),
            if (i < researchers.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(height: 0.5, color: _kBorder),
              ),
          ],
        ],
      ),
    );
  }
}

class ResearcherRow extends StatelessWidget {
  final ResearcherModel researcher;

  const ResearcherRow({super.key, required this.researcher});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _kSurface,
          child: Text(
            researcher.name.isNotEmpty ? researcher.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kBlue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            researcher.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _kText,
            ),
          ),
        ),
        if (researcher.profilePdfUrl != null)
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PDFViewer(
                          url: researcher.profilePdfUrl!,
                          title: researcher.name,
                        ),
                  ),
                ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kBlueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 14,
                    color: _kBlueMid,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kBlueMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final ResearchPaperDetailModel paper;

  const ActionButton({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    final isPaid = paper.type == 'paid';

    return GestureDetector(
      onTap: () {
        if (!isPaid) {
          final fullUrl =
              paper.fileUrl.startsWith('http')
                  ? paper.fileUrl
                  : '${ResearchApi.baseUrl}${paper.fileUrl}';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PDFViewer(url: fullUrl, title: paper.title),
            ),
          );
        } else {
          // Khalti payment logic here
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPaid ? _kOrange : _kBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPaid
                  ? Icons.shopping_cart_rounded
                  : Icons.picture_as_pdf_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isPaid
                  ? 'Buy & Read — Rs. ${paper.price!.toStringAsFixed(0)}'
                  : 'Read Paper',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const DetailErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kRedSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Unable to load paper details.\nPull down to refresh or tap retry.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _kTextMuted, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Try Again',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewer extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewer({super.key, required this.url, required this.title});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  late final Future<Uint8List?> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = PdfBytesCache.fetch(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: FutureBuilder<Uint8List?>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
                  SizedBox(height: 14),
                  Text(
                    'Loading PDF...',
                    style: TextStyle(fontSize: 14, color: _kTextMuted),
                  ),
                ],
              ),
            );
          }

          if (snapshot.data == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 40, color: _kTextMuted),
                  SizedBox(height: 10),
                  Text(
                    'Failed to load PDF',
                    style: TextStyle(fontSize: 14, color: _kTextMuted),
                  ),
                ],
              ),
            );
          }

          return SfPdfViewer.memory(snapshot.data!);
        },
      ),
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _formatDate(DateTime dt) {
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
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
