// ─── reels_music_screen.dart ─────────────────────────────────────────────────
// Place at: lib/Innovator/screens/reels_music_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/provider/reels_provider.dart';

class ReelsMusicScreen extends ConsumerStatefulWidget {
  const ReelsMusicScreen({super.key});

  @override
  ConsumerState<ReelsMusicScreen> createState() => _ReelsMusicScreenState();
}

class _ReelsMusicScreenState extends ConsumerState<ReelsMusicScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _activeFilter = 'All';
  String? _playingId;
  final AudioPlayer _player = AudioPlayer();
  bool _playerLoading = false;

  late AnimationController _waveController;

  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  // Language/category filters
  static const List<String> _filters = [
    'All',
    'Trending',
    'Nepali',
    'Pop',
    'Hip-Hop',
    'Romantic',
    'Party',
    'Chill',
    'Indie',
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _searchCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  List<ReelsMusicTrack> _filtered(List<ReelsMusicTrack> all) {
    var list = all;
    if (_activeFilter != 'All' && _activeFilter != 'Trending') {
      final q = _activeFilter.toLowerCase();
      list =
          list
              .where(
                (t) =>
                    t.genre.toLowerCase() == q || t.language.toLowerCase() == q,
              )
              .toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list =
          list
              .where(
                (t) =>
                    t.title.toLowerCase().contains(q) ||
                    t.artist.toLowerCase().contains(q),
              )
              .toList();
    }
    return list;
  }

  Future<void> _togglePlay(ReelsMusicTrack track) async {
    if (_playingId == track.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() {
      _playingId = track.id;
      _playerLoading = true;
    });
    try {
      await _player.stop();
      await _player.play(UrlSource(track.audioUrl));
    } catch (e) {
      debugPrint('Audio error: $e');
    } finally {
      if (mounted) setState(() => _playerLoading = false);
    }
  }

  void _selectTrack(ReelsMusicTrack track) {
    ref.read(reelsProvider.notifier).selectMusic(track);
    _player.stop();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('♪ "${track.title}" added to reel'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(reelsProvider).selectedMusic;

    final musicAsync =
        _query.isNotEmpty
            ? ref.watch(reelsMusicSearchProvider(_query))
            : ref.watch(reelsMusicProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        children: [
          SafeArea(bottom: false, child: _buildHeader(selected)),
          _buildSearchBar(),
          _buildFilterChips(),
          const SizedBox(height: 4),
          Expanded(
            child: musicAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(244, 135, 6, 1),
                    ),
                  ),
              error:
                  (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white38,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load music',
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Check your internet connection',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(reelsMusicProvider);
                            ref.invalidate(reelsMusicSearchProvider(_query));
                          },
                          child: Text(
                            'Retry',
                            style: TextStyle(color: _orange),
                          ),
                        ),
                      ],
                    ),
                  ),
              data: (all) {
                final tracks = _query.isNotEmpty ? all : _filtered(all);
                if (tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          color: Colors.white24,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _query.isNotEmpty
                              ? 'No results for "$_query"'
                              : 'No $_activeFilter songs found',
                          style: const TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 32),
                  itemCount: tracks.length,
                  itemBuilder: (_, i) => _buildTrackTile(tracks[i], selected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ReelsMusicTrack? selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              _player.stop();
              Navigator.pop(context);
            },
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add Music',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (selected != null)
            TextButton.icon(
              onPressed: () {
                ref.read(reelsProvider.notifier).clearMusic();
                setState(() {});
              },
              icon: const Icon(
                Icons.remove_circle_outline,
                size: 16,
                color: Colors.white54,
              ),
              label: const Text(
                'Remove',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search songs, artists...',
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
          suffixIcon:
              _query.isNotEmpty
                  ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(Icons.close, color: Colors.white38),
                  )
                  : null,
          filled: true,
          fillColor: Colors.white10,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final active = _activeFilter == f;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = f),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _orange : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: active ? Colors.white : Colors.white70,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackTile(ReelsMusicTrack track, ReelsMusicTrack? selected) {
    final isPlaying = _playingId == track.id;
    final isSelected = selected?.id == track.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSelected
                ? _orange.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _orange.withOpacity(0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () => _togglePlay(track),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying ? _orange : Colors.white12,
              image:
                  (!isPlaying && track.albumArt != null)
                      ? DecorationImage(
                        image: NetworkImage(track.albumArt!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _playerLoading && isPlaying
                    ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : isPlaying
                    ? _buildWaveIcon()
                    : (track.albumArt == null
                        ? const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        )
                        : Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black45,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        )),
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isSelected ? _orange : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${track.artist}${track.language.isNotEmpty ? ' · ${track.language[0].toUpperCase()}${track.language.substring(1)}' : ''}',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              track.durationString,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _selectTrack(track),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.green.shade700 : _orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSelected ? '✓ Added' : 'Use',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveIcon() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final delay = i * 0.25;
            final t = (_waveController.value + delay) % 1.0;
            final h = 6.0 + 10.0 * (0.5 + 0.5 * (t * 3.14159 * 2).abs() % 1);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
