import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:innovator/KMS/api_calling_services.dart/auth_service.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/dashboard/admin_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/coordinator_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:innovator/KMS/screens/student/student_attendance_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Future<Widget> _startScreenFuture;

  @override
  void initState() {
    super.initState();
    _startScreenFuture = _resolveStartScreen();
  }

  Future<Widget> _resolveStartScreen() async {
    try {
      final authService = AuthService();

      final isLoggedIn = await authService.isLoggedIn();

      if (!isLoggedIn) {
        log('No token found — showing LoginScreen');
        return const KmsLoginScreen();
      }

      final role = await authService.getSavedRole();
      log('Token found — role: $role — routing to dashboard');

      switch (role?.toLowerCase()) {
        case 'admin':
          return const AdminDashboardScreen();
        case 'teacher':
          return const TeacherDashboardScreen();
        case 'coordinator':
          return const CoordinatorDashboardScreen();
        case 'student':
          return const StudentAttendanceScreen();
        default:
          log('Unknown role "$role" — falling back to LoginScreen');
          return const KmsLoginScreen();
      }
    } catch (e) {
      log('AuthWrapper error: $e — falling back to LoginScreen');
      return const KmsLoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const KmsLoginScreen();
        }

        return snapshot.data ?? const KmsLoginScreen();
      },
    );
  }
}
