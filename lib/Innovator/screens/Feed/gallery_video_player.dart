import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

class GalleryVideoPlayer extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;

  const GalleryVideoPlayer({Key? key, required this.url, this.thumbnailUrl})
    : super(key: key);

  @override
  State<GalleryVideoPlayer> createState() => _GalleryVideoPlayerState();
}

class _GalleryVideoPlayerState extends State<GalleryVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _disposed = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isDragging = false;
  bool _hasError = false;
  String? _errorMessage;
  double _dragPosition = 0.0;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPlayer();
    _startHideTimer();
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onListener);
    _controller?.pause();
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || _disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller!.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else if (state == AppLifecycleState.resumed && _initialized) {
      _controller!.play();
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  // ── Initialize ─────────────────────────────────────────────────────────────

  Future<void> _initPlayer() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _initialized = false;
    });

    try {
      // Dispose previous controller if retrying
      _controller?.removeListener(_onListener);
      await _controller?.pause();
      await _controller?.dispose();
      _controller = null;

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      await controller.initialize();
      if (_disposed) {
        controller.dispose();
        return;
      }

      await controller.setLooping(false);
      await controller.setVolume(1.0); // gallery = sound on by default
      controller.addListener(_onListener);

      if (mounted && !_disposed) {
        setState(() {
          _controller = controller;
          _initialized = true;
          _isMuted = false;
          _isPlaying = true;
        });
        controller.play();
      }
    } catch (e) {
      developer.log('[GalleryVideo] init error: $e');
      if (mounted && !_disposed) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video. Tap to retry.';
        });
      }
    }
  }

  void _onListener() {
    if (_disposed || _controller == null || !mounted) return;
    final playing = _controller!.value.isPlaying;
    if (_isPlaying != playing) setState(() => _isPlaying = playing);
  }

  // ── Control helpers ────────────────────────────────────────────────────────

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_disposed && _isPlaying && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _onTap() {
    if (!_initialized) return;
    if (_showControls) {
      _togglePlayPause();
    } else {
      _showControlsTemporarily();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        // When paused manually, keep controls visible
        _hideTimer?.cancel();
        _showControls = true;
      } else {
        _controller!.play();
        _isPlaying = true;
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _showControlsTemporarily();
  }

  void _seekBy(int seconds) {
    if (_controller == null || !_initialized) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    Duration newPos = current + Duration(seconds: seconds);
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > total) newPos = total;
    _controller!.seekTo(newPos);
    _showControlsTemporarily();
  }

  void _openFullscreen() {
    if (_controller == null || !_initialized) return;
    // Pause gallery player before going fullscreen
    _controller!.pause();
    setState(() => _isPlaying = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _GalleryFullscreenPage(
              url: widget.url,
              thumbnailUrl: widget.thumbnailUrl,
              startPosition: _controller!.value.position,
            ),
      ),
    ).then((_) {
      // Resume after returning from fullscreen
      if (mounted && !_disposed && _controller != null) {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
    });
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_hasError) {
      return _buildErrorState();
    }

    // Loading state
    if (!_initialized) {
      return _buildLoadingState();
    }

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video ─────────────────────────────────────────────────────
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

            // ── Buffering spinner ─────────────────────────────────────────
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller!,
              builder: (_, value, __) {
                if (value.isBuffering && !_isDragging) {
                  return const Center(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        color: Color(0xFFF48706),
                        strokeWidth: 3,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // ── Controls overlay (animated in/out) ────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _buildControlsOverlay(),
              ),
            ),

            // ── Progress bar — always at the very bottom ──────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildThinProgressBar(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading state ──────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: widget.thumbnailUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: Color(0xFFF48706),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Loading video...',
                  style: TextStyle(
                    color: AppColors.whitecolor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.whitecolor,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ?? 'Unable to load video',
              style: const TextStyle(color: AppColors.whitecolor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initPlayer,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48706),
                foregroundColor: AppColors.whitecolor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Controls overlay ───────────────────────────────────────────────────────

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.25, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Top bar: mute + fullscreen ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Mute
                  _CtrlBtn(
                    icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                    onTap: _toggleMute,
                  ),
                  const SizedBox(width: 8),
                  // Fullscreen
                  _CtrlBtn(icon: Icons.fullscreen, onTap: _openFullscreen),
                ],
              ),
            ),

            // ── Centre: skip-back + play/pause + skip-forward ─────────────
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Skip back 10s
                  _BigBtn(
                    icon: Icons.replay_10,
                    size: 32,
                    onTap: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 28),

                  // Play / Pause
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.whitecolor,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.whitecolor,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),

                  // Skip forward 10s
                  _BigBtn(
                    icon: Icons.forward_10,
                    size: 32,
                    onTap: () => _seekBy(10),
                  ),
                ],
              ),
            ),

            // ── Bottom: buffer + scrubber + timestamps ────────────────────
            if (_initialized && _controller != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, value, __) {
                    final totalMs = value.duration.inMilliseconds.toDouble();
                    final posMs =
                        _isDragging
                            ? _dragPosition
                            : value.position.inMilliseconds.toDouble();
                    final sliderVal =
                        totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

                    // Buffer %
                    double buffered = 0;
                    if (value.buffered.isNotEmpty && totalMs > 0) {
                      buffered =
                          value.buffered.last.end.inMilliseconds / totalMs;
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Buffer bar (thin, sits above scrubber)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LinearProgressIndicator(
                            value: buffered.clamp(0.0, 1.0),
                            backgroundColor: AppColors.whitecolor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.whitecolor,
                            ),
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Scrubber slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFF48706),
                            inactiveTrackColor: AppColors.whitecolor,
                            thumbColor: const Color(0xFFF48706),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            trackHeight: 3.5,
                          ),
                          child: Slider(
                            value: sliderVal,
                            onChangeStart: (_) {
                              setState(() => _isDragging = true);
                              _hideTimer?.cancel();
                              _controller!.pause();
                            },
                            onChanged: (v) {
                              setState(() => _dragPosition = v * totalMs);
                            },
                            onChangeEnd: (v) {
                              final ms = (v * totalMs).toInt();
                              _controller!
                                  .seekTo(Duration(milliseconds: ms))
                                  .then((_) {
                                    if (mounted && !_disposed) {
                                      _controller!.play();
                                      setState(() {
                                        _isDragging = false;
                                        _isPlaying = true;
                                      });
                                      _startHideTimer();
                                    }
                                  });
                            },
                          ),
                        ),

                        // Timestamps row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(Duration(milliseconds: posMs.toInt())),
                                style: const TextStyle(
                                  color: AppColors.whitecolor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _format(value.duration),
                                style: const TextStyle(
                                  color: AppColors.whitecolor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Thin orange bar always visible at very bottom (even when controls hidden)
  Widget _buildThinProgressBar() {
    if (!_initialized || _controller == null) return const SizedBox.shrink();
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller!,
      builder: (_, value, __) {
        final total = value.duration.inMilliseconds;
        final pos = value.position.inMilliseconds;
        final progress = total > 0 ? pos / total : 0.0;
        return SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.whitecolor,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF48706)),
            minHeight: 3,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GalleryFullscreenPage
// Opened when user taps fullscreen inside GalleryVideoPlayer
// Supports landscape rotation, scrubber, skip, play/pause, mute
// ─────────────────────────────────────────────────────────────────────────────

class _GalleryFullscreenPage extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final Duration startPosition;

  const _GalleryFullscreenPage({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    this.startPosition = Duration.zero,
  }) : super(key: key);

  @override
  State<_GalleryFullscreenPage> createState() => _GalleryFullscreenPageState();
}

class _GalleryFullscreenPageState extends State<_GalleryFullscreenPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _disposed = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isDragging = false;
  double _dragPosition = 0.0;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreen();
    _initPlayer();
    _startHideTimer();
  }

  @override
  void dispose() {
    _disposed = true;
    _hideTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onListener);
    _controller?.pause();
    final c = _controller;
    _controller = null;
    c?.dispose();
    _exitFullscreen();
    super.dispose();
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _initPlayer() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),

        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
      );
      await controller.initialize();
      if (_disposed) {
        controller.dispose();
        return;
      }

      await controller.seekTo(widget.startPosition);
      await controller.setLooping(false);
      await controller.setVolume(1.0);
      controller.addListener(_onListener);

      if (mounted && !_disposed) {
        setState(() {
          _controller = controller;
          _initialized = true;
          _isMuted = false;
        });
        controller.play();
      }
    } catch (e) {
      developer.log('[GalleryFullscreen] init error: $e');
    }
  }

  void _onListener() {
    if (_disposed || _controller == null || !mounted) return;
    final playing = _controller!.value.isPlaying;
    if (_isPlaying != playing) setState(() => _isPlaying = playing);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || _disposed) return;
    if (state == AppLifecycleState.paused)
      _controller!.pause();
    else if (state == AppLifecycleState.resumed && _isPlaying)
      _controller!.play();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_disposed && _isPlaying && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        _hideTimer?.cancel();
        _showControls = true;
      } else {
        _controller!.play();
        _isPlaying = true;
        _startHideTimer();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _showControlsTemporarily();
  }

  void _seekBy(int seconds) {
    if (_controller == null || !_initialized) return;
    final current = _controller!.value.position;
    final total = _controller!.value.duration;
    Duration newPos = current + Duration(seconds: seconds);
    if (newPos < Duration.zero) newPos = Duration.zero;
    if (newPos > total) newPos = total;
    _controller!.seekTo(newPos);
    _showControlsTemporarily();
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControlsTemporarily,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video ───────────────────────────────────────────────────────
            Center(
              child:
                  _initialized && _controller != null
                      ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                      : _buildThumb(),
            ),

            // ── Buffering ───────────────────────────────────────────────────
            if (_initialized && _controller != null)
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller!,
                builder:
                    (_, v, __) =>
                        v.isBuffering
                            ? const Center(
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF48706),
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
              ),

            // ── Controls overlay ────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: _buildControls(),
              ),
            ),

            // ── Thin progress bar always at bottom ──────────────────────────
            if (_initialized && _controller != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, value, __) {
                    final total = value.duration.inMilliseconds;
                    final pos = value.position.inMilliseconds;
                    return SizedBox(
                      height: 3,
                      child: LinearProgressIndicator(
                        value: total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: AppColors.whitecolor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF48706),
                        ),
                        minHeight: 3,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.thumbnailUrl != null)
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            fit: BoxFit.contain,
          ),
        const Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              color: Color(0xFFF48706),
              strokeWidth: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.65),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.85),
          ],
          stops: const [0.0, 0.2, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back + mute ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.whitecolor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: AppColors.whitecolor,
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),

            // ── Centre controls ─────────────────────────────────────────────
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BigBtn(
                    icon: Icons.replay_10,
                    size: 30,
                    onTap: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 28),
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.whitecolor,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.whitecolor,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                  _BigBtn(
                    icon: Icons.forward_10,
                    size: 30,
                    onTap: () => _seekBy(10),
                  ),
                ],
              ),
            ),

            // ── Bottom: scrubber + timestamps ───────────────────────────────
            if (_initialized && _controller != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _controller!,
                  builder: (_, value, __) {
                    final totalMs = value.duration.inMilliseconds.toDouble();
                    final posMs =
                        _isDragging
                            ? _dragPosition
                            : value.position.inMilliseconds.toDouble();
                    final sliderVal =
                        totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

                    double buffered = 0;
                    if (value.buffered.isNotEmpty && totalMs > 0) {
                      buffered =
                          value.buffered.last.end.inMilliseconds / totalMs;
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Buffer bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LinearProgressIndicator(
                            value: buffered.clamp(0.0, 1.0),
                            backgroundColor: AppColors.whitecolor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.whitecolor,
                            ),
                            minHeight: 2,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Scrubber
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFFF48706),
                            inactiveTrackColor: AppColors.whitecolor,
                            thumbColor: const Color(0xFFF48706),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                            trackHeight: 3.5,
                          ),
                          child: Slider(
                            value: sliderVal,
                            onChangeStart: (_) {
                              setState(() => _isDragging = true);
                              _hideTimer?.cancel();
                              _controller!.pause();
                            },
                            onChanged: (v) {
                              setState(() => _dragPosition = v * totalMs);
                            },
                            onChangeEnd: (v) {
                              final ms = (v * totalMs).toInt();
                              _controller!
                                  .seekTo(Duration(milliseconds: ms))
                                  .then((_) {
                                    if (mounted && !_disposed) {
                                      _controller!.play();
                                      setState(() {
                                        _isDragging = false;
                                        _isPlaying = true;
                                      });
                                      _startHideTimer();
                                    }
                                  });
                            },
                          ),
                        ),

                        // Timestamps
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _format(Duration(milliseconds: posMs.toInt())),
                                style: const TextStyle(
                                  color: AppColors.whitecolor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _format(value.duration),
                                style: const TextStyle(
                                  color: AppColors.whitecolor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable button widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Small icon button for top bar (mute, fullscreen)
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CtrlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.whitecolor, size: 20),
      ),
    );
  }
}

/// Large circular button for centre controls (skip, play/pause)
class _BigBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _BigBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.whitecolor, size: size),
      ),
    );
  }
}
