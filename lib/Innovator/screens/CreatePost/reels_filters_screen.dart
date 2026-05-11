// ─── reels_filters_screen.dart ───────────────────────────────────────────────
// Place at: lib/Innovator/screens/CreatePost/reels_filters_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/provider/reels_provider.dart';
import 'package:video_player/video_player.dart';

class ReelsFiltersScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const ReelsFiltersScreen({super.key, required this.videoPath});

  @override
  ConsumerState<ReelsFiltersScreen> createState() => _ReelsFiltersScreenState();
}

class _ReelsFiltersScreenState extends ConsumerState<ReelsFiltersScreen> {
  VideoPlayerController? _ctrl;
  bool _videoReady = false;
  int _selectedIdx = 0;
  int _compareIdx = -1; // finger-hold comparison
  bool _isComparing = false;

  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  @override
  void initState() {
    super.initState();
    _selectedIdx = ref.read(reelsProvider).selectedFilterIndex;
    _initVideo();
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.file(File(widget.videoPath));
    _ctrl = ctrl;
    await ctrl.initialize();
    ctrl.setLooping(true);
    ctrl.setVolume(0);
    ctrl.play();
    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Widget _videoPreview(int filterIdx) {
    // FIX: use [reelsFilters] — defined in reels_provider.dart
    final filter = reelsFilters[filterIdx];
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(filter.matrix),
      child:
          _videoReady && _ctrl != null
              ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _ctrl!.value.size.width,
                    height: _ctrl!.value.size.height,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),
              )
              : Container(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Main video with selected filter ─────────────────────────────────
          _videoPreview(_selectedIdx),

          // ── Comparison overlay (hold on a thumbnail) ─────────────────────
          if (_isComparing && _compareIdx >= 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 200,
              right: MediaQuery.of(context).size.width / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _videoPreview(_compareIdx),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Colors.black54,
                      child: Text(
                        reelsFilters[_compareIdx].name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // Vertical divider
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(width: 2, color: Colors.white54),
                  ),
                ],
              ),
            ),

          // ── Top bar ───────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _topBtn(Icons.arrow_back_ios_new_rounded, () {
                    // FIX: [selectFilter] is now defined on [ReelsNotifier]
                    ref.read(reelsProvider.notifier).selectFilter(_selectedIdx);
                    Navigator.pop(context);
                  }),
                  const Spacer(),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(reelsProvider.notifier)
                          .selectFilter(_selectedIdx);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Current filter label ──────────────────────────────────────────
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reelsFilters[_selectedIdx].name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // ── Hint ─────────────────────────────────────────────────────────
          const Positioned(
            bottom: 175,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Hold filter to compare',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),

          // ── Filter thumbnails row ─────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildFiltersRow()),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // FIX: use [reelsFilters]
              itemCount: reelsFilters.length,
              itemBuilder: (_, i) {
                final f = reelsFilters[i];
                final selected = _selectedIdx == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIdx = i),
                  onLongPressStart:
                      (_) => setState(() {
                        _compareIdx = i;
                        _isComparing = true;
                      }),
                  onLongPressEnd: (_) => setState(() => _isComparing = false),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: selected ? 70 : 62,
                          height: selected ? 70 : 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? _orange : Colors.white24,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(f.matrix),
                              child:
                                  _videoReady && _ctrl != null
                                      ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: _ctrl!.value.size.width,
                                          height: _ctrl!.value.size.height,
                                          child: VideoPlayer(_ctrl!),
                                        ),
                                      )
                                      : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade400,
                                              Colors.orange.shade400,
                                            ],
                                          ),
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.name,
                          style: TextStyle(
                            color: selected ? _orange : Colors.white60,
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
