import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:developer' as developer;

// ─────────────────────────────────────────────────────────────────────────────
// Aspect ratio limits — exactly like Facebook/Instagram
// ─────────────────────────────────────────────────────────────────────────────
// const double _kMinAspectRatio = 9 / 16; // tallest portrait allowed
// const double _kMaxAspectRatio = 16 / 9; // widest landscape allowed

// ─────────────────────────────────────────────────────────────────────────────
// FacebookVideoWidget — Feed auto-play with adaptive height
// ─────────────────────────────────────────────────────────────────────────────

class FacebookVideoWidget extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final bool looping;
  final bool startMuted;
  final double maxPortraitHeight;

  const FacebookVideoWidget({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    this.looping = true,
    this.startMuted = true,
    this.maxPortraitHeight = 520,
  }) : super(key: key);

  @override
  State<FacebookVideoWidget> createState() => _FacebookVideoWidgetState();
}

class _FacebookVideoWidgetState extends State<FacebookVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController? _controller;
  double _aspectRatio = 16 / 9;
  bool _initialized = false;
  bool _disposed = false;
  bool _initStarted = false;
  bool _isMuted = false;
  bool _isPlaying = false;
  bool _showControls = false;
  Timer? _hideControlsTimer;

  final String _id = UniqueKey().toString();

  // One video plays at a time across the entire feed
  static final Map<String, _FacebookVideoWidgetState> _registry = {};

  @override
  bool get wantKeepAlive => false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registry[_id] = this;
  }

  @override
  void dispose() {
    _disposed = true;
    _registry.remove(_id);
    _hideControlsTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onVideoListener);
    _controller?.pause();
    // Null out _controller BEFORE calling dispose() so that the
    // notifyListeners() fired inside dispose() finds no live
    // ValueListenableBuilder referencing the old controller.
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
      if (mounted && !_disposed) setState(() => _isPlaying = false);
    } else if (state == AppLifecycleState.resumed && _initialized) {
      _controller!.play();
      if (mounted && !_disposed) setState(() => _isPlaying = true);
    }
  }

  // ── Initialize ─────────────────────────────────────────────────────────────

  Future<void> _initPlayer() async {
    if (_initStarted || _disposed) return;
    _initStarted = true;

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
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

      // ↓ Read real size from initialized controller
      final size = controller.value.size;
      final realRatio =
          (size.height > 0)
              ? size.width / size.height
              : 16 / 9; // fallback if size unknown

      await controller.setLooping(widget.looping);
      await controller.setVolume(widget.startMuted ? 0.0 : 1.0);
      controller.addListener(_onVideoListener);

      if (mounted && !_disposed) {
        setState(() {
          _controller = controller;
          _aspectRatio = realRatio; // ← UPDATE state variable here
          _initialized = true;
          _isMuted = widget.startMuted;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_disposed && _controller != null) {
            _controller!.play();
            setState(() => _isPlaying = true);
          }
        });
      }
    } catch (e) {
      developer.log('[FBVideo] init error: $e');
      controller?.dispose();
      if (mounted && !_disposed) {
        setState(() => _initStarted = false);
      }
    }
  }

  void _onVideoListener() {
    if (_disposed || _controller == null) return;
    final playing = _controller!.value.isPlaying;
    if (mounted && _isPlaying != playing) {
      setState(() => _isPlaying = playing);
    }
  }

  // ── Visibility: auto-play / pause ──────────────────────────────────────────

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_disposed || !mounted) return;
    final fraction = info.visibleFraction;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !mounted) return;

      if (fraction >= 0.7) {
        if (!_initStarted) _initPlayer();
        _pauseOthers();
        if (_initialized && _controller != null) {
          _controller!.play();
          if (mounted) setState(() => _isPlaying = true);
        }
      } else if (fraction < 0.4) {
        if (_controller != null) {
          // ── GUARANTEED DISPOSAL ORDER ──────────────────────────────────────
          // Step 1: Detach our listener — no more _onVideoListener callbacks
          _controller!.removeListener(_onVideoListener);
          _controller!.pause();

          // Step 2: Capture controller in local, then NULL out _controller
          //         and reset flags BEFORE setState so the rebuild sees
          //         _controller == null and removes every ValueListenableBuilder
          //         from the tree.
          final VideoPlayerController controllerToDispose = _controller!;
          _controller = null;
          _initialized = false;
          _initStarted = false;

          // Step 3: Rebuild NOW — tree no longer contains any
          //         ValueListenableBuilder that references the old controller.
          if (mounted && !_disposed) setState(() => _isPlaying = false);

          // Step 4: Dispose AFTER the frame has finished painting.
          //         At this point all ValueListenableBuilderState children are
          //         gone, so notifyListeners() inside dispose() is harmless.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controllerToDispose.dispose();
          });
        } else {
          if (mounted && !_disposed) setState(() => _isPlaying = false);
        }
      }
    });
  }

  void _pauseOthers() {
    for (final entry in _registry.entries) {
      if (entry.key != _id &&
          entry.value.mounted &&
          !entry.value._disposed &&
          entry.value._initialized) {
        entry.value._controller?.pause();
        if (entry.value.mounted) {
          // ignore: invalid_use_of_protected_member
          entry.value.setState(() => entry.value._isPlaying = false);
        }
      }
    }
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
    _showControlsTemporarily();
  }

  void _toggleMute() {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_disposed) setState(() => _showControls = false);
    });
  }

  void _onTap() {
    if (!_initialized) return;
    if (_showControls) {
      _togglePlayPause();
    } else {
      _showControlsTemporarily();
    }
  }

  void _openFullscreen() {
    if (_controller == null || !_initialized) return;
    _controller!.pause();
    setState(() => _isPlaying = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FacebookFullscreenPage(
              url: widget.url,
              thumbnailUrl: widget.thumbnailUrl,
              startPosition: _controller!.value.position,
            ),
      ),
    ).then((_) {
      if (mounted && !_disposed && _controller != null) {
        _controller!.play();
        setState(() => _isPlaying = true);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: Key(_id),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: _onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            // Use real video ratio after init, else default to 9:16 portrait
            final videoRatio =
                (_initialized && _controller != null)
                    ? _controller!
                        .value
                        .aspectRatio // e.g. 0.5625 for 9:16
                    : (9 / 16); // tall default before init

            // Height grows freely — no max clamp
            final height = width / _aspectRatio;

            return SizedBox(
              width: width,
              height: height,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Video or placeholder ──────────────────────────────
                    if (_initialized && _controller != null)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      )
                    else
                      _buildThumbnail(),

                    // ── Buffering spinner ─────────────────────────────────
                    if (_initialized && _controller != null)
                      ValueListenableBuilder<VideoPlayerValue>(
                        valueListenable: _controller!,
                        builder: (_, value, __) {
                          if (value.isBuffering) {
                            return const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF48706),
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                    // ── Init loading ──────────────────────────────────────
                    if (!_initialized && _initStarted)
                      const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            color: Color(0xFFF48706),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),

                    // ── Controls overlay ──────────────────────────────────
                    if (_initialized)
                      AnimatedOpacity(
                        opacity: (_showControls || !_isPlaying) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: _buildControlsOverlay(),
                      ),

                    // ── Progress bar always at bottom ─────────────────────
                    if (_initialized && _controller != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildProgressBar(),
                      ),

                    // ── Mute button always visible bottom-right ───────────
                    if (_initialized)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _toggleMute,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.whitecolor.withOpacity(0.2),
                              ),
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: AppColors.whitecolor,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final showPlayIcon =
        !_initStarted; // only show play icon if not attempted yet

    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.thumbnailUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => const ColoredBox(color: Colors.black12),
            errorWidget:
                (_, __, ___) => const ColoredBox(color: Colors.black12),
          ),
          if (showPlayIcon)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.whitecolor,
                size: 54,
              ),
            ),

          if (_initStarted && !_initialized)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Loading ...',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.35),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.45),
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Centre play/pause
          Center(
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.whitecolor,
                  size: 30,
                ),
              ),
            ),
          ),
          // Fullscreen top-right
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _openFullscreen,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: AppColors.whitecolor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller!,
      builder: (_, value, __) {
        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        final progress = duration > 0 ? position / duration : 0.0;
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
// FacebookFullscreenPage
// Full-screen player: scrubber, skip ±10s, play/pause, mute, buffer bar
// ─────────────────────────────────────────────────────────────────────────────

class FacebookFullscreenPage extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final Duration startPosition;

  const FacebookFullscreenPage({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    this.startPosition = Duration.zero,
  }) : super(key: key);

  @override
  State<FacebookFullscreenPage> createState() => _FacebookFullscreenPageState();
}

class _FacebookFullscreenPageState extends State<FacebookFullscreenPage>
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
      developer.log('[Fullscreen] init error: $e');
    }
  }

  void _onListener() {
    if (_disposed || _controller == null) return;
    final playing = _controller!.value.isPlaying;
    if (mounted && _isPlaying != playing) {
      setState(() => _isPlaying = playing);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || _disposed) return;
    if (state == AppLifecycleState.paused) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed && _isPlaying) {
      _controller!.play();
    }
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
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
    _showControlsTemporarily();
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
    final newPos = current + Duration(seconds: seconds);
    _controller!.seekTo(
      newPos < Duration.zero
          ? Duration.zero
          : newPos > total
          ? total
          : newPos,
    );
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
                              child: CircularProgressIndicator(
                                color: Color(0xFFF48706),
                                strokeWidth: 3,
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
          child: CircularProgressIndicator(
            color: Color(0xFFF48706),
            strokeWidth: 3,
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
            // ── Top bar ─────────────────────────────────────────────────────
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
                  // Skip back 10s
                  _IconBtn(
                    icon: Icons.replay_10,
                    size: 28,
                    onTap: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 30),

                  // Play / Pause
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
                  const SizedBox(width: 30),

                  // Skip forward 10s
                  _IconBtn(
                    icon: Icons.forward_10,
                    size: 28,
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

                    // Buffer progress
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
// Small helper widget — circular icon button
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.whitecolor, size: size),
      ),
    );
  }
}
