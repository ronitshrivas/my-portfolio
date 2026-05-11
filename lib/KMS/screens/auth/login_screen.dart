import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/provider/auth_provider.dart';
import 'package:innovator/KMS/provider/constant_provider.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';
import 'package:innovator/KMS/provider/user_provider.dart';
import 'package:innovator/KMS/screens/auth/student_login_screen.dart';
import 'package:innovator/KMS/screens/auth/student_register_screen.dart';
import 'package:innovator/KMS/screens/dashboard/coordinator_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/teacher_dashboard_screen.dart';

class KmsLoginScreen extends ConsumerStatefulWidget {
  const KmsLoginScreen({super.key});

  @override
  ConsumerState<KmsLoginScreen> createState() => _KmsLoginScreenState();
}

class _KmsLoginScreenState extends ConsumerState<KmsLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final response = await ref
          .read(authProvider)
          .login(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final role = response['user']['role'] as String? ?? '';

      if (!mounted) return;

      switch (role) {
        // case 'admin':
        //   ref.invalidate(userDetailsProvider);
        //   Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(builder: (_) => AdminDashboardScreen()),
        //   );
        //   break;
        case 'coordinator':
          ref.invalidate(userDetailsProvider);
          ref.refresh(coordinatorAttendanceProvider);
          ref.refresh(teacherSessionsProvider);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => CoordinatorDashboardScreen()),
          );
          break;
        case 'teacher':
          ref.invalidate(userDetailsProvider);
          ref.invalidate(teacherProfileProvider);
          ref.invalidate(kycStatusProvider);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TeacherDashboardScreen()),
          );
          break;
        case 'student':
          ref.invalidate(userDetailsProvider);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StudentLoginScreen()),
          );
          break;
        default:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unknown role: $role')));
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isLoading,
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
                                'Welcome Back',
                                style: AppStyle.heading1.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                formFieldTopText: 'EMAIL',
                                controller: emailController,
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),
                              _buildTextField(
                                formFieldTopText: 'PASSWORD',
                                controller: passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                                fieldId: 'login_password',
                              ),
                              SizedBox(height: context.screenHeight * 0.04),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
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
                                      isLoading
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
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => StudentLoginScreen(),
                                            ),
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppStyle.buttonColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child:
                                          isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                              : const Text(
                                                'Login as Student',
                                                style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Don\'t have an account? ',
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
                                          'Signup',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: AppStyle.mediumText,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
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
                    ? ref.watch(obscureProvider(fieldId))
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
                            ref.read(obscureProvider(fieldId).notifier).state =
                                !obscureText;
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
