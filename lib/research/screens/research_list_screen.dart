import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/research/core/widget/research_card.dart';
import 'package:innovator/research/core/widget/research_card_skeleton.dart';
import 'package:innovator/research/provider/research_provider.dart';
import 'package:innovator/research/screens/get_research_paper_byId.dart';
import 'package:innovator/research/screens/my_earning_screen.dart';
import 'package:innovator/research/screens/upload_research_paper.dart';

const _kBlue = Color(0xFF185FA5);
const _kBlueMid = Color(0xFF378ADD);
const _kRed = Color(0xFFA32D2D);
const _kRedSoft = Color(0xFFFCEBEB);
const _kText = Color(0xFF1C1C1E);
const _kTextSub = Color(0xFF555555);
const _kTextMuted = Color(0xFF8A8A8E);
const _kSurface = Color(0xFFF7F8FA);
const _kBg = Color(0xFFF2F4F7);
const _kBorder = Color(0xFFE2E4E8);
const _kCard = Color(0xFFFFFFFF);

class ResearchListScreen extends ConsumerStatefulWidget {
  const ResearchListScreen({super.key});

  @override
  ConsumerState<ResearchListScreen> createState() => _ResearchListScreenState();
}

class _ResearchListScreenState extends ConsumerState<ResearchListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  String? _selType;
  String? _selStatus;
  bool _isLoadMoreScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  Future<void> _openDetail(int paperId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResearchDetailScreen(paperId: paperId)),
    );
    if (mounted) {
      ref.read(researchListProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadMoreScheduled) return;
    if (_scrollCtrl.position.pixels <
        _scrollCtrl.position.maxScrollExtent - 200)
      return;

    _isLoadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(researchListProvider.notifier).loadMore();
      }
      _isLoadMoreScheduled = false;
    });
  }

  Future<void> _refresh() async {
    _isLoadMoreScheduled = false;
    return ref.read(researchListProvider.notifier).refresh();
  }

  void _applyFilters() {
    ref
        .read(researchListProvider.notifier)
        .applyFilter(
          ResearchFilter(
            search:
                _searchCtrl.text.trim().isEmpty
                    ? null
                    : _searchCtrl.text.trim(),
            type: _selType,
            status: _selStatus,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(researchListProvider);

    return SafeArea(
      top: false,
      child: Scaffold(
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
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  )
                  : null,
          title: const Text(
            'Research Papers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          centerTitle: true,
           actions: [
    GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyEarningsScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kBlue, _kBlueMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'R',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(height: 0.5, color: _kBorder),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: _kCard,
              child: _SearchFilterBar(
                searchCtrl: _searchCtrl,
                selType: _selType,
                selStatus: _selStatus,
                onTypeChanged: (v) {
                  setState(() => _selType = v);
                  _applyFilters();
                },
                onStatusChanged: (v) {
                  setState(() => _selStatus = v);
                  _applyFilters();
                },
                onSearchSubmitted: (_) => _applyFilters(),
                onSearchCleared: () {
                  _searchCtrl.clear();
                  _applyFilters();
                },
              ),
            ),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ResearchListState state) {
    // if (state.isLoading && state.papers.isEmpty) {
    //   return const Center(
    //     child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2.5),
    //   );
    // }

    if (state.isLoading && state.papers.isEmpty) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        itemCount: 6,
        itemBuilder: (_, __) => const ResearchCardSkeleton(),
      );
    }

    if (state.error != null && state.papers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: _kBlue,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _ErrorView(message: state.error!, onRetry: _refresh),
          ),
        ),
      );
    }

    if (state.papers.isEmpty) {
      final hasFilters =
          _selType != null || _selStatus != null || _searchCtrl.text.isNotEmpty;

      return RefreshIndicator(
        onRefresh: _refresh,
        color: _kBlue,
        strokeWidth: 2.5,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _EmptyView(
              hasFilters: hasFilters,
              onUpload: () => UploadResearchPaperSheet.show(context),
              onClearFilters: () {
                setState(() {
                  _selType = null;
                  _selStatus = null;
                  _searchCtrl.clear();
                });
                _applyFilters();
              },
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: _kBlue,
      strokeWidth: 2.5,
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        itemCount: state.papers.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == state.papers.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: _kBlue, strokeWidth: 2),
              ),
            );
          }
          return GestureDetector(
            // onTap: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder:
            //           (_) => ResearchDetailScreen(paperId: state.papers[i].id),
            //     ),
            //   );
            // },
            onTap: () => _openDetail(state.papers[i].id),
            child: ResearchPaperCard(paper: state.papers[i]),
          );
        },
      ),
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final String? selType;
  final String? selStatus;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;

  const _SearchFilterBar({
    required this.searchCtrl,
    required this.selType,
    required this.selStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onSubmitted: onSearchSubmitted,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: _kText),
            decoration: InputDecoration(
              hintText: 'Search papers...',
              hintStyle: const TextStyle(fontSize: 14, color: _kTextMuted),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: _kTextMuted,
              ),
              suffixIcon:
                  searchCtrl.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 18,
                          color: _kTextMuted,
                        ),
                        onPressed: onSearchCleared,
                      )
                      : null,
              filled: true,
              fillColor: _kSurface,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kBlueMid, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _Chip(
                  label: 'All',
                  selected: selType == null && selStatus == null,
                  onTap: () {
                    onTypeChanged(null);
                    onStatusChanged(null);
                  },
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Free',
                  selected: selType == 'free',
                  onTap: () => onTypeChanged(selType == 'free' ? null : 'free'),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Paid',
                  selected: selType == 'paid',
                  onTap: () => onTypeChanged(selType == 'paid' ? null : 'paid'),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: _kBorder),
                const SizedBox(width: 12),
                _Chip(
                  label: 'Active',
                  selected: selStatus == 'active',
                  onTap:
                      () => onStatusChanged(
                        selStatus == 'active' ? null : 'active',
                      ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'Pending',
                  selected: selStatus == 'pending',
                  onTap:
                      () => onStatusChanged(
                        selStatus == 'pending' ? null : 'pending',
                      ),
                ),

                _Chip(
                  label: "Upload",
                  selected: selType == 'upload',
                  onTap: () => UploadResearchPaperSheet.show(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? Color.fromRGBO(244, 135, 6, 1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Color.fromRGBO(244, 135, 6, 1) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : _kTextMuted,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

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
              'Unable to load research papers.\nPull down to refresh or tap retry.',
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

class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onUpload;
  final VoidCallback onClearFilters;

  const _EmptyView({
    required this.hasFilters,
    required this.onUpload,
    required this.onClearFilters,
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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBorder),
              ),
              child: Icon(
                hasFilters ? Icons.search_off_rounded : Icons.article_outlined,
                size: 36,
                color: _kTextMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'No results found' : 'No research papers yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Try clearing your filters or search query.'
                  : 'Be the first to upload a research paper.\nPull down to refresh.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _kTextMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: hasFilters ? onClearFilters : onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      hasFilters
                          ? Colors.transparent
                          : Color.fromRGBO(244, 135, 6, 1),
                  borderRadius: BorderRadius.circular(10),
                  border: hasFilters ? Border.all(color: _kBorder) : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFilters
                          ? Icons.filter_alt_off_rounded
                          : Icons.upload_file_rounded,
                      size: 18,
                      color: hasFilters ? _kTextSub : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasFilters ? 'Clear Filters' : 'Upload Paper',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasFilters ? _kTextSub : Colors.white,
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
