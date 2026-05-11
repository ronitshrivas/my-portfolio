// cross_platform.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class CrossPlatformAuth {
  static GoogleSignIn? _googleSignIn;
  
  // Initialize Google Sign-In based on platform
  static GoogleSignIn? get googleSignIn {
    if (_googleSignIn != null) return _googleSignIn;
    
    // Check if Google Sign-In is supported on this platform
    if (!isGoogleSignInSupported) {
      developer.log('Google Sign-In not supported on this platform');
      return null;
    }
    
    try {
      if (kIsWeb) {
        // Web configuration - you need to add your web client ID
        _googleSignIn = GoogleSignIn(
          clientId: 'YOUR_WEB_CLIENT_ID.googleusercontent.com', // Replace with your actual web client ID
          scopes: ['email', 'profile'],
        );
        developer.log('Google Sign-In initialized for Web');
      } else if (Platform.isAndroid || Platform.isIOS) {
        // Mobile configuration
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );
        developer.log('Google Sign-In initialized for ${Platform.operatingSystem}');
      }
      return _googleSignIn;
    } catch (e) {
      developer.log('Error initializing Google Sign-In: $e');
      return null;
    }
  }
  
  // Check if Google Sign-In is supported on current platform
  static bool get isGoogleSignInSupported {
    try {
      if (kIsWeb) {
        developer.log('Platform check: Web - Google Sign-In supported');
        return true;
      }
      
      if (Platform.isAndroid) {
        developer.log('Platform check: Android - Google Sign-In supported');
        return true;
      }
      
      if (Platform.isIOS) {
        developer.log('Platform check: iOS - Google Sign-In supported');
        return true;
      }
      
      // Windows, macOS, Linux desktop are not supported
      developer.log('Platform check: ${Platform.operatingSystem} - Google Sign-In NOT supported');
      return false;
    } catch (e) {
      developer.log('Error checking platform support: $e');
      return false;
    }
  }
  
  // Safe Google Sign-In method
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      developer.log('Attempting Google Sign-In...');
      
      if (!isGoogleSignInSupported) {
        throw UnsupportedError('Google Sign-In is not supported on this platform (${kIsWeb ? 'Web' : Platform.operatingSystem})');
      }
      
      final googleSignIn = CrossPlatformAuth.googleSignIn;
      if (googleSignIn == null) {
        throw Exception('Google Sign-In not intialized properly');
      }
      
      developer.log('Starting Google Sign-In flow...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        developer.log('User cancelled Google Sign-In');
        return null; // User cancelled
      }
      
      developer.log('Google Sign-In account obtained: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      developer.log('Google authentication tokens obtained');
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      developer.log('Firebase credential created');
      
      // Sign in to Firebase with the Google credentials
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      developer.log('Firebase sign-in successful: ${userCredential.user?.email}');
      
      return userCredential;
    } catch (e) {
      developer.log('Google Sign-In error: $e');
      rethrow;
    }
  }
  
  // Safe sign out method
  static Future<void> signOut() async {
    try {
      developer.log('Signing out from Google and Firebase...');
      
      if (isGoogleSignInSupported && _googleSignIn != null) {
        await _googleSignIn!.signOut();
        developer.log('Google Sign-Out successful');
      }
      
      await FirebaseAuth.instance.signOut();
      developer.log('Firebase Sign-Out successful');
    } catch (e) {
      developer.log('Error during sign out: $e');
    }
  }
  
  // Get current platform info for debugging
  static String get platformInfo {
    if (kIsWeb) return 'Web';
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return 'Unknown';
    }
  }
}