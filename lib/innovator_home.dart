import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/Innovator/provider/notification_provider.dart';
import 'package:innovator/Innovator/provider/upload_provider.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Feed/Video_Feed.dart';
import 'package:innovator/Innovator/widget/FloatingMenuwidget.dart';

// ── CHANGE 1: StatefulWidget → ConsumerStatefulWidget ──────────────────────
class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

// ── CHANGE 2: State<Homepage> → ConsumerState<Homepage> ────────────────────
class _HomepageState extends ConsumerState<Homepage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkForUpdate();
    FloatingMenuOverlay.show(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── CHANGE 3: Wire lifecycle to polling speed ───────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // User opened the app → switch to fast polling (every 8 seconds)
        // Also triggers an immediate poll so the user sees fresh notifications
        // the moment they return to the app.
        log('App resumed → fast polling');
        ref.read(notificationProvider.notifier).setAppActive(true);
        break;

      case AppLifecycleState.paused:
        // App went to background → switch to slow polling (every 30 seconds)
        // This is battery-friendly. FCM handles background system tray
        // notifications independently — this polling is only for the
        // in-app banner when the app is open.
        log('App paused → slow polling');
        ref.read(notificationProvider.notifier).setAppActive(false);
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No polling changes needed for these states
        break;
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      log('Checking for Update!');
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        log('Update available!');
        if (info.immediateUpdateAllowed) {
          _performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          _performFlexibleUpdate();
        }
      } else {
        log('No update available');
      }
    } catch (error) {
      log('Error checking for update: $error');
    }
  }

  Future<void> _performImmediateUpdate() async {
    try {
      log('Starting immediate update');
      await InAppUpdate.performImmediateUpdate();
    } catch (error) {
      log('Immediate update failed: $error');
    }
  }

  Future<void> _performFlexibleUpdate() async {
    try {
      log('Starting flexible update');
      await InAppUpdate.startFlexibleUpdate();
      InAppUpdate.completeFlexibleUpdate()
          .then((_) {
            log('Flexible update completed');
            _showUpdateCompletedSnackbar();
          })
          .catchError((error) {
            log('Error completing flexible update: $error');
          });
    } catch (error) {
      log('Flexible update failed: $error');
    }
  }

  void _showUpdateCompletedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Update downloaded. Restart app to apply changes.'),
        action: SnackBarAction(
          label: 'RESTART',
          onPressed: () {
            InAppUpdate.completeFlexibleUpdate();
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _navigateToVideoFeed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ReelsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     key: _scaffoldKey,
  //     body: GestureDetector(
  //       onHorizontalDragEnd: (DragEndDetails details) {
  //         if (details.primaryVelocity! < -200) {
  //           _navigateToVideoFeed();
  //         }
  //       },
  //       child: Inner_HomePage(),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(postUploadingProvider);
    final uploadMessage = ref.watch(postUploadMessageProvider);

    // Auto-clear success/error message after 3 seconds
    if (uploadMessage != null) {
      Future.microtask(() async {
        await Future.delayed(const Duration(seconds: 3));
        ref.read(postUploadMessageProvider.notifier).state = null;
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          // Upload banner at the very top
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child:
                isUploading
                    ? _UploadingBanner()
                    : uploadMessage != null
                    ? _UploadResultBanner(message: uploadMessage)
                    : const SizedBox.shrink(),
          ),

          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity! < -200) {
                  _navigateToVideoFeed();
                }
              },
              child: Inner_HomePage(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadingBanner extends StatefulWidget {
  @override
  State<_UploadingBanner> createState() => _UploadingBannerState();
}

class _UploadingBannerState extends State<_UploadingBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1877F2),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your post is uploading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      final dots = '.' * ((_controller.value * 3).floor() + 1);
                      return Text(
                        dots,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _animation,
                builder:
                    (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: null,
                        minHeight: 4,
                        backgroundColor: Colors.white.withAlpha(25),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withAlpha(90),
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
}

class _UploadResultBanner extends StatelessWidget {
  final String message;
  const _UploadResultBanner({required this.message});

  bool get _isSuccess => message.contains('successfully');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _isSuccess ? Colors.green.shade600 : Colors.red.shade600,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                _isSuccess ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
