import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innovator/Innovator/provider/reels_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'reels_music_screen.dart';
import 'reels_preview_screen.dart';

const _kPrimary = Color.fromRGBO(244, 135, 6, 1);

class ReelsCameraScreen extends ConsumerStatefulWidget {
  const ReelsCameraScreen({super.key});

  static Future<void> openWithPermissions(BuildContext context) async {
    // 1. Check current status (instant — no dialog)
    var camStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    // 2. Only request if not yet granted (shows dialog only first time)
    if (!camStatus.isGranted) camStatus = await Permission.camera.request();
    if (!micStatus.isGranted) micStatus = await Permission.microphone.request();

    if (!camStatus.isGranted || !micStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera & microphone permission required'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // 3. Permissions OK → push screen (camera will init instantly inside)
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReelsCameraScreen()),
      );
    }
  }

  @override
  ConsumerState<ReelsCameraScreen> createState() => _ReelsCameraScreenState();
}

class _ReelsCameraScreenState extends ConsumerState<ReelsCameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _micEnabled = true;
  List<CameraDescription> _cameras = [];
  CameraController? _ctrl;
  bool _ready = false;
  bool _recording = false;
  bool _isFront = false;
  FlashMode _flash = FlashMode.off;
  int _elapsed = 0;
  Timer? _recTimer;
  int _countdown = 0;
  Timer? _cdTimer;
  int _timerSec = 0;
  bool _showFilters = false;
  bool _showSpeed = false;
  bool _showTimer = false;
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  final AudioPlayer _musicPlayer = AudioPlayer();
  bool _musicPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.10).animate(_pulse);
    _initCams();
  }

  Future<void> _initCams() async {
    try {
      // Fast status check only — no dialog, no delay
      final camOk = await Permission.camera.status;
      final micOk = await Permission.microphone.status;

      if (!camOk.isGranted || !micOk.isGranted) {
        // Permissions not granted — request them as fallback
        final cam = await Permission.camera.request();
        final mic = await Permission.microphone.request();
        if (!cam.isGranted || !mic.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Camera & microphone permission required'),
              ),
            );
          }
          return;
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('No cameras found on device');
        return;
      }

      // Init with back camera (index 0) by default
      await _initCtrl(_cameras[0]);
    } catch (e) {
      debugPrint('cam init error: $e');
    }
  }

  Future<void> _initCtrl(CameraDescription d, {bool enableAudio = true}) async {
    final old = _ctrl;
    if (mounted) setState(() => _ready = false);
    _ctrl = null;
    _micEnabled = enableAudio; // ← track it here

    try {
      await old?.dispose();
    } catch (_) {}

    final controller = CameraController(
      d,
      ResolutionPreset.veryHigh,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _ctrl = controller;

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        _ctrl = null;
        return;
      }
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('ctrl init error: $e');
      try {
        await controller.dispose();
      } catch (_) {}
      _ctrl = null;
      if (mounted) setState(() => _ready = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (s == AppLifecycleState.inactive) {
      _recTimer?.cancel();
      _musicPlayer.pause();
      ctrl.dispose();
      _ctrl = null;
      if (mounted) setState(() => _ready = false);
    } else if (s == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _initCtrl(_cameras[_isFront ? 1 : 0]);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recTimer?.cancel();
    _cdTimer?.cancel();
    _ctrl?.dispose();
    _pulse.dispose();
    _musicPlayer.dispose();
    super.dispose();
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _recording) return;
    if (!mounted) return;

    setState(() {
      _ready = false;
      _isFront = !_isFront;
    });

    ref.read(reelsProvider.notifier).toggleCamera();

    final index = _isFront ? 1 : 0;
    if (index < _cameras.length) {
      await _initCtrl(_cameras[index]);
    }
  }

  Future<void> _toggleFlash() async {
    if (_ctrl == null || !_ready) return;
    final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _ctrl?.setFlashMode(next);
      if (mounted) setState(() => _flash = next);
    } catch (e) {
      debugPrint('flash error: $e');
    }
  }

  Future<void> _pickGallery() async {
    final v = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 3),
    );
    if (v != null && mounted) {
      ref.read(reelsProvider.notifier).setVideo(v.path, fromGallery: true);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReelsPreviewScreen(videoPath: v.path),
        ),
      );
    }
  }

  void _handleRecordTap() {
    if (_recording) {
      _stopRec();
      return;
    }
    if (_timerSec > 0) {
      _startCountdown();
    } else {
      _startRec();
    }
  }

  void _startCountdown() {
    if (mounted) setState(() => _countdown = _timerSec);
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _startRec();
      }
    });
  }

  Future<void> _startRec() async {
    final hasMusic = ref.read(reelsProvider).selectedMusic != null;

    // If music is selected, reinitialize camera WITHOUT mic audio
    if (hasMusic && _micEnabled) {
      await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: false);
      if (!_ready || _ctrl == null) return;
    }

    final ctrl = _ctrl;
    if (ctrl == null || !ctrl.value.isInitialized || !_ready) return;

    try {
      await ctrl.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _recording = true;
        _elapsed = 0;
        _showFilters = false;
        _showSpeed = false;
      });

      final selectedMusic = ref.read(reelsProvider).selectedMusic;
      if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
        try {
          await _musicPlayer.play(UrlSource(selectedMusic.audioUrl));
          if (mounted) setState(() => _musicPlaying = true);
        } catch (e) {
          debugPrint('Music play error: $e');
        }
      }

      final maxSec = ref.read(reelsProvider).maxDurationSeconds;
      _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _elapsed++);
        if (_elapsed >= maxSec) _stopRec();
      });
    } catch (e) {
      debugPrint('startRec error: $e');
      if (mounted) setState(() => _recording = false);
    }
  }

  Future<void> _stopRec() async {
    _recTimer?.cancel();
    final ctrl = _ctrl;
    if (ctrl == null || !_recording) return;

    try {
      final f = await ctrl.stopVideoRecording();
      if (!mounted) return;
      setState(() => _recording = false);

      await _musicPlayer.stop();
      if (mounted) setState(() => _musicPlaying = false);

      // Restore mic audio for next recording session
      await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: true);

      ref.read(reelsProvider.notifier).setVideo(f.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReelsPreviewScreen(videoPath: f.path),
        ),
      );
    } catch (e) {
      debugPrint('stopRec error: $e');
      if (mounted) setState(() => _recording = false);
    }
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _buildCameraPreview() {
    if (!_ready || _ctrl == null || !_ctrl!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
      );
    }

    final rs = ref.watch(reelsProvider);
    final matrix = kReelFilters[rs.selectedFilterIndex].matrix;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: _FullScreenCameraPreview(controller: _ctrl!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ref.watch(reelsProvider);
    final maxSec = rs.maxDurationSeconds;
    final progress = _recording ? (_elapsed / maxSec).clamp(0.0, 1.0) : 0.0;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final h = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _buildCameraPreview()),

            if (_recording)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
                ),
              ),

            Positioned(
              top: safeTop + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _circBtn(Icons.close, () {
                    _musicPlayer.stop();
                    ref.read(reelsProvider.notifier).reset();
                    Navigator.pop(context);
                  }),
                  const Spacer(),
                  // Music pill
                  GestureDetector(
                    onTap: () async {
                      if (_musicPlaying) {
                        await _musicPlayer.stop();
                        if (mounted) setState(() => _musicPlaying = false);
                      }
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReelsMusicScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color:
                              rs.selectedMusic != null
                                  ? _kPrimary
                                  : Colors.white38,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_musicPlaying)
                            const _MusicWaveBars()
                          else
                            Icon(
                              Icons.music_note_rounded,
                              color:
                                  rs.selectedMusic != null
                                      ? _kPrimary
                                      : Colors.white,
                              size: 16,
                            ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              rs.selectedMusic?.title ?? 'Add Sound',
                              style: TextStyle(
                                color:
                                    rs.selectedMusic != null
                                        ? _kPrimary
                                        : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _circBtn(
                    _flash == FlashMode.off
                        ? Icons.flash_off_rounded
                        : Icons.flash_on_rounded,
                    _toggleFlash,
                  ),
                ],
              ),
            ),

            // ── RIGHT SIDEBAR ───────────────────────────────────────────────
            Positioned(
              right: 12,
              top: h * 0.22,
              child: Column(
                children: [
                  _sideItem(Icons.flip_camera_android_rounded, 'Flip', _flip),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => setState(() => _showSpeed = !_showSpeed),
                    child: _sideLabel(
                      Icons.speed_rounded,
                      rs.recordingSpeed == 1.0 ? '1×' : '${rs.recordingSpeed}×',
                      highlight: rs.recordingSpeed != 1.0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => setState(() => _showTimer = !_showTimer),
                    child: _sideLabel(
                      Icons.timer_rounded,
                      _timerSec == 0 ? 'Timer' : '${_timerSec}s',
                      highlight: _timerSec != 0,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sideItem(Icons.auto_fix_high_rounded, 'Effects', () {}),
                  const SizedBox(height: 22),
                  _sideItem(
                    Icons.lens_blur_rounded,
                    'Filters',
                    () => setState(() {
                      _showFilters = !_showFilters;
                      _showSpeed = false;
                      _showTimer = false;
                    }),
                  ),
                ],
              ),
            ),

            // ── BOTTOM CONTROLS ─────────────────────────────────────────────
            Positioned(
              bottom: safeBot + 16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Duration chips
                  if (!_recording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            [15, 30, 60, 180].map((d) {
                              final sel = rs.maxDurationSeconds == d;
                              return GestureDetector(
                                onTap:
                                    () => ref
                                        .read(reelsProvider.notifier)
                                        .setMaxDuration(d),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel ? Colors.white : Colors.black45,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          sel ? Colors.white : Colors.white38,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    d < 60 ? '${d}s' : '${d ~/ 60}m',
                                    style: TextStyle(
                                      color: sel ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery button
                      GestureDetector(
                        onTap: _recording ? null : _pickGallery,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white54),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),

                      // Record button
                      GestureDetector(
                        onTap: _handleRecordTap,
                        child:
                            _recording
                                ? _StopBtn(elapsed: _elapsed, max: maxSec)
                                : ScaleTransition(
                                  scale: _pulseAnim,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 64,
                                        height: 64,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                      ),

                      const SizedBox(width: 52),
                    ],
                  ),
                ],
              ),
            ),

            // ── FILTER PANEL ────────────────────────────────────────────────
            if (_showFilters)
              Positioned(
                bottom: safeBot + 160,
                left: 0,
                right: 0,
                height: 110,
                child: Container(
                  color: Colors.black54,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: kReelFilters.length,
                    itemBuilder: (_, i) {
                      final f = kReelFilters[i];
                      final sel = rs.selectedFilterIndex == i;
                      return GestureDetector(
                        onTap: () {
                          ref.read(reelsProvider.notifier).setFilter(i);
                          setState(() => _showFilters = false);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Color(f.previewColor),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? _kPrimary : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                f.name,
                                style: TextStyle(
                                  color: sel ? _kPrimary : Colors.white,
                                  fontSize: 10,
                                  fontWeight:
                                      sel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── SPEED PANEL ─────────────────────────────────────────────────
            if (_showSpeed)
              Positioned(
                right: 64,
                top: h * 0.28,
                child: _OptionPanel(
                  items: const ['0.3×', '0.5×', '1×', '2×', '3×'],
                  values: const [0.3, 0.5, 1.0, 2.0, 3.0],
                  selectedValue: rs.recordingSpeed,
                  onSelect: (v) {
                    ref.read(reelsProvider.notifier).setSpeed(v);
                    setState(() => _showSpeed = false);
                  },
                ),
              ),

            // ── TIMER PANEL ─────────────────────────────────────────────────
            if (_showTimer)
              Positioned(
                right: 64,
                top: h * 0.40,
                child: _OptionPanel(
                  items: const ['Off', '3s', '10s'],
                  values: const [0.0, 3.0, 10.0],
                  selectedValue: _timerSec.toDouble(),
                  onSelect:
                      (v) => setState(() {
                        _timerSec = v.toInt();
                        _showTimer = false;
                      }),
                ),
              ),

            // ── COUNTDOWN OVERLAY ───────────────────────────────────────────
            if (_countdown > 0)
              Center(
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 30, color: Colors.black87)],
                  ),
                ),
              ),

            // ── REC BADGE ───────────────────────────────────────────────────
            if (_recording)
              Positioned(
                top: safeTop + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.white, size: 8),
                        const SizedBox(width: 6),
                        Text(
                          _fmt(_elapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _circBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    ),
  );

  Widget _sideItem(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: _sideLabel(icon, label));

  Widget _sideLabel(IconData icon, String label, {bool highlight = false}) =>
      Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
              border: highlight ? Border.all(color: _kPrimary, width: 2) : null,
            ),
            child: Icon(
              icon,
              color: highlight ? _kPrimary : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: highlight ? _kPrimary : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED MUSIC WAVE BARS
// ─────────────────────────────────────────────────────────────────────────────
class _MusicWaveBars extends StatefulWidget {
  const _MusicWaveBars();

  @override
  State<_MusicWaveBars> createState() => _MusicWaveBarsState();
}

class _MusicWaveBarsState extends State<_MusicWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(4, (i) {
            final delay = i * 0.25;
            final t = (_ctrl.value + delay) % 1.0;
            final barH = 4.0 + 8.0 * t;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 2.5,
              height: barH,
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STOP BUTTON (circular progress + red square)
// ─────────────────────────────────────────────────────────────────────────────
class _StopBtn extends StatelessWidget {
  final int elapsed, max;
  const _StopBtn({required this.elapsed, required this.max});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 80,
    height: 80,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: (elapsed / max).clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
        ),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN CAMERA PREVIEW — covers screen without stretch, crops edges
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;
  const _FullScreenCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return const SizedBox.shrink();

    // previewSize.width is always the LARGER dimension (landscape native)
    final portraitW =
        previewSize.height < previewSize.width
            ? previewSize.height
            : previewSize.width;
    final portraitH =
        previewSize.height > previewSize.width
            ? previewSize.height
            : previewSize.width;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: portraitW,
          height: portraitH,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OPTION PANEL (speed / timer dropdowns)
// ─────────────────────────────────────────────────────────────────────────────
class _OptionPanel extends StatelessWidget {
  final List<String> items;
  final List<double> values;
  final double selectedValue;
  final ValueChanged<double> onSelect;

  const _OptionPanel({
    required this.items,
    required this.values,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(items.length, (i) {
        final sel = values[i] == selectedValue;
        return GestureDetector(
          onTap: () => onSelect(values[i]),
          child: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? _kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              items[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: sel ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
    ),
  );
}


// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:innovator/Innovator/provider/reels_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'reels_music_screen.dart';
// import 'reels_preview_screen.dart';

// const _kPrimary = Color.fromRGBO(244, 135, 6, 1);

// class ReelsCameraScreen extends ConsumerStatefulWidget {
//   const ReelsCameraScreen({super.key});

//   static Future<void> openWithPermissions(BuildContext context) async {
//     // 1. Check current status (instant — no dialog)
//     var camStatus = await Permission.camera.status;
//     var micStatus = await Permission.microphone.status;

//     // 2. Only request if not yet granted (shows dialog only first time)
//     if (!camStatus.isGranted) camStatus = await Permission.camera.request();
//     if (!micStatus.isGranted) micStatus = await Permission.microphone.request();

//     if (!camStatus.isGranted || !micStatus.isGranted) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Camera & microphone permission required'),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//       return;
//     }

//     // 3. Permissions OK → push screen (camera will init instantly inside)
//     if (context.mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ReelsCameraScreen()),
//       );
//     }
//   }

//   @override
//   ConsumerState<ReelsCameraScreen> createState() => _ReelsCameraScreenState();
// }

// class _ReelsCameraScreenState extends ConsumerState<ReelsCameraScreen>
//     with WidgetsBindingObserver, SingleTickerProviderStateMixin {
//   bool _micEnabled = true;
//   List<CameraDescription> _cameras = [];
//   CameraController? _ctrl;
//   bool _ready = false;
//   bool _recording = false;
//   bool _isFront = false;
//   FlashMode _flash = FlashMode.off;
//   int _elapsed = 0;
//   Timer? _recTimer;
//   int _countdown = 0;
//   Timer? _cdTimer;
//   int _timerSec = 0;
//   bool _showFilters = false;
//   bool _showSpeed = false;
//   bool _showTimer = false;
//   late AnimationController _pulse;
//   late Animation<double> _pulseAnim;

//   final AudioPlayer _musicPlayer = AudioPlayer();
//   bool _musicPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween(begin: 1.0, end: 1.10).animate(_pulse);
//     _initCams();
//   }

//   Future<void> _initCams() async {
//     try {
//       // Fast status check only — no dialog, no delay
//       final camOk = await Permission.camera.status;
//       final micOk = await Permission.microphone.status;

//       if (!camOk.isGranted || !micOk.isGranted) {
//         // Permissions not granted — request them as fallback
//         final cam = await Permission.camera.request();
//         final mic = await Permission.microphone.request();
//         if (!cam.isGranted || !mic.isGranted) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Camera & microphone permission required'),
//               ),
//             );
//           }
//           return;
//         }
//       }

//       _cameras = await availableCameras();
//       if (_cameras.isEmpty) {
//         debugPrint('No cameras found on device');
//         return;
//       }

//       // Init with back camera (index 0) by default
//       await _initCtrl(_cameras[0]);
//     } catch (e) {
//       debugPrint('cam init error: $e');
//     }
//   }

//   Future<void> _initCtrl(CameraDescription d, {bool enableAudio = true}) async {
//     final old = _ctrl;
//     if (mounted) setState(() => _ready = false);
//     _ctrl = null;
//     _micEnabled = enableAudio; // ← track it here

//     try {
//       await old?.dispose();
//     } catch (_) {}

//     final controller = CameraController(
//       d,
//       ResolutionPreset.veryHigh,
//       enableAudio: enableAudio,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );

//     _ctrl = controller;

//     try {
//       await controller.initialize();
//       if (!mounted) {
//         await controller.dispose();
//         _ctrl = null;
//         return;
//       }
//       await controller.setFocusMode(FocusMode.auto);
//       await controller.setExposureMode(ExposureMode.auto);
//       if (mounted) setState(() => _ready = true);
//     } catch (e) {
//       debugPrint('ctrl init error: $e');
//       try {
//         await controller.dispose();
//       } catch (_) {}
//       _ctrl = null;
//       if (mounted) setState(() => _ready = false);
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState s) {
//     final ctrl = _ctrl;
//     if (ctrl == null || !ctrl.value.isInitialized) return;

//     if (s == AppLifecycleState.inactive) {
//       _recTimer?.cancel();
//       _musicPlayer.pause();
//       ctrl.dispose();
//       _ctrl = null;
//       if (mounted) setState(() => _ready = false);
//     } else if (s == AppLifecycleState.resumed) {
//       if (_cameras.isNotEmpty) {
//         _initCtrl(_cameras[_isFront ? 1 : 0]);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _recTimer?.cancel();
//     _cdTimer?.cancel();
//     _ctrl?.dispose();
//     _pulse.dispose();
//     _musicPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _flip() async {
//     if (_cameras.length < 2 || _recording) return;
//     if (!mounted) return;

//     setState(() {
//       _ready = false;
//       _isFront = !_isFront;
//     });

//     ref.read(reelsProvider.notifier).toggleCamera();

//     final index = _isFront ? 1 : 0;
//     if (index < _cameras.length) {
//       await _initCtrl(_cameras[index]);
//     }
//   }

//   Future<void> _toggleFlash() async {
//     if (_ctrl == null || !_ready) return;
//     final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
//     try {
//       await _ctrl?.setFlashMode(next);
//       if (mounted) setState(() => _flash = next);
//     } catch (e) {
//       debugPrint('flash error: $e');
//     }
//   }

//   Future<void> _pickGallery() async {
//     final v = await ImagePicker().pickVideo(
//       source: ImageSource.gallery,
//       maxDuration: const Duration(minutes: 3),
//     );
//     if (v != null && mounted) {
//       ref.read(reelsProvider.notifier).setVideo(v.path, fromGallery: true);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ReelsPreviewScreen(videoPath: v.path),
//         ),
//       );
//     }
//   }

//   void _handleRecordTap() {
//     if (_recording) {
//       _stopRec();
//       return;
//     }
//     if (_timerSec > 0) {
//       _startCountdown();
//     } else {
//       _startRec();
//     }
//   }

//   void _startCountdown() {
//     if (mounted) setState(() => _countdown = _timerSec);
//     _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) {
//         t.cancel();
//         return;
//       }
//       setState(() => _countdown--);
//       if (_countdown <= 0) {
//         t.cancel();
//         _startRec();
//       }
//     });
//   }

//   Future<void> _startRec() async {
//     final hasMusic = ref.read(reelsProvider).selectedMusic != null;

//     // If music is selected, reinitialize camera WITHOUT mic audio
//     if (hasMusic && _micEnabled) {
//       await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: false);
//       if (!_ready || _ctrl == null) return;
//     }

//     final ctrl = _ctrl;
//     if (ctrl == null || !ctrl.value.isInitialized || !_ready) return;

//     try {
//       await ctrl.startVideoRecording();
//       if (!mounted) return;
//       setState(() {
//         _recording = true;
//         _elapsed = 0;
//         _showFilters = false;
//         _showSpeed = false;
//       });

//       final selectedMusic = ref.read(reelsProvider).selectedMusic;
//       if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
//         try {
//           await _musicPlayer.play(UrlSource(selectedMusic.audioUrl));
//           if (mounted) setState(() => _musicPlaying = true);
//         } catch (e) {
//           debugPrint('Music play error: $e');
//         }
//       }

//       final maxSec = ref.read(reelsProvider).maxDurationSeconds;
//       _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//         if (!mounted) {
//           t.cancel();
//           return;
//         }
//         setState(() => _elapsed++);
//         if (_elapsed >= maxSec) _stopRec();
//       });
//     } catch (e) {
//       debugPrint('startRec error: $e');
//       if (mounted) setState(() => _recording = false);
//     }
//   }

//   Future<void> _stopRec() async {
//     _recTimer?.cancel();
//     final ctrl = _ctrl;
//     if (ctrl == null || !_recording) return;

//     try {
//       final f = await ctrl.stopVideoRecording();
//       if (!mounted) return;
//       setState(() => _recording = false);

//       await _musicPlayer.stop();
//       if (mounted) setState(() => _musicPlaying = false);

//       // Restore mic audio for next recording session
//       await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: true);

//       ref.read(reelsProvider.notifier).setVideo(f.path);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ReelsPreviewScreen(videoPath: f.path),
//         ),
//       );
//     } catch (e) {
//       debugPrint('stopRec error: $e');
//       if (mounted) setState(() => _recording = false);
//     }
//   }

//   String _fmt(int s) =>
//       '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

//   Widget _buildCameraPreview() {
//     if (!_ready || _ctrl == null || !_ctrl!.value.isInitialized) {
//       return const Center(
//         child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
//       );
//     }

//     final rs = ref.watch(reelsProvider);
//     final matrix = kReelFilters[rs.selectedFilterIndex].matrix;

//     return ColorFiltered(
//       colorFilter: ColorFilter.matrix(matrix),
//       child: _FullScreenCameraPreview(controller: _ctrl!),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final rs = ref.watch(reelsProvider);
//     final maxSec = rs.maxDurationSeconds;
//     final progress = _recording ? (_elapsed / maxSec).clamp(0.0, 1.0) : 0.0;
//     final safeTop = MediaQuery.of(context).padding.top;
//     final safeBot = MediaQuery.of(context).padding.bottom;
//     final h = MediaQuery.of(context).size.height;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             Positioned.fill(child: _buildCameraPreview()),

//             if (_recording)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 height: 3,
//                 child: LinearProgressIndicator(
//                   value: progress,
//                   backgroundColor: Colors.white24,
//                   valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
//                 ),
//               ),

//             Positioned(
//               top: safeTop + 8,
//               left: 12,
//               right: 12,
//               child: Row(
//                 children: [
//                   _circBtn(Icons.close, () {
//                     _musicPlayer.stop();
//                     ref.read(reelsProvider.notifier).reset();
//                     Navigator.pop(context);
//                   }),
//                   const Spacer(),
//                   // Music pill
//                   GestureDetector(
//                     onTap: () async {
//                       if (_musicPlaying) {
//                         await _musicPlayer.stop();
//                         if (mounted) setState(() => _musicPlaying = false);
//                       }
//                       if (mounted) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ReelsMusicScreen(),
//                           ),
//                         );
//                       }
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.black54,
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(
//                           color:
//                               rs.selectedMusic != null
//                                   ? _kPrimary
//                                   : Colors.white38,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           if (_musicPlaying)
//                             const _MusicWaveBars()
//                           else
//                             Icon(
//                               Icons.music_note_rounded,
//                               color:
//                                   rs.selectedMusic != null
//                                       ? _kPrimary
//                                       : Colors.white,
//                               size: 16,
//                             ),
//                           const SizedBox(width: 6),
//                           ConstrainedBox(
//                             constraints: const BoxConstraints(maxWidth: 140),
//                             child: Text(
//                               rs.selectedMusic?.title ?? 'Add Sound',
//                               style: TextStyle(
//                                 color:
//                                     rs.selectedMusic != null
//                                         ? _kPrimary
//                                         : Colors.white,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   _circBtn(
//                     _flash == FlashMode.off
//                         ? Icons.flash_off_rounded
//                         : Icons.flash_on_rounded,
//                     _toggleFlash,
//                   ),
//                 ],
//               ),
//             ),

//             // ── RIGHT SIDEBAR ───────────────────────────────────────────────
//             Positioned(
//               right: 12,
//               top: h * 0.22,
//               child: Column(
//                 children: [
//                   _sideItem(Icons.flip_camera_android_rounded, 'Flip', _flip),
//                   const SizedBox(height: 22),
//                   GestureDetector(
//                     onTap: () => setState(() => _showSpeed = !_showSpeed),
//                     child: _sideLabel(
//                       Icons.speed_rounded,
//                       rs.recordingSpeed == 1.0 ? '1×' : '${rs.recordingSpeed}×',
//                       highlight: rs.recordingSpeed != 1.0,
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   GestureDetector(
//                     onTap: () => setState(() => _showTimer = !_showTimer),
//                     child: _sideLabel(
//                       Icons.timer_rounded,
//                       _timerSec == 0 ? 'Timer' : '${_timerSec}s',
//                       highlight: _timerSec != 0,
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   _sideItem(Icons.auto_fix_high_rounded, 'Effects', () {}),
//                   const SizedBox(height: 22),
//                   _sideItem(
//                     Icons.lens_blur_rounded,
//                     'Filters',
//                     () => setState(() {
//                       _showFilters = !_showFilters;
//                       _showSpeed = false;
//                       _showTimer = false;
//                     }),
//                   ),
//                 ],
//               ),
//             ),

//             // ── BOTTOM CONTROLS ─────────────────────────────────────────────
//             Positioned(
//               bottom: safeBot + 16,
//               left: 0,
//               right: 0,
//               child: Column(
//                 children: [
//                   // Duration chips
//                   if (!_recording)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 22),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children:
//                             [15, 30, 60, 180].map((d) {
//                               final sel = rs.maxDurationSeconds == d;
//                               return GestureDetector(
//                                 onTap:
//                                     () => ref
//                                         .read(reelsProvider.notifier)
//                                         .setMaxDuration(d),
//                                 child: AnimatedContainer(
//                                   duration: const Duration(milliseconds: 200),
//                                   margin: const EdgeInsets.symmetric(
//                                     horizontal: 6,
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: sel ? Colors.white : Colors.black45,
//                                     borderRadius: BorderRadius.circular(20),
//                                     border: Border.all(
//                                       color:
//                                           sel ? Colors.white : Colors.white38,
//                                       width: 1.2,
//                                     ),
//                                   ),
//                                   child: Text(
//                                     d < 60 ? '${d}s' : '${d ~/ 60}m',
//                                     style: TextStyle(
//                                       color: sel ? Colors.black : Colors.white,
//                                       fontWeight: FontWeight.w700,
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                       ),
//                     ),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       // Gallery button
//                       GestureDetector(
//                         onTap: _recording ? null : _pickGallery,
//                         child: Container(
//                           width: 52,
//                           height: 52,
//                           decoration: BoxDecoration(
//                             color: Colors.white24,
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.white54),
//                           ),
//                           child: const Icon(
//                             Icons.photo_library_rounded,
//                             color: Colors.white,
//                             size: 26,
//                           ),
//                         ),
//                       ),

//                       // Record button
//                       GestureDetector(
//                         onTap: _handleRecordTap,
//                         child:
//                             _recording
//                                 ? _StopBtn(elapsed: _elapsed, max: maxSec)
//                                 : ScaleTransition(
//                                   scale: _pulseAnim,
//                                   child: Container(
//                                     width: 80,
//                                     height: 80,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white,
//                                         width: 4,
//                                       ),
//                                     ),
//                                     child: Center(
//                                       child: Container(
//                                         width: 64,
//                                         height: 64,
//                                         decoration: const BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                       ),

//                       const SizedBox(width: 52),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // ── FILTER PANEL ────────────────────────────────────────────────
//             if (_showFilters)
//               Positioned(
//                 bottom: safeBot + 160,
//                 left: 0,
//                 right: 0,
//                 height: 110,
//                 child: Container(
//                   color: Colors.black54,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     itemCount: kReelFilters.length,
//                     itemBuilder: (_, i) {
//                       final f = kReelFilters[i];
//                       final sel = rs.selectedFilterIndex == i;
//                       return GestureDetector(
//                         onTap: () {
//                           ref.read(reelsProvider.notifier).setFilter(i);
//                           setState(() => _showFilters = false);
//                         },
//                         child: Container(
//                           margin: const EdgeInsets.only(right: 12),
//                           child: Column(
//                             children: [
//                               AnimatedContainer(
//                                 duration: const Duration(milliseconds: 200),
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   color: Color(f.previewColor),
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: Border.all(
//                                     color: sel ? _kPrimary : Colors.transparent,
//                                     width: 2.5,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 f.name,
//                                 style: TextStyle(
//                                   color: sel ? _kPrimary : Colors.white,
//                                   fontSize: 10,
//                                   fontWeight:
//                                       sel ? FontWeight.w700 : FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),

//             // ── SPEED PANEL ─────────────────────────────────────────────────
//             if (_showSpeed)
//               Positioned(
//                 right: 64,
//                 top: h * 0.28,
//                 child: _OptionPanel(
//                   items: const ['0.3×', '0.5×', '1×', '2×', '3×'],
//                   values: const [0.3, 0.5, 1.0, 2.0, 3.0],
//                   selectedValue: rs.recordingSpeed,
//                   onSelect: (v) {
//                     ref.read(reelsProvider.notifier).setSpeed(v);
//                     setState(() => _showSpeed = false);
//                   },
//                 ),
//               ),

//             // ── TIMER PANEL ─────────────────────────────────────────────────
//             if (_showTimer)
//               Positioned(
//                 right: 64,
//                 top: h * 0.40,
//                 child: _OptionPanel(
//                   items: const ['Off', '3s', '10s'],
//                   values: const [0.0, 3.0, 10.0],
//                   selectedValue: _timerSec.toDouble(),
//                   onSelect:
//                       (v) => setState(() {
//                         _timerSec = v.toInt();
//                         _showTimer = false;
//                       }),
//                 ),
//               ),

//             // ── COUNTDOWN OVERLAY ───────────────────────────────────────────
//             if (_countdown > 0)
//               Center(
//                 child: Text(
//                   '$_countdown',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 120,
//                     fontWeight: FontWeight.w900,
//                     shadows: [Shadow(blurRadius: 30, color: Colors.black87)],
//                   ),
//                 ),
//               ),

//             // ── REC BADGE ───────────────────────────────────────────────────
//             if (_recording)
//               Positioned(
//                 top: safeTop + 10,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.circle, color: Colors.white, size: 8),
//                         const SizedBox(width: 6),
//                         Text(
//                           _fmt(_elapsed),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // HELPER WIDGETS
//   // ─────────────────────────────────────────────────────────────────────────
//   Widget _circBtn(IconData icon, VoidCallback onTap) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 40,
//       height: 40,
//       decoration: const BoxDecoration(
//         color: Colors.black45,
//         shape: BoxShape.circle,
//       ),
//       child: Icon(icon, color: Colors.white, size: 22),
//     ),
//   );

//   Widget _sideItem(IconData icon, String label, VoidCallback onTap) =>
//       GestureDetector(onTap: onTap, child: _sideLabel(icon, label));

//   Widget _sideLabel(IconData icon, String label, {bool highlight = false}) =>
//       Column(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: Colors.black54,
//               shape: BoxShape.circle,
//               border: highlight ? Border.all(color: _kPrimary, width: 2) : null,
//             ),
//             child: Icon(
//               icon,
//               color: highlight ? _kPrimary : Colors.white,
//               size: 22,
//             ),
//           ),
//           const SizedBox(height: 3),
//           Text(
//             label,
//             style: TextStyle(
//               color: highlight ? _kPrimary : Colors.white,
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // ANIMATED MUSIC WAVE BARS
// // ─────────────────────────────────────────────────────────────────────────────
// class _MusicWaveBars extends StatefulWidget {
//   const _MusicWaveBars();

//   @override
//   State<_MusicWaveBars> createState() => _MusicWaveBarsState();
// }

// class _MusicWaveBarsState extends State<_MusicWaveBars>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ctrl,
//       builder: (_, __) {
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: List.generate(4, (i) {
//             final delay = i * 0.25;
//             final t = (_ctrl.value + delay) % 1.0;
//             final barH = 4.0 + 8.0 * t;
//             return Container(
//               margin: const EdgeInsets.symmetric(horizontal: 1),
//               width: 2.5,
//               height: barH,
//               decoration: BoxDecoration(
//                 color: _kPrimary,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // STOP BUTTON (circular progress + red square)
// // ─────────────────────────────────────────────────────────────────────────────
// class _StopBtn extends StatelessWidget {
//   final int elapsed, max;
//   const _StopBtn({required this.elapsed, required this.max});

//   @override
//   Widget build(BuildContext context) => SizedBox(
//     width: 80,
//     height: 80,
//     child: Stack(
//       alignment: Alignment.center,
//       children: [
//         SizedBox(
//           width: 80,
//           height: 80,
//           child: CircularProgressIndicator(
//             value: (elapsed / max).clamp(0.0, 1.0),
//             strokeWidth: 4,
//             backgroundColor: Colors.white30,
//             valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
//           ),
//         ),
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: Colors.red,
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // FULL SCREEN CAMERA PREVIEW — covers screen without stretch, crops edges
// // ─────────────────────────────────────────────────────────────────────────────
// class _FullScreenCameraPreview extends StatelessWidget {
//   final CameraController controller;
//   const _FullScreenCameraPreview({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     final previewSize = controller.value.previewSize;
//     if (previewSize == null) return const SizedBox.shrink();

//     // previewSize.width is always the LARGER dimension (landscape native)
//     final portraitW =
//         previewSize.height < previewSize.width
//             ? previewSize.height
//             : previewSize.width;
//     final portraitH =
//         previewSize.height > previewSize.width
//             ? previewSize.height
//             : previewSize.width;

//     return SizedBox.expand(
//       child: FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: portraitW,
//           height: portraitH,
//           child: CameraPreview(controller),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // OPTION PANEL (speed / timer dropdowns)
// // ─────────────────────────────────────────────────────────────────────────────
// class _OptionPanel extends StatelessWidget {
//   final List<String> items;
//   final List<double> values;
//   final double selectedValue;
//   final ValueChanged<double> onSelect;

//   const _OptionPanel({
//     required this.items,
//     required this.values,
//     required this.selectedValue,
//     required this.onSelect,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//     decoration: BoxDecoration(
//       color: Colors.black87,
//       borderRadius: BorderRadius.circular(14),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(items.length, (i) {
//         final sel = values[i] == selectedValue;
//         return GestureDetector(
//           onTap: () => onSelect(values[i]),
//           child: Container(
//             width: 58,
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: sel ? _kPrimary : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               items[i],
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: sel ? Colors.black : Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         );
//       }),
//     ),
//   );
// }
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:innovator/Innovator/provider/reels_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'reels_music_screen.dart';
// import 'reels_preview_screen.dart';

// const _kPrimary = Color.fromRGBO(244, 135, 6, 1);

// class ReelsCameraScreen extends ConsumerStatefulWidget {
//   const ReelsCameraScreen({super.key});

//   static Future<void> openWithPermissions(BuildContext context) async {
//     // 1. Check current status (instant — no dialog)
//     var camStatus = await Permission.camera.status;
//     var micStatus = await Permission.microphone.status;

//     // 2. Only request if not yet granted (shows dialog only first time)
//     if (!camStatus.isGranted) camStatus = await Permission.camera.request();
//     if (!micStatus.isGranted) micStatus = await Permission.microphone.request();

//     if (!camStatus.isGranted || !micStatus.isGranted) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Camera & microphone permission required'),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//       return;
//     }

//     // 3. Permissions OK → push screen (camera will init instantly inside)
//     if (context.mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ReelsCameraScreen()),
//       );
//     }
//   }

//   @override
//   ConsumerState<ReelsCameraScreen> createState() => _ReelsCameraScreenState();
// }

// class _ReelsCameraScreenState extends ConsumerState<ReelsCameraScreen>
//     with WidgetsBindingObserver, SingleTickerProviderStateMixin {
//   bool _micEnabled = true;
//   List<CameraDescription> _cameras = [];
//   CameraController? _ctrl;
//   bool _ready = false;
//   bool _recording = false;
//   bool _isFront = false;
//   FlashMode _flash = FlashMode.off;
//   int _elapsed = 0;
//   Timer? _recTimer;
//   int _countdown = 0;
//   Timer? _cdTimer;
//   int _timerSec = 0;
//   bool _showFilters = false;
//   bool _showSpeed = false;
//   bool _showTimer = false;
//   late AnimationController _pulse;
//   late Animation<double> _pulseAnim;

//   final AudioPlayer _musicPlayer = AudioPlayer();
//   bool _musicPlaying = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//     _pulse = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _pulseAnim = Tween(begin: 1.0, end: 1.10).animate(_pulse);
//     _initCams();
//   }

//   Future<void> _initCams() async {
//     try {
//       // Fast status check only — no dialog, no delay
//       final camOk = await Permission.camera.status;
//       final micOk = await Permission.microphone.status;

//       if (!camOk.isGranted || !micOk.isGranted) {
//         // Permissions not granted — request them as fallback
//         final cam = await Permission.camera.request();
//         final mic = await Permission.microphone.request();
//         if (!cam.isGranted || !mic.isGranted) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text('Camera & microphone permission required'),
//               ),
//             );
//           }
//           return;
//         }
//       }

//       _cameras = await availableCameras();
//       if (_cameras.isEmpty) {
//         debugPrint('No cameras found on device');
//         return;
//       }

//       // Init with back camera (index 0) by default
//       await _initCtrl(_cameras[0]);
//     } catch (e) {
//       debugPrint('cam init error: $e');
//     }
//   }

//   Future<void> _initCtrl(CameraDescription d, {bool enableAudio = true}) async {
//     final old = _ctrl;
//     if (mounted) setState(() => _ready = false);
//     _ctrl = null;
//     _micEnabled = enableAudio; // ← track it here

//     try {
//       await old?.dispose();
//     } catch (_) {}

//     final controller = CameraController(
//       d,
//       ResolutionPreset.veryHigh,
//       enableAudio: enableAudio,
//       imageFormatGroup: ImageFormatGroup.jpeg,
//     );

//     _ctrl = controller;

//     try {
//       await controller.initialize();
//       if (!mounted) {
//         await controller.dispose();
//         _ctrl = null;
//         return;
//       }
//       await controller.setFocusMode(FocusMode.auto);
//       await controller.setExposureMode(ExposureMode.auto);
//       if (mounted) setState(() => _ready = true);
//     } catch (e) {
//       debugPrint('ctrl init error: $e');
//       try {
//         await controller.dispose();
//       } catch (_) {}
//       _ctrl = null;
//       if (mounted) setState(() => _ready = false);
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState s) {
//     final ctrl = _ctrl;
//     if (ctrl == null || !ctrl.value.isInitialized) return;

//     if (s == AppLifecycleState.inactive) {
//       _recTimer?.cancel();
//       _musicPlayer.pause();
//       ctrl.dispose();
//       _ctrl = null;
//       if (mounted) setState(() => _ready = false);
//     } else if (s == AppLifecycleState.resumed) {
//       if (_cameras.isNotEmpty) {
//         _initCtrl(_cameras[_isFront ? 1 : 0]);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _recTimer?.cancel();
//     _cdTimer?.cancel();
//     _ctrl?.dispose();
//     _pulse.dispose();
//     _musicPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _flip() async {
//     if (_cameras.length < 2 || _recording) return;
//     if (!mounted) return;

//     setState(() {
//       _ready = false;
//       _isFront = !_isFront;
//     });

//     ref.read(reelsProvider.notifier).toggleCamera();

//     final index = _isFront ? 1 : 0;
//     if (index < _cameras.length) {
//       await _initCtrl(_cameras[index]);
//     }
//   }

//   Future<void> _toggleFlash() async {
//     if (_ctrl == null || !_ready) return;
//     final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
//     try {
//       await _ctrl?.setFlashMode(next);
//       if (mounted) setState(() => _flash = next);
//     } catch (e) {
//       debugPrint('flash error: $e');
//     }
//   }

//   Future<void> _pickGallery() async {
//     final v = await ImagePicker().pickVideo(
//       source: ImageSource.gallery,
//       maxDuration: const Duration(minutes: 3),
//     );
//     if (v != null && mounted) {
//       ref.read(reelsProvider.notifier).setVideo(v.path, fromGallery: true);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ReelsPreviewScreen(videoPath: v.path),
//         ),
//       );
//     }
//   }

//   void _handleRecordTap() {
//     if (_recording) {
//       _stopRec();
//       return;
//     }
//     if (_timerSec > 0) {
//       _startCountdown();
//     } else {
//       _startRec();
//     }
//   }

//   void _startCountdown() {
//     if (mounted) setState(() => _countdown = _timerSec);
//     _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) {
//         t.cancel();
//         return;
//       }
//       setState(() => _countdown--);
//       if (_countdown <= 0) {
//         t.cancel();
//         _startRec();
//       }
//     });
//   }

//   Future<void> _startRec() async {
//     final hasMusic = ref.read(reelsProvider).selectedMusic != null;

//     // If music is selected, reinitialize camera WITHOUT mic audio
//     if (hasMusic && _micEnabled) {
//       await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: false);
//       if (!_ready || _ctrl == null) return;
//     }

//     final ctrl = _ctrl;
//     if (ctrl == null || !ctrl.value.isInitialized || !_ready) return;

//     try {
//       await ctrl.startVideoRecording();
//       if (!mounted) return;
//       setState(() {
//         _recording = true;
//         _elapsed = 0;
//         _showFilters = false;
//         _showSpeed = false;
//       });

//       final selectedMusic = ref.read(reelsProvider).selectedMusic;
//       if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
//         try {
//           await _musicPlayer.play(UrlSource(selectedMusic.audioUrl));
//           if (mounted) setState(() => _musicPlaying = true);
//         } catch (e) {
//           debugPrint('Music play error: $e');
//         }
//       }

//       final maxSec = ref.read(reelsProvider).maxDurationSeconds;
//       _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//         if (!mounted) {
//           t.cancel();
//           return;
//         }
//         setState(() => _elapsed++);
//         if (_elapsed >= maxSec) _stopRec();
//       });
//     } catch (e) {
//       debugPrint('startRec error: $e');
//       if (mounted) setState(() => _recording = false);
//     }
//   }

//   Future<void> _stopRec() async {
//     _recTimer?.cancel();
//     final ctrl = _ctrl;
//     if (ctrl == null || !_recording) return;

//     try {
//       final f = await ctrl.stopVideoRecording();
//       if (!mounted) return;
//       setState(() => _recording = false);

//       await _musicPlayer.stop();
//       if (mounted) setState(() => _musicPlaying = false);

//       // Restore mic audio for next recording session
//       await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: true);

//       ref.read(reelsProvider.notifier).setVideo(f.path);
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ReelsPreviewScreen(videoPath: f.path),
//         ),
//       );
//     } catch (e) {
//       debugPrint('stopRec error: $e');
//       if (mounted) setState(() => _recording = false);
//     }
//   }

//   String _fmt(int s) =>
//       '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

//   Widget _buildCameraPreview() {
//     if (!_ready || _ctrl == null || !_ctrl!.value.isInitialized) {
//       return const Center(
//         child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
//       );
//     }

//     final rs = ref.watch(reelsProvider);
//     final matrix = kReelFilters[rs.selectedFilterIndex].matrix;

//     return ColorFiltered(
//       colorFilter: ColorFilter.matrix(matrix),
//       child: _FullScreenCameraPreview(controller: _ctrl!),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final rs = ref.watch(reelsProvider);
//     final maxSec = rs.maxDurationSeconds;
//     final progress = _recording ? (_elapsed / maxSec).clamp(0.0, 1.0) : 0.0;
//     final safeTop = MediaQuery.of(context).padding.top;
//     final safeBot = MediaQuery.of(context).padding.bottom;
//     final h = MediaQuery.of(context).size.height;

//     return AnnotatedRegion<SystemUiOverlayStyle>(
//       value: SystemUiOverlayStyle.light,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             Positioned.fill(child: _buildCameraPreview()),

//             if (_recording)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 height: 3,
//                 child: LinearProgressIndicator(
//                   value: progress,
//                   backgroundColor: Colors.white24,
//                   valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
//                 ),
//               ),

//             Positioned(
//               top: safeTop + 8,
//               left: 12,
//               right: 12,
//               child: Row(
//                 children: [
//                   _circBtn(Icons.close, () {
//                     _musicPlayer.stop();
//                     ref.read(reelsProvider.notifier).reset();
//                     Navigator.pop(context);
//                   }),
//                   const Spacer(),
//                   // Music pill
//                   GestureDetector(
//                     onTap: () async {
//                       if (_musicPlaying) {
//                         await _musicPlayer.stop();
//                         if (mounted) setState(() => _musicPlaying = false);
//                       }
//                       if (mounted) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const ReelsMusicScreen(),
//                           ),
//                         );
//                       }
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.black54,
//                         borderRadius: BorderRadius.circular(30),
//                         border: Border.all(
//                           color:
//                               rs.selectedMusic != null
//                                   ? _kPrimary
//                                   : Colors.white38,
//                         ),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           if (_musicPlaying)
//                             const _MusicWaveBars()
//                           else
//                             Icon(
//                               Icons.music_note_rounded,
//                               color:
//                                   rs.selectedMusic != null
//                                       ? _kPrimary
//                                       : Colors.white,
//                               size: 16,
//                             ),
//                           const SizedBox(width: 6),
//                           ConstrainedBox(
//                             constraints: const BoxConstraints(maxWidth: 140),
//                             child: Text(
//                               rs.selectedMusic?.title ?? 'Add Sound',
//                               style: TextStyle(
//                                 color:
//                                     rs.selectedMusic != null
//                                         ? _kPrimary
//                                         : Colors.white,
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   _circBtn(
//                     _flash == FlashMode.off
//                         ? Icons.flash_off_rounded
//                         : Icons.flash_on_rounded,
//                     _toggleFlash,
//                   ),
//                 ],
//               ),
//             ),

//             // ── RIGHT SIDEBAR ───────────────────────────────────────────────
//             Positioned(
//               right: 12,
//               top: h * 0.22,
//               child: Column(
//                 children: [
//                   _sideItem(Icons.flip_camera_android_rounded, 'Flip', _flip),
//                   const SizedBox(height: 22),
//                   GestureDetector(
//                     onTap: () => setState(() => _showSpeed = !_showSpeed),
//                     child: _sideLabel(
//                       Icons.speed_rounded,
//                       rs.recordingSpeed == 1.0 ? '1×' : '${rs.recordingSpeed}×',
//                       highlight: rs.recordingSpeed != 1.0,
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   GestureDetector(
//                     onTap: () => setState(() => _showTimer = !_showTimer),
//                     child: _sideLabel(
//                       Icons.timer_rounded,
//                       _timerSec == 0 ? 'Timer' : '${_timerSec}s',
//                       highlight: _timerSec != 0,
//                     ),
//                   ),
//                   const SizedBox(height: 22),
//                   _sideItem(Icons.auto_fix_high_rounded, 'Effects', () {}),
//                   const SizedBox(height: 22),
//                   _sideItem(
//                     Icons.lens_blur_rounded,
//                     'Filters',
//                     () => setState(() {
//                       _showFilters = !_showFilters;
//                       _showSpeed = false;
//                       _showTimer = false;
//                     }),
//                   ),
//                 ],
//               ),
//             ),

//             // ── BOTTOM CONTROLS ─────────────────────────────────────────────
//             Positioned(
//               bottom: safeBot + 16,
//               left: 0,
//               right: 0,
//               child: Column(
//                 children: [
//                   // Duration chips
//                   if (!_recording)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 22),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children:
//                             [15, 30, 60, 180].map((d) {
//                               final sel = rs.maxDurationSeconds == d;
//                               return GestureDetector(
//                                 onTap:
//                                     () => ref
//                                         .read(reelsProvider.notifier)
//                                         .setMaxDuration(d),
//                                 child: AnimatedContainer(
//                                   duration: const Duration(milliseconds: 200),
//                                   margin: const EdgeInsets.symmetric(
//                                     horizontal: 6,
//                                   ),
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 16,
//                                     vertical: 8,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: sel ? Colors.white : Colors.black45,
//                                     borderRadius: BorderRadius.circular(20),
//                                     border: Border.all(
//                                       color:
//                                           sel ? Colors.white : Colors.white38,
//                                       width: 1.2,
//                                     ),
//                                   ),
//                                   child: Text(
//                                     d < 60 ? '${d}s' : '${d ~/ 60}m',
//                                     style: TextStyle(
//                                       color: sel ? Colors.black : Colors.white,
//                                       fontWeight: FontWeight.w700,
//                                       fontSize: 13,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                       ),
//                     ),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       // Gallery button
//                       GestureDetector(
//                         onTap: _recording ? null : _pickGallery,
//                         child: Container(
//                           width: 52,
//                           height: 52,
//                           decoration: BoxDecoration(
//                             color: Colors.white24,
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: Colors.white54),
//                           ),
//                           child: const Icon(
//                             Icons.photo_library_rounded,
//                             color: Colors.white,
//                             size: 26,
//                           ),
//                         ),
//                       ),

//                       // Record button
//                       GestureDetector(
//                         onTap: _handleRecordTap,
//                         child:
//                             _recording
//                                 ? _StopBtn(elapsed: _elapsed, max: maxSec)
//                                 : ScaleTransition(
//                                   scale: _pulseAnim,
//                                   child: Container(
//                                     width: 80,
//                                     height: 80,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(
//                                         color: Colors.white,
//                                         width: 4,
//                                       ),
//                                     ),
//                                     child: Center(
//                                       child: Container(
//                                         width: 64,
//                                         height: 64,
//                                         decoration: const BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                       ),

//                       const SizedBox(width: 52),
//                     ],
//                   ),
//                 ],
//               ),
//             ),

//             // ── FILTER PANEL ────────────────────────────────────────────────
//             if (_showFilters)
//               Positioned(
//                 bottom: safeBot + 160,
//                 left: 0,
//                 right: 0,
//                 height: 110,
//                 child: Container(
//                   color: Colors.black54,
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 10,
//                     ),
//                     itemCount: kReelFilters.length,
//                     itemBuilder: (_, i) {
//                       final f = kReelFilters[i];
//                       final sel = rs.selectedFilterIndex == i;
//                       return GestureDetector(
//                         onTap: () {
//                           ref.read(reelsProvider.notifier).setFilter(i);
//                           setState(() => _showFilters = false);
//                         },
//                         child: Container(
//                           margin: const EdgeInsets.only(right: 12),
//                           child: Column(
//                             children: [
//                               AnimatedContainer(
//                                 duration: const Duration(milliseconds: 200),
//                                 width: 60,
//                                 height: 60,
//                                 decoration: BoxDecoration(
//                                   color: Color(f.previewColor),
//                                   borderRadius: BorderRadius.circular(10),
//                                   border: Border.all(
//                                     color: sel ? _kPrimary : Colors.transparent,
//                                     width: 2.5,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 5),
//                               Text(
//                                 f.name,
//                                 style: TextStyle(
//                                   color: sel ? _kPrimary : Colors.white,
//                                   fontSize: 10,
//                                   fontWeight:
//                                       sel ? FontWeight.w700 : FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),

//             // ── SPEED PANEL ─────────────────────────────────────────────────
//             if (_showSpeed)
//               Positioned(
//                 right: 64,
//                 top: h * 0.28,
//                 child: _OptionPanel(
//                   items: const ['0.3×', '0.5×', '1×', '2×', '3×'],
//                   values: const [0.3, 0.5, 1.0, 2.0, 3.0],
//                   selectedValue: rs.recordingSpeed,
//                   onSelect: (v) {
//                     ref.read(reelsProvider.notifier).setSpeed(v);
//                     setState(() => _showSpeed = false);
//                   },
//                 ),
//               ),

//             // ── TIMER PANEL ─────────────────────────────────────────────────
//             if (_showTimer)
//               Positioned(
//                 right: 64,
//                 top: h * 0.40,
//                 child: _OptionPanel(
//                   items: const ['Off', '3s', '10s'],
//                   values: const [0.0, 3.0, 10.0],
//                   selectedValue: _timerSec.toDouble(),
//                   onSelect:
//                       (v) => setState(() {
//                         _timerSec = v.toInt();
//                         _showTimer = false;
//                       }),
//                 ),
//               ),

//             // ── COUNTDOWN OVERLAY ───────────────────────────────────────────
//             if (_countdown > 0)
//               Center(
//                 child: Text(
//                   '$_countdown',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 120,
//                     fontWeight: FontWeight.w900,
//                     shadows: [Shadow(blurRadius: 30, color: Colors.black87)],
//                   ),
//                 ),
//               ),

//             // ── REC BADGE ───────────────────────────────────────────────────
//             if (_recording)
//               Positioned(
//                 top: safeTop + 10,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 5,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.circle, color: Colors.white, size: 8),
//                         const SizedBox(width: 6),
//                         Text(
//                           _fmt(_elapsed),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─────────────────────────────────────────────────────────────────────────
//   // HELPER WIDGETS
//   // ─────────────────────────────────────────────────────────────────────────
//   Widget _circBtn(IconData icon, VoidCallback onTap) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 40,
//       height: 40,
//       decoration: const BoxDecoration(
//         color: Colors.black45,
//         shape: BoxShape.circle,
//       ),
//       child: Icon(icon, color: Colors.white, size: 22),
//     ),
//   );

//   Widget _sideItem(IconData icon, String label, VoidCallback onTap) =>
//       GestureDetector(onTap: onTap, child: _sideLabel(icon, label));

//   Widget _sideLabel(IconData icon, String label, {bool highlight = false}) =>
//       Column(
//         children: [
//           Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: Colors.black54,
//               shape: BoxShape.circle,
//               border: highlight ? Border.all(color: _kPrimary, width: 2) : null,
//             ),
//             child: Icon(
//               icon,
//               color: highlight ? _kPrimary : Colors.white,
//               size: 22,
//             ),
//           ),
//           const SizedBox(height: 3),
//           Text(
//             label,
//             style: TextStyle(
//               color: highlight ? _kPrimary : Colors.white,
//               fontSize: 10,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // ANIMATED MUSIC WAVE BARS
// // ─────────────────────────────────────────────────────────────────────────────
// class _MusicWaveBars extends StatefulWidget {
//   const _MusicWaveBars();

//   @override
//   State<_MusicWaveBars> createState() => _MusicWaveBarsState();
// }

// class _MusicWaveBarsState extends State<_MusicWaveBars>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     )..repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ctrl,
//       builder: (_, __) {
//         return Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: List.generate(4, (i) {
//             final delay = i * 0.25;
//             final t = (_ctrl.value + delay) % 1.0;
//             final barH = 4.0 + 8.0 * t;
//             return Container(
//               margin: const EdgeInsets.symmetric(horizontal: 1),
//               width: 2.5,
//               height: barH,
//               decoration: BoxDecoration(
//                 color: _kPrimary,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             );
//           }),
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // STOP BUTTON (circular progress + red square)
// // ─────────────────────────────────────────────────────────────────────────────
// class _StopBtn extends StatelessWidget {
//   final int elapsed, max;
//   const _StopBtn({required this.elapsed, required this.max});

//   @override
//   Widget build(BuildContext context) => SizedBox(
//     width: 80,
//     height: 80,
//     child: Stack(
//       alignment: Alignment.center,
//       children: [
//         SizedBox(
//           width: 80,
//           height: 80,
//           child: CircularProgressIndicator(
//             value: (elapsed / max).clamp(0.0, 1.0),
//             strokeWidth: 4,
//             backgroundColor: Colors.white30,
//             valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
//           ),
//         ),
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: Colors.red,
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // FULL SCREEN CAMERA PREVIEW — covers screen without stretch, crops edges
// // ─────────────────────────────────────────────────────────────────────────────
// class _FullScreenCameraPreview extends StatelessWidget {
//   final CameraController controller;
//   const _FullScreenCameraPreview({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     final previewSize = controller.value.previewSize;
//     if (previewSize == null) return const SizedBox.shrink();

//     // previewSize.width is always the LARGER dimension (landscape native)
//     final portraitW =
//         previewSize.height < previewSize.width
//             ? previewSize.height
//             : previewSize.width;
//     final portraitH =
//         previewSize.height > previewSize.width
//             ? previewSize.height
//             : previewSize.width;

//     return SizedBox.expand(
//       child: FittedBox(
//         fit: BoxFit.cover,
//         child: SizedBox(
//           width: portraitW,
//           height: portraitH,
//           child: CameraPreview(controller),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // OPTION PANEL (speed / timer dropdowns)
// // ─────────────────────────────────────────────────────────────────────────────
// class _OptionPanel extends StatelessWidget {
//   final List<String> items;
//   final List<double> values;
//   final double selectedValue;
//   final ValueChanged<double> onSelect;

//   const _OptionPanel({
//     required this.items,
//     required this.values,
//     required this.selectedValue,
//     required this.onSelect,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//     decoration: BoxDecoration(
//       color: Colors.black87,
//       borderRadius: BorderRadius.circular(14),
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(items.length, (i) {
//         final sel = values[i] == selectedValue;
//         return GestureDetector(
//           onTap: () => onSelect(values[i]),
//           child: Container(
//             width: 58,
//             padding: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: sel ? _kPrimary : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Text(
//               items[i],
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: sel ? Colors.black : Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         );
//       }),
//     ),
//   );
// }

// // import 'dart:async';
// // import 'dart:io';
// // import 'package:audioplayers/audioplayers.dart';
// // import 'package:camera/camera.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:innovator/Innovator/provider/reels_provider.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:path_provider/path_provider.dart';

// // import 'reels_music_screen.dart';
// // import 'reels_preview_screen.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:http_parser/http_parser.dart';
// // import 'package:innovator/Innovator/App_data/App_data.dart';
// // import 'package:innovator/Innovator/constant/api_constants.dart';
// // import 'package:innovator/Innovator/provider/upload_provider.dart';

// // const _kPrimary = Color.fromRGBO(244, 135, 6, 1);

// // class ReelsCameraScreen extends ConsumerStatefulWidget {
// //   const ReelsCameraScreen({super.key});

// //   static Future<void> openWithPermissions(BuildContext context) async {
// //     var camStatus = await Permission.camera.status;
// //     var micStatus = await Permission.microphone.status;
// //     if (!camStatus.isGranted) camStatus = await Permission.camera.request();
// //     if (!micStatus.isGranted) micStatus = await Permission.microphone.request();
// //     if (!camStatus.isGranted || !micStatus.isGranted) {
// //       if (context.mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text('Camera & microphone permission required'),
// //             behavior: SnackBarBehavior.floating,
// //           ),
// //         );
// //       }
// //       return;
// //     }
// //     if (context.mounted) {
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (_) => const ReelsCameraScreen()),
// //       );
// //     }
// //   }

// //   @override
// //   ConsumerState<ReelsCameraScreen> createState() => _ReelsCameraScreenState();
// // }

// // class _ReelsCameraScreenState extends ConsumerState<ReelsCameraScreen>
// //     with WidgetsBindingObserver, SingleTickerProviderStateMixin {
// //   bool _micEnabled = true;
// //   List<CameraDescription> _cameras = [];
// //   CameraController? _ctrl;
// //   bool _ready = false;
// //   bool _recording = false;
// //   bool _isFront = false;
// //   FlashMode _flash = FlashMode.off;
// //   int _elapsed = 0;
// //   Timer? _recTimer;
// //   int _countdown = 0;
// //   Timer? _cdTimer;
// //   int _timerSec = 0;
// //   bool _showFilters = false;
// //   bool _showSpeed = false;
// //   bool _showTimer = false;

// //   // ── Mode: 'both' = tap→photo, hold→video (Instagram style) ──────────────
// //   bool _isHolding = false;
// //   bool _captureMode = false; // true while actively taking photo

// //   late AnimationController _pulse;
// //   late Animation<double> _pulseAnim;

// //   final AudioPlayer _musicPlayer = AudioPlayer();
// //   bool _musicPlaying = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);
// //     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
// //     _pulse = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 900),
// //     )..repeat(reverse: true);
// //     _pulseAnim = Tween(begin: 1.0, end: 1.10).animate(_pulse);
// //     _initCams();
// //   }

// //   Future<void> _initCams() async {
// //     try {
// //       final camOk = await Permission.camera.status;
// //       final micOk = await Permission.microphone.status;
// //       if (!camOk.isGranted || !micOk.isGranted) {
// //         final cam = await Permission.camera.request();
// //         final mic = await Permission.microphone.request();
// //         if (!cam.isGranted || !mic.isGranted) return;
// //       }
// //       _cameras = await availableCameras();
// //       if (_cameras.isEmpty) return;
// //       await _initCtrl(_cameras[0]);
// //     } catch (e) {
// //       debugPrint('cam init error: $e');
// //     }
// //   }

// //   Future<void> _initCtrl(CameraDescription d, {bool enableAudio = true}) async {
// //     final old = _ctrl;
// //     if (mounted) setState(() => _ready = false);
// //     _ctrl = null;
// //     _micEnabled = enableAudio;
// //     try {
// //       await old?.dispose();
// //     } catch (_) {}
// //     final controller = CameraController(
// //       d,
// //       ResolutionPreset.veryHigh,
// //       enableAudio: enableAudio,
// //       imageFormatGroup: ImageFormatGroup.jpeg,
// //     );
// //     _ctrl = controller;
// //     try {
// //       await controller.initialize();
// //       if (!mounted) {
// //         await controller.dispose();
// //         _ctrl = null;
// //         return;
// //       }
// //       await controller.setFocusMode(FocusMode.auto);
// //       await controller.setExposureMode(ExposureMode.auto);
// //       if (mounted) setState(() => _ready = true);
// //     } catch (e) {
// //       debugPrint('ctrl init error: $e');
// //       try {
// //         await controller.dispose();
// //       } catch (_) {}
// //       _ctrl = null;
// //       if (mounted) setState(() => _ready = false);
// //     }
// //   }

// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState s) {
// //     final ctrl = _ctrl;
// //     if (ctrl == null || !ctrl.value.isInitialized) return;
// //     if (s == AppLifecycleState.inactive) {
// //       _recTimer?.cancel();
// //       _musicPlayer.pause();
// //       ctrl.dispose();
// //       _ctrl = null;
// //       if (mounted) setState(() => _ready = false);
// //     } else if (s == AppLifecycleState.resumed) {
// //       if (_cameras.isNotEmpty) _initCtrl(_cameras[_isFront ? 1 : 0]);
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     _recTimer?.cancel();
// //     _cdTimer?.cancel();
// //     _ctrl?.dispose();
// //     _pulse.dispose();
// //     _musicPlayer.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _flip() async {
// //     if (_cameras.length < 2 || _recording) return;
// //     if (!mounted) return;
// //     setState(() {
// //       _ready = false;
// //       _isFront = !_isFront;
// //     });
// //     ref.read(reelsProvider.notifier).toggleCamera();
// //     final index = _isFront ? 1 : 0;
// //     if (index < _cameras.length) await _initCtrl(_cameras[index]);
// //   }

// //   Future<void> _toggleFlash() async {
// //     if (_ctrl == null || !_ready) return;
// //     final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
// //     try {
// //       await _ctrl?.setFlashMode(next);
// //       if (mounted) setState(() => _flash = next);
// //     } catch (e) {
// //       debugPrint('flash error: $e');
// //     }
// //   }

// //   Future<void> _pickGallery() async {
// //     final picker = ImagePicker();
// //     // Show sheet: pick video or photo
// //     final choice = await showModalBottomSheet<String>(
// //       context: context,
// //       backgroundColor: const Color(0xFF1A1A1A),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder:
// //           (_) => SafeArea(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 ListTile(
// //                   leading: const Icon(
// //                     Icons.videocam_rounded,
// //                     color: Colors.white,
// //                   ),
// //                   title: const Text(
// //                     'Pick Video',
// //                     style: TextStyle(color: Colors.white),
// //                   ),
// //                   onTap: () => Navigator.pop(context, 'video'),
// //                 ),
// //                 ListTile(
// //                   leading: const Icon(Icons.photo_rounded, color: Colors.white),
// //                   title: const Text(
// //                     'Pick Photo',
// //                     style: TextStyle(color: Colors.white),
// //                   ),
// //                   onTap: () => Navigator.pop(context, 'photo'),
// //                 ),
// //               ],
// //             ),
// //           ),
// //     );
// //     if (choice == 'video') {
// //       final v = await picker.pickVideo(
// //         source: ImageSource.gallery,
// //         maxDuration: const Duration(minutes: 3),
// //       );
// //       if (v != null && mounted) {
// //         ref.read(reelsProvider.notifier).setVideo(v.path, fromGallery: true);
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => ReelsPreviewScreen(videoPath: v.path),
// //           ),
// //         );
// //       }
// //     } else if (choice == 'photo') {
// //       final p = await picker.pickImage(source: ImageSource.gallery);
// //       if (p != null && mounted) {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => ReelsPhotoPreviewScreen(imagePath: p.path),
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   // ── TAP → Take Photo ────────────────────────────────────────────────────
// //   Future<void> _takePhoto() async {
// //     final ctrl = _ctrl;
// //     if (ctrl == null || !ctrl.value.isInitialized || !_ready || _recording)
// //       return;
// //     if (mounted) setState(() => _captureMode = true);
// //     try {
// //       final file = await ctrl.takePicture();
// //       if (mounted) {
// //         setState(() => _captureMode = false);
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => ReelsPhotoPreviewScreen(imagePath: file.path),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       debugPrint('takePicture error: $e');
// //       if (mounted) setState(() => _captureMode = false);
// //     }
// //   }

// //   // ── LONG PRESS START → Start Video Recording ────────────────────────────
// //   void _onLongPressStart(LongPressStartDetails _) {
// //     if (_recording) return;
// //     setState(() => _isHolding = true);
// //     if (_timerSec > 0) {
// //       _startCountdown();
// //     } else {
// //       _startRec();
// //     }
// //   }

// //   // ── LONG PRESS END → Stop Video Recording ───────────────────────────────
// //   void _onLongPressEnd(LongPressEndDetails _) {
// //     setState(() => _isHolding = false);
// //     if (_recording && !_stopping) _stopRec();
// //   }

// //   void _startCountdown() {
// //     if (mounted) setState(() => _countdown = _timerSec);
// //     _cdTimer = Timer.periodic(const Duration(seconds: 1), (t) {
// //       if (!mounted) {
// //         t.cancel();
// //         return;
// //       }
// //       setState(() => _countdown--);
// //       if (_countdown <= 0) {
// //         t.cancel();
// //         _startRec();
// //       }
// //     });
// //   }

// //   Future<void> _startRec() async {
// //     // Reset stop-guard so a new recording cycle is always allowed
// //     _stopping = false;

// //     final hasMusic = ref.read(reelsProvider).selectedMusic != null;
// //     // Always reinit without mic when music is selected, regardless of
// //     // the current _micEnabled value (which may be stale from a prior cycle).
// //     if (hasMusic) {
// //       await _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: false);
// //       if (!_ready || _ctrl == null || !mounted) return;
// //     }
// //     final ctrl = _ctrl;
// //     if (ctrl == null || !ctrl.value.isInitialized || !_ready) return;
// //     try {
// //       await ctrl.startVideoRecording();
// //       if (!mounted) return;
// //       setState(() {
// //         _recording = true;
// //         _elapsed = 0;
// //         _showFilters = false;
// //         _showSpeed = false;
// //       });
// //       final selectedMusic = ref.read(reelsProvider).selectedMusic;
// //       if (selectedMusic != null && selectedMusic.audioUrl.isNotEmpty) {
// //         try {
// //           await _musicPlayer.stop(); // ensure clean state before playing
// //           await _musicPlayer.play(UrlSource(selectedMusic.audioUrl));
// //           if (mounted) setState(() => _musicPlaying = true);
// //         } catch (e) {
// //           debugPrint('Music play error: $e');
// //         }
// //       }
// //       final maxSec = ref.read(reelsProvider).maxDurationSeconds;
// //       _recTimer = Timer.periodic(const Duration(seconds: 1), (t) {
// //         if (!mounted) {
// //           t.cancel();
// //           return;
// //         }
// //         setState(() => _elapsed++);
// //         if (_elapsed >= maxSec) _stopRec();
// //       });
// //     } catch (e) {
// //       debugPrint('startRec error: $e');
// //       if (mounted)
// //         setState(() {
// //           _recording = false;
// //           _isHolding = false;
// //         });
// //     }
// //   }

// //   // Guards against the timer and user tapping stop at the exact same moment.
// //   bool _stopping = false;

// //   Future<void> _stopRec() async {
// //     // Guard: already stopping (timer + tap race)
// //     if (_stopping) return;
// //     _stopping = true;

// //     _recTimer?.cancel();
// //     _recTimer = null;

// //     final ctrl = _ctrl;
// //     if (ctrl == null || !_recording) {
// //       _stopping = false;
// //       return;
// //     }

// //     try {
// //       // 1. Stop music FIRST so it never bleeds past recording end
// //       await _musicPlayer.stop();
// //       if (mounted) setState(() => _musicPlaying = false);

// //       // 2. Stop the camera recording
// //       final f = await ctrl.stopVideoRecording();
// //       if (!mounted) {
// //         _stopping = false;
// //         return;
// //       }

// //       setState(() {
// //         _recording = false;
// //         _isHolding = false;
// //       });

// //       // 3. Navigate to preview IMMEDIATELY — do NOT wait for camera reinit
// //       ref.read(reelsProvider.notifier).setVideo(f.path);
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(
// //           builder: (_) => ReelsPreviewScreen(videoPath: f.path),
// //         ),
// //       );

// //       // 4. Reinitialise camera in the background for when user pops back
// //       _initCtrl(_cameras[_isFront ? 1 : 0], enableAudio: true);
// //     } catch (e) {
// //       debugPrint('stopRec error: $e');
// //       if (mounted) {
// //         setState(() {
// //           _recording = false;
// //           _isHolding = false;
// //         });
// //       }
// //     } finally {
// //       _stopping = false;
// //     }
// //   }

// //   String _fmt(int s) =>
// //       '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

// //   Widget _buildCameraPreview() {
// //     if (!_ready || _ctrl == null || !_ctrl!.value.isInitialized) {
// //       return const Center(
// //         child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2),
// //       );
// //     }
// //     final rs = ref.watch(reelsProvider);
// //     final matrix = kReelFilters[rs.selectedFilterIndex].matrix;
// //     return ColorFiltered(
// //       colorFilter: ColorFilter.matrix(matrix),
// //       child: _FullScreenCameraPreview(controller: _ctrl!),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final rs = ref.watch(reelsProvider);
// //     final maxSec = rs.maxDurationSeconds;
// //     final progress = _recording ? (_elapsed / maxSec).clamp(0.0, 1.0) : 0.0;
// //     final safeTop = MediaQuery.of(context).padding.top;
// //     final safeBot = MediaQuery.of(context).padding.bottom;
// //     final h = MediaQuery.of(context).size.height;

// //     return AnnotatedRegion<SystemUiOverlayStyle>(
// //       value: SystemUiOverlayStyle.light,
// //       child: Scaffold(
// //         backgroundColor: Colors.black,
// //         body: Stack(
// //           fit: StackFit.expand,
// //           children: [
// //             Positioned.fill(child: _buildCameraPreview()),

// //             // ── Progress bar ────────────────────────────────────────────
// //             if (_recording)
// //               Positioned(
// //                 top: 0,
// //                 left: 0,
// //                 right: 0,
// //                 height: 3,
// //                 child: LinearProgressIndicator(
// //                   value: progress,
// //                   backgroundColor: Colors.white24,
// //                   valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
// //                 ),
// //               ),

// //             // ── Top bar ─────────────────────────────────────────────────
// //             Positioned(
// //               top: safeTop + 8,
// //               left: 12,
// //               right: 12,
// //               child: Row(
// //                 children: [
// //                   _circBtn(Icons.close, () {
// //                     _musicPlayer.stop();
// //                     ref.read(reelsProvider.notifier).reset();
// //                     Navigator.pop(context);
// //                   }),
// //                   const Spacer(),
// //                   // Music pill
// //                   GestureDetector(
// //                     onTap: () async {
// //                       if (_musicPlaying) {
// //                         await _musicPlayer.stop();
// //                         if (mounted) setState(() => _musicPlaying = false);
// //                       }
// //                       if (mounted) {
// //                         Navigator.push(
// //                           context,
// //                           MaterialPageRoute(
// //                             builder: (_) => const ReelsMusicScreen(),
// //                           ),
// //                         );
// //                       }
// //                     },
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 14,
// //                         vertical: 8,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: Colors.black54,
// //                         borderRadius: BorderRadius.circular(30),
// //                         border: Border.all(
// //                           color:
// //                               rs.selectedMusic != null
// //                                   ? _kPrimary
// //                                   : Colors.white38,
// //                         ),
// //                       ),
// //                       child: Row(
// //                         mainAxisSize: MainAxisSize.min,
// //                         children: [
// //                           if (_musicPlaying)
// //                             const _MusicWaveBars()
// //                           else
// //                             Icon(
// //                               Icons.music_note_rounded,
// //                               color:
// //                                   rs.selectedMusic != null
// //                                       ? _kPrimary
// //                                       : Colors.white,
// //                               size: 16,
// //                             ),
// //                           const SizedBox(width: 6),
// //                           ConstrainedBox(
// //                             constraints: const BoxConstraints(maxWidth: 140),
// //                             child: Text(
// //                               rs.selectedMusic?.title ?? 'Add Sound',
// //                               style: TextStyle(
// //                                 color:
// //                                     rs.selectedMusic != null
// //                                         ? _kPrimary
// //                                         : Colors.white,
// //                                 fontSize: 13,
// //                                 fontWeight: FontWeight.w700,
// //                               ),
// //                               maxLines: 1,
// //                               overflow: TextOverflow.ellipsis,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   _circBtn(
// //                     _flash == FlashMode.off
// //                         ? Icons.flash_off_rounded
// //                         : Icons.flash_on_rounded,
// //                     _toggleFlash,
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // ── RIGHT SIDEBAR ────────────────────────────────────────────
// //             Positioned(
// //               right: 12,
// //               top: h * 0.22,
// //               child: Column(
// //                 children: [
// //                   _sideItem(Icons.flip_camera_android_rounded, 'Flip', _flip),
// //                   const SizedBox(height: 22),
// //                   GestureDetector(
// //                     onTap: () => setState(() => _showSpeed = !_showSpeed),
// //                     child: _sideLabel(
// //                       Icons.speed_rounded,
// //                       rs.recordingSpeed == 1.0 ? '1×' : '${rs.recordingSpeed}×',
// //                       highlight: rs.recordingSpeed != 1.0,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 22),
// //                   GestureDetector(
// //                     onTap: () => setState(() => _showTimer = !_showTimer),
// //                     child: _sideLabel(
// //                       Icons.timer_rounded,
// //                       _timerSec == 0 ? 'Timer' : '${_timerSec}s',
// //                       highlight: _timerSec != 0,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 22),
// //                   _sideItem(Icons.auto_fix_high_rounded, 'Effects', () {}),
// //                   const SizedBox(height: 22),
// //                   _sideItem(
// //                     Icons.lens_blur_rounded,
// //                     'Filters',
// //                     () => setState(() {
// //                       _showFilters = !_showFilters;
// //                       _showSpeed = false;
// //                       _showTimer = false;
// //                     }),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // ── MODE HINT ────────────────────────────────────────────────
// //             if (!_recording)
// //               Positioned(
// //                 bottom: safeBot + 170,
// //                 left: 0,
// //                 right: 0,
// //                 child: const Center(
// //                   child: Text(
// //                     'TAP for photo • HOLD for video',
// //                     style: TextStyle(
// //                       color: Colors.white54,
// //                       fontSize: 12,
// //                       fontWeight: FontWeight.w500,
// //                     ),
// //                   ),
// //                 ),
// //               ),

// //             // ── BOTTOM CONTROLS ──────────────────────────────────────────
// //             Positioned(
// //               bottom: safeBot + 16,
// //               left: 0,
// //               right: 0,
// //               child: Column(
// //                 children: [
// //                   // Duration chips (video mode only)
// //                   if (!_recording && !_isHolding)
// //                     Padding(
// //                       padding: const EdgeInsets.only(bottom: 22),
// //                       child: Row(
// //                         mainAxisAlignment: MainAxisAlignment.center,
// //                         children:
// //                             [15, 30, 60, 180].map((d) {
// //                               final sel = rs.maxDurationSeconds == d;
// //                               return GestureDetector(
// //                                 onTap:
// //                                     () => ref
// //                                         .read(reelsProvider.notifier)
// //                                         .setMaxDuration(d),
// //                                 child: AnimatedContainer(
// //                                   duration: const Duration(milliseconds: 200),
// //                                   margin: const EdgeInsets.symmetric(
// //                                     horizontal: 6,
// //                                   ),
// //                                   padding: const EdgeInsets.symmetric(
// //                                     horizontal: 16,
// //                                     vertical: 8,
// //                                   ),
// //                                   decoration: BoxDecoration(
// //                                     color: sel ? Colors.white : Colors.black45,
// //                                     borderRadius: BorderRadius.circular(20),
// //                                     border: Border.all(
// //                                       color:
// //                                           sel ? Colors.white : Colors.white38,
// //                                       width: 1.2,
// //                                     ),
// //                                   ),
// //                                   child: Text(
// //                                     d < 60 ? '${d}s' : '${d ~/ 60}m',
// //                                     style: TextStyle(
// //                                       color: sel ? Colors.black : Colors.white,
// //                                       fontWeight: FontWeight.w700,
// //                                       fontSize: 13,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               );
// //                             }).toList(),
// //                       ),
// //                     ),

// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                     crossAxisAlignment: CrossAxisAlignment.center,
// //                     children: [
// //                       // Gallery button
// //                       GestureDetector(
// //                         onTap: _recording ? null : _pickGallery,
// //                         child: Container(
// //                           width: 52,
// //                           height: 52,
// //                           decoration: BoxDecoration(
// //                             color: Colors.white24,
// //                             borderRadius: BorderRadius.circular(10),
// //                             border: Border.all(color: Colors.white54),
// //                           ),
// //                           child: const Icon(
// //                             Icons.photo_library_rounded,
// //                             color: Colors.white,
// //                             size: 26,
// //                           ),
// //                         ),
// //                       ),

// //                       // ── INSTAGRAM-STYLE CAPTURE BUTTON ────────────────
// //                       // Tap = photo, Hold = video
// //                       GestureDetector(
// //                         onTap: _recording ? _stopRec : _takePhoto,
// //                         onLongPressStart: _recording ? null : _onLongPressStart,
// //                         onLongPressEnd: _recording ? null : _onLongPressEnd,
// //                         child:
// //                             _recording
// //                                 ? _StopBtn(elapsed: _elapsed, max: maxSec)
// //                                 : AnimatedContainer(
// //                                   duration: const Duration(milliseconds: 120),
// //                                   width: _isHolding ? 90 : 80,
// //                                   height: _isHolding ? 90 : 80,
// //                                   decoration: BoxDecoration(
// //                                     shape: BoxShape.circle,
// //                                     border: Border.all(
// //                                       color:
// //                                           _isHolding ? _kPrimary : Colors.white,
// //                                       width: _isHolding ? 5 : 4,
// //                                     ),
// //                                   ),
// //                                   child: Center(
// //                                     child: AnimatedContainer(
// //                                       duration: const Duration(
// //                                         milliseconds: 120,
// //                                       ),
// //                                       width: _isHolding ? 74 : 64,
// //                                       height: _isHolding ? 74 : 64,
// //                                       decoration: BoxDecoration(
// //                                         shape: BoxShape.circle,
// //                                         color:
// //                                             _captureMode
// //                                                 ? Colors.white60
// //                                                 : _isHolding
// //                                                 ? _kPrimary
// //                                                 : Colors.white,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ),
// //                       ),

// //                       // Flip button (right side)
// //                       GestureDetector(
// //                         onTap: _recording ? null : _flip,
// //                         child: Container(
// //                           width: 52,
// //                           height: 52,
// //                           decoration: const BoxDecoration(
// //                             color: Colors.white24,
// //                             shape: BoxShape.circle,
// //                           ),
// //                           child: const Icon(
// //                             Icons.flip_camera_android_rounded,
// //                             color: Colors.white,
// //                             size: 26,
// //                           ),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             // ── FILTER PANEL ─────────────────────────────────────────────
// //             if (_showFilters)
// //               Positioned(
// //                 bottom: safeBot + 160,
// //                 left: 0,
// //                 right: 0,
// //                 height: 110,
// //                 child: Container(
// //                   color: Colors.black54,
// //                   child: ListView.builder(
// //                     scrollDirection: Axis.horizontal,
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 12,
// //                       vertical: 10,
// //                     ),
// //                     itemCount: kReelFilters.length,
// //                     itemBuilder: (_, i) {
// //                       final f = kReelFilters[i];
// //                       final sel = rs.selectedFilterIndex == i;
// //                       return GestureDetector(
// //                         onTap: () {
// //                           ref.read(reelsProvider.notifier).setFilter(i);
// //                           setState(() => _showFilters = false);
// //                         },
// //                         child: Container(
// //                           margin: const EdgeInsets.only(right: 12),
// //                           child: Column(
// //                             children: [
// //                               AnimatedContainer(
// //                                 duration: const Duration(milliseconds: 200),
// //                                 width: 60,
// //                                 height: 60,
// //                                 decoration: BoxDecoration(
// //                                   color: Color(f.previewColor),
// //                                   borderRadius: BorderRadius.circular(10),
// //                                   border: Border.all(
// //                                     color: sel ? _kPrimary : Colors.transparent,
// //                                     width: 2.5,
// //                                   ),
// //                                 ),
// //                               ),
// //                               const SizedBox(height: 5),
// //                               Text(
// //                                 f.name,
// //                                 style: TextStyle(
// //                                   color: sel ? _kPrimary : Colors.white,
// //                                   fontSize: 10,
// //                                   fontWeight:
// //                                       sel ? FontWeight.w700 : FontWeight.w500,
// //                                 ),
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //               ),

// //             // ── SPEED PANEL ──────────────────────────────────────────────
// //             if (_showSpeed)
// //               Positioned(
// //                 right: 64,
// //                 top: h * 0.28,
// //                 child: _OptionPanel(
// //                   items: const ['0.3×', '0.5×', '1×', '2×', '3×'],
// //                   values: const [0.3, 0.5, 1.0, 2.0, 3.0],
// //                   selectedValue: rs.recordingSpeed,
// //                   onSelect: (v) {
// //                     ref.read(reelsProvider.notifier).setSpeed(v);
// //                     setState(() => _showSpeed = false);
// //                   },
// //                 ),
// //               ),

// //             // ── TIMER PANEL ───────────────────────────────────────────────
// //             if (_showTimer)
// //               Positioned(
// //                 right: 64,
// //                 top: h * 0.40,
// //                 child: _OptionPanel(
// //                   items: const ['Off', '3s', '10s'],
// //                   values: const [0.0, 3.0, 10.0],
// //                   selectedValue: _timerSec.toDouble(),
// //                   onSelect:
// //                       (v) => setState(() {
// //                         _timerSec = v.toInt();
// //                         _showTimer = false;
// //                       }),
// //                 ),
// //               ),

// //             // ── COUNTDOWN OVERLAY ─────────────────────────────────────────
// //             if (_countdown > 0)
// //               Center(
// //                 child: Text(
// //                   '$_countdown',
// //                   style: const TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 120,
// //                     fontWeight: FontWeight.w900,
// //                     shadows: [Shadow(blurRadius: 30, color: Colors.black87)],
// //                   ),
// //                 ),
// //               ),

// //             // ── REC BADGE ─────────────────────────────────────────────────
// //             if (_recording)
// //               Positioned(
// //                 top: safeTop + 10,
// //                 left: 0,
// //                 right: 0,
// //                 child: Center(
// //                   child: Container(
// //                     padding: const EdgeInsets.symmetric(
// //                       horizontal: 14,
// //                       vertical: 5,
// //                     ),
// //                     decoration: BoxDecoration(
// //                       color: Colors.red,
// //                       borderRadius: BorderRadius.circular(20),
// //                     ),
// //                     child: Row(
// //                       mainAxisSize: MainAxisSize.min,
// //                       children: [
// //                         const Icon(Icons.circle, color: Colors.white, size: 8),
// //                         const SizedBox(width: 6),
// //                         Text(
// //                           _fmt(_elapsed),
// //                           style: const TextStyle(
// //                             color: Colors.white,
// //                             fontWeight: FontWeight.bold,
// //                             fontSize: 13,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //               ),

// //             // ── PHOTO FLASH ───────────────────────────────────────────────
// //             if (_captureMode)
// //               Positioned.fill(
// //                 child: IgnorePointer(
// //                   child: AnimatedOpacity(
// //                     opacity: _captureMode ? 0.6 : 0.0,
// //                     duration: const Duration(milliseconds: 80),
// //                     child: Container(color: Colors.white),
// //                   ),
// //                 ),
// //               ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _circBtn(IconData icon, VoidCallback onTap) => GestureDetector(
// //     onTap: onTap,
// //     child: Container(
// //       width: 40,
// //       height: 40,
// //       decoration: const BoxDecoration(
// //         color: Colors.black45,
// //         shape: BoxShape.circle,
// //       ),
// //       child: Icon(icon, color: Colors.white, size: 22),
// //     ),
// //   );

// //   Widget _sideItem(IconData icon, String label, VoidCallback onTap) =>
// //       GestureDetector(onTap: onTap, child: _sideLabel(icon, label));

// //   Widget _sideLabel(IconData icon, String label, {bool highlight = false}) =>
// //       Column(
// //         children: [
// //           Container(
// //             width: 44,
// //             height: 44,
// //             decoration: BoxDecoration(
// //               color: Colors.black54,
// //               shape: BoxShape.circle,
// //               border: highlight ? Border.all(color: _kPrimary, width: 2) : null,
// //             ),
// //             child: Icon(
// //               icon,
// //               color: highlight ? _kPrimary : Colors.white,
// //               size: 22,
// //             ),
// //           ),
// //           const SizedBox(height: 3),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               color: highlight ? _kPrimary : Colors.white,
// //               fontSize: 10,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //         ],
// //       );
// // }

// // // ─── Photo Preview Screen ─────────────────────────────────────────────────────
// // class ReelsPhotoPreviewScreen extends ConsumerStatefulWidget {
// //   final String imagePath;
// //   const ReelsPhotoPreviewScreen({super.key, required this.imagePath});

// //   @override
// //   ConsumerState<ReelsPhotoPreviewScreen> createState() =>
// //       _ReelsPhotoPreviewScreenState();
// // }

// // class _ReelsPhotoPreviewScreenState
// //     extends ConsumerState<ReelsPhotoPreviewScreen> {
// //   final TextEditingController _captionCtrl = TextEditingController();
// //   bool _isUploading = false;
// //   final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

// //   @override
// //   void dispose() {
// //     _captionCtrl.dispose();
// //     super.dispose();
// //   }

// //   Future<void> _uploadPhoto() async {
// //     if (_isUploading) return;
// //     setState(() => _isUploading = true);

// //     // Signal global upload banner on the home screen
// //     ref.read(postUploadingProvider.notifier).state = true;
// //     ref.read(postUploadMessageProvider.notifier).state = null;

// //     try {
// //       final appData = AppData();
// //       await appData.initialize();

// //       final uri = Uri.parse(ApiConstants.createpost);
// //       final request = http.MultipartRequest('POST', uri);

// //       // Auth header
// //       if (appData.accessToken != null) {
// //         request.headers['Authorization'] = 'Bearer ${appData.accessToken}';
// //       }

// //       // Caption / content field
// //       final caption = _captionCtrl.text.trim();
// //       if (caption.isNotEmpty) {
// //         request.fields['content'] = caption;
// //       }

// //       // Attach the image file
// //       request.files.add(
// //         await http.MultipartFile.fromPath(
// //           'media',
// //           widget.imagePath,
// //           contentType: MediaType('image', 'jpeg'),
// //         ),
// //       );

// //       final streamed = await request.send().timeout(const Duration(seconds: 60));
// //       final response = await http.Response.fromStream(streamed);

// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         ref.read(postUploadingProvider.notifier).state = false;
// //         ref.read(postUploadMessageProvider.notifier).state =
// //             'Photo posted successfully! 📸';
// //         if (mounted) {
// //           Navigator.of(context).popUntil((r) => r.isFirst);
// //         }
// //       } else {
// //         throw Exception('Server returned ${response.statusCode}: ${response.body}');
// //       }
// //     } catch (e) {
// //       ref.read(postUploadingProvider.notifier).state = false;
// //       ref.read(postUploadMessageProvider.notifier).state =
// //           'Upload failed. Please try again.';
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text('Upload error: $e'),
// //             backgroundColor: Colors.red.shade700,
// //           ),
// //         );
// //       }
// //     } finally {
// //       if (mounted) setState(() => _isUploading = false);
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: Stack(
// //         fit: StackFit.expand,
// //         children: [
// //           // Photo preview
// //           Positioned.fill(
// //             child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
// //           ),
// //           // Top bar
// //           Positioned(
// //             top: MediaQuery.of(context).padding.top,
// //             left: 0,
// //             right: 0,
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(
// //                       Icons.arrow_back_ios_new_rounded,
// //                       color: Colors.white,
// //                     ),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const Spacer(),
// //                   const Text(
// //                     'Photo',
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   const Spacer(),
// //                   const SizedBox(width: 48),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           // Bottom controls
// //           Positioned(
// //             bottom: 0,
// //             left: 0,
// //             right: 0,
// //             child: Container(
// //               padding: EdgeInsets.only(
// //                 bottom: MediaQuery.of(context).padding.bottom + 12,
// //                 top: 12,
// //                 left: 16,
// //                 right: 16,
// //               ),
// //               decoration: const BoxDecoration(
// //                 gradient: LinearGradient(
// //                   begin: Alignment.bottomCenter,
// //                   end: Alignment.topCenter,
// //                   colors: [Colors.black, Colors.transparent],
// //                   stops: [0.55, 1.0],
// //                 ),
// //               ),
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: GestureDetector(
// //                       onTap: () => _showCaptionSheet(),
// //                       child: Container(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 14,
// //                           vertical: 10,
// //                         ),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white12,
// //                           borderRadius: BorderRadius.circular(24),
// //                           border: Border.all(color: Colors.white30),
// //                         ),
// //                         child: Text(
// //                           _captionCtrl.text.isEmpty
// //                               ? 'Write a caption...'
// //                               : _captionCtrl.text,
// //                           style: TextStyle(
// //                             color:
// //                                 _captionCtrl.text.isEmpty
// //                                     ? Colors.white38
// //                                     : Colors.white,
// //                             fontSize: 14,
// //                           ),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 10),
// //                   GestureDetector(
// //                     onTap: _isUploading ? null : _uploadPhoto,
// //                     child: Container(
// //                       padding: const EdgeInsets.symmetric(
// //                         horizontal: 20,
// //                         vertical: 10,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: _orange,
// //                         borderRadius: BorderRadius.circular(24),
// //                       ),
// //                       child:
// //                           _isUploading
// //                               ? const SizedBox(
// //                                 width: 18,
// //                                 height: 18,
// //                                 child: CircularProgressIndicator(
// //                                   color: Colors.white,
// //                                   strokeWidth: 2,
// //                                 ),
// //                               )
// //                               : const Text(
// //                                 'Share',
// //                                 style: TextStyle(
// //                                   color: Colors.white,
// //                                   fontWeight: FontWeight.bold,
// //                                   fontSize: 15,
// //                                 ),
// //                               ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showCaptionSheet() {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       backgroundColor: const Color(0xFF1A1A1A),
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //       ),
// //       builder:
// //           (_) => Padding(
// //             padding: EdgeInsets.only(
// //               bottom: MediaQuery.of(context).viewInsets.bottom,
// //             ),
// //             child: Container(
// //               padding: const EdgeInsets.all(20),
// //               child: Column(
// //                 mainAxisSize: MainAxisSize.min,
// //                 children: [
// //                   Row(
// //                     children: [
// //                       const Text(
// //                         'Caption',
// //                         style: TextStyle(
// //                           color: Colors.white,
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                         ),
// //                       ),
// //                       const Spacer(),
// //                       TextButton(
// //                         onPressed: () {
// //                           Navigator.pop(context);
// //                           setState(() {});
// //                         },
// //                         child: Text(
// //                           'Done',
// //                           style: TextStyle(color: _orange, fontSize: 15),
// //                         ),
// //                       ),
// //                     ],
// //                   ),
// //                   const SizedBox(height: 12),
// //                   TextField(
// //                     controller: _captionCtrl,
// //                     autofocus: true,
// //                     maxLines: 4,
// //                     style: const TextStyle(color: Colors.white),
// //                     decoration: InputDecoration(
// //                       hintText: 'Write a caption...',
// //                       hintStyle: const TextStyle(color: Colors.white38),
// //                       filled: true,
// //                       fillColor: Colors.white12,
// //                       border: OutlineInputBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                         borderSide: BorderSide.none,
// //                       ),
// //                     ),
// //                     onChanged: (_) => setState(() {}),
// //                   ),
// //                   const SizedBox(height: 8),
// //                 ],
// //               ),
// //             ),
// //           ),
// //     );
// //   }
// // }

// // // ─── Animated Music Wave Bars ─────────────────────────────────────────────────
// // class _MusicWaveBars extends StatefulWidget {
// //   const _MusicWaveBars();
// //   @override
// //   State<_MusicWaveBars> createState() => _MusicWaveBarsState();
// // }

// // class _MusicWaveBarsState extends State<_MusicWaveBars>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _ctrl;
// //   @override
// //   void initState() {
// //     super.initState();
// //     _ctrl = AnimationController(
// //       vsync: this,
// //       duration: const Duration(milliseconds: 600),
// //     )..repeat(reverse: true);
// //   }

// //   @override
// //   void dispose() {
// //     _ctrl.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return AnimatedBuilder(
// //       animation: _ctrl,
// //       builder:
// //           (_, __) => Row(
// //             mainAxisAlignment: MainAxisAlignment.center,
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: List.generate(4, (i) {
// //               final t = (_ctrl.value + i * 0.25) % 1.0;
// //               final barH = 4.0 + 8.0 * t;
// //               return Container(
// //                 margin: const EdgeInsets.symmetric(horizontal: 1),
// //                 width: 2.5,
// //                 height: barH,
// //                 decoration: BoxDecoration(
// //                   color: _kPrimary,
// //                   borderRadius: BorderRadius.circular(2),
// //                 ),
// //               );
// //             }),
// //           ),
// //     );
// //   }
// // }

// // // ─── Stop Button ──────────────────────────────────────────────────────────────
// // class _StopBtn extends StatelessWidget {
// //   final int elapsed, max;
// //   const _StopBtn({required this.elapsed, required this.max});
// //   @override
// //   Widget build(BuildContext context) => SizedBox(
// //     width: 80,
// //     height: 80,
// //     child: Stack(
// //       alignment: Alignment.center,
// //       children: [
// //         SizedBox(
// //           width: 80,
// //           height: 80,
// //           child: CircularProgressIndicator(
// //             value: (elapsed / max).clamp(0.0, 1.0),
// //             strokeWidth: 4,
// //             backgroundColor: Colors.white30,
// //             valueColor: const AlwaysStoppedAnimation<Color>(_kPrimary),
// //           ),
// //         ),
// //         Container(
// //           width: 36,
// //           height: 36,
// //           decoration: BoxDecoration(
// //             color: Colors.red,
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // // ─── Full Screen Camera Preview ───────────────────────────────────────────────
// // class _FullScreenCameraPreview extends StatelessWidget {
// //   final CameraController controller;
// //   const _FullScreenCameraPreview({required this.controller});
// //   @override
// //   Widget build(BuildContext context) {
// //     final previewSize = controller.value.previewSize;
// //     if (previewSize == null) return const SizedBox.shrink();
// //     final portraitW =
// //         previewSize.height < previewSize.width
// //             ? previewSize.height
// //             : previewSize.width;
// //     final portraitH =
// //         previewSize.height > previewSize.width
// //             ? previewSize.height
// //             : previewSize.width;
// //     return SizedBox.expand(
// //       child: FittedBox(
// //         fit: BoxFit.cover,
// //         child: SizedBox(
// //           width: portraitW,
// //           height: portraitH,
// //           child: CameraPreview(controller),
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ─── Option Panel ─────────────────────────────────────────────────────────────
// // class _OptionPanel extends StatelessWidget {
// //   final List<String> items;
// //   final List<double> values;
// //   final double selectedValue;
// //   final ValueChanged<double> onSelect;
// //   const _OptionPanel({
// //     required this.items,
// //     required this.values,
// //     required this.selectedValue,
// //     required this.onSelect,
// //   });
// //   @override
// //   Widget build(BuildContext context) => Container(
// //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
// //     decoration: BoxDecoration(
// //       color: Colors.black87,
// //       borderRadius: BorderRadius.circular(14),
// //     ),
// //     child: Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: List.generate(items.length, (i) {
// //         final sel = values[i] == selectedValue;
// //         return GestureDetector(
// //           onTap: () => onSelect(values[i]),
// //           child: Container(
// //             width: 58,
// //             padding: const EdgeInsets.symmetric(vertical: 10),
// //             decoration: BoxDecoration(
// //               color: sel ? _kPrimary : Colors.transparent,
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Text(
// //               items[i],
// //               textAlign: TextAlign.center,
// //               style: TextStyle(
// //                 color: sel ? Colors.black : Colors.white,
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 14,
// //               ),
// //             ),
// //           ),
// //         );
// //       }),
// //     ),
// //   );
// // }