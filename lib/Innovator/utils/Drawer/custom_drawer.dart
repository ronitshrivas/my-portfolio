import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/controllers/user_controller.dart';
import 'package:innovator/Innovator/screens/Eliza_ChatBot/Elizahomescreen.dart';
import 'package:innovator/Innovator/screens/Events/Events.dart';
import 'package:innovator/Innovator/screens/F&Q/F&Qscreen.dart';
import 'package:innovator/Innovator/screens/Feed/Video_Feed.dart';
import 'package:innovator/Innovator/screens/Privacy_Policy/privacy_screen.dart';
import 'package:innovator/Innovator/screens/Profile/profile_page.dart';
import 'package:innovator/Innovator/screens/Settings/settings.dart';
import 'package:innovator/Innovator/services/fcm_services.dart';
import 'package:innovator/Innovator/utils/Drawer/drawer_cache_manager.dart';
import 'package:innovator/Innovator/widget/FloatingMenuwidget.dart';
import 'package:innovator/KMS/core/constants/service/auth_wrapper.dart';
import 'package:innovator/ecommerce/screens/Shop/Shop_Page.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';
import 'package:innovator/elearning/screens/course_list_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// DrawerProfileState — immutable data class
// ─────────────────────────────────────────────────────────────────────────────
class DrawerProfileState {
  final String name;
  final String email;
  final String? picture;
  final bool isRefreshing;
  final int imageVersion; // bumped only on actual avatar change

  const DrawerProfileState({
    this.name = 'User',
    this.email = '',
    this.picture,
    this.isRefreshing = false,
    this.imageVersion = 0,
  });

  DrawerProfileState copyWith({
    String? name,
    String? email,
    String? picture,
    bool? isRefreshing,
    int? imageVersion,
    bool clearPicture = false,
  }) {
    return DrawerProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      picture: clearPicture ? null : (picture ?? this.picture),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      imageVersion: imageVersion ?? this.imageVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DrawerProfileState &&
      other.name == name &&
      other.email == email &&
      other.picture == picture &&
      other.isRefreshing == isRefreshing &&
      other.imageVersion == imageVersion;

  @override
  int get hashCode =>
      Object.hash(name, email, picture, isRefreshing, imageVersion);
}

// ─────────────────────────────────────────────────────────────────────────────
// DrawerProfileNotifier — all async work lives here, NOT in widgets
// ─────────────────────────────────────────────────────────────────────────────
class DrawerProfileNotifier extends StateNotifier<DrawerProfileState> {
  DrawerProfileNotifier() : super(const DrawerProfileState()) {
    _loadFromAppData();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call this before opening the drawer (pre-warm). Safe to call multiple times.
  void prewarm() {
    _loadFromAppData();
    _refreshInBackground();
  }

  /// Called after a successful avatar upload anywhere in the app.
  void invalidateAvatar() {
    _loadFromAppData();
    // Bump version so CachedNetworkImage re-fetches the new avatar
    state = state.copyWith(imageVersion: state.imageVersion + 1);
    _refreshInBackground();
  }

  void clear() {
    state = const DrawerProfileState();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  void _loadFromAppData() {
    final userData = AppData().currentUser;
    if (userData == null) return;

    final photoUrl = userData['photo_url']?.toString() ?? '';
    final profileAvatar =
        (userData['profile'] as Map<String, dynamic>?)?['avatar']?.toString() ??
        '';
    final legacyPicture = userData['picture']?.toString() ?? '';

    state = state.copyWith(
      name: _extractName(userData),
      email: userData['email']?.toString() ?? '',
      picture:
          photoUrl.isNotEmpty
              ? photoUrl
              : profileAvatar.isNotEmpty
              ? profileAvatar
              : legacyPicture.isNotEmpty
              ? legacyPicture
              : null,
    );
  }

  Future<void> _refreshInBackground() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true);

    try {
      // Layer 1: Hive persistent cache (fast, local)
      final persistentCache = await DrawerProfileCache.getCachedProfile();
      if (persistentCache != null) {
        state = state.copyWith(
          name: persistentCache.name,
          email: persistentCache.email,
          picture: persistentCache.picturePath,
        );
      }

      // Layer 2: Network
      await _fetchFromNetwork();
    } catch (e) {
      developer.log('Drawer background refresh failed: $e');
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }

  Future<void> _fetchFromNetwork() async {
    final authToken = AppData().accessToken;
    if (authToken == null) return;

    final response = await http
        .get(
          Uri.parse(ApiConstants.fetchuserprofile),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return;

    final responseData = json.decode(response.body) as Map<String, dynamic>;
    final profile = responseData['profile'] as Map<String, dynamic>? ?? {};

    final avatarPath = profile['avatar']?.toString() ?? '';
    final photoUrl = responseData['photo_url']?.toString() ?? '';
    final normalizedPicture =
        photoUrl.isNotEmpty
            ? photoUrl
            : avatarPath.isNotEmpty
            ? avatarPath
            : null;

    final normalizedName = _extractName(responseData);

    // Only bump imageVersion if the picture URL actually changed
    final didAvatarChange = normalizedPicture != state.picture;

    state = state.copyWith(
      name: normalizedName,
      email: responseData['email']?.toString() ?? '',
      picture: normalizedPicture,
      imageVersion: didAvatarChange ? state.imageVersion + 1 : null,
    );

    // Update AppData & Hive cache in the background — don't await
    AppData().updateUser(responseData);
    DrawerProfileCache.cacheProfile(
      userId: responseData['id']?.toString() ?? '',
      name: normalizedName,
      email: responseData['email']?.toString() ?? '',
      picturePath: normalizedPicture,
    );
  }

  String _extractName(Map<String, dynamic> data) {
    final fullName = data['full_name']?.toString() ?? '';
    if (fullName.isNotEmpty) return fullName;
    final username = data['username']?.toString() ?? '';
    if (username.isNotEmpty) return username;
    return data['name']?.toString() ?? 'User';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider — auto-dispose keeps memory clean when drawer is closed
// ─────────────────────────────────────────────────────────────────────────────
final drawerProfileProvider =
    StateNotifierProvider<DrawerProfileNotifier, DrawerProfileState>(
      (ref) => DrawerProfileNotifier(),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Legacy InstantCache — kept for backward-compatibility with the rest of the app
// Delegates to the notifier when possible; works standalone when no notifier.
// ─────────────────────────────────────────────────────────────────────────────
class InstantCache {
  static DrawerProfileNotifier? _notifier;

  /// Wire this up once after ProviderContainer is created (e.g. in main or after
  /// login). Not mandatory — legacy callers still work without it.
  static void bindNotifier(DrawerProfileNotifier notifier) {
    _notifier = notifier;
  }

  static void init() {
    // no-op: notifier initialises itself in its constructor
  }

  static void invalidate() => _notifier?.invalidateAvatar();
  static void clear() => _notifier?.clear();
}

// ─────────────────────────────────────────────────────────────────────────────
// InstantDrawerService
// ─────────────────────────────────────────────────────────────────────────────
class InstantDrawerService {
  static void show(BuildContext context, WidgetRef ref) {
    // Pre-warm BEFORE the animation starts so data is ready when drawer opens
    ref.read(drawerProfileProvider.notifier).prewarm();

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent, // We handle our own backdrop
        transitionDuration: const Duration(milliseconds: 120),
        reverseTransitionDuration: const Duration(milliseconds: 80),
        pageBuilder: (context, animation, _) {
          final drawerWidth = math.min(
            MediaQuery.of(context).size.width * 0.8,
            300.0,
          );
          // FIX: Use FadeTransition + SlideTransition instead of AnimatedBuilder
          // These use the compositor (GPU), not widget rebuild on every tick.
          return RepaintBoundary(
            child: _InstantDrawerOverlay(
              animation: animation,
              drawerWidth: drawerWidth,
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InstantDrawerOverlay — now uses GPU-composited transitions (no AnimatedBuilder)
// ─────────────────────────────────────────────────────────────────────────────
class _InstantDrawerOverlay extends StatelessWidget {
  final Animation<double> animation;
  final double drawerWidth;

  const _InstantDrawerOverlay({
    required this.animation,
    required this.drawerWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Backdrop opacity via FadeTransition — zero rebuilds, GPU composited
    final backdropOpacity = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

    // Slide offset via SlideTransition — zero rebuilds, GPU composited
    final slideOffset = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -8) Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            // GPU-composited backdrop — no widget rebuild per frame
            FadeTransition(
              opacity: backdropOpacity,
              child: const ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(),
              ),
            ),

            // GPU-composited drawer panel
            Align(
              alignment: Alignment.centerLeft,
              child: SlideTransition(
                position: slideOffset,
                child: RepaintBoundary(
                  child: Container(
                    width: drawerWidth,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.whitecolor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      // FIX: Removed heavy box shadow — causes rasterization on
                      // every frame during animation on low-end devices.
                      // Use a subtle static border instead.
                    ),
                    child: const TrueInstantDrawer(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrueInstantDrawer — now a ConsumerWidget (Riverpod)
// ─────────────────────────────────────────────────────────────────────────────
class TrueInstantDrawer extends ConsumerStatefulWidget {
  const TrueInstantDrawer({super.key});

  @override
  ConsumerState<TrueInstantDrawer> createState() => _TrueInstantDrawerState();
}

class _TrueInstantDrawerState extends ConsumerState<TrueInstantDrawer> {
  bool _kmsEnabled = false;

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ref.watch causes rebuild ONLY when DrawerProfileState actually changes.
    // Individual fields are read in child builders so only affected subtrees rebuild.
    final profile = ref.watch(drawerProfileProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap:
                () => _quickNavigate(
                  () => ProviderScope(
                    child: UserProfileScreen(
                      userId: AppData().currentUserId ?? '',
                    ),
                  ),
                ),
            child: _DrawerHeader(
              profile: profile,
              kmsEnabled: _kmsEnabled,
              onKmsToggle: (value) {
                setState(() => _kmsEnabled = value);
                if (value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AuthWrapper()),
                  );
                }
              },
            ),
          ),
          Expanded(child: _buildMenu()),
        ],
      ),
    );
  }

  // ── Menu ────────────────────────────────────────────────────────────────────

  Widget _buildMenu() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          _QuickMenuItem(
            icon: Icons.person_rounded,
            title: 'Profile',
            onTap: _goToProfile,
          ),

          _QuickMenuItem(
            icon: Icons.menu_book_rounded,
            title: 'E-Learning',
            onTap: _goToElearning,
          ),
          _QuickMenuItem(
            icon: Icons.shop,
            title: 'Shop',
            onTap: _goToEcommerce,
          ),
          _QuickMenuItem(
            icon: Icons.video_collection,
            title: 'Reels',
            onTap: _gotoreels,
          ),
          _QuickMenuItem(
            icon: Icons.event_available,
            title: 'Events',
            onTap: _goToEvents,
          ),
          _QuickMenuItem(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy & Policy',
            onTap: _goToPrivacy,
          ),
          _QuickMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: _goToSettings,
          ),
          _QuickMenuItem(
            icon: Icons.help_rounded,
            title: 'FAQ',
            onTap: _goToFAQ,
          ),
          const SizedBox(height: 20),
          _buildDivider(),
          _QuickMenuItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            onTap: _showLogout,
            isLogout: true,
          ),
          const SizedBox(height: 20),
          const _DrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  void _goToProfile() => _quickNavigate(
    () => ProviderScope(
      child: UserProfileScreen(userId: AppData().currentUserId ?? ''),
    ),
  );
  void _gotoreels() => _quickNavigate(() => ReelsScreen());
  void _goToEvents() => _quickNavigate(() => EventsHomePage());
  void _goToElearning() => _quickNavigate(() => const CourseListScreen());
  void _goToEcommerce() => _quickNavigate(() => const ShopPage());
  void _goToPrivacy() =>
      _quickNavigate(() => const ProviderScope(child: PrivacyPolicy()));
  void _goToSettings() => _quickNavigate(() => const SettingsScreen());
  void _goToFAQ() => _quickNavigate(() => const FAQScreen());

  void _quickNavigate(Widget Function() builder) {
    Navigator.of(context).pop();
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Logout Confirmation'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),

              ElevatedButton(
                onPressed: () async {
                  await FCMService().clearToken();
                  await ref
                      .read(elearningNotificationServiceProvider)
                      .clearToken();
                  AppData().clearAuthToken();
                  ref.read(drawerProfileProvider.notifier).clear();
                  AppData().logout();
                  FloatingMenuOverlay.remove();
                  Navigator.of(dialogContext).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.whitecolor),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _executeOptimizedLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      developer.log('Firebase signout error: $e');
    }
    try {
      if (Get.isRegistered<UserController>())
        Get.delete<UserController>(force: true);
    } catch (e) {
      developer.log('UserController clear error: $e');
    }
    try {
      await DrawerProfileCache.clearCache();
      await DefaultCacheManager().emptyCache();
    } catch (e) {
      developer.log('Cache clear error: $e');
    }
    ref.read(drawerProfileProvider.notifier).clear();
    developer.log('Logout complete');
  }
}

class _DrawerHeader extends StatelessWidget {
  final DrawerProfileState profile;
  final bool kmsEnabled;
  final ValueChanged<bool> onKmsToggle;

  const _DrawerHeader({
    required this.profile,
    required this.kmsEnabled,
    required this.onKmsToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(244, 135, 6, 1),
            Color.fromRGBO(244, 135, 6, 0.9),
            Color.fromRGBO(244, 135, 6, 1),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _ProfileAvatar(profile: profile),
                  if (profile.isRefreshing)
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: _RefreshBadge(),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.whitecolor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              profile.isRefreshing && profile.name == 'User'
                  ? const SizedBox(
                    width: 100,
                    height: 20,
                    child: LinearProgressIndicator(
                      color: AppColors.whitecolor,
                      backgroundColor: AppColors.whitecolor,
                    ),
                  )
                  : Text(
                    profile.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppColors.whitecolor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter Thin',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              if (profile.email.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whitecolor.withAlpha(20),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    profile.email,
                    style: const TextStyle(
                      color: AppColors.whitecolor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 5),
              // KMS toggle
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kmsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: AppColors.whitecolor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KMS',
                      style: TextStyle(
                        color: AppColors.whitecolor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: kmsEnabled,
                      onChanged: onKmsToggle,
                      inactiveTrackColor: AppColors.whitecolor.withAlpha(20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final DrawerProfileState profile;

  const _ProfileAvatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    String? resolvedUrl;
    if (profile.picture != null && profile.picture!.isNotEmpty) {
      resolvedUrl =
          profile.picture!.startsWith('http')
              ? profile.picture!
              : '${ApiConstants.userBase}${profile.picture}';
    }

    final versionedUrl =
        resolvedUrl != null && profile.imageVersion > 0
            ? '$resolvedUrl?v=${profile.imageVersion}'
            : resolvedUrl;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.whitecolor.withAlpha(20),
      ),
      child:
          profile.isRefreshing && versionedUrl == null
              ? const CircularProgressIndicator(
                color: AppColors.whitecolor,
                strokeWidth: 2,
              )
              : versionedUrl != null
              ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: versionedUrl,
                  fit: BoxFit.cover,
                  width: 70,
                  height: 70,
                  placeholder:
                      (_, __) => const CircularProgressIndicator(
                        color: AppColors.whitecolor,
                        strokeWidth: 2,
                      ),
                  errorWidget:
                      (_, __, ___) => const Icon(
                        Icons.person,
                        size: 35,
                        color: AppColors.whitecolor,
                      ),
                ),
              )
              : const Icon(Icons.person, size: 35, color: AppColors.whitecolor),
    );
  }
}

class _RefreshBadge extends StatelessWidget {
  const _RefreshBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.whitecolor,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color.fromRGBO(244, 135, 6, 1),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 135, 6, 1).withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Color.fromRGBO(244, 135, 6, 1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Innovator App v : 1.0.67',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Pvt Ltd',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  const _QuickMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:
                isLogout
                    ? LinearGradient(
                      colors: [
                        Colors.red.withAlpha(10),
                        Colors.red.withAlpha(20),
                      ],
                    )
                    : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isLogout
                          ? Colors.red.withAlpha(10)
                          : const Color.fromRGBO(244, 135, 6, 1).withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      isLogout
                          ? Colors.red
                          : const Color.fromRGBO(244, 135, 6, 1),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLogout ? Colors.red : Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SmoothDrawerService {
  static void showLeftDrawer(BuildContext context, WidgetRef ref) {
    InstantDrawerService.show(context, ref);
  }
}

class CustomDrawer extends TrueInstantDrawer {
  const CustomDrawer({super.key});
}

class OptimizedCustomDrawer extends TrueInstantDrawer {
  const OptimizedCustomDrawer({super.key});
}

class ZeroLagDrawer extends TrueInstantDrawer {
  const ZeroLagDrawer({super.key});
}
