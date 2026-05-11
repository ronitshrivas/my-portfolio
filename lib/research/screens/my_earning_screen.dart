import 'package:flutter/material.dart';

const _kBlue = Color(0xFF185FA5);
const _kBlueMid = Color(0xFF378ADD);
const _kText = Color(0xFF1C1C1E);
const _kTextSub = Color(0xFF555555);
const _kTextMuted = Color(0xFF8A8A8E);
const _kSurface = Color(0xFFF7F8FA);
const _kBg = Color(0xFFF2F4F7);
const _kBorder = Color(0xFFE2E4E8);
const _kCard = Color(0xFFFFFFFF);
const _kGreen = Color(0xFF22A05B);
const _kGreenSoft = Color(0xFFE8F8EE);

class MyEarningsScreen extends StatefulWidget {
  const MyEarningsScreen({super.key});

  @override
  State<MyEarningsScreen> createState() => _MyEarningsScreenState();
}

class _MyEarningsScreenState extends State<MyEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildTabSection()),
          SliverToBoxAdapter(child: _buildTransactionList()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: _kBlue,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kBlue, _kBlueMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'My Earnings',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'NPR 12,480',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(width: 10),
                          Padding(
                            padding: EdgeInsets.only(bottom: 5),
                            child: _GrowthBadge(text: '+8.4%'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total lifetime earnings',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              _StatCard(
                value: 'NPR 3,200',
                label: 'This Month',
                icon: Icons.calendar_month_rounded,
                iconColor: _kBlue,
                iconBg: Color(0xFFEBF3FF),
              ),
              _Divider(),
              _StatCard(
                value: '24',
                label: 'Papers Sold',
                icon: Icons.article_rounded,
                iconColor: _kGreen,
                iconBg: _kGreenSoft,
              ),
              _Divider(),
              _StatCard(
                value: 'NPR 540',
                label: 'Pending',
                icon: Icons.hourglass_top_rounded,
                iconColor: Color(0xFFE8A020),
                iconBg: Color(0xFFFFF7E6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Transform.translate(
      offset: const Offset(0, -10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: TabBar(
            controller: _tabCtrl,
            onTap: (_) => setState(() {}),
            indicator: BoxDecoration(
              color: _kBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: _kTextMuted,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Received'),
              Tab(text: 'Pending'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = [
      _Transaction(
        title: 'Quantum Computing Basics',
        date: 'May 4, 2026',
        amount: 'NPR 450',
        status: 'received',
        buyer: 'Aarav S.',
      ),
      _Transaction(
        title: 'ML in Healthcare',
        date: 'May 3, 2026',
        amount: 'NPR 320',
        status: 'pending',
        buyer: 'Priya M.',
      ),
      _Transaction(
        title: 'Neural Networks Deep Dive',
        date: 'May 2, 2026',
        amount: 'NPR 580',
        status: 'received',
        buyer: 'Rohan K.',
      ),
      _Transaction(
        title: 'Data Privacy Laws 2025',
        date: 'May 1, 2026',
        amount: 'NPR 200',
        status: 'received',
        buyer: 'Sneha T.',
      ),
      _Transaction(
        title: 'Blockchain for Beginners',
        date: 'Apr 29, 2026',
        amount: 'NPR 340',
        status: 'pending',
        buyer: 'Bikash R.',
      ),
    ];

    final filtered = _tabCtrl.index == 0
        ? transactions
        : transactions
            .where(
              (t) => _tabCtrl.index == 1
                  ? t.status == 'received'
                  : t.status == 'pending',
            )
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No transactions here',
                        style: TextStyle(color: _kTextMuted, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) => _TransactionTile(t: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _GrowthBadge extends StatelessWidget {
  final String text;
  const _GrowthBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 13),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _kTextMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: _kBorder,
      );
}

class _Transaction {
  final String title;
  final String date;
  final String amount;
  final String status;
  final String buyer;
  const _Transaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.status,
    required this.buyer,
  });
}

class _TransactionTile extends StatelessWidget {
  final _Transaction t;
  const _TransactionTile({required this.t});

  @override
  Widget build(BuildContext context) {
    final isReceived = t.status == 'received';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isReceived ? _kGreenSoft : const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isReceived
                  ? Icons.arrow_downward_rounded
                  : Icons.hourglass_top_rounded,
              color: isReceived ? _kGreen : const Color(0xFFE8A020),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${t.buyer} · ${t.date}',
                  style: const TextStyle(fontSize: 12, color: _kTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isReceived ? _kGreen : const Color(0xFFE8A020),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isReceived ? _kGreenSoft : const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isReceived ? 'Received' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isReceived ? _kGreen : const Color(0xFFE8A020),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}