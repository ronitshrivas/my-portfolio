import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/Authorization/otp.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/helper/dialogs.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Username Check State
// ─────────────────────────────────────────────────────────────────────────────

enum UsernameStatus { idle, checking, available, taken, error }

class UsernameCheckState {
  final UsernameStatus status;
  final List<String> suggestions;
  final String? errorMessage;

  const UsernameCheckState({
    this.status = UsernameStatus.idle,
    this.suggestions = const [],
    this.errorMessage,
  });

  UsernameCheckState copyWith({
    UsernameStatus? status,
    List<String>? suggestions,
    String? errorMessage,
  }) => UsernameCheckState(
    status: status ?? this.status,
    suggestions: suggestions ?? this.suggestions,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

class UsernameNotifier extends StateNotifier<UsernameCheckState> {
  UsernameNotifier() : super(const UsernameCheckState());

  Timer? _debounce;

  // Called on every keystroke — debounced 500ms so we don't spam the API
  void onUsernameChanged(String username) {
    _debounce?.cancel();

    if (username.isEmpty) {
      state = const UsernameCheckState();
      return;
    }

    // Show "checking" immediately so user sees feedback
    state = state.copyWith(status: UsernameStatus.checking, suggestions: []);

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkUsername(username.trim());
    });
  }

  Future<void> _checkUsername(String username) async {
    if (username.length < 3) {
      state = state.copyWith(
        status: UsernameStatus.error,
        errorMessage: 'Username must be at least 3 characters',
        suggestions: [],
      );
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.checkusername}?username=$username'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isAvailable = data['is_available'] == true;
        final suggestions =
            (data['suggestions'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            [];

        state = state.copyWith(
          status: isAvailable ? UsernameStatus.available : UsernameStatus.taken,
          suggestions: isAvailable ? [] : suggestions,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: UsernameStatus.error,
          errorMessage: 'Could not check username',
          suggestions: [],
        );
      }
    } catch (e) {
      developer.log('Username check error: $e');
      state = state.copyWith(
        status: UsernameStatus.error,
        errorMessage: 'Network error',
        suggestions: [],
      );
    }
  }

  void selectSuggestion(String suggestion) {
    // When user taps a suggestion, immediately mark as available
    state = state.copyWith(status: UsernameStatus.available, suggestions: []);
  }

  void reset() {
    _debounce?.cancel();
    state = const UsernameCheckState();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// Provider — autoDispose so it cleans up when Signup screen is popped
final usernameProvider =
    StateNotifierProvider.autoDispose<UsernameNotifier, UsernameCheckState>(
      (ref) => UsernameNotifier(),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Signup Screen
// ─────────────────────────────────────────────────────────────────────────────

class Signup extends ConsumerStatefulWidget {
  const Signup({super.key});

  @override
  ConsumerState<Signup> createState() => _SignupState();
}

class _SignupState extends ConsumerState<Signup> {
  final Color preciseGreen = const Color.fromRGBO(244, 135, 6, 1);

  bool _isPasswordVisible = false;
  bool isLoading = false;
  bool rememberMe = false;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController genderController = TextEditingController();

  String completePhoneNumber = '';
  DateTime? selectedDate;

  @override
  void dispose() {
    usernameController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    dobController.dispose();
    genderController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: preciseGreen,
                onPrimary: AppColors.whitecolor,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = _formatDate(picked);
      });
    }
  }

  bool _validateFields() {
    final usernameState = ref.read(usernameProvider);

    if (usernameController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter a username');
      return false;
    }
    if (usernameState.status == UsernameStatus.taken) {
      Dialogs.showSnackbar(context, 'Username is already taken');
      return false;
    }
    if (usernameState.status == UsernameStatus.checking) {
      Dialogs.showSnackbar(context, 'Please wait — checking username...');
      return false;
    }
    if (fullNameController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your full name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your email');
      return false;
    }
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      Dialogs.showSnackbar(context, 'Please enter a valid email');
      return false;
    }
    if (passwordController.text.length < 6) {
      Dialogs.showSnackbar(context, 'Password must be at least 6 characters');
      return false;
    }
    if (completePhoneNumber.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your phone number');
      return false;
    }
    if (dobController.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your date of birth');
      return false;
    }
    if (genderController.text.trim().isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter your gender');
      return false;
    }
    return true;
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe) {
        await prefs.setString('email', emailController.text.trim());
        await prefs.setString('password', passwordController.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> _signUp() async {
    if (!_validateFields()) return;

    setState(() => isLoading = true);

    try {
      final requestBody = {
        'username': usernameController.text.trim(),
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'phone_number': completePhoneNumber,
        'address': addressController.text.trim(),
        'date_of_birth': dobController.text,
        'gender': genderController.text.trim(),
      };

      developer.log('Signup request: $requestBody');

      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      developer.log(
        'Signup response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _saveCredentials();
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
          );
        }
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        final error =
            data?['message'] ??
            data?['error'] ??
            data?['detail'] ??
            'Registration failed (${response.statusCode})';
        if (mounted) Dialogs.showSnackbar(context, error.toString());
      }
    } catch (e) {
      developer.log('Signup error: $e');
      if (mounted) {
        Dialogs.showSnackbar(
          context,
          'Network error. Please check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Theme(
      data: ThemeData(
        primaryColor: preciseGreen,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: preciseGreen, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // ── Orange header ──────────────────────────────────────────────
            Container(
              width: mq.width,
              height: mq.height / 2.0,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(244, 135, 6, 1),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: mq.width * 0.03,
                  top: mq.height * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text(
                      'CREATE\nACCOUNT',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        color: AppColors.whitecolor,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(
                        'animation/loginimage.gif',
                        width: mq.width * 0.5,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── White form card ────────────────────────────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: mq.width,
                height: mq.height / 1.6,
                decoration: const BoxDecoration(
                  color: AppColors.whitecolor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(70)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // ── USERNAME — Riverpod real-time check ────────────
                        _UsernameField(
                          controller: usernameController,
                          preciseGreen: preciseGreen,
                        ),
                        SizedBox(height: mq.height * 0.025),

                        _buildField(
                          'Full Name',
                          fullNameController,
                          hint: 'Enter your full name',
                        ),
                        SizedBox(height: mq.height * 0.025),

                        _buildField(
                          'Email',
                          emailController,
                          hint: 'Enter your email',
                          prefixIcon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: mq.height * 0.025),

                        // Phone
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText('Phone Number'),
                            SizedBox(height: mq.height * 0.004),
                            IntlPhoneField(
                              controller: phoneController,
                              initialCountryCode: 'NP',
                              decoration: _inputDecoration(
                                hint: 'Phone Number',
                              ),
                              onChanged: (phone) {
                                completePhoneNumber = phone.completeNumber;
                              },
                            ),
                          ],
                        ),

                        // Date of Birth
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText('Date of Birth'),
                            SizedBox(height: mq.height * 0.004),
                            TextField(
                              controller: dobController,
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              decoration: _inputDecoration(
                                hint: 'YYYY-MM-DD',
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.date_range),
                                  onPressed: () => _selectDate(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mq.height * 0.025),

                        // Gender
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText('Gender'),
                            SizedBox(height: mq.height * 0.004),
                            DropdownButtonFormField<String>(
                              value:
                                  genderController.text.isEmpty
                                      ? null
                                      : genderController.text,
                              items:
                                  const ['Male', 'Female', 'Other']
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                if (value != null)
                                  genderController.text = value;
                              },
                              decoration: _inputDecoration(
                                hint: 'Select your gender',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mq.height * 0.025),

                        _buildField(
                          'Address',
                          addressController,
                          hint: 'Enter your address',
                        ),
                        SizedBox(height: mq.height * 0.025),

                        // Password
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _labelText('Password'),
                            SizedBox(height: mq.height * 0.004),
                            TextField(
                              controller: passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: _inputDecoration(
                                hint: 'Enter your password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _isPasswordVisible =
                                                !_isPasswordVisible,
                                      ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  activeColor: preciseGreen,
                                  checkColor: AppColors.whitecolor,
                                  value: rememberMe,
                                  onChanged:
                                      (v) => setState(() => rememberMe = v!),
                                ),
                                InkWell(
                                  onTap:
                                      () => setState(
                                        () => rememberMe = !rememberMe,
                                      ),
                                  child: const Text('Remember Me'),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Sign up button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: preciseGreen,
                            foregroundColor: AppColors.whitecolor,
                            elevation: 10,
                            minimumSize: const Size(200, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading ? null : _signUp,
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.whitecolor,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.person_add),
                          label: Text(
                            isLoading ? 'Creating Account...' : 'Sign Up',
                            style: const TextStyle(
                              color: AppColors.whitecolor,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton.icon(
                          onPressed:
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              ),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Login'),
                          style: TextButton.styleFrom(
                            foregroundColor: preciseGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (isLoading)
              Container(
                color: Colors.black.withAlpha(30),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final mq = MediaQuery.of(context).size;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _labelText(label),
        SizedBox(height: mq.height * 0.004),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: _inputDecoration(
            hint: hint,
            prefixIcon:
                prefixIcon != null
                    ? Icon(prefixIcon, color: Colors.black54)
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _labelText(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontFamily: 'InterThin',
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 14,
      color: Colors.grey,
      fontFamily: 'InterThin',
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color.fromRGBO(244, 135, 6, 1)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _UsernameField — ConsumerWidget, watches usernameProvider independently
// Only this widget rebuilds on every keystroke, not the entire form
// ─────────────────────────────────────────────────────────────────────────────

class _UsernameField extends ConsumerWidget {
  final TextEditingController controller;
  final Color preciseGreen;

  const _UsernameField({required this.controller, required this.preciseGreen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usernameProvider);
    final mq = MediaQuery.of(context).size;

    // Border color based on status
    Color borderColor() {
      switch (state.status) {
        case UsernameStatus.available:
          return Colors.green.shade500;
        case UsernameStatus.taken:
          return Colors.red.shade400;
        case UsernameStatus.checking:
          return Colors.orange.shade300;
        default:
          return Colors.grey.shade300;
      }
    }

    // Suffix icon based on status
    Widget? suffixIcon() {
      switch (state.status) {
        case UsernameStatus.checking:
          return Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orange.shade400,
              ),
            ),
          );
        case UsernameStatus.available:
          return Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade500,
            size: 22,
          );
        case UsernameStatus.taken:
          return Icon(
            Icons.cancel_rounded,
            color: Colors.red.shade400,
            size: 22,
          );
        default:
          return null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Username',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'InterThin',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        SizedBox(height: mq.height * 0.004),

        // ── Text field ─────────────────────────────────────────────────────
        TextFormField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          onChanged:
              (value) =>
                  ref.read(usernameProvider.notifier).onUsernameChanged(value),
          decoration: InputDecoration(
            hintText: 'Enter your username',
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'InterThin',
            ),
            prefixIcon: const Icon(
              Icons.alternate_email,
              color: Colors.black54,
            ),
            suffixIcon: suffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor()),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor(), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor(), width: 2),
            ),
          ),
        ),

        // ── Status message ─────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _buildStatusMessage(state),
        ),

        // ── Suggestions ────────────────────────────────────────────────────
        if (state.status == UsernameStatus.taken &&
            state.suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Try one of these:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                state.suggestions.map((suggestion) {
                  return _SuggestionChip(
                    label: suggestion,
                    preciseGreen: preciseGreen,
                    onTap: () {
                      // Fill the field and mark as available
                      controller.text = suggestion;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                      ref
                          .read(usernameProvider.notifier)
                          .selectSuggestion(suggestion);
                      // Trigger a fresh check for this suggestion
                      ref
                          .read(usernameProvider.notifier)
                          .onUsernameChanged(suggestion);
                    },
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusMessage(UsernameCheckState state) {
    switch (state.status) {
      case UsernameStatus.available:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 14,
                color: Colors.green.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Username is available!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case UsernameStatus.taken:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 4),
              Text(
                'Username already taken',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case UsernameStatus.error:
        return Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            state.errorMessage ?? 'Invalid username',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionChip — tappable username pill, orange on tap
// ─────────────────────────────────────────────────────────────────────────────

class _SuggestionChip extends StatefulWidget {
  final String label;
  final Color preciseGreen;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.preciseGreen,
    required this.onTap,
  });

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              _pressed ? widget.preciseGreen : widget.preciseGreen.withAlpha(8),
          border: Border.all(
            color:
                _pressed
                    ? widget.preciseGreen
                    : widget.preciseGreen.withAlpha(40),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alternate_email,
              size: 13,
              color: _pressed ? AppColors.whitecolor : widget.preciseGreen,
            ),
            const SizedBox(width: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _pressed ? AppColors.whitecolor : widget.preciseGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
