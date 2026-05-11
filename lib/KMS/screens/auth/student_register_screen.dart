import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/core/constants/mediaquery.dart';
import 'package:innovator/KMS/model/student_model/school_list_model.dart';
import 'package:innovator/KMS/provider/auth_provider.dart';
import 'package:innovator/KMS/provider/student_provider/school_provider.dart';
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/auth/student_login_screen.dart';

final _studentSignupObscureProvider = StateProvider.family<bool, String>(
  (ref, id) => true,
);

class StudentSignupScreen extends ConsumerStatefulWidget {
  const StudentSignupScreen({super.key});

  @override
  ConsumerState<StudentSignupScreen> createState() =>
      _StudentSignupScreenState();
}

class _StudentSignupScreenState extends ConsumerState<StudentSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  SchoolModel? _selectedSchool;
  ClassroomModel? _selectedClassroom;
  bool _isLoading = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider)
          .studentRegister(
            userName: _userNameController.text.trim(),
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            address: _addressController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            schoolId: _selectedSchool!.id,
            classroomId: _selectedClassroom?.id,
          );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
        );
      }
    } catch (e) {
      log('Student signup error: $e');
      if (mounted) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolListAsync = ref.watch(schoolListProvider);

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
                                'Student Registration',
                                style: AppStyle.heading1.copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Username
                              _buildTextField(
                                formFieldTopText: 'USERNAME',
                                controller: _userNameController,
                                icon: Icons.person_outline,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Full Name
                              _buildTextField(
                                formFieldTopText: 'FULL NAME',
                                controller: _fullNameController,
                                icon: Icons.badge_outlined,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Email
                              _buildTextField(
                                formFieldTopText: 'EMAIL',
                                controller: _emailController,
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Password
                              _buildTextField(
                                formFieldTopText: 'PASSWORD',
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                                fieldId: 'student_signup_password',
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Address
                              _buildTextField(
                                formFieldTopText: 'ADDRESS',
                                controller: _addressController,
                                icon: Icons.location_on_outlined,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // Phone Number
                              _buildTextField(
                                formFieldTopText: 'PHONE NUMBER',
                                controller: _phoneController,
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              SizedBox(height: context.screenHeight * 0.02),

                              // ── School Dropdown ──────────────────────────
                              schoolListAsync.when(
                                loading:
                                    () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                error:
                                    (err, _) => Text(
                                      'Failed to load schools. Please try again.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: AppStyle.mediumText,
                                      ),
                                    ),
                                data:
                                    (data) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // School
                                        _buildDropdownField<SchoolModel>(
                                          label: 'SCHOOL',
                                          hint: 'Select your school',
                                          value: _selectedSchool,
                                          items: data.schools,
                                          displayText: (s) => s.name,
                                          validator: (value) {
                                            if (value == null) {
                                              return 'PLEASE SELECT YOUR SCHOOL';
                                            }
                                            return null;
                                          },
                                          onChanged: (school) {
                                            setState(() {
                                              _selectedSchool = school;
                                              _selectedClassroom =
                                                  null; // Reset classroom when school changes
                                            });
                                          },
                                        ),
                                        Builder(
                                          builder: (context) {
                                            final filteredClassrooms =
                                                _selectedSchool == null
                                                    ? <ClassroomModel>[]
                                                    : data.classrooms
                                                        .where(
                                                          (c) =>
                                                              c.schoolId ==
                                                              _selectedSchool!
                                                                  .id,
                                                        )
                                                        .toList();

                                            // No classrooms for this school — skip the dropdown entirely
                                            if (_selectedSchool != null &&
                                                filteredClassrooms.isEmpty) {
                                              return const SizedBox.shrink();
                                            }

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height:
                                                      context.screenHeight *
                                                      0.02,
                                                ),
                                                _buildDropdownField<
                                                  ClassroomModel
                                                >(
                                                  label: 'CLASSROOM',
                                                  hint:
                                                      _selectedSchool == null
                                                          ? 'Select a school first'
                                                          : 'Select your classroom',
                                                  value: _selectedClassroom,
                                                  items: filteredClassrooms,
                                                  displayText: (c) => c.name,
                                                  validator: (value) {
                                                    if (value == null) {
                                                      return 'PLEASE SELECT YOUR CLASSROOM';
                                                    }
                                                    return null;
                                                  },
                                                  onChanged: (classroom) {
                                                    setState(
                                                      () =>
                                                          _selectedClassroom =
                                                              classroom,
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                              ),

                              SizedBox(height: context.screenHeight * 0.03),

                              // Sign Up Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignup,
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

  // ── Text Field ─────────────────────────────────────────────────────────────

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
                    ? ref.watch(_studentSignupObscureProvider(fieldId))
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
                            ref
                                .read(
                                  _studentSignupObscureProvider(
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

  // ── Generic Dropdown Field ─────────────────────────────────────────────────

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required String? Function(T?) validator,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppStyle.mediumText,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        FormField<T>(
          initialValue: null,
          validator: validator,
          builder: (FormFieldState<T> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.black,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      value: value,
                      isExpanded: true,
                      hint: Text(
                        hint,
                        style: TextStyle(
                          color: items.isEmpty ? Colors.grey : Colors.black54,
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Colors.black),
                      items:
                          items
                              .map(
                                (item) => DropdownMenuItem<T>(
                                  value: item,
                                  child: Text(displayText(item)),
                                ),
                              )
                              .toList(),
                      onChanged:
                          items.isEmpty
                              ? null
                              : (selected) {
                                onChanged(selected);
                                state.didChange(selected);
                              },
                    ),
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      state.errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
