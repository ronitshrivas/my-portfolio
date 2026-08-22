import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:innovator/firebase_options.dart';
import 'core/cache/hive_cache.dart';
import 'splash_page.dart';
import 'services/auth_session.dart';
import 'services/push_service.dart';
import 'theme/brand_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use Android's system Photo Picker (ACTION_PICK_IMAGES): permission-free,
  // available on every Android 11+ device (backported via Play Services), and
  // it never hands back unreadable gallery URIs — which is what breaks image
  // selection on some Vivo / Xiaomi ROMs.
  if (Platform.isAndroid) {
    final android = ImagePickerPlatform.instance;
    if (android is ImagePickerAndroid) {
      android.useAndroidPhotoPicker = true;
    }
  }
  // Larger decoded-image cache so feed scroll stays smooth.
  PaintingBinding.instance.imageCache.maximumSize = 280;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 200 << 20;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushService.instance.initLocalNotifications();
  // Ask for notification permission at launch, independent of login, so the
  // system dialog always appears on first run (Android 13+ / targetSdk 36).
  await PushService.instance.ensurePermissions();
  // Attach the foreground listener at launch (independent of login) so a push
  // arriving while the app is open ALWAYS renders a local heads-up notification.
  PushService.instance.attachForegroundListener();
  await HiveCache.init();
  await AuthSession.instance.load();
  // If already signed in, register for push right away.
  if (AuthSession.instance.isSignedIn) {
    PushService.instance.init();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // ProviderScope enables Riverpod app-wide without changing any UI.
  runApp(const ProviderScope(child: InnovatorApp()));
}

class InnovatorApp extends StatelessWidget {
  const InnovatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innovator',
      debugShowCheckedModeBanner: false,
      navigatorKey: PushService.navigatorKey,
      theme: _buildTheme(),
      home: const SplashPage(),
    );
  }

  /// Light theme with Plus Jakarta Sans as the app-wide typeface. Colors stay
  /// entirely on [BrandColors]; only the font family and letter-spacing change.
  ThemeData _buildTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: BrandColors.canvas,
      // App-wide bundled font. Every weight is registered in pubspec, so
      // FontWeight.w100..w900 all resolve to the right Inter file.
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: BrandColors.accent,
        primary: BrandColors.secondarySurface,
        secondary: BrandColors.accent,
        surface: BrandColors.canvas,
        onPrimary: BrandColors.text,
        onSecondary: BrandColors.secondarySurface,
        brightness: Brightness.light,
      ),
      splashFactory: NoSplash.splashFactory,
    );

    final textTheme = base.textTheme
        .apply(bodyColor: BrandColors.text, displayColor: BrandColors.text);

    return base.copyWith(
      textTheme: _withSpacing(textTheme),
      primaryTextTheme: _withSpacing(textTheme),
    );
  }

  /// Slightly tightens headings and opens up body text for a cleaner rhythm.
  TextTheme _withSpacing(TextTheme t) => t.copyWith(
        displayLarge: t.displayLarge?.copyWith(letterSpacing: -0.5),
        displayMedium: t.displayMedium?.copyWith(letterSpacing: -0.5),
        displaySmall: t.displaySmall?.copyWith(letterSpacing: -0.4),
        headlineLarge: t.headlineLarge?.copyWith(letterSpacing: -0.4),
        headlineMedium: t.headlineMedium?.copyWith(letterSpacing: -0.3),
        headlineSmall: t.headlineSmall?.copyWith(letterSpacing: -0.3),
        titleLarge: t.titleLarge?.copyWith(letterSpacing: -0.2),
        titleMedium: t.titleMedium?.copyWith(letterSpacing: -0.1),
        bodyLarge: t.bodyLarge?.copyWith(letterSpacing: 0.1, height: 1.45),
        bodyMedium: t.bodyMedium?.copyWith(letterSpacing: 0.1, height: 1.45),
        labelLarge: t.labelLarge?.copyWith(letterSpacing: 0.2),
      );
}
