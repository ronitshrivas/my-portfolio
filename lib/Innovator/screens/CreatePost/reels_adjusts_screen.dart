// ─── reels_adjust_screen.dart ────────────────────────────────────────────────
// Place at: lib/Innovator/screens/CreatePost/reels_adjust_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/provider/reels_provider.dart';
import 'package:video_player/video_player.dart';

class ReelsAdjustScreen extends ConsumerStatefulWidget {
  const ReelsAdjustScreen({super.key});

  @override
  ConsumerState<ReelsAdjustScreen> createState() => _ReelsAdjustScreenState();
}

class _ReelsAdjustScreenState extends ConsumerState<ReelsAdjustScreen> {
  VideoPlayerController? _ctrl;
  bool _videoReady = false;

  // Local copies so we can preview without committing to state
  late double _brightness;
  late double _contrast;
  late double _saturation;
  late double _warmth;
  double _fade = 0;
  double _vignette = 0;

  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  @override
  void initState() {
    super.initState();
    final s = ref.read(reelsProvider);
    _brightness = s.brightness;
    _contrast = s.contrast;
    _saturation = s.saturation;
    _warmth = s.warmth;
    _fade = s.fade;

    // FIX: [recordedVideoPath] is now a field on [ReelsState]
    final videoPath = s.recordedVideoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      _initVideo(videoPath);
    }
  }

  Future<void> _initVideo(String path) async {
    final ctrl = VideoPlayerController.file(File(path));
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

  /// Commit local slider values back to the Riverpod state.
  void _commit() {
    final notifier = ref.read(reelsProvider.notifier);
    notifier.setBrightness(_brightness);
    notifier.setContrast(_contrast);
    notifier.setSaturation(_saturation);
    notifier.setWarmth(_warmth);
    notifier.setFade(_fade);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _warmth = 0;
      _fade = 0;
      _vignette = 0;
    });
  }

  /// Build a composite 4×5 colour matrix from current slider values.
  List<double> _buildMatrix() {
    final b = _brightness / 100.0 * 0.5; // −0.5 … 0.5
    final c = 1.0 + _contrast / 100.0; // 0.0 … 2.0
    final s = 1.0 + _saturation / 100.0; // 0.0 … 2.0

    final rAdd = _warmth > 0 ? _warmth / 100.0 * 0.2 : 0.0;
    final bSub = _warmth > 0 ? _warmth / 100.0 * 0.1 : 0.0;
    final bAdd = _warmth < 0 ? (-_warmth) / 100.0 * 0.2 : 0.0;
    final rSub = _warmth < 0 ? (-_warmth) / 100.0 * 0.1 : 0.0;

    // Luminance coefficients for saturation
    const lr = 0.299;
    const lg = 0.587;
    const lb = 0.114;
    final sr = (1 - s) * lr;
    final sg = (1 - s) * lg;
    final sb = (1 - s) * lb;

    final bVal = (b + (1.0 - c) * 0.5) * 255.0;

    return [
      c * (s + sr + rAdd - rSub),
      c * sg,
      c * (sb - bSub + bAdd),
      0,
      bVal,
      c * sr,
      c * (s + sg),
      c * sb,
      0,
      bVal,
      c * sr,
      c * sg,
      c * (s + sb - bSub + bAdd),
      0,
      bVal,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matrix = _buildMatrix();
    final hasChanges =
        _brightness != 0 ||
        _contrast != 0 ||
        _saturation != 0 ||
        _warmth != 0 ||
        _fade != 0 ||
        _vignette != 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video preview with live adjustment ──────────────────────────────
          if (_videoReady && _ctrl != null)
            ColorFiltered(
              colorFilter: ColorFilter.matrix(matrix),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _ctrl!.value.size.width,
                    height: _ctrl!.value.size.height,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),
              ),
            )
          else
            Container(color: const Color(0xFF1A1A1A)),

          // ── Fade overlay ───────────────────────────────────────────────────
          if (_fade > 0)
            Positioned.fill(
              child: Opacity(
                opacity: (_fade / 100).clamp(0, 0.5),
                child: Container(color: Colors.white),
              ),
            ),

          // ── Vignette overlay ──────────────────────────────────────────────
          if (_vignette > 0)
            Positioned.fill(
              child: Opacity(
                opacity: (_vignette / 100).clamp(0, 0.8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      radius: 1.2,
                    ),
                  ),
                ),
              ),
            ),

          // ── Top bar ────────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: _buildTopBar(hasChanges),
          ),

          // ── Sliders panel ─────────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildSlidersPanel()),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool hasChanges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Adjust',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (hasChanges)
                GestureDetector(
                  onTap: _reset,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _commit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(16),
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
        ],
      ),
    );
  }

  Widget _buildSlidersPanel() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.6, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSlider(
            label: 'Brightness',
            icon: Icons.wb_sunny_rounded,
            value: _brightness,
            color: const Color(0xFFFFD700),
            onChanged: (v) => setState(() => _brightness = v),
          ),
          _buildSlider(
            label: 'Contrast',
            icon: Icons.contrast_rounded,
            value: _contrast,
            color: const Color(0xFF9C9C9C),
            onChanged: (v) => setState(() => _contrast = v),
          ),
          _buildSlider(
            label: 'Saturation',
            icon: Icons.palette_rounded,
            value: _saturation,
            color: const Color(0xFFFF6B9D),
            onChanged: (v) => setState(() => _saturation = v),
          ),
          _buildSlider(
            label: 'Warmth',
            icon: Icons.thermostat_rounded,
            value: _warmth,
            color: const Color(0xFFFF8C42),
            onChanged: (v) => setState(() => _warmth = v),
          ),
          _buildSlider(
            label: 'Fade',
            icon: Icons.blur_on_rounded,
            value: _fade,
            color: const Color(0xFFAEC6CF),
            min: 0,
            onChanged: (v) => setState(() => _fade = v),
          ),
          _buildSlider(
            label: 'Vignette',
            icon: Icons.vignette_rounded,
            value: _vignette,
            color: const Color(0xFF888888),
            min: 0,
            onChanged: (v) => setState(() => _vignette = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
    double min = -100,
    double max = 100,
  }) {
    final displayVal = value.round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              displayVal >= 0 && min < 0 ? '+$displayVal' : '$displayVal',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: value.abs() > 0.5 ? color : Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
