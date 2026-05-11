import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/widget/FloatingMenuwidget.dart';
import 'package:innovator/innovator_home.dart';
import 'dart:developer' as developer;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      developer.log('Splash screen initializing...');

      // Initialize AppData first
      await AppData().initialize();

      // Check for Firebase Auth state mismatch (happens after reinstall)
      //await _checkAndHandleAuthState();

      // Add a small delay to show the splash screen
      await Future.delayed(const Duration(milliseconds: 1300));

      // Navigate based on final auth state
      if (AppData().isAuthenticated) {
        developer.log('User authenticated, navigating to home');
        _navigateToHome();
      } else {
        developer.log(' User not authenticated, navigating to login');
        _navigateToLogin();
      }
    } catch (e) {
      developer.log(' Error in splash initialization: $e');
      // On any error, navigate to login for safety
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const Homepage()));
  }

  void _navigateToLogin() {
    FloatingMenuOverlay.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar color to match splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.whitecolor, AppColors.whitecolor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app logo
              Image.asset(
                'animation/splash_csreen.gif',
                width: 400,
                height: 400,
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
