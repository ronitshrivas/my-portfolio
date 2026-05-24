// import 'package:flutter/material.dart';

// const _kBlue = Color(0xFF185FA5);
// const _kBlueMid = Color(0xFF378ADD);
// const _kText = Color(0xFF1C1C1E);
// const _kTextSub = Color(0xFF555555);
// const _kTextMuted = Color(0xFF8A8A8E);
// const _kSurface = Color(0xFFF7F8FA);
// const _kBg = Color(0xFFF2F4F7);
// const _kBorder = Color(0xFFE2E4E8);
// const _kCard = Color(0xFFFFFFFF);
// const _kGreen = Color(0xFF22A05B);
// const _kGreenSoft = Color(0xFFE8F8EE);

// class MyEarningsScreen extends StatefulWidget {
//   const MyEarningsScreen({super.key});

//   @override
//   State<MyEarningsScreen> createState() => _MyEarningsScreenState();
// }

// class _MyEarningsScreenState extends State<MyEarningsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabCtrl;

//   @override
//   void initState() {
//     super.initState();
//     _tabCtrl = TabController(length: 3, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _kBg,
//       body: CustomScrollView(
//         slivers: [
//           _buildSliverAppBar(context),
//           SliverToBoxAdapter(child: _buildStatsRow()),
//           SliverToBoxAdapter(child: _buildTabSection()),
//           SliverToBoxAdapter(child: _buildTransactionList()),
//           const SliverToBoxAdapter(child: SizedBox(height: 32)),
//         ],
//       ),
//     );
//   }

//   Widget _buildSliverAppBar(BuildContext context) {
//     return SliverAppBar(
//       expandedHeight: 220,
//       pinned: true,
//       backgroundColor: _kBlue,
//       leading: GestureDetector(
//         onTap: () => Navigator.pop(context),
//         child: Container(
//           margin: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
//         ),
//       ),
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [_kBlue, _kBlueMid],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Stack(
//             children: [
//               Positioned(
//                 top: -30,
//                 right: -40,
//                 child: Container(
//                   width: 160,
//                   height: 160,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.06),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: 20,
//                 left: -20,
//                 child: Container(
//                   width: 100,
//                   height: 100,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.05),
//                   ),
//                 ),
//               ),
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       const Text(
//                         'My Earnings',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           letterSpacing: 0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       const Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         children: [
//                           Text(
//                             'NPR 12,480',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 36,
//                               fontWeight: FontWeight.w800,
//                               letterSpacing: -1,
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Padding(
//                             padding: EdgeInsets.only(bottom: 5),
//                             child: _GrowthBadge(text: '+8.4%'),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Total lifetime earnings',
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.6),
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsRow() {
//     return Transform.translate(
//       offset: const Offset(0, -20),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
//           decoration: BoxDecoration(
//             color: _kCard,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.07),
//                 blurRadius: 14,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: const Row(
//             children: [
//               _StatCard(
//                 value: 'NPR 3,200',
//                 label: 'This Month',
//                 icon: Icons.calendar_month_rounded,
//                 iconColor: _kBlue,
//                 iconBg: Color(0xFFEBF3FF),
//               ),
//               _Divider(),
//               _StatCard(
//                 value: '24',
//                 label: 'Papers Sold',
//                 icon: Icons.article_rounded,
//                 iconColor: _kGreen,
//                 iconBg: _kGreenSoft,
//               ),
//               _Divider(),
//               _StatCard(
//                 value: 'NPR 540',
//                 label: 'Pending',
//                 icon: Icons.hourglass_top_rounded,
//                 iconColor: Color(0xFFE8A020),
//                 iconBg: Color(0xFFFFF7E6),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTabSection() {
//     return Transform.translate(
//       offset: const Offset(0, -10),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Container(
//           height: 40,
//           decoration: BoxDecoration(
//             color: _kSurface,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: _kBorder),
//           ),
//           child: TabBar(
//             controller: _tabCtrl,
//             onTap: (_) => setState(() {}),
//             indicator: BoxDecoration(
//               color: _kBlue,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             indicatorSize: TabBarIndicatorSize.tab,
//             dividerColor: Colors.transparent,
//             labelColor: Colors.white,
//             unselectedLabelColor: _kTextMuted,
//             labelStyle: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w600,
//             ),
//             unselectedLabelStyle: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w400,
//             ),
//             tabs: const [
//               Tab(text: 'All'),
//               Tab(text: 'Received'),
//               Tab(text: 'Pending'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTransactionList() {
//     final transactions = [
//       _Transaction(
//         title: 'Quantum Computing Basics',
//         date: 'May 4, 2026',
//         amount: 'NPR 450',
//         status: 'received',
//         buyer: 'Aarav S.',
//       ),
//       _Transaction(
//         title: 'ML in Healthcare',
//         date: 'May 3, 2026',
//         amount: 'NPR 320',
//         status: 'pending',
//         buyer: 'Priya M.',
//       ),
//       _Transaction(
//         title: 'Neural Networks Deep Dive',
//         date: 'May 2, 2026',
//         amount: 'NPR 580',
//         status: 'received',
//         buyer: 'Rohan K.',
//       ),
//       _Transaction(
//         title: 'Data Privacy Laws 2025',
//         date: 'May 1, 2026',
//         amount: 'NPR 200',
//         status: 'received',
//         buyer: 'Sneha T.',
//       ),
//       _Transaction(
//         title: 'Blockchain for Beginners',
//         date: 'Apr 29, 2026',
//         amount: 'NPR 340',
//         status: 'pending',
//         buyer: 'Bikash R.',
//       ),
//     ];

//     final filtered = _tabCtrl.index == 0
//         ? transactions
//         : transactions
//             .where(
//               (t) => _tabCtrl.index == 1
//                   ? t.status == 'received'
//                   : t.status == 'pending',
//             )
//             .toList();

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 8),
//           const Padding(
//             padding: EdgeInsets.only(bottom: 12),
//             child: Text(
//               'Recent Transactions',
//               style: TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w700,
//                 color: _kText,
//               ),
//             ),
//           ),
//           Container(
//             decoration: BoxDecoration(
//               color: _kCard,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: filtered.isEmpty
//                 ? const Padding(
//                     padding: EdgeInsets.all(32),
//                     child: Center(
//                       child: Text(
//                         'No transactions here',
//                         style: TextStyle(color: _kTextMuted, fontSize: 14),
//                       ),
//                     ),
//                   )
//                 : ListView.separated(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: filtered.length,
//                     separatorBuilder: (_, __) =>
//                         const Divider(height: 1, indent: 70),
//                     itemBuilder: (_, i) => _TransactionTile(t: filtered[i]),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Supporting Widgets ────────────────────────────────────────────────────────

// class _GrowthBadge extends StatelessWidget {
//   final String text;
//   const _GrowthBadge({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.18),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(Icons.trending_up_rounded, color: Colors.white, size: 13),
//           const SizedBox(width: 3),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatCard extends StatelessWidget {
//   final String value;
//   final String label;
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;

//   const _StatCard({
//     required this.value,
//     required this.label,
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Column(
//         children: [
//           Container(
//             width: 38,
//             height: 38,
//             decoration: BoxDecoration(
//               color: iconBg,
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Icon(icon, color: iconColor, size: 20),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 13,
//               fontWeight: FontWeight.w700,
//               color: _kText,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 3),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 11, color: _kTextMuted),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Divider extends StatelessWidget {
//   const _Divider();
//   @override
//   Widget build(BuildContext context) => Container(
//         width: 1,
//         height: 48,
//         color: _kBorder,
//       );
// }

// class _Transaction {
//   final String title;
//   final String date;
//   final String amount;
//   final String status;
//   final String buyer;
//   const _Transaction({
//     required this.title,
//     required this.date,
//     required this.amount,
//     required this.status,
//     required this.buyer,
//   });
// }

// class _TransactionTile extends StatelessWidget {
//   final _Transaction t;
//   const _TransactionTile({required this.t});

//   @override
//   Widget build(BuildContext context) {
//     final isReceived = t.status == 'received';
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//       child: Row(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: isReceived ? _kGreenSoft : const Color(0xFFFFF7E6),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(
//               isReceived
//                   ? Icons.arrow_downward_rounded
//                   : Icons.hourglass_top_rounded,
//               color: isReceived ? _kGreen : const Color(0xFFE8A020),
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   t.title,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: _kText,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   '${t.buyer} · ${t.date}',
//                   style: const TextStyle(fontSize: 12, color: _kTextMuted),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 t.amount,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                   color: isReceived ? _kGreen : const Color(0xFFE8A020),
//                 ),
//               ),
//               const SizedBox(height: 3),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: isReceived ? _kGreenSoft : const Color(0xFFFFF7E6),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   isReceived ? 'Received' : 'Pending',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.w600,
//                     color: isReceived ? _kGreen : const Color(0xFFE8A020),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

const _kBlue = Color(0xFF185FA5);
const _kBlueMid = Color(0xFF378ADD);
const _kText = Color(0xFF1C1C1E);
const _kTextMuted = Color(0xFF8A8A8E);
const _kSurface = Color(0xFFF7F8FA);
const _kBg = Color(0xFFF2F4F7);
const _kBorder = Color(0xFFE2E4E8);
const _kCard = Color(0xFFFFFFFF);
const _kGreen = Color(0xFF22A05B);
const _kGreenSoft = Color(0xFFE8F8EE);

class MyEarningsScreen extends StatelessWidget {
  const MyEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _kBlue,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              ),
            ),
            title: const Text(
              'My Earnings',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Container(
              color: _kBlue,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: const AtmEarningsCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const StatsRow(),
                    const SizedBox(height: 16),
                    const EarningsChartCard(),
                    const SizedBox(height: 16),
                    const TransactionListSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AtmEarningsCard extends StatelessWidget {
  const AtmEarningsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x3D185FA5), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(255, 255, 255, 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: 40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 200, 60, 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Icon(Icons.credit_card, color: Colors.white, size: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.trending_up_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '+8.4% this month',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Total Earnings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'NPR 12,480',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, size: 16, color: _kBlue),
                              SizedBox(width: 6),
                              Text(
                                'Withdraw to Wallet',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '•••• •••• ••••  8421',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Color.fromRGBO(255, 255, 255, 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: const Row(
        children: [
          EarningStatCard(
            value: 'NPR 3,200',
            label: 'This Month',
            icon: Icons.calendar_month_rounded,
            iconColor: _kBlue,
            iconBg: Color(0xFFEBF3FF),
          ),
          VerticalDividerLine(),
          EarningStatCard(
            value: '24',
            label: 'Papers Sold',
            icon: Icons.article_rounded,
            iconColor: _kGreen,
            iconBg: _kGreenSoft,
          ),
          VerticalDividerLine(),
          EarningStatCard(
            value: 'NPR 12,480',
            label: 'Total Earned',
            icon: Icons.wallet_rounded,
            iconColor: Color(0xFF7B2FBE),
            iconBg: Color(0xFFF3E8FF),
          ),
        ],
      ),
    );
  }
}

class EarningStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const EarningStatCard({
    super.key,
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
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: _kTextMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class VerticalDividerLine extends StatelessWidget {
  const VerticalDividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: _kBorder);
  }
}

class EarningsChartCard extends StatefulWidget {
  const EarningsChartCard({super.key});

  @override
  State<EarningsChartCard> createState() => _EarningsChartCardState();
}

class _EarningsChartCardState extends State<EarningsChartCard> {
  int? _hoveredIndex;

  final List<double> monthlyData = const [
    800, 1400, 1100, 2200, 1800, 2800, 3200, 2600, 3800, 4200, 5100, 6200,
  ];

  final List<String> months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Monthly Earnings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: const Text(
                  '2026',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'NPR 6,200 peak in December',
            style: TextStyle(fontSize: 12, color: Color.fromRGBO(34, 160, 91, 1)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final localPos = details.localPosition;
                final chartWidth = box.size.width - 32;
                final step = chartWidth / (monthlyData.length - 1);
                final index = (localPos.dx / step).round().clamp(0, monthlyData.length - 1);
                setState(() => _hoveredIndex = index);
              },
              child: CustomPaint(
                size: const Size(double.infinity, 160),
                painter: EarningsLinePainter(
                  data: monthlyData,
                  labels: months,
                  highlightIndex: _hoveredIndex,
                  lineColor: _kBlue,
                  gradientColors: [
                    Color.fromRGBO(24, 95, 165, 0.25),
                    Color.fromRGBO(24, 95, 165, 0.0),
                  ],
                ),
              ),
            ),
          ),
          if (_hoveredIndex != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${months[_hoveredIndex!]}  NPR ${NumberFormat('#,###').format(monthlyData[_hoveredIndex!].toInt())}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kBlue),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class EarningsLinePainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final int? highlightIndex;
  final Color lineColor;
  final List<Color> gradientColors;

  EarningsLinePainter({
    required this.data,
    required this.labels,
    required this.highlightIndex,
    required this.lineColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const double labelHeight = 20;
    const double topPadding = 12;
    final double chartHeight = size.height - labelHeight - topPadding;

    final double maxValue = data.reduce(max);
    final double minValue = data.reduce(min);
    final double range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    double xStep = (data.length > 1) ? size.width / (data.length - 1) : size.width;

    Offset getPoint(int i) {
      final x = i * xStep;
      final normalized = (data[i] - minValue) / range;
      final y = topPadding + chartHeight * (1 - normalized);
      return Offset(x, y);
    }

    final path = Path();
    path.moveTo(getPoint(0).dx, getPoint(0).dy);

    for (int i = 0; i < data.length - 1; i++) {
      final p1 = getPoint(i);
      final p2 = getPoint(i + 1);
      final cp1 = Offset(p1.dx + xStep * 0.35, p1.dy);
      final cp2 = Offset(p2.dx - xStep * 0.35, p2.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(getPoint(data.length - 1).dx, topPadding + chartHeight);
    fillPath.lineTo(0, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFE8EBF0)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = topPadding + chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i < data.length; i++) {
      final pt = getPoint(i);
      final isHighlighted = highlightIndex == i;

      if (isHighlighted) {
        final highlightLinePaint = Paint()
          ..color = const Color(0xFFCCDCF0)
          ..strokeWidth = 1;
        canvas.drawLine(Offset(pt.dx, topPadding), Offset(pt.dx, topPadding + chartHeight), highlightLinePaint);

        canvas.drawCircle(pt, 7, Paint()..color = Color.fromRGBO(24, 95, 165, 0.2));
        canvas.drawCircle(pt, 5, Paint()..color = Colors.white);
        canvas.drawCircle(pt, 5, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 2.5);
      } else if (i % 2 == 0) {
        canvas.drawCircle(pt, 3, Paint()..color = Colors.white);
        canvas.drawCircle(pt, 3, Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      if (i % 2 != 0 && i != labels.length - 1) continue;
      final pt = getPoint(i);

      labelPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          fontWeight: highlightIndex == i ? FontWeight.w700 : FontWeight.w400,
          color: highlightIndex == i ? lineColor : const Color(0xFF8A8A8E),
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(pt.dx - labelPainter.width / 2, topPadding + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(EarningsLinePainter oldDelegate) =>
      oldDelegate.highlightIndex != highlightIndex || oldDelegate.data != data;
}

class TransactionListSection extends StatelessWidget {
  const TransactionListSection({super.key});

  @override
  Widget build(BuildContext context) {
    const transactions = [
      ReceivedTransaction(
        title: 'Quantum Computing Basics',
        date: 'May 4, 2026',
        amount: 'NPR 450',
        buyer: 'Aarav S.',
      ),
      ReceivedTransaction(
        title: 'Neural Networks Deep Dive',
        date: 'May 2, 2026',
        amount: 'NPR 580',
        buyer: 'Rohan K.',
      ),
      ReceivedTransaction(
        title: 'Data Privacy Laws 2025',
        date: 'May 1, 2026',
        amount: 'NPR 200',
        buyer: 'Sneha T.',
      ),
      ReceivedTransaction(
        title: 'Blockchain Architecture',
        date: 'Apr 27, 2026',
        amount: 'NPR 340',
        buyer: 'Bikash R.',
      ),
      ReceivedTransaction(
        title: 'Computer Vision Fundamentals',
        date: 'Apr 24, 2026',
        amount: 'NPR 620',
        buyer: 'Priya M.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Received Payments',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
            itemBuilder: (_, i) => TransactionTile(transaction: transactions[i]),
          ),
        ),
      ],
    );
  }
}

class ReceivedTransaction {
  final String title;
  final String date;
  final String amount;
  final String buyer;

  const ReceivedTransaction({
    required this.title,
    required this.date,
    required this.amount,
    required this.buyer,
  });
}

class TransactionTile extends StatelessWidget {
  final ReceivedTransaction transaction;

  const TransactionTile({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kGreenSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_downward_rounded, color: _kGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText),
                ),
                const SizedBox(height: 3),
                Text(
                  '${transaction.buyer} · ${transaction.date}',
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
                transaction.amount,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kGreen),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _kGreenSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Received',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NumberFormat {
  final String pattern;
  const NumberFormat(this.pattern);
  String format(num value) {
    final str = value.toInt().toString();
    final result = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(str[i]);
      count++;
    }
    return result.toString().split('').reversed.join();
  }
}