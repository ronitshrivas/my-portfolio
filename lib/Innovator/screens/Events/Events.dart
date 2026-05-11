import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────

class _T {
  static const bg = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigh = Color(0xFFEFEFF0);
  static const orange = Color(0xFFF48706);
  static const orangeDim = Color(0x22F48706);
  static const textPrimary = Color(0xFF1C1C1E);
  static const textSecondary = Color(0xFF6C6C70);
  static const divider = Color(0xFFE5E5EA);
  static const green = Color(0xFF25A244);
  static const greenDim = Color(0x1E25A244);
  static const urgent = Color(0xFFD93025);
  static const urgentDim = Color(0x1ED93025);
}

// ─── API ──────────────────────────────────────────────────────────────────────

const _kBaseUrl = 'http://36.253.137.34:8005/api/events/';

// ─── Model ────────────────────────────────────────────────────────────────────

class TechEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String createdByUsername;
  final int participantsCount;
  final bool isParticipant;
  final DateTime createdAt;
  bool isFavorite;

  TechEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.createdByUsername,
    required this.participantsCount,
    required this.isParticipant,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory TechEvent.fromJson(Map<String, dynamic> j) => TechEvent(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    location: j['location'] ?? '',
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
    createdByUsername: j['created_by_username'] ?? '',
    participantsCount: j['participants_count'] ?? 0,
    isParticipant: j['is_participant'] ?? false,
    createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    isFavorite: j['isFavorite'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'location': location,
    'date': date.toIso8601String(),
    'created_by_username': createdByUsername,
    'participants_count': participantsCount,
    'is_participant': isParticipant,
    'created_at': createdAt.toIso8601String(),
    'isFavorite': isFavorite,
  };

  TechEvent copyWith({bool? isFavorite}) => TechEvent(
    id: id,
    title: title,
    description: description,
    location: location,
    date: date,
    createdByUsername: createdByUsername,
    participantsCount: participantsCount,
    isParticipant: isParticipant,
    createdAt: createdAt,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

// ─── State ────────────────────────────────────────────────────────────────────

class EventsState {
  final List<TechEvent> events;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int activeTab;
  final Set<String> favoriteIds;

  const EventsState({
    this.events = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.activeTab = 0,
    this.favoriteIds = const {},
  });

  List<TechEvent> get filteredEvents {
    final q = searchQuery.toLowerCase();
    final base =
        events.where((e) {
            if (q.isEmpty) return true;
            return e.title.toLowerCase().contains(q) ||
                e.description.toLowerCase().contains(q) ||
                e.location.toLowerCase().contains(q) ||
                e.createdByUsername.toLowerCase().contains(q);
          }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return activeTab == 1 ? base.where((e) => e.isFavorite).toList() : base;
  }

  int get savedCount => events.where((e) => e.isFavorite).length;

  int get upcomingCount =>
      events.where((e) => e.date.isAfter(DateTime.now())).length;

  EventsState copyWith({
    List<TechEvent>? events,
    bool? isLoading,
    String? error,
    String? searchQuery,
    int? activeTab,
    Set<String>? favoriteIds,
  }) => EventsState(
    events: events ?? this.events,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    searchQuery: searchQuery ?? this.searchQuery,
    activeTab: activeTab ?? this.activeTab,
    favoriteIds: favoriteIds ?? this.favoriteIds,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier() : super(const EventsState()) {
    _init();
  }

  Future<void> _init() async {
    await AppData().initialize();
    await _loadFavorites();
    await fetchEvents();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('favorite_events') ?? [];
    state = state.copyWith(favoriteIds: ids.toSet());
  }

  Future<void> fetchEvents() async {
    final token = AppData().accessToken ?? '';
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_events');
      if (cached != null) {
        final list =
            (json.decode(cached) as List)
                .map((e) => TechEvent.fromJson(e))
                .toList();
        _applyFavorites(list);
        state = state.copyWith(events: list, isLoading: false);
      }
      final res = await http.get(
        Uri.parse(_kBaseUrl),
        headers: {if (token.isNotEmpty) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final fresh =
            (json.decode(res.body) as List)
                .map((e) => TechEvent.fromJson(e))
                .toList();
        _applyFavorites(fresh);
        await prefs.setString(
          'cached_events',
          json.encode(fresh.map((e) => e.toJson()).toList()),
        );
        state = state.copyWith(events: fresh, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'HTTP ${res.statusCode}',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _applyFavorites(List<TechEvent> list) {
    for (var e in list) e.isFavorite = state.favoriteIds.contains(e.id);
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = Set<String>.from(state.favoriteIds);
    ids.contains(id) ? ids.remove(id) : ids.add(id);
    await prefs.setStringList('favorite_events', ids.toList());
    final updated =
        state.events
            .map(
              (e) => e.id == id ? e.copyWith(isFavorite: ids.contains(id)) : e,
            )
            .toList();
    state = state.copyWith(events: updated, favoriteIds: ids);
  }

  Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required String date,
  }) async {
    final token = AppData().accessToken ?? '';
    try {
      final res = await http.post(
        Uri.parse(_kBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'location': location,
          'date': date,
          'participants': [],
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await fetchEvents();
        return true;
      }
      // Log the actual error so you can see what the server says
      print('createEvent failed: ${res.statusCode} ${res.body}');
      return false;
    } catch (e) {
      print('createEvent exception: $e');
      return false;
    }
  }

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setTab(int i) => state = state.copyWith(activeTab: i);
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>(
  (ref) => EventsNotifier(),
);

// ═════════════════════════════════════════════════════════════════════════════
//  PAGE
// ═════════════════════════════════════════════════════════════════════════════

class EventsHomePage extends ConsumerStatefulWidget {
  const EventsHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends ConsumerState<EventsHomePage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsProvider);
    final notifier = ref.read(eventsProvider.notifier);

    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            RefreshIndicator(
              color: _T.orange,
              backgroundColor: _T.surface,
              onRefresh: notifier.fetchEvents,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Hero ──────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back_ios_new),
                      alignment: Alignment.topLeft,
                    ),
                  ),

                  // ── Search + Tabs (sticky) ─────────────────────────────
                  SliverAppBar(
                    pinned: true,
                    floating: false,
                    backgroundColor: _T.bg,
                    elevation: 0,
                    toolbarHeight: 0,
                    collapsedHeight: 0,
                    expandedHeight: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: null,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(116),
                      child: _SearchTabsBar(
                        searchCtrl: _searchCtrl,
                        state: state,
                        onSearch: notifier.setSearch,
                        onTab: notifier.setTab,
                      ),
                    ),
                  ),

                  // ── List ──────────────────────────────────────────────────
                  if (state.isLoading && state.events.isEmpty)
                    const SliverFillRemaining(child: _LoadingView())
                  else if (state.error != null && state.events.isEmpty)
                    SliverFillRemaining(
                      child: _ErrorView(
                        error: state.error!,
                        onRetry: notifier.fetchEvents,
                      ),
                    )
                  else if (state.filteredEvents.isEmpty)
                    const SliverFillRemaining(child: _EmptyView())
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        4,
                        16,
                        MediaQuery.of(context).padding.bottom + 90,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) =>
                              _EventCard(event: state.filteredEvents[i]),
                          childCount: state.filteredEvents.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── FAB ──────────────────────────────────────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              right: 20,
              child: _CreateFAB(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final EventsState state;
  const _HeroSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3E0), Color(0xFFF5F5F7)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _T.orange,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TECHEVENTS',
                style: TextStyle(
                  color: _T.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              Consumer(
                builder:
                    (ctx, ref, _) => GestureDetector(
                      onTap:
                          () => ref.read(eventsProvider.notifier).fetchEvents(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _T.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _T.divider),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: _T.textSecondary,
                          size: 17,
                        ),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Headline
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -0.8,
              ),
              children: [
                TextSpan(
                  text: 'Discover\n',
                  style: TextStyle(color: _T.textPrimary),
                ),
                TextSpan(
                  text: '& Join ',
                  style: TextStyle(color: _T.textPrimary),
                ),
                TextSpan(text: 'Events', style: TextStyle(color: _T.orange)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stat pills
          Wrap(
            spacing: 8,
            children: [
              _Pill(
                label: 'upcoming',
                value: '${state.upcomingCount}',
                color: _T.orange,
              ),
              _Pill(
                label: 'saved',
                value: '${state.savedCount}',
                color: _T.green,
              ),
              _Pill(
                label: 'total',
                value: '${state.events.length}',
                color: _T.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Pill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.65), fontSize: 12),
        ),
      ],
    ),
  );
}

// ─── Sticky Search + Tabs ─────────────────────────────────────────────────────

class _SearchTabsBar extends StatelessWidget {
  final TextEditingController searchCtrl;
  final EventsState state;
  final void Function(String) onSearch;
  final void Function(int) onTab;

  const _SearchTabsBar({
    required this.searchCtrl,
    required this.state,
    required this.onSearch,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _T.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          SizedBox(
            height: 46,
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearch,
              style: const TextStyle(color: _T.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search events, places…',
                hintStyle: const TextStyle(
                  color: _T.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _T.textSecondary,
                  size: 19,
                ),
                suffixIcon:
                    searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                          onTap: () {
                            searchCtrl.clear();
                            onSearch('');
                          },
                          child: const Icon(
                            Icons.cancel_rounded,
                            color: _T.textSecondary,
                            size: 17,
                          ),
                        )
                        : null,
                filled: true,
                fillColor: _T.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _T.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _T.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _T.orange, width: 1.2),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Tab row
          Row(
            children: [
              _TabChip(
                label: 'All',
                count: state.events.length,
                active: state.activeTab == 0,
                onTap: () => onTab(0),
              ),
              const SizedBox(width: 8),
              _TabChip(
                label: 'Saved',
                count: state.savedCount,
                active: state.activeTab == 1,
                onTap: () => onTab(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? _T.orange : _T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? _T.orange : _T.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : _T.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: active ? Colors.white.withOpacity(0.22) : _T.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: active ? Colors.white : _T.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Event Card ───────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  final TechEvent event;
  const _EventCard({required this.event});

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final eventDay = DateTime(
      event.date.year,
      event.date.month,
      event.date.day,
    );
    final diff =
        eventDay
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;

    if (diff < 0) return const SizedBox.shrink();

    final isToday = diff == 0;
    final isSoon = diff <= 3;
    final accent =
        isToday
            ? _T.urgent
            : isSoon
            ? _T.orange
            : _T.green;
    final accentDim =
        isToday
            ? _T.urgentDim
            : isSoon
            ? _T.orangeDim
            : _T.greenDim;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.divider),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: _T.orange.withOpacity(0.05),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date block
                    Container(
                      width: 50,
                      height: 58,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(0.22)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${event.date.day}',
                            style: TextStyle(
                              color: accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _months[event.date.month - 1],
                            style: TextStyle(
                              color: accent.withOpacity(0.65),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: _T.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 12,
                                color: _T.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                event.createdByUsername,
                                style: const TextStyle(
                                  color: _T.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Bookmark btn
                    GestureDetector(
                      onTap:
                          () => ref
                              .read(eventsProvider.notifier)
                              .toggleFavorite(event.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color:
                              event.isFavorite ? _T.orangeDim : _T.surfaceHigh,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          event.isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                          color:
                              event.isFavorite ? _T.orange : _T.textSecondary,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Description ──
                Text(
                  event.description,
                  style: const TextStyle(
                    color: _T.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // ── Divider ──
                Container(height: 1, color: _T.divider),
                const SizedBox(height: 10),

                // ── Footer ──
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: _T.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: const TextStyle(
                          color: _T.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // People count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _T.surfaceHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            size: 11,
                            color: _T.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${event.participantsCount}',
                            style: const TextStyle(
                              color: _T.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Days badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isToday
                            ? '● Today'
                            : diff == 1
                            ? 'Tomorrow'
                            : '$diff days',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _CreateFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:
        () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _CreateEventSheet(),
        ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _T.orange,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _T.orange.withOpacity(0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 20),
          SizedBox(width: 7),
          Text(
            'New Event',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _T.orange, strokeWidth: 2),
        SizedBox(height: 14),
        Text(
          'Fetching events…',
          style: TextStyle(color: _T.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

class _ErrorView extends ConsumerWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.urgent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: _T.urgent,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connection Error',
            style: TextStyle(
              color: _T.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                color: _T.orange,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _T.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _T.divider),
          ),
          child: const Icon(
            Icons.event_busy_rounded,
            color: _T.textSecondary,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No events found',
          style: TextStyle(
            color: _T.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Try a different search or create one',
          style: TextStyle(color: _T.textSecondary, fontSize: 14),
        ),
      ],
    ),
  );
}

// ─── Create Sheet ─────────────────────────────────────────────────────────────

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();
  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _date;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder:
          (ctx, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: _T.orange,
                surface: _T.surface,
              ),
            ),
            child: child!,
          ),
    );
    if (p != null) setState(() => _date = p);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a date')));
      return;
    }
    setState(() => _busy = true);
    final ds =
        '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}'
        '-${_date!.day.toString().padLeft(2, '0')}';
    final ok = await ref
        .read(eventsProvider.notifier)
        .createEvent(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          location: _locCtrl.text.trim(),
          date: ds,
        );
    setState(() => _busy = false);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? _T.green : _T.urgent,
          content: Text(ok ? 'Event created!' : 'Failed to create event'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _T.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _T.orangeDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: _T.orange,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Create Event',
                    style: TextStyle(
                      color: _T.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _Field(
                ctrl: _titleCtrl,
                label: 'Event Title',
                icon: Icons.title_rounded,
                validator:
                    (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                ctrl: _descCtrl,
                label: 'Description',
                icon: Icons.notes_rounded,
                maxLines: 3,
                validator:
                    (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _Field(
                ctrl: _locCtrl,
                label: 'Location',
                icon: Icons.location_on_rounded,
                validator:
                    (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Date picker row
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: _T.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _T.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: _date != null ? _T.orange : _T.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _date == null
                            ? 'Select Date'
                            : '${_date!.day} ${_monthName(_date!.month)} ${_date!.year}',
                        style: TextStyle(
                          color:
                              _date != null ? _T.textPrimary : _T.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _busy ? null : _submit,
                  child:
                      _busy
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Publish Event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _mNames = [
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
  String _monthName(int m) => _mNames[m - 1];
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    validator: validator,
    style: const TextStyle(color: _T.textPrimary, fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _T.textSecondary),
      prefixIcon: Icon(icon, color: _T.textSecondary, size: 18),
      filled: true,
      fillColor: _T.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.urgent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}
