import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:innovator/Innovator/provider/reels_provider.dart';
import 'package:innovator/Innovator/provider/upload_provider.dart';
import 'package:innovator/Innovator/screens/CreatePost/reels_adjusts_screen.dart';
import 'package:innovator/innovator_home.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';

import 'reels_effects_screen.dart';
import 'reels_filters_screen.dart';
import 'reels_music_screen.dart';

class ReelsPreviewScreen extends ConsumerStatefulWidget {
  final String videoPath;

  const ReelsPreviewScreen({super.key, required this.videoPath});

  @override
  ConsumerState<ReelsPreviewScreen> createState() => _ReelsPreviewScreenState();
}

class _ReelsPreviewScreenState extends ConsumerState<ReelsPreviewScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _muted = false;
  bool _isUploading = false;

  final TextEditingController _captionCtrl = TextEditingController();

  // ── Music player ──────────────────────────────────────────────────────────
  AudioPlayer? _musicPlayer;
  bool _musicPlaying = false;

  static const String _reelsApi = 'http://36.253.137.34:8005/api/reels/';
  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  @override
  void initState() {
    super.initState();
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelsProvider.notifier).setRecordedVideo(widget.videoPath);

      final selectedMusic = ref.read(reelsProvider).selectedMusic;
      if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
        _startMusicPlayback(selectedMusic);
      }
    });
  }

  Future<void> _initVideo() async {
    final ctrl = VideoPlayerController.file(File(widget.videoPath));
    _videoCtrl = ctrl;
    await ctrl.initialize();

    if (ctrl.value.size.isEmpty) {
      debugPrint('Video size is empty after initialize!');
      return;
    }

    ctrl.setLooping(true);
    final hasMusic = ref.read(reelsProvider).selectedMusic != null;
    ctrl.setVolume(hasMusic ? 0.0 : 1.0);
    ctrl.play();
    if (mounted) setState(() => _videoReady = true);
  }

  Future<void> _startMusicPlayback(ReelsMusicTrack track) async {
    _musicPlayer ??= AudioPlayer();
    try {
      await _musicPlayer!.play(UrlSource(track.audioUrl));
      if (mounted) setState(() => _musicPlaying = true);
      // Loop the music
      _musicPlayer!.onPlayerComplete.listen((_) async {
        if (mounted && _musicPlaying) {
          await _musicPlayer!.play(UrlSource(track.audioUrl));
        }
      });
    } catch (e) {
      debugPrint('Music playback error: $e');
    }
  }

  Future<void> _toggleMusicPlayback(ReelsMusicTrack track) async {
    _musicPlayer ??= AudioPlayer();
    if (_musicPlaying) {
      await _musicPlayer!.pause();
      setState(() => _musicPlaying = false);
    } else {
      await _musicPlayer!.play(UrlSource(track.audioUrl));
      setState(() => _musicPlaying = true);
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _captionCtrl.dispose();
    _musicPlayer?.stop();
    _musicPlayer?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPLOAD: Send video + music_url as separate fields (no ffmpeg needed)
  // The backend merges the audio server-side, or stores them separately.
  // This approach avoids ALL ffmpeg dependencies.
  // ─────────────────────────────────────────────────────────────────────────
  // Future<void> _uploadReel() async {
  //   if (_isUploading) return;
  //   setState(() => _isUploading = true);

  //   // Stop music before uploading
  //   await _musicPlayer?.stop();
  //   setState(() => _musicPlaying = false);

  //   try {
  //     final appData = AppData();
  //     final request = http.MultipartRequest('POST', Uri.parse(_reelsApi));

  //     if (appData.accessToken != null) {
  //       request.headers['Authorization'] = 'Bearer ${appData.accessToken}';
  //     }

  //     // Caption
  //     final caption = _captionCtrl.text.trim();
  //     if (caption.isNotEmpty) request.fields['caption'] = caption;

  //     // FIX: Send selected music URL as a field so backend can merge/store it
  //     final selectedMusic = ref.read(reelsProvider).selectedMusic;
  //     if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
  //       request.fields['music_url'] = selectedMusic.audioUrl;
  //       request.fields['music_title'] = selectedMusic.title;
  //       request.fields['music_artist'] = selectedMusic.artist;
  //     }

  //     // Video file
  //     final mimeType = lookupMimeType(widget.videoPath) ?? 'video/mp4';
  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         'video',
  //         widget.videoPath,
  //         contentType: MediaType.parse(mimeType),
  //         filename: p.basename(widget.videoPath),
  //       ),
  //     );

  //     final streamed = await request.send().timeout(
  //       const Duration(seconds: 120),
  //     );
  //     final response = await http.Response.fromStream(streamed);

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       if (mounted) {
  //         // Reset provider state
  //         ref.read(reelsProvider.notifier).reset();
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: const Text('🎉 Reel published successfully!'),
  //             backgroundColor: Colors.green.shade600,
  //           ),
  //         );
  //         await Future.delayed(const Duration(seconds: 1));
  //         if (mounted) {
  //           Navigator.of(context).popUntil((r) => r.isFirst);
  //         }
  //       }
  //     } else {
  //       Map<String, dynamic> body = {};
  //       try {
  //         body = json.decode(response.body) as Map<String, dynamic>;
  //       } catch (_) {}
  //       final msg =
  //           body['detail']?.toString() ??
  //           body['message']?.toString() ??
  //           'Upload failed (${response.statusCode})';
  //       _showError(msg);
  //     }
  //   } catch (e) {
  //     _showError('Upload error');
  //   } finally {
  //     if (mounted) setState(() => _isUploading = false);
  //   }
  // }

  Future<void> _uploadReel() async {
    if (_isUploading) return;

    // Capture everything BEFORE navigating (widget will be disposed)
    final String captionText = _captionCtrl.text.trim();
    final String videoPath = widget.videoPath;
    final String? accessToken = AppData().accessToken;
    final ReelsMusicTrack? selectedMusic =
        ref.read(reelsProvider).selectedMusic;

    final container = ProviderScope.containerOf(context);

    await _musicPlayer?.stop();

    container.read(postUploadingProvider.notifier).state = true;
    container.read(postUploadMessageProvider.notifier).state = null;

    ref.read(reelsProvider.notifier).reset();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Homepage()),
      (route) => false,
    );

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_reelsApi));

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      if (captionText.isNotEmpty) {
        request.fields['caption'] = captionText;
      }

      if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
        request.fields['music_url'] = selectedMusic.audioUrl;
        request.fields['music_title'] = selectedMusic.title;
        request.fields['music_artist'] = selectedMusic.artist;
      }

      final mimeType = lookupMimeType(videoPath) ?? 'video/mp4';
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          videoPath,
          contentType: MediaType.parse(mimeType),
          filename: p.basename(videoPath),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        container.read(postUploadingProvider.notifier).state = false;
        container.read(postUploadMessageProvider.notifier).state =
            'Reel published successfully! 🎉';
      } else {
        Map<String, dynamic> body = {};
        try {
          body = json.decode(response.body) as Map<String, dynamic>;
        } catch (_) {}
        final msg =
            body['detail']?.toString() ??
            body['message']?.toString() ??
            'Upload failed (${response.statusCode})';
        container.read(postUploadingProvider.notifier).state = false;
        container.read(postUploadMessageProvider.notifier).state = msg;
      }
    } catch (e) {
      container.read(postUploadingProvider.notifier).state = false;
      container.read(postUploadMessageProvider.notifier).state =
          'Error uploading reel: $e';
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reels = ref.watch(reelsProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.loose,
        children: [
          // ── FIX: Correct video preview (no squish) ────────────────────────
          if (_videoReady && _videoCtrl != null)
            _buildFixedVideoPreview(reels)
          else
            const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(244, 135, 6, 1),
              ),
            ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // ── Music bar ────────────────────────────────────────────────────
          if (reels.selectedMusic != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              right: 16,
              child: _buildMusicBar(reels.selectedMusic!),
            ),

          // ── Bottom controls ──────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(reels),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIX: Build video preview that fills the screen correctly
  //
  // Root cause of squish: using SizedBox.expand + FittedBox.cover with
  // VideoPlayer directly causes the widget to use the widget's size, not the
  // video's actual pixel dimensions, leading to incorrect aspect mapping.
  //
  // Fix: Wrap VideoPlayer in its correct pixel dimensions, then let
  // FittedBox + BoxFit.cover scale it to fill the screen properly.
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFixedVideoPreview(ReelsState reels) {
    final filter = reelsFilters[reels.selectedFilterIndex];
    final videoSize = _videoCtrl!.value.size;

    // Ensure we have valid video dimensions
    if (videoSize.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color.fromRGBO(244, 135, 6, 1)),
      );
    }

    // Always use portrait orientation
    final double videoW =
        videoSize.width < videoSize.height ? videoSize.width : videoSize.height;
    final double videoH =
        videoSize.width > videoSize.height ? videoSize.width : videoSize.height;

    Widget videoWidget = LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final videoAR = videoW / videoH;
        final screenAR = screenW / screenH;

        // Cover: scale up so video fills entire screen, crop excess
        double scale;
        if (screenAR > videoAR) {
          // Screen wider than video → fit by width
          scale = screenW / (screenH * videoAR);
        } else {
          // Screen taller than video → fit by height
          scale = (screenH * videoAR) / screenW;
        }
        // Clamp scale so we never scale down below 1.0
        scale = scale < 1.0 ? 1.0 : scale;

        return ClipRect(
          child: OverflowBox(
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox(
              width: screenW * scale,
              height: screenH * scale,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(filter.matrix),
                child: VideoPlayer(_videoCtrl!),
              ),
            ),
          ),
        );
      },
    );

    // Brightness / warmth overlay layers
    final List<Widget> layers = [Positioned.fill(child: videoWidget)];

    if (reels.brightness > 0)
      layers.add(
        Positioned.fill(
          child: Opacity(
            opacity: (reels.brightness / 100).clamp(0.0, 0.4),
            child: Container(color: Colors.white),
          ),
        ),
      );
    if (reels.brightness < 0)
      layers.add(
        Positioned.fill(
          child: Opacity(
            opacity: (-reels.brightness / 100).clamp(0.0, 0.5),
            child: Container(color: Colors.black),
          ),
        ),
      );
    if (reels.warmth > 0)
      layers.add(
        Positioned.fill(
          child: Opacity(
            opacity: (reels.warmth / 100).clamp(0.0, 0.25),
            child: Container(color: Colors.orange.shade300),
          ),
        ),
      );
    if (reels.warmth < 0)
      layers.add(
        Positioned.fill(
          child: Opacity(
            opacity: (-reels.warmth / 100).clamp(0.0, 0.25),
            child: Container(color: Colors.blue.shade200),
          ),
        ),
      );

    return Stack(fit: StackFit.expand, children: layers);
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              _musicPlayer?.stop();
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _muted = !_muted);
              _videoCtrl?.setVolume(_muted ? 0 : 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMusicBar(ReelsMusicTrack track) {
    return GestureDetector(
      onTap: () => _toggleMusicPlayback(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FIX: show pause/play based on actual playback state
            Icon(
              _musicPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            // Animated music wave when playing
            if (_musicPlaying) ...[
              _MusicWaveSmall(),
              const SizedBox(width: 4),
            ] else ...[
              const Icon(Icons.music_note, color: Colors.white, size: 14),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '${track.title} • ${track.artist}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                _musicPlayer?.stop();
                setState(() => _musicPlaying = false);
                _videoCtrl?.setVolume(1.0); // restore video audio
                ref.read(reelsProvider.notifier).clearMusic();
              },
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ReelsState reels) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.55, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditTools(reels),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _showCaptionSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Text(
                        _captionCtrl.text.isEmpty
                            ? 'Write a caption...'
                            : _captionCtrl.text,
                        style: TextStyle(
                          color:
                              _captionCtrl.text.isEmpty
                                  ? Colors.white38
                                  : Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isUploading ? null : _uploadReel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child:
                        _isUploading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Share',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTools(ReelsState reels) {
    final tools = [
      (
        Icons.music_note_rounded,
        'Music',
        reels.selectedMusic != null,
        () async {
          // Pause music before navigating to music screen
          await _musicPlayer?.pause();
          setState(() => _musicPlaying = false);
          if (mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReelsMusicScreen()),
            );
            // After returning, auto-play newly selected music
            final music = ref.read(reelsProvider).selectedMusic;
            if (music != null) {
              await _startMusicPlayback(music);
              // Mute video audio since music is selected
              _videoCtrl?.setVolume(0.0);
            }
          }
        },
      ),
      (
        Icons.auto_fix_high_rounded,
        'Effects',
        false,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReelsEffectsScreen()),
        ),
      ),
      (
        Icons.color_lens_rounded,
        'Filters',
        reels.selectedFilterIndex != 0,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReelsFiltersScreen(videoPath: widget.videoPath),
          ),
        ),
      ),
      (
        Icons.tune_rounded,
        'Adjust',
        reels.brightness != 0 ||
            reels.contrast != 0 ||
            reels.saturation != 0 ||
            reels.warmth != 0,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReelsAdjustScreen()),
        ),
      ),
      (Icons.text_fields_rounded, 'Text', false, _showCaptionSheet),
    ];

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tools.length,
        itemBuilder: (_, i) {
          final (icon, label, active, onTap) = tools[i];
          return GestureDetector(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: active ? _orange.withOpacity(0.2) : Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? _orange : Colors.white24,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: active ? _orange : Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: active ? _orange : Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCaptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Caption',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(color: _orange, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionCtrl,
                    autofocus: true,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
  }
}

// ─── Small music wave indicator ───────────────────────────────────────────────
class _MusicWaveSmall extends StatefulWidget {
  @override
  State<_MusicWaveSmall> createState() => _MusicWaveSmallState();
}

class _MusicWaveSmallState extends State<_MusicWaveSmall>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
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
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(3, (i) {
            final t = (_ctrl.value + i * 0.3) % 1.0;
            final h = 4.0 + 6.0 * t;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 2,
              height: h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
