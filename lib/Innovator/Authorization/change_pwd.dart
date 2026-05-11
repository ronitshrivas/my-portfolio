import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';

enum CharacterMood { idle, typing, thinking, happy, angry, sad }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _oldPasswordError;

  String? _passwordMatchError;
  bool _confirmTouched = false;

  CharacterMood _mood = CharacterMood.idle;

  late AnimationController _entryCtrl;
  late AnimationController _idleCtrl;
  late AnimationController _angryCtrl;
  late AnimationController _sadCtrl;
  late AnimationController _happyCtrl;
  late AnimationController _thinkCtrl;

  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;
  late Animation<double> _breathe;
  late Animation<double> _angryShake;
  late Animation<double> _sadDroop;
  late Animation<double> _happyJump;
  late Animation<double> _thinkBob;

  static const _orange = Color.fromRGBO(244, 135, 6, 1);
  static const _orangeLight = Color(0xFFFFF3E0);
  static const _bg = Colors.white;
  static const _white = Colors.white;
  static const _textDark = Color(0xFF1A1A1A);
  static const _textGrey = Color(0xFF757575);
  static const _error = Color(0xFFD32F2F);
  static const _success = Color(0xFF2E7D32);

  final AppData _appData = AppData();

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _angryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat(reverse: true);
    _sadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _happyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _thinkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _breathe = Tween<double>(begin: 0, end: 1).animate(_idleCtrl);
    _angryShake = Tween<double>(begin: -5, end: 5).animate(_angryCtrl);
    _sadDroop = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _sadCtrl, curve: Curves.easeOut));
    _happyJump = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _happyCtrl, curve: Curves.elasticOut));
    _thinkBob = Tween<double>(begin: 0, end: 1).animate(_thinkCtrl);

    _entryCtrl.forward();

    _oldCtrl.addListener(_onTyping);
    _newCtrl.addListener(_onNewPasswordChanged);
    _confirmCtrl.addListener(_onConfirmPasswordChanged);
  }

  void _onTyping() {
    if (_mood == CharacterMood.happy ||
        _mood == CharacterMood.angry ||
        _mood == CharacterMood.sad)
      return;
    if (_mood != CharacterMood.typing) {
      setState(() => _mood = CharacterMood.typing);
    }
  }

  void _onNewPasswordChanged() {
    _onTyping();
    if (_confirmTouched) {
      _evaluatePasswordMatch();
    }
  }

  void _onConfirmPasswordChanged() {
    _onTyping();
    if (!_confirmTouched && _confirmCtrl.text.isNotEmpty) {
      _confirmTouched = true;
    }
    if (_confirmTouched) {
      _evaluatePasswordMatch();
    }
  }

  void _evaluatePasswordMatch() {
    final newPass = _newCtrl.text;
    final confirmPass = _confirmCtrl.text;

    String? error;

    if (confirmPass.isEmpty) {
      error = null;
    } else if (newPass != confirmPass) {
      error = 'Passwords do not match';
    } else {
      error = null;
    }

    if (error != _passwordMatchError) {
      setState(() => _passwordMatchError = error);
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _idleCtrl.dispose();
    _angryCtrl.dispose();
    _sadCtrl.dispose();
    _happyCtrl.dispose();
    _thinkCtrl.dispose();
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _oldPasswordError = null;
      _confirmTouched = true;
    });
    _evaluatePasswordMatch();

    if (!_formKey.currentState!.validate()) {
      _triggerSad();
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _snack('New password and confirm password do not match', error: true);
      _triggerSad();
      return;
    }

    setState(() {
      _isLoading = true;
      _mood = CharacterMood.thinking;
    });

    try {
      final url = Uri.parse(ApiConstants.changePassword);
      final hdrs = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_appData.accessToken}',
      };
      final body = jsonEncode({
        'old_password': _oldCtrl.text,
        'new_password': _newCtrl.text,
        'confirm_password': _confirmCtrl.text,
      });

      developer.log('POST $url  body=$body');
      final response = await http.post(url, headers: hdrs, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _triggerHappy();
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) _showSuccessDialog();
      } else {
        final err = jsonDecode(response.body);
        if (err is Map && err.containsKey('old_password')) {
          final msgs = err['old_password'];
          final msg =
              (msgs is List && msgs.isNotEmpty)
                  ? msgs.first.toString()
                  : 'Old password is incorrect.';
          setState(() => _oldPasswordError = msg);
          _formKey.currentState!.validate();
          _triggerAngry();
          _snack(msg, error: true);
        } else {
          final msg = err['message']?.toString() ?? 'Failed to change password';
          _triggerSad();
          _snack(msg, error: true);
        }
      }
    } catch (e) {
      developer.log('Error: $e');
      _triggerSad();
      _snack('An error occurred. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (_mood == CharacterMood.thinking) {
        setState(() => _mood = CharacterMood.idle);
      }
    }
  }

  void _triggerAngry() => setState(() => _mood = CharacterMood.angry);
  void _triggerSad() {
    setState(() => _mood = CharacterMood.sad);
    _sadCtrl.forward(from: 0);
  }

  void _triggerHappy() {
    setState(() => _mood = CharacterMood.happy);
    _happyCtrl.forward(from: 0);
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_rounded : Icons.check_circle_rounded,
              color: _white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: error ? _error : _success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccessDialog() {
    void goToLogin(BuildContext ctx) {
      if (Navigator.of(ctx, rootNavigator: true).canPop()) {
        Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => WillPopScope(
            onWillPop: () async => false,
            child: _CountdownDialog(
              onNavigate: () => goToLogin(dialogCtx),
              orange: _orange,
              white: _white,
              success: _success,
              textDark: _textDark,
              textGrey: _textGrey,
            ),
          ),
    );
  }

  Widget _buildCharacter() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _idleCtrl,
        _angryCtrl,
        _sadCtrl,
        _happyCtrl,
        _thinkCtrl,
      ]),
      builder: (_, __) {
        double dx = 0, dy = 0;

        if (_mood == CharacterMood.angry) {
          dx = _angryShake.value;
        } else if (_mood == CharacterMood.happy) {
          dy = -_happyJump.value * 18;
        } else if (_mood == CharacterMood.thinking) {
          dy = math.sin(_thinkBob.value * math.pi * 2) * 4;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: CustomPaint(
            size: const Size(160, 230),
            painter: _PersonPainter(
              mood: _mood,
              breathe: _breathe.value,
              sadProgress: _sadDroop.value,
              happyProgress: _happyJump.value,
              thinkProgress: _thinkBob.value,
              orange: _orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaption() {
    String text;
    Color color;
    IconData icon;
    switch (_mood) {
      case CharacterMood.idle:
        text = 'Ready to secure your account';
        color = _textGrey;
        icon = Icons.security_rounded;
        break;
      case CharacterMood.typing:
        text = 'Great, keep going!';
        color = _orange;
        icon = Icons.edit_rounded;
        break;
      case CharacterMood.thinking:
        text = 'Verifying your credentials…';
        color = const Color(0xFF1565C0);
        icon = Icons.hourglass_top_rounded;
        break;
      case CharacterMood.happy:
        text = 'Wonderful! Password secured! 🎉';
        color = _success;
        icon = Icons.celebration_rounded;
        break;
      case CharacterMood.angry:
        text = 'That old password is WRONG!';
        color = _error;
        icon = Icons.mood_bad_rounded;
        break;
      case CharacterMood.sad:
        text = 'Hmm, something went wrong…';
        color = const Color(0xFFE65100);
        icon = Icons.sentiment_dissatisfied_rounded;
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey(_mood),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 7),
            Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    String? externalError,
    String? realtimeError,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _textGrey,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          validator: (v) {
            if (realtimeError != null) return null;
            return externalError ?? validator(v);
          },
          autovalidateMode: AutovalidateMode.disabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textGrey.withAlpha(130), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(icon, color: _orange, size: 20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: _textGrey.withAlpha(160),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  realtimeError != null
                      ? const BorderSide(color: _error, width: 1.5)
                      : BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  realtimeError != null
                      ? const BorderSide(color: _error, width: 2)
                      : const BorderSide(color: _orange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _error, width: 2),
            ),
            errorStyle: const TextStyle(
              color: _error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child:
              realtimeError != null
                  ? Padding(
                    padding: const EdgeInsets.only(top: 6, left: 14),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: _error,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          realtimeError,
                          style: const TextStyle(
                            color: _error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withAlpha(22),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          width: 56,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: _orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        _buildCharacter(),
                        const SizedBox(height: 16),
                        _buildCaption(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          controller: _oldCtrl,
                          label: 'CURRENT PASSWORD',
                          hint: 'Your current password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureOld,
                          onToggle:
                              () => setState(() => _obscureOld = !_obscureOld),
                          externalError: _oldPasswordError,
                          validator: (v) {
                            if (_oldPasswordError != null)
                              return _oldPasswordError;
                            if (v == null || v.isEmpty)
                              return 'Please enter your current password';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _newCtrl,
                          label: 'NEW PASSWORD',
                          hint: 'Create a strong new password',
                          icon: Icons.lock_open_rounded,
                          obscure: _obscureNew,
                          onToggle:
                              () => setState(() => _obscureNew = !_obscureNew),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please enter your new password';
                            if (v.length < 6)
                              return 'At least 6 characters required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _confirmCtrl,
                          label: 'CONFIRM NEW PASSWORD',
                          hint: 'Re-enter your new password',
                          icon: Icons.verified_user_rounded,
                          obscure: _obscureConfirm,
                          onToggle:
                              () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                          realtimeError: _passwordMatchError,
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please confirm your new password';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        disabledBackgroundColor: _orange.withAlpha(120),
                        elevation: 4,
                        shadowColor: _orange.withAlpha(80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: _white,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_reset_rounded,
                                    color: _white,
                                    size: 22,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Update Password',
                                    style: TextStyle(
                                      color: _white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _orangeLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _orange.withAlpha(60)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.tips_and_updates_rounded,
                          color: _orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Use 8+ characters · Mix UPPER & lower case '
                            '· Add numbers & symbols · Avoid personal info',
                            style: TextStyle(
                              fontSize: 13,
                              color: _orange.withAlpha(220),
                              fontWeight: FontWeight.w500,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownDialog extends StatefulWidget {
  final VoidCallback onNavigate;
  final Color orange;
  final Color white;
  final Color success;
  final Color textDark;
  final Color textGrey;

  const _CountdownDialog({
    required this.onNavigate,
    required this.orange,
    required this.white,
    required this.success,
    required this.textDark,
    required this.textGrey,
  });

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog>
    with SingleTickerProviderStateMixin {
  int _seconds = 3;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _tick();
  }

  void _tick() async {
    for (int i = _seconds; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _seconds = i - 1);
    }
    if (mounted) widget.onNavigate();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: widget.white,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressCtrl,
                    builder:
                        (_, __) => SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(
                            value: 1.0 - _progressCtrl.value,
                            strokeWidth: 3.5,
                            backgroundColor: widget.success.withAlpha(40),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.success,
                            ),
                          ),
                        ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.success, width: 2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: widget.success,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Password Updated!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: widget.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'For your security, you will be logged out now. '
              'Please login again with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: widget.textGrey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                'Redirecting in $_seconds second${_seconds == 1 ? '' : 's'}…',
                key: ValueKey(_seconds),
                style: TextStyle(
                  fontSize: 12.5,
                  color: widget.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Go to Login',
                  style: TextStyle(
                    color: widget.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonPainter extends CustomPainter {
  final CharacterMood mood;
  final double breathe;
  final double sadProgress;
  final double happyProgress;
  final double thinkProgress;
  final Color orange;

  _PersonPainter({
    required this.mood,
    required this.breathe,
    required this.sadProgress,
    required this.happyProgress,
    required this.thinkProgress,
    required this.orange,
  });

  static const _skin = Color(0xFFFFD5B0);
  static const _skinDark = Color(0xFFE8A87C);
  static const _hair = Color(0xFF3E2723);
  static const _shirtTop = Color.fromRGBO(244, 135, 6, 1);
  static const _shirtBot = Color(0xFFE65100);
  static const _pants = Color(0xFF37474F);
  static const _pantsDark = Color(0xFF263238);
  static const _shoe = Color(0xFF212121);
  static const _shoeTrim = Color(0xFF424242);
  static const _eyeWhite = Colors.white;
  static const _pupilClr = Color(0xFF1A1A1A);
  static const _cheek = Color(0xFFFFAB91);
  static const _tearClr = Color(0xFF64B5F6);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final sadOff = sadProgress * 6.0;
    final breathY = breathe * 1.5;

    _drawShadow(canvas, cx, size.height, sadOff);
    _drawShoes(canvas, cx, size, sadOff);
    _drawLegs(canvas, cx, size, sadOff);
    _drawTorso(canvas, cx, size, sadOff, breathY);
    _drawArms(canvas, cx, size, sadOff, breathY);
    _drawHead(canvas, cx, size, sadOff, breathY);
  }

  void _drawShadow(Canvas canvas, double cx, double bottom, double sadOff) {
    final scaleX =
        mood == CharacterMood.happy ? 0.4 + (1 - happyProgress) * 0.5 : 0.75;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, bottom - 4 + sadOff),
        width: 72 * scaleX,
        height: 9,
      ),
      Paint()
        ..color = Colors.black.withAlpha(25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void _drawShoes(Canvas canvas, double cx, Size size, double sadOff) {
    final y = size.height - 10 + sadOff;
    final shoe = Paint()..color = _shoe;
    final trim = Paint()..color = _shoeTrim;
    final shine = Paint()..color = Colors.white.withAlpha(35);

    final lPath =
        Path()
          ..moveTo(cx - 34, y - 12)
          ..lineTo(cx - 11, y - 12)
          ..lineTo(cx - 7, y)
          ..lineTo(cx - 40, y)
          ..close();
    canvas.drawPath(lPath, shoe);
    canvas.drawPath(
      lPath,
      trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 26, y - 8), width: 12, height: 4),
      shine,
    );

    final rPath =
        Path()
          ..moveTo(cx + 11, y - 12)
          ..lineTo(cx + 34, y - 12)
          ..lineTo(cx + 40, y)
          ..lineTo(cx + 7, y)
          ..close();
    canvas.drawPath(rPath, shoe);
    canvas.drawPath(
      rPath,
      trim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 26, y - 8), width: 12, height: 4),
      shine,
    );
  }

  void _drawLegs(Canvas canvas, double cx, Size size, double sadOff) {
    final top = size.height - 72 + sadOff;
    final bot = size.height - 22 + sadOff;

    canvas.drawPath(
      Path()
        ..moveTo(cx - 24, top)
        ..lineTo(cx - 8, top)
        ..lineTo(cx - 11, bot)
        ..lineTo(cx - 30, bot)
        ..close(),
      Paint()..color = _pants,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 8, top)
        ..lineTo(cx + 24, top)
        ..lineTo(cx + 30, bot)
        ..lineTo(cx + 11, bot)
        ..close(),
      Paint()..color = _pants,
    );
    canvas.drawLine(
      Offset(cx, top + 2),
      Offset(cx, top + 14),
      Paint()
        ..color = _pantsDark
        ..strokeWidth = 1.5,
    );
    final stitch =
        Paint()
          ..color = _pantsDark.withAlpha(90)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 26, top + 6, 12, 10),
        const Radius.circular(2),
      ),
      stitch,
    );
  }

  void _drawTorso(
    Canvas canvas,
    double cx,
    Size size,
    double sadOff,
    double breathY,
  ) {
    final tTop = size.height - 146 + sadOff - breathY;
    final tBot = size.height - 66 + sadOff;
    final w = 52.0;
    final rect = Rect.fromLTWH(cx - w, tTop, w * 2, tBot - tTop);

    final shirtPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [_shirtTop, _shirtBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      shirtPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withAlpha(45), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx - 11, tTop + 4)
        ..lineTo(cx, tTop + 20)
        ..lineTo(cx + 11, tTop + 4),
      Paint()
        ..color = _shirtBot.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(cx, tTop + 24 + i * 14.0),
        2.5,
        Paint()..color = _shirtBot.withAlpha(120),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 18, tTop + 22, 16, 13),
        const Radius.circular(3),
      ),
      Paint()
        ..color = _shirtBot.withAlpha(90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawRect(
      Rect.fromLTWH(cx - w, tBot - 14, w * 2, 10),
      Paint()..color = _pantsDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, tBot - 9), width: 16, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFBDBDBD),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, tBot - 9), width: 6, height: 3),
      Paint()..color = const Color(0xFF9E9E9E),
    );
  }

  void _drawArms(
    Canvas canvas,
    double cx,
    Size size,
    double sadOff,
    double breathY,
  ) {
    final shoulderY = size.height - 144 + sadOff - breathY;
    const w = 52.0;

    final sleevePaint =
        Paint()
          ..color = _shirtTop
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 17
          ..style = PaintingStyle.stroke;
    final forearmPaint =
        Paint()
          ..color = _skin
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 13
          ..style = PaintingStyle.stroke;
    final handPaint = Paint()..color = _skin;

    switch (mood) {
      case CharacterMood.angry:
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 10,
          cx - w - 24,
          shoulderY + 42,
          sleevePaint,
          forearmPaint,
        );
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 10,
          cx + w + 24,
          shoulderY + 42,
          sleevePaint,
          forearmPaint,
        );
        _fist(canvas, cx - w - 24, shoulderY + 47, handPaint);
        _fist(canvas, cx + w + 24, shoulderY + 47, handPaint);
        break;

      case CharacterMood.happy:
        final raise = happyProgress * 32;
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 10,
          cx - w - 30,
          shoulderY - 18 - raise,
          sleevePaint,
          forearmPaint,
        );
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 10,
          cx + w + 30,
          shoulderY - 18 - raise,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx - w - 30, shoulderY - 22 - raise, handPaint);
        _hand(canvas, cx + w + 30, shoulderY - 22 - raise, handPaint);
        break;

      case CharacterMood.sad:
        final droop = sadProgress * 8;
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 8,
          shoulderY + 72 + droop,
          sleevePaint,
          forearmPaint,
        );
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + w + 8,
          shoulderY + 72 + droop,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx - w - 8, shoulderY + 76 + droop, handPaint);
        _hand(canvas, cx + w + 8, shoulderY + 76 + droop, handPaint);
        break;

      case CharacterMood.thinking:
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 6,
          shoulderY + 54,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx - w - 6, shoulderY + 58, handPaint);
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + 6,
          shoulderY + 22,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx + 6, shoulderY + 26, handPaint);
        break;

      case CharacterMood.typing:
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 14,
          cx - w + 14,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx - w + 14, shoulderY + 62, handPaint);
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 14,
          cx + w - 14,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx + w - 14, shoulderY + 62, handPaint);
        break;

      default:
        _arm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 16,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        _arm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + w + 16,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        _hand(canvas, cx - w - 16, shoulderY + 62, handPaint);
        _hand(canvas, cx + w + 16, shoulderY + 62, handPaint);
    }
  }

  void _arm(
    Canvas canvas,
    double x1,
    double y1,
    double x2,
    double y2,
    Paint sleevePaint,
    Paint forearmPaint,
  ) {
    final mx = x1 + (x2 - x1) * 0.58;
    final my = y1 + (y2 - y1) * 0.58;
    canvas.drawLine(Offset(x1, y1), Offset(mx, my), sleevePaint);
    canvas.drawLine(Offset(mx, my), Offset(x2, y2), forearmPaint);
  }

  void _hand(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 9, paint);
    final fp =
        Paint()
          ..color = _skinDark.withAlpha(110)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(x + i * 3.5, y - 4),
        Offset(x + i * 3.5, y + 4),
        fp,
      );
    }
  }

  void _fist(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 17, height: 14),
        const Radius.circular(5),
      ),
      paint,
    );
    final kp =
        Paint()
          ..color = _skinDark.withAlpha(100)
          ..strokeWidth = 0.9
          ..style = PaintingStyle.stroke;
    for (int i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(x + i * 4.5, y - 5), 2, kp);
    }
  }

  void _drawHead(
    Canvas canvas,
    double cx,
    Size size,
    double sadOff,
    double breathY,
  ) {
    final cy = size.height - 185 + sadOff - breathY;

    _drawHair(canvas, cx, cy);
    _drawEars(canvas, cx, cy);
    canvas.drawCircle(Offset(cx, cy), 40, Paint()..color = _skin);
    canvas.drawCircle(
      Offset(cx, cy),
      40,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.45, -0.4),
          radius: 0.9,
          colors: [Colors.white.withAlpha(55), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 40)),
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - 10, cy + 34, 20, 14),
      Paint()..color = _skinDark.withAlpha(170),
    );
    _drawEyebrows(canvas, cx, cy);
    _drawFace(canvas, cx, cy);
  }

  void _drawHair(Canvas canvas, double cx, double cy) {
    final hp = Paint()..color = _hair;
    final h =
        Path()
          ..moveTo(cx - 38, cy - 8)
          ..quadraticBezierTo(cx - 42, cy - 50, cx, cy - 48)
          ..quadraticBezierTo(cx + 42, cy - 50, cx + 38, cy - 8)
          ..quadraticBezierTo(cx + 32, cy - 40, cx, cy - 42)
          ..quadraticBezierTo(cx - 32, cy - 40, cx - 38, cy - 8)
          ..close();
    canvas.drawPath(h, hp);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 39, cy - 14), width: 10, height: 24),
      hp,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 39, cy - 14), width: 10, height: 24),
      hp,
    );
    canvas.drawLine(
      Offset(cx - 6, cy - 46),
      Offset(cx + 14, cy - 36),
      Paint()
        ..color = Colors.white.withAlpha(28)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEars(Canvas canvas, double cx, double cy) {
    final ep = Paint()..color = _skin;
    final ei = Paint()..color = _skinDark.withAlpha(100);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 40, cy + 2), width: 10, height: 15),
      ep,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 39, cy + 2), width: 5, height: 8),
      ei,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 40, cy + 2), width: 10, height: 15),
      ep,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 39, cy + 2), width: 5, height: 8),
      ei,
    );
  }

  void _drawEyebrows(Canvas canvas, double cx, double cy) {
    final bp =
        Paint()
          ..color = _hair
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    switch (mood) {
      case CharacterMood.angry:
        canvas.drawLine(Offset(cx - 26, cy - 16), Offset(cx - 10, cy - 23), bp);
        canvas.drawLine(Offset(cx + 10, cy - 23), Offset(cx + 26, cy - 16), bp);
        break;
      case CharacterMood.sad:
        canvas.drawLine(Offset(cx - 26, cy - 23), Offset(cx - 10, cy - 16), bp);
        canvas.drawLine(Offset(cx + 10, cy - 16), Offset(cx + 26, cy - 23), bp);
        break;
      case CharacterMood.happy:
        _arc(canvas, cx - 18, cy - 20, bp, raised: true);
        _arc(canvas, cx + 18, cy - 20, bp, raised: true);
        break;
      case CharacterMood.thinking:
        _arc(canvas, cx - 18, cy - 18, bp, raised: false);
        canvas.drawLine(Offset(cx + 10, cy - 23), Offset(cx + 26, cy - 20), bp);
        break;
      default:
        _arc(canvas, cx - 18, cy - 19, bp, raised: false);
        _arc(canvas, cx + 18, cy - 19, bp, raised: false);
    }
  }

  void _arc(
    Canvas canvas,
    double cx,
    double cy,
    Paint paint, {
    required bool raised,
  }) {
    final rise = raised ? 6.0 : 2.5;
    final p =
        Path()
          ..moveTo(cx - 12, cy)
          ..quadraticBezierTo(cx, cy - rise, cx + 12, cy);
    canvas.drawPath(p, paint);
  }

  void _drawFace(Canvas canvas, double cx, double cy) {
    final eyeY = cy + 4.0;
    final eyeGp = 15.0;

    _drawEye(canvas, cx - eyeGp, eyeY, left: true);
    _drawEye(canvas, cx + eyeGp, eyeY, left: false);

    final np = Paint()..color = _skinDark.withAlpha(100);
    canvas.drawCircle(Offset(cx - 2, cy + 14), 2.5, np);
    canvas.drawCircle(Offset(cx + 2, cy + 14), 2.5, np);
    canvas.drawLine(
      Offset(cx, cy + 8),
      Offset(cx, cy + 12),
      Paint()
        ..color = _skinDark.withAlpha(70)
        ..strokeWidth = 1.5,
    );

    if (mood == CharacterMood.happy) {
      canvas.drawCircle(
        Offset(cx - 28, cy + 12),
        9,
        Paint()..color = _cheek.withAlpha(110),
      );
      canvas.drawCircle(
        Offset(cx + 28, cy + 12),
        9,
        Paint()..color = _cheek.withAlpha(110),
      );
    }
    if (mood == CharacterMood.angry) {
      canvas.drawCircle(
        Offset(cx - 28, cy + 10),
        9,
        Paint()..color = Colors.red.withAlpha(55),
      );
      canvas.drawCircle(
        Offset(cx + 28, cy + 10),
        9,
        Paint()..color = Colors.red.withAlpha(55),
      );
    }

    _drawMouth(canvas, cx, cy + 24);

    if (mood == CharacterMood.sad && sadProgress > 0.35) {
      _drawTear(canvas, cx + eyeGp + 4, eyeY + 12);
    }

    if (mood == CharacterMood.thinking) {
      _drawSweat(canvas, cx + 38, cy - 8);
    }

    if (mood == CharacterMood.angry) {
      final vp =
          Paint()
            ..color = Colors.red.withAlpha(190)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx + 34, cy - 14), Offset(cx + 38, cy - 6), vp);
      canvas.drawLine(Offset(cx + 38, cy - 6), Offset(cx + 34, cy + 2), vp);
    }

    if (mood == CharacterMood.happy && happyProgress > 0.5) {
      _star(canvas, cx - 48, cy - 22, orange);
      _star(canvas, cx + 48, cy - 26, orange);
      if (happyProgress > 0.8) {
        _star(canvas, cx, cy - 52, orange.withAlpha(160));
      }
    }
  }

  void _drawEye(Canvas canvas, double x, double y, {required bool left}) {
    final wh = Paint()..color = _eyeWhite;
    final pu = Paint()..color = _pupilClr;
    final gl = Paint()..color = Colors.white;

    switch (mood) {
      case CharacterMood.happy:
        final ap =
            Paint()
              ..color = _pupilClr
              ..strokeWidth = 2.8
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
        final arc =
            Path()
              ..moveTo(x - 10, y)
              ..quadraticBezierTo(x, y - 10, x + 10, y);
        canvas.drawPath(arc, ap);
        break;

      case CharacterMood.angry:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 17, height: 10),
          wh,
        );
        canvas.drawCircle(Offset(x, y + 1), 4, pu);
        canvas.drawCircle(Offset(x - 2, y - 1), 1.5, gl);
        break;

      case CharacterMood.sad:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 19, height: 18),
          wh,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y + 7), width: 17, height: 7),
          Paint()..color = _tearClr.withAlpha(65),
        );
        canvas.drawCircle(Offset(x, y + 2), 5.5, pu);
        canvas.drawCircle(Offset(x - 2, y), 1.8, gl);
        break;

      case CharacterMood.thinking:
        final w = left ? 19.0 : 17.0;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: 18),
          wh,
        );
        canvas.drawCircle(Offset(x + 3, y + 1), 5.5, pu);
        canvas.drawCircle(Offset(x + 1, y - 2), 1.8, gl);
        break;

      default:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 19, height: 19),
          wh,
        );
        canvas.drawCircle(Offset(x, y), 6, pu);
        canvas.drawCircle(Offset(x - 2, y - 2), 2, gl);
    }
  }

  void _drawMouth(Canvas canvas, double cx, double my) {
    final mp =
        Paint()
          ..color = const Color(0xFF5D2A00)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    switch (mood) {
      case CharacterMood.happy:
        final smile =
            Path()
              ..moveTo(cx - 15, my - 4)
              ..quadraticBezierTo(cx, my + 13, cx + 15, my - 4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, my + 2), width: 24, height: 8),
            const Radius.circular(4),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawPath(smile, mp);
        break;

      case CharacterMood.angry:
        final frown =
            Path()
              ..moveTo(cx - 15, my + 4)
              ..quadraticBezierTo(cx, my - 8, cx + 15, my + 4);
        canvas.drawPath(frown, mp);
        final tp =
            Paint()
              ..color = const Color(0xFF5D2A00).withAlpha(110)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke;
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(cx + i * 5.0, my - 4),
            Offset(cx + i * 5.0, my + 2),
            tp,
          );
        }
        break;

      case CharacterMood.sad:
        final frown =
            Path()
              ..moveTo(cx - 13, my + 5)
              ..quadraticBezierTo(cx, my - 7, cx + 13, my + 5);
        canvas.drawPath(frown, mp);
        final lip =
            Path()
              ..moveTo(cx - 10, my + 7)
              ..quadraticBezierTo(cx, my + 13, cx + 10, my + 7);
        canvas.drawPath(
          lip,
          Paint()
            ..color = const Color(0xFF5D2A00).withAlpha(75)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        break;

      case CharacterMood.thinking:
        final smirk =
            Path()
              ..moveTo(cx - 4, my + 1)
              ..quadraticBezierTo(cx + 6, my - 2, cx + 15, my + 5);
        canvas.drawPath(smirk, mp);
        break;

      default:
        final smile =
            Path()
              ..moveTo(cx - 11, my)
              ..quadraticBezierTo(cx, my + 7, cx + 11, my);
        canvas.drawPath(smile, mp);
    }
  }

  void _drawTear(Canvas canvas, double x, double y) {
    final tp = Paint()..color = _tearClr.withAlpha(210);
    final t =
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 7, y + 9, x + 4, y + 17)
          ..quadraticBezierTo(x - 2, y + 19, x - 5, y + 15)
          ..quadraticBezierTo(x - 7, y + 9, x, y)
          ..close();
    canvas.drawPath(t, tp);
    canvas.drawCircle(
      Offset(x + 1, y + 5),
      1.8,
      Paint()..color = Colors.white.withAlpha(160),
    );
  }

  void _drawSweat(Canvas canvas, double x, double y) {
    final sp = Paint()..color = const Color(0xFF90CAF9).withAlpha(200);
    final p =
        Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 5, y + 7, x + 3, y + 13)
          ..quadraticBezierTo(x - 2, y + 15, x - 4, y + 11)
          ..quadraticBezierTo(x - 5, y + 7, x, y)
          ..close();
    canvas.drawPath(p, sp);
  }

  void _star(Canvas canvas, double cx, double cy, Color color) {
    final p = Path();
    for (int i = 0; i < 5; i++) {
      final oa = (i * 72 - 90) * math.pi / 180;
      final ia = oa + 36 * math.pi / 180;
      final ox = cx + 8 * math.cos(oa);
      final oy = cy + 8 * math.sin(oa);
      final ix = cx + 4 * math.cos(ia);
      final iy = cy + 4 * math.sin(ia);
      if (i == 0)
        p.moveTo(ox, oy);
      else
        p.lineTo(ox, oy);
      p.lineTo(ix, iy);
    }
    p.close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PersonPainter old) =>
      old.mood != mood ||
      old.breathe != breathe ||
      old.sadProgress != sadProgress ||
      old.happyProgress != happyProgress ||
      old.thinkProgress != thinkProgress;
}
