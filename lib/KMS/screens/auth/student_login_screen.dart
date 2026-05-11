import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/provider/auth_provider.dart';
import 'package:innovator/KMS/provider/user_provider.dart';
import 'package:innovator/KMS/screens/auth/student_register_screen.dart';
import 'package:innovator/KMS/screens/student/student_attendance_screen.dart';

final _studentLoginObscureProvider = StateProvider.family<bool, String>(
  (ref, id) => true,
);

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider)
          .studentLogin(
            username: usernameController.text.trim(),
            password: passwordController.text.trim(),
          );

      if (!mounted) return;
      ref.invalidate(userDetailsProvider);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StudentAttendanceScreen()),
      );
    } catch (e) {
      log('Student login error: $e');
      if (mounted) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isLoading,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/kms/auth_backgroundimage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                  top: context.screenHeight * 0.02,
                  bottom: context.screenHeight * 0.05,
                  right: context.screenWidth * 0.05,
                  left: context.screenWidth * 0.05,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(
                      const Color(0xffC3C9CD),
                      BlendMode.dstOver,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 50,
                                width: 50,
                                color: AppStyle.primaryColor,
                                child: Image.asset(
                                  'assets/kms/settings.png',
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Student Login',
                                style: AppStyle.heading1.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                formFieldTopText: 'USERNAME',
                                controller: usernameController,
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),
                              _buildTextField(
                                formFieldTopText: 'PASSWORD',
                                controller: passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                                fieldId: 'student_login_password',
                              ),
                              SizedBox(height: context.screenHeight * 0.04),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppStyle.buttonColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                          : const Text(
                                            'Log in',
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                              SizedBox(height: context.screenHeight * 0.02),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: AppStyle.mediumText,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap:
                                        () => Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const StudentSignupScreen(),
                                          ),
                                        ),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: AppStyle.mediumText,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    required String formFieldTopText,
    String? fieldId,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formFieldTopText,
          style: TextStyle(
            fontSize: AppStyle.mediumText,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Consumer(
          builder: (context, ref, child) {
            final obscureText =
                isPassword && fieldId != null
                    ? ref.watch(_studentLoginObscureProvider(fieldId))
                    : false;

            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelStyle: const TextStyle(color: Colors.black),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                suffixIcon:
                    isPassword && fieldId != null
                        ? IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            ref
                                .read(
                                  _studentLoginObscureProvider(
                                    fieldId,
                                  ).notifier,
                                )
                                .state = !obscureText;
                          },
                        )
                        : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $formFieldTopText'.toUpperCase();
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
