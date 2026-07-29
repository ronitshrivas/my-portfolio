import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/Notification/Notification_Listscreen.dart';
import 'package:innovator/Innovator/provider/notification_provider.dart';
import 'package:innovator/Innovator/provider/upload_provider.dart';
import 'package:innovator/Innovator/screens/Events/Events.dart';
import 'package:innovator/Innovator/newui/chat_page.dart' as newui;
import 'package:innovator/Innovator/newui/elearning_page.dart' as newui;
import 'package:innovator/Innovator/newui/shop_page.dart' as newui;
import 'package:innovator/Innovator/newui/cart_page.dart' as newui;
import 'package:innovator/Innovator/newui/search_section.dart' as newui;
import 'package:innovator/Innovator/newui/post_page.dart' as newui;
import 'package:innovator/Innovator/newui/services/auth_session.dart'
    as newui_auth;
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Feed/Video_Feed.dart';
import 'package:innovator/Innovator/screens/Privacy_Policy/privacy_screen.dart';
import 'package:innovator/Innovator/screens/F&Q/F&Qscreen.dart';
import 'package:innovator/Innovator/screens/Profile/profile_page.dart';
import 'package:innovator/Innovator/screens/Settings/settings.dart';
import 'package:innovator/Innovator/services/fcm_services.dart';
import 'package:innovator/Innovator/ui/ui.dart';
import 'package:innovator/Innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/elearning/screens/course_list_screen.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _checkForUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
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

  // Persistent shell nav. Tapping an icon swaps the section in place so the
  // liquid bar is always visible, exactly like the new UI. The bar can be
  // dragged to any edge and dropped to dock there.
  //
  // Bar layout matches new_innovator_UI:
  // Chat, E-learning, Search · [logo] · Post, Shop, Menu.
  static const List<LiquidNavItem> _navLeading = [
    LiquidNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
    LiquidNavItem(icon: Icons.school_outlined, label: 'E-learning'),
    LiquidNavItem(icon: Icons.search_rounded, label: 'Search'),
  ];
  static const List<LiquidNavItem> _navTrailing = [
    LiquidNavItem(icon: Icons.post_add_rounded, label: 'Post'),
    LiquidNavItem(icon: Icons.storefront_outlined, label: 'Shop'),
    LiquidNavItem(icon: Icons.menu_rounded, label: 'Menu', pinBottom: true),
  ];
  static const List<LiquidNavItem> _navItems = [..._navLeading, ..._navTrailing];

  final ScrollController _scroll = ScrollController();

  NavDock _dock = NavDock.bottom;
  int _selected = -1;
  bool _showCart = false;
  bool _dragging = false;
  Offset _dragPos = Offset.zero;
  NavDock? _previewDock;

  int get _feedIndex => -1;
  int get _searchIndex => _navItems.indexWhere((i) => i.label == 'Search');
  int get _chatIndex => _navItems.indexWhere((i) => i.label == 'Chat');
  int get _learnIndex => _navItems.indexWhere((i) => i.label == 'E-learning');
  int get _shopIndex => _navItems.indexWhere((i) => i.label == 'Shop');
  int get _postIndex => _navItems.indexWhere((i) => i.label == 'Post');

  void _onNavSelect(int index) {
    final item = _navItems[index];
    switch (item.label) {
      case 'Menu':
        _scaffoldKey.currentState?.openDrawer();
        return;
      default:
        setState(() {
          _selected = index;
          _showCart = false;
        });
    }
  }

  /// Logo tap returns to the feed and scrolls it to the top.
  void _goToFeed() {
    setState(() {
      _selected = _feedIndex;
      _showCart = false;
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Clearance so section content isn't hidden under the docked nav bar.
  EdgeInsets get _sectionPadding => switch (_dock) {
    NavDock.bottom => const EdgeInsets.fromLTRB(0, 8, 0, 108),
    NavDock.top => const EdgeInsets.fromLTRB(0, 96, 0, 20),
    _ => const EdgeInsets.fromLTRB(0, 8, 0, 20),
  };

  /// The current section under the persistent nav bar. Feed is the default.
  Widget _currentSection() {
    final pad = _sectionPadding;
    if (_showCart) {
      return newui.CartSection(
        key: const ValueKey('cart'),
        contentPadding: pad,
        onShop: () => setState(() => _showCart = false),
      );
    }
    if (_selected == _searchIndex) {
      return newui.SearchSection(
        key: const ValueKey('search'),
        contentPadding: pad,
      );
    }
    if (_selected == _chatIndex) {
      return newui.ChatSection(
        key: const ValueKey('chat'),
        contentPadding: pad,
      );
    }
    if (_selected == _learnIndex) {
      return newui.ELearningSection(
        key: const ValueKey('elearning'),
        contentPadding: pad,
      );
    }
    if (_selected == _shopIndex) {
      return newui.ShopSection(
        key: const ValueKey('shop'),
        contentPadding: pad,
        onCartTap: () => setState(() => _showCart = true),
      );
    }
    if (_selected == _postIndex) {
      return newui.PostSection(
        key: const ValueKey('post'),
        authorName: ref.watch(drawerProfileProvider).name,
        contentPadding: pad,
        onPosted: () => setState(() => _selected = _feedIndex),
      );
    }
    return GestureDetector(
      key: const ValueKey('feed'),
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < -200) {
          _navigateToVideoFeed();
        }
      },
      child: const Inner_HomePage(),
    );
  }

  void _openScreen(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  NavDock _nearestDock(Offset position) {
    final size = MediaQuery.of(context).size;
    final distances = <NavDock, double>{
      NavDock.left: position.dx,
      NavDock.right: size.width - position.dx,
      NavDock.top: position.dy,
      NavDock.bottom: size.height - position.dy,
    };
    return distances.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  void _onDragStart(DragStartDetails details) {
    HapticFeedback.mediumImpact();
    setState(() {
      _dragging = true;
      _dragPos = details.globalPosition;
      _previewDock = _nearestDock(details.globalPosition);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final preview = _nearestDock(details.globalPosition);
    if (preview != _previewDock) HapticFeedback.selectionClick();
    setState(() {
      _dragPos = details.globalPosition;
      _previewDock = preview;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    HapticFeedback.lightImpact();
    setState(() {
      _dock = _previewDock ?? _nearestDock(_dragPos);
      _dragging = false;
      _previewDock = null;
    });
  }

  EdgeInsets get _contentMargin => switch (_dock) {
    NavDock.left => const EdgeInsets.only(left: 78),
    NavDock.right => const EdgeInsets.only(right: 78),
    _ => EdgeInsets.zero,
  };

  Future<void> _handleLogout() async {
    try {
      await FCMService().clearToken();
    } catch (e) {
      log('Logout token clear error: $e');
    }
    AppData().clearAuthToken();
    ref.read(drawerProfileProvider.notifier).clear();
    await AppData().logout();
    // Clear the mirrored new UI session too, so its API calls stop.
    await newui_auth.AuthSession.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  Widget _buildDrawer() {
    final profile = ref.watch(drawerProfileProvider);
    return GlassDrawer(
      name: profile.name.isEmpty ? 'User' : profile.name,
      title: profile.email,
      avatarUrl: profile.picture,
      onProfile: () => _openScreen(
        UserProfileScreen(userId: AppData().currentUserId ?? ''),
      ),
      onLogout: _handleLogout,
      items: [
        GlassDrawerItem(
          icon: Icons.person_outline_rounded,
          label: 'Profile',
          onTap: () => _openScreen(
            UserProfileScreen(userId: AppData().currentUserId ?? ''),
          ),
        ),
        GlassDrawerItem(
          icon: Icons.notifications_none_rounded,
          label: 'Notification',
          onTap: () => _openScreen(const NotificationListScreen()),
        ),
        GlassDrawerItem(
          icon: Icons.storefront_outlined,
          label: 'Shop',
          onTap: () => setState(() => _selected = _shopIndex),
        ),
        GlassDrawerItem(
          icon: Icons.school_outlined,
          label: 'E-learning',
          onTap: () => _openScreen(const CourseListScreen()),
        ),
        GlassDrawerItem(
          icon: Icons.event_outlined,
          label: 'Events',
          onTap: () => _openScreen(EventsHomePage()),
        ),
        GlassDrawerItem(
          icon: Icons.shield_outlined,
          label: 'Privacy & Policy',
          onTap: () => _openScreen(const ProviderScope(child: PrivacyPolicy())),
        ),
        GlassDrawerItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: () => _openScreen(const SettingsScreen()),
        ),
        GlassDrawerItem(
          icon: Icons.help_outline_rounded,
          label: 'FAQ',
          onTap: () => _openScreen(const FAQScreen()),
        ),
      ],
    );
  }

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
      backgroundColor: BrandColors.canvas,
      drawerScrimColor: BrandColors.ink.withValues(alpha: .06),
      drawer: _buildDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(
            key: ValueKey('background'),
            animate: false,
          ),
          // Content column: upload banner on top, the active section below.
          // Sections swap in place under the persistent nav bar.
          Padding(
            key: const ValueKey('content'),
            padding: _contentMargin,
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: isUploading
                      ? _UploadingBanner()
                      : uploadMessage != null
                      ? _UploadResultBanner(message: uploadMessage)
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _currentSection(),
                  ),
                ),
              ],
            ),
          ),
          if (_dragging && _previewDock != null)
            _EdgeGlow(key: const ValueKey('edge-glow'), dock: _previewDock!),
          _buildNav(context),
          if (_dragging)
            Positioned(
              key: const ValueKey('drag-ghost'),
              left: _dragPos.dx - 30,
              top: _dragPos.dy - 30,
              child: const IgnorePointer(child: _DragGhost()),
            ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bar = GestureDetector(
      onPanStart: _onDragStart,
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      onPanCancel: () => setState(() {
        _dragging = false;
        _previewDock = null;
      }),
      // Hidden (not removed) while dragging so the gesture survives; springs
      // into shape whenever it lands on a new edge.
      child: Opacity(
        opacity: _dragging ? 0 : 1,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(_dock),
          tween: Tween(begin: .75, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (context, t, child) => Transform.scale(
            scale: t,
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
          child: LiquidNavBar(
            dock: _dock,
            leading: _navLeading,
            trailing: _navTrailing,
            selectedIndex: _selected,
            onSelect: _onNavSelect,
            onLogoTap: _goToFeed,
          ),
        ),
      ),
    );

    const navKey = ValueKey('nav-bar');
    return switch (_dock) {
      NavDock.bottom => Positioned(
        key: navKey,
        left: 14,
        right: 14,
        bottom: 8 - keyboard,
        child: SafeArea(bottom: keyboard == 0, child: bar),
      ),
      NavDock.top => Positioned(
        key: navKey,
        left: 14,
        right: 14,
        top: 8,
        child: SafeArea(child: bar),
      ),
      NavDock.left => Positioned(
        key: navKey,
        left: 10,
        top: 0,
        bottom: 0,
        child: SafeArea(child: Center(child: bar)),
      ),
      NavDock.right => Positioned(
        key: navKey,
        right: 10,
        top: 0,
        bottom: 0,
        child: SafeArea(child: Center(child: bar)),
      ),
    };
  }
}

/// The logo orb pulsing gently while it's being dragged.
class _DragGhost extends StatelessWidget {
  const _DragGhost();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .85, end: 1.05),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: const Opacity(opacity: .92, child: NavLogoOrb(size: 60)),
    );
  }
}

/// Soft glow along the edge the nav bar would dock to if dropped now.
class _EdgeGlow extends StatelessWidget {
  const _EdgeGlow({super.key, required this.dock});

  final NavDock dock;

  @override
  Widget build(BuildContext context) {
    const thickness = 14.0;
    final ink = BrandColors.ink;
    final gradient = switch (dock) {
      NavDock.left => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [ink.withValues(alpha: .30), ink.withValues(alpha: 0)],
      ),
      NavDock.right => LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [ink.withValues(alpha: .30), ink.withValues(alpha: 0)],
      ),
      NavDock.top => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [ink.withValues(alpha: .30), ink.withValues(alpha: 0)],
      ),
      NavDock.bottom => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [ink.withValues(alpha: .30), ink.withValues(alpha: 0)],
      ),
    };

    final glow = IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(dock),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
      ),
    );

    return switch (dock) {
      NavDock.left => Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: thickness,
        child: glow,
      ),
      NavDock.right => Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: thickness,
        child: glow,
      ),
      NavDock.top => Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: thickness,
        child: glow,
      ),
      NavDock.bottom => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: thickness,
        child: glow,
      ),
    };
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
