import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/provider/auth_provider.dart';
import 'package:innovator/KMS/provider/constant_provider.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';



class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String selectedRole = '';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await ref
          .read(authProvider)
          .register(
            userName: nameController.text.trim(),
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            role: selectedRole.toLowerCase(),
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => KmsLoginScreen()),
        );
      }
    } catch (e) {
      log('Registration error: $e');
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppStyle.primaryColor,
                                  child: Image.asset(
                                    'assets/kms/settings.png',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Create Account',
                                style: AppStyle.heading1.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Full Name
                              _buildTextField(
                                formFieldTopText: 'USER NAME',
                                controller: nameController,
                                icon: Icons.person_outline,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Email
                              _buildTextField(
                                formFieldTopText: 'EMAIL',
                                controller: emailController,
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Password
                              _buildTextField(
                                formFieldTopText: 'PASSWORD',
                                controller: passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                                fieldId: 'signup_password',
                              ),
                              SizedBox(height: context.screenHeight * 0.02),
                              // Role Dropdown
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ROLE',
                                    style: TextStyle(
                                      fontSize: AppStyle.mediumText,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  FormField<String>(
                                    initialValue: null,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'PLEASE SELECT YOUR ROLE';
                                      }
                                      return null;
                                    },
                                    builder: (FormFieldState<String> state) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    state.hasError
                                                        ? Colors.red
                                                        : Colors.black,
                                              ),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value:
                                                    selectedRole.isEmpty
                                                        ? null
                                                        : selectedRole,
                                                isExpanded: true,
                                                hint: const Text(
                                                  'Select your role',
                                                ),
                                                icon: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                  color: Colors.black,
                                                ),
                                                dropdownColor: Colors.white,
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                ),
                                                items:
                                                    [
                                                          'Admin',
                                                          'Coordinator',
                                                          'Teacher',
                                                          'Student',
                                                        ]
                                                        .map(
                                                          (role) =>
                                                              DropdownMenuItem(
                                                                value: role,
                                                                child: Text(
                                                                  role,
                                                                ),
                                                              ),
                                                        )
                                                        .toList(),
                                                onChanged: (value) {
                                                  setState(
                                                    () => selectedRole = value!,
                                                  );
                                                  state.didChange(value);
                                                },
                                              ),
                                            ),
                                          ),
                                          if (state.hasError)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 6,
                                                left: 12,
                                              ),
                                              child: Text(
                                                state.errorText!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: context.screenHeight * 0.03),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleSignup,
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
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                ),
                              ),
                              SizedBox(height: context.screenHeight * 0.03),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account? ',
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
                                                (_) => const KmsLoginScreen(),
                                          ),
                                        ),
                                    child: const Text(
                                      'Login',
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
                    ? ref.watch(obscureProvider(fieldId))
                    : false;

            return TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelStyle: const TextStyle(color: Colors.black),
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
