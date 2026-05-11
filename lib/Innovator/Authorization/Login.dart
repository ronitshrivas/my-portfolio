import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Forget_PWD.dart';
import 'package:innovator/Innovator/Authorization/signup.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/helper/dialogs.dart';
import 'package:innovator/Innovator/services/fcm_services.dart';
import 'package:innovator/ecommerce/provider/notificationProvider.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';
import 'package:innovator/innovator_home.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.clearFields = false});
  final bool clearFields;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final Color _orange = const Color.fromRGBO(244, 135, 6, 1);

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isGoogleLoading = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // ── Google Sign-In singleton ──────────────────────────────────────────────
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  @override
  void initState() {
    super.initState();
    if (widget.clearFields) {
      _emailCtrl.clear();
      _passwordCtrl.clear();
    } else {
      _loadSaved();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Saved credentials ─────────────────────────────────────────────────────

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('rememberMe') ?? false;
      if (remember && mounted) {
        setState(() {
          _rememberMe = true;
          _emailCtrl.text = prefs.getString('email') ?? '';
          _passwordCtrl.text = prefs.getString('password') ?? '';
        });
      }
    } catch (e) {
      developer.log('loadSaved error: $e');
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('email', _emailCtrl.text.trim());
        await prefs.setString('password', _passwordCtrl.text.trim());
        await prefs.setBool('rememberMe', true);
      } else {
        await prefs.remove('email');
        await prefs.remove('password');
        await prefs.setBool('rememberMe', false);
      }
    } catch (e) {
      developer.log('saveCredentials error: $e');
    }
  }

  // ── Email / Password Login ────────────────────────────────────────────────

  Future<void> _login() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      Dialogs.showSnackbar(context, 'Please enter both email and password');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text.trim(),
        }),
      );

      developer.log(
        'Login ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final accessToken = data['access_token']?.toString() ?? '';
        final refreshToken = data['refresh_token']?.toString() ?? '';
        final user = (data['user'] as Map<String, dynamic>?) ?? {};

        if (accessToken.isEmpty) {
          Dialogs.showSnackbar(context, 'Login failed: no token in response');
          return;
        }

        await AppData().saveLoginData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        developer.log(
          'Login saved — access_token: ${accessToken.substring(0, 30)}...',
        );
        developer.log('User: $user');
        await _saveCredentials();
        if (!mounted) return;
        _navigateAfterLogin(user);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final fcmToken = await FirebaseMessaging.instance.getToken();
          developer.log('FCM TOKEN IS: $fcmToken');
          if (fcmToken == null) return;
          if (!mounted) return;
          await Future.wait([
            FCMService().registerToken(),
            ref
                .read(elearningNotificationServiceProvider)
                .registerFcmToken(fcmToken),
            ref
                .read(ecommerceNotificationServiceProvider)
                .registerFcmToken(fcmToken),
          ]);
        });
      } else {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;

        final detail = data?['detail'];
        final msg =
            (detail is List ? detail.join(', ') : detail?.toString()) ??
            data?['message']?.toString() ??
            data?['error']?.toString() ??
            'Login failed (${response.statusCode})';
        Dialogs.showSnackbar(context, msg);
      }
    } catch (e) {
      developer.log('Login error: $e');
      Dialogs.showSnackbar(
        context,
        'Network error. Please check your connection.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      TextInput.finishAutofillContext(shouldSave: false);
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

  // Shows the native Google account picker, gets the idToken,
  // signs into Firebase, then sends the token to the backend SSO API.
  Future<void> _showAccountPicker() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Step 1: Show Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User dismissed the picker — not an error
        developer.log('Google Sign-In: user cancelled');
        return;
      }

      // Step 2: Get Google auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        developer.log('Google Sign-In: idToken is null');
        if (mounted) {
          Dialogs.showSnackbar(
            context,
            'Google Sign-In failed: could not retrieve token',
          );
        }
        return;
      }

      developer.log(
        'Google idToken (first 40): ${idToken.substring(0, 40)}...',
      );

      // Step 3: Sign into Firebase with Google credential (keeps Firebase Auth in sync)
      try {
        final OAuthCredential firebaseCred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(firebaseCred);
        developer.log('Firebase sign-in with Google: success');
      } catch (firebaseErr) {
        // Non-fatal — still proceed with backend SSO
        developer.log('Firebase Google sign-in (non-fatal): $firebaseErr');
      }

      // Step 4: Exchange token with your backend
      await _sendGoogleTokenToBackend(idToken);
    } catch (e) {
      developer.log('Google Sign-In error: $e');
      if (mounted) {
        Dialogs.showSnackbar(
          context,
          'Google Sign-In failed. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  /// POSTs the Google ID token to the backend SSO endpoint.
  /// On success, saves auth tokens via AppData and navigates — same as email login.
  Future<void> _sendGoogleTokenToBackend(String googleIdToken) async {
    const String ssoUrl = 'http://36.253.137.34:8010/api/auth/sso/google/';

    developer.log('Posting to SSO: $ssoUrl');

    try {
      final response = await http.post(
        Uri.parse(ssoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'google_token': googleIdToken}),
      );

      developer.log(
        'SSO ${response.statusCode}: '
        '${response.body.substring(0, response.body.length.clamp(0, 300))}',
      );
      developer.log('googgle id token : $googleIdToken');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Handles multiple common token key patterns from backends
        final accessToken =
            data['access_token']?.toString() ??
            data['token']?.toString() ??
            (data['tokens'] as Map<String, dynamic>?)?['access']?.toString() ??
            '';

        final refreshToken =
            data['refresh_token']?.toString() ??
            (data['tokens'] as Map<String, dynamic>?)?['refresh']?.toString() ??
            '';

        final user =
            (data['user'] as Map<String, dynamic>?) ??
            (data['data'] as Map<String, dynamic>?) ??
            {};

        if (accessToken.isEmpty) {
          developer.log(
            'SSO: no token in response. Keys: ${data.keys.toList()}',
          );
          if (mounted) {
            Dialogs.showSnackbar(
              context,
              'Google Sign-In failed: server did not return a token',
            );
          }
          await _googleSignIn.signOut(); // Allow retry
          return;
        }

        // Save auth data — identical path to email/password login
        await AppData().saveLoginData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        developer.log('SSO login saved. User: $user');

        if (mounted) _navigateAfterLogin(user);

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final fcmToken = await FirebaseMessaging.instance.getToken();
          developer.log('FCM TOKEN after Google login: $fcmToken');
          if (fcmToken == null) return;
          if (!mounted) return;
          await Future.wait([
            FCMService().registerToken(),
            ref
                .read(elearningNotificationServiceProvider)
                .registerFcmToken(fcmToken),
            ref
                .read(ecommerceNotificationServiceProvider)
                .registerFcmToken(fcmToken),
          ]);
        });
      } else {
        // Parse backend error message
        Map<String, dynamic>? errorData;
        try {
          errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        } catch (_) {}

        final msg =
            errorData?['detail']?.toString() ??
            errorData?['message']?.toString() ??
            errorData?['error']?.toString() ??
            'Google Sign-In failed (${response.statusCode})';

        developer.log('SSO error: $msg');
        if (mounted) Dialogs.showSnackbar(context, msg);

        await _googleSignIn.signOut(); // Allow retry with different account
      }
    } catch (e) {
      developer.log('SSO network error: $e');
      if (mounted) {
        Dialogs.showSnackbar(
          context,
          'Network error during Google Sign-In. Please try again.',
        );
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _navigateAfterLogin(Map<String, dynamic> user) {
    final appData = AppData();

    if (appData.isProfileComplete) {
      developer.log('Profile complete → Homepage');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Homepage()),
        (Route) => false,
      );
    } else {
      developer.log('Profile incomplete → Homepage + snackbar');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Homepage()),
        (_) => false,
      );
      // Future.delayed(const Duration(milliseconds: 100), () {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(
      //         content: const Row(
      //           children: [
      //             Icon(Icons.info_outline, color: AppColors.whitecolor),
      //             SizedBox(width: 8),
      //             Expanded(
      //               child: Text('Please complete your profile to continue'),
      //             ),
      //           ],
      //         ),
      //         backgroundColor: Colors.orange,
      //         behavior: SnackBarBehavior.floating,
      //         duration: const Duration(seconds: 4),
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(10),
      //         ),
      //       ),
      //     );
      //   }
      // });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Theme(
      data: ThemeData(primaryColor: _orange),
      child: Scaffold(
        body: Stack(
          children: [
            // Orange header
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
                      'Welcome\nBack,',
                      style: TextStyle(
                        fontSize: 30,
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

            // White card
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
                  padding: EdgeInsets.only(
                    top: mq.height * 0.05,
                    left: mq.width * 0.05,
                    right: mq.width * 0.05,
                    bottom: mq.height * 0.02,
                  ),
                  child: SingleChildScrollView(
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Email
                            _label('Email'),
                            SizedBox(height: mq.height * 0.004),
                            TextFormField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onEditingComplete:
                                  () => _passwordFocus.requestFocus(),
                              decoration: _dec(
                                hint: 'Enter your email',
                                prefix: Icons.email,
                              ),
                            ),

                            SizedBox(height: mq.height * 0.025),

                            // Password
                            _label('Password'),
                            SizedBox(height: mq.height * 0.004),
                            TextFormField(
                              controller: _passwordCtrl,
                              focusNode: _passwordFocus,
                              obscureText: !_isPasswordVisible,
                              autofillHints: const [AutofillHints.password],
                              onEditingComplete: () {
                                TextInput.finishAutofillContext();
                                _login();
                              },
                              decoration: _dec(
                                hint: 'Enter your password',
                                suffix: IconButton(
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

                            SizedBox(height: mq.height * 0.01),

                            // Remember me + Forgot password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      activeColor: _orange,
                                      checkColor: AppColors.whitecolor,
                                      value: _rememberMe,
                                      onChanged:
                                          (v) =>
                                              setState(() => _rememberMe = v!),
                                    ),
                                    InkWell(
                                      onTap:
                                          () => setState(
                                            () => _rememberMe = !_rememberMe,
                                          ),
                                      child: const Text('Remember Me'),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  const ForgotPasswordScreen(),
                                        ),
                                      ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: mq.height * 0.02),

                            // Login button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _orange,
                                elevation: 10,
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.whitecolor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),

                            SizedBox(height: mq.height * 0.02),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: mq.width * 0.01),
                                InkWell(
                                  onTap: () {
                                    TextInput.finishAutofillContext(
                                      shouldSave: false,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const Signup(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.blue,
                                      fontSize: 15,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: mq.height * 0.03),

                            // Google Sign-In button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(
                                  244,
                                  135,
                                  6,
                                  1,
                                ),
                                shape: const StadiumBorder(),
                                elevation: 1,
                              ),
                              onPressed:
                                  _isGoogleLoading ? null : _showAccountPicker,
                              icon:
                                  _isGoogleLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Lottie.asset(
                                        'animation/Googlesignup.json',
                                        height: mq.height * .05,
                                      ),
                              label: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 19,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Sign In with ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    TextSpan(
                                      text: 'Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Full-screen loading overlay (covers both email & Google loading)
            if (_isLoading || _isGoogleLoading)
              Container(
                color: Colors.black.withAlpha(30),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'InterThin',
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    ),
  );

  InputDecoration _dec({
    required String hint,
    IconData? prefix,
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
    prefixIcon: prefix != null ? Icon(prefix, color: Colors.black54) : null,
    suffixIcon: suffix,
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
