import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_notes_model.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_shared_widget.dart';

final _sessionFilterProvider = StateProvider<String>((ref) => 'ALL');

class CoordinatorSessionsScreen extends ConsumerWidget {
  const CoordinatorSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(teacherSessionsProvider);

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
          'Teaching Logs',
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
              onTap: () => ref.refresh(teacherSessionsProvider),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded,
                    size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          sessionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  CoordinatorMiniStat(
                      label: 'Total',
                      value: '${data.totalSessions}',
                      color: Colors.white),
                  const SizedBox(width: 10),
                  CoordinatorMiniStat(
                      label: 'Teachers',
                      value:
                          '${data.sessions!.map((s) => s.teacherId).toSet().length}',
                      color: Colors.amberAccent.shade100),
                  const SizedBox(width: 10),
                  CoordinatorMiniStat(
                      label: 'Students',
                      value:
                          '${data.sessions!.fold(0, (sum, s) => sum + s.studentCount!)}',
                      color: Colors.greenAccent.shade200),
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
                    child: _SessionFilterChips(),
                  ),
                  const SizedBox(height: 14),

                  Expanded(
                    child: sessionsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: CoordinatorErrorBox(error: e)
                      ),
                      data: (data) {
                        if (data.sessions!.isEmpty) {
                          return const CoordinatorEmptyState(
                            icon: Icons.menu_book_rounded,
                            message: 'No teaching logs yet',
                          );
                        }

                        return ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: data.sessions!.length,
                          itemBuilder: (context, i) {
                            final session = data.sessions![i];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CoordinatorSessionDetailScreen(
                                          session: session),
                                ),
                              ),
                              child: _SessionListTile(session: session),
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

// ─── Filter chips ─────────────────────────────────────────────────────────────

class _SessionFilterChips extends ConsumerWidget {
  const _SessionFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(_sessionFilterProvider);
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
              onTap: () =>
                  ref.read(_sessionFilterProvider.notifier).state = f,
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
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade600,
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

// ─── Session list tile ────────────────────────────────────────────────────────

class _SessionListTile extends StatelessWidget {
  final TeacherSessionModel session;
  const _SessionListTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppStyle.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.menu_book_rounded,
                color: AppStyle.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.teacherName ?? 'Unknown Teacher',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        color: Colors.black87)),
                Text(session.classroomName ?? 'Unknown Classroom',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontFamily: 'Inter')),
                const SizedBox(height: 4),
                Text(
                  session.notes ?? 'No notes available',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontFamily: 'Inter'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(session.date ?? 'No Date',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                      fontFamily: 'Inter')),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppStyle.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${session.studentCount} students',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppStyle.primaryColor,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: Colors.grey.shade300),
        ],
      ),
    );
  }
}

// ─── Session Detail Screen ────────────────────────────────────────────────────

class CoordinatorSessionDetailScreen extends ConsumerStatefulWidget {
  final TeacherSessionModel session;
  const CoordinatorSessionDetailScreen(
      {super.key, required this.session});

  @override
  ConsumerState<CoordinatorSessionDetailScreen> createState() =>
      _CoordinatorSessionDetailScreenState();
}

class _CoordinatorSessionDetailScreenState
    extends ConsumerState<CoordinatorSessionDetailScreen> {
  bool _isLoading = false;
  bool _acted = false;
  bool _approved = false;

  Future<void> _verify(String action, {String? coordinatorNotes}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(
        verifySessionProvider({
          'teacherId': widget.session.teacherId,
          'classroomId': widget.session.classroomId,
          'date': widget.session.date,
          'notes': widget.session.notes,
          'action': action,
          'coordinatorNotes': coordinatorNotes,
        }).future,
      );
      setState(() {
        _acted = true;
        _approved = action == 'approve';
      });
      if (mounted) {
        ref.refresh(teacherSessionsProvider);
        _snack(
          action == 'approve' ? 'Log approved!' : 'Log rejected.',
          action == 'approve' ? Colors.green : Colors.red.shade400,
          action == 'approve'
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
        );
      }
    } catch (e) {
      if (mounted) _snack('Failed: $e', Colors.red.shade400, Icons.error);
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
            hintText: 'Enter reason for rejecting this log...',
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
              _verify('reject', coordinatorNotes: ctrl.text.trim());
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
    return Scaffold( 
        backgroundColor: AppStyle.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyle.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Teaching Log Detail',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
            fontSize: 18,
          ), 
        ),
      ),
      body: Container(
    
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // teacher info
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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppStyle.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.menu_book_rounded,
                          color: AppStyle.primaryColor, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.session.teacherName ?? 'Unknown Teacher',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Inter',
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(widget.session.classroomName ?? 'Unknown Classroom',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                            fontFamily: 'Inter')),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: widget.session.date ?? 'No Date'),
                    const Divider(height: 20),
                    _InfoRow(
                        icon: Icons.people_rounded,
                        label: 'Students',
                        value:
                            '${widget.session.studentCount ?? 0} students'),
                    const Divider(height: 20),
                    _InfoRow(
                        icon: Icons.class_rounded,
                        label: 'Classroom',
                        value: widget.session.classroomName ?? 'Unknown Classroom'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // teaching notes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: AppStyle.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'What was taught',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          color: AppStyle.primaryColor,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppStyle.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppStyle.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        widget.session.notes ?? 'No notes available',
                        style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            color: Colors.black87,
                            height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // action area
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_acted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _approved
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _approved
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _approved
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: _approved ? Colors.green : Colors.red,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _approved ? 'Log Approved' : 'Log Rejected',
                          style: TextStyle(
                            color: _approved
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
                            border:
                                Border.all(color: Colors.red.shade200),
                          ),
                          child: Center(
                            child: Text('Reject Log',
                                style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _verify('approve'),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.green.shade300),
                          ),
                          child: Center(
                            child: Text('Approve Log',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    fontSize: 15)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontFamily: 'Inter')),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}