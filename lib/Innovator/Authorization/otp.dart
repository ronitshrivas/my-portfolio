import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/constant/api_constants.dart';

class SingleDigitFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final digit = digits[digits.length - 1];
    return TextEditingValue(
      text: digit,
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

class PinInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final Color activeColor;
  final bool hasError;
  final bool isLocked;

  const PinInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    required this.activeColor,
    this.hasError = false,
    this.isLocked = false,
  });

  @override
  State<PinInputField> createState() => PinInputFieldState();
}

class PinInputFieldState extends State<PinInputField> {
  late final List<TextEditingController> controllers;
  late final List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(widget.length, (_) => TextEditingController());
    focusNodes = List.generate(widget.length, (i) {
      return FocusNode(
        onKeyEvent: (node, event) {
          if (widget.isLocked) return KeyEventResult.handled;
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controllers[i].text.isEmpty &&
              i > 0) {
            controllers[i - 1].clear();
            focusNodes[i - 1].requestFocus();
            notifyChange();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      );
    });

    for (final f in focusNodes) {
      f.addListener(() {
        if (mounted) setState(() {});
      });
    }

    for (final c in controllers) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  String get pin => controllers.map((c) => c.text).join();

  void notifyChange() {
    final currentPin = pin;
    widget.onChanged(currentPin);
    if (currentPin.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(currentPin);
    }
    if (mounted) setState(() {});
  }

  void onBoxChanged(int index, String val) {
    if (widget.isLocked) return;
    if (val.length == 1) {
      if (index < widget.length - 1) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    }
    notifyChange();
  }

  void clearAll() {
    for (final c in controllers) {
      c.clear();
    }
    if (focusNodes.isNotEmpty) {
      focusNodes[0].requestFocus();
    }
    notifyChange();
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (i) => PinBox(
          controller: controllers[i],
          focusNode: focusNodes[i],
          activeColor: widget.activeColor,
          hasError: widget.hasError,
          isLocked: widget.isLocked,
          onChanged: (v) => onBoxChanged(i, v),
        ),
      ),
    );
  }
}

class PinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Color activeColor;
  final bool hasError;
  final bool isLocked;
  final ValueChanged<String> onChanged;

  const PinBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.activeColor,
    required this.hasError,
    required this.isLocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus && !isLocked;
    final hasValue = controller.text.isNotEmpty;

    final Color borderColor;
    final Color bgColor;

    if (isLocked && hasValue) {
      borderColor = const Color(0xFF2E7D32);
      bgColor = const Color(0xFFE8F5E9);
    } else if (hasError) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.shade50;
    } else if (isFocused) {
      borderColor = activeColor;
      bgColor = const Color(0xFFF5F5F5);
    } else {
      borderColor = const Color(0xFFE0E0E0);
      bgColor = const Color(0xFFF5F5F5);
    }

    return SizedBox(
      width: 44,
      height: 54,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 44,
            height: 54,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isFocused || hasError || isLocked ? 2.0 : 1.0,
              ),
            ),
            child: Center(
              child:
                  hasValue
                      ? isLocked
                          ? Icon(
                            Icons.circle,
                            size: 10,
                            color: const Color(0xFF2E7D32),
                          )
                          : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  hasError
                                      ? Colors.red.shade400
                                      : const Color(0xFF212529),
                            ),
                          )
                      : isFocused
                      ? BlinkingCursor(color: activeColor)
                      : const SizedBox.shrink(),
            ),
          ),
          if (!isLocked)
            Positioned.fill(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  SingleDigitFormatter(),
                ],
                style: const TextStyle(color: Colors.transparent, fontSize: 18),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class BlinkingCursor extends StatefulWidget {
  final Color color;

  const BlinkingCursor({super.key, required this.color});

  @override
  State<BlinkingCursor> createState() => BlinkingCursorState();
}

class BlinkingCursorState extends State<BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Container(
        width: 1.5,
        height: 20,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

enum OtpMood { idle, typing, thinking, happy, wrong, sad }

class OtpResetPasswordScreen extends StatefulWidget {
  final String email;

  const OtpResetPasswordScreen({super.key, required this.email});

  @override
  State<OtpResetPasswordScreen> createState() => OtpResetPasswordScreenState();
}

class OtpResetPasswordScreenState extends State<OtpResetPasswordScreen>
    with TickerProviderStateMixin {
  final GlobalKey<PinInputFieldState> pinFieldKey =
      GlobalKey<PinInputFieldState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isResending = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  int resendSeconds = 10;
  int otpExpirySeconds = 600;

  Timer? resendTimer;
  Timer? otpExpiryTimer;

  String otpError = '';
  String currentOtp = '';
  bool otpVerified = false;
  bool otpExpired = false;
  String? passwordMatchError;
  bool confirmTouched = false;

  OtpMood mood = OtpMood.idle;

  late AnimationController entryController;
  late AnimationController idleController;
  late AnimationController angryController;
  late AnimationController sadController;
  late AnimationController happyController;
  late AnimationController thinkController;
  late AnimationController shakeController;
  late AnimationController successController;

  late Animation<double> entryFade;
  late Animation<Offset> entrySlide;
  late Animation<double> breathe;
  late Animation<double> angryShake;
  late Animation<double> sadDroop;
  late Animation<double> happyJump;
  late Animation<double> thinkBob;
  late Animation<double> shakeAnim;
  late Animation<double> successScale;
  late Animation<double> successOpacity;

  static const Color orange = Color.fromRGBO(244, 135, 6, 1);
  static const Color orangeLight = Color(0xFFFFF3E0);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color white = Colors.white;

  @override
  void initState() {
    super.initState();
    initAnimations();
    startResendTimer();
    startOtpExpiryTimer();
    entryController.forward();
    newPasswordController.addListener(onNewPasswordChanged);
    confirmPasswordController.addListener(onConfirmPasswordChanged);
  }

  void initAnimations() {
    entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    angryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
    )..repeat(reverse: true);
    sadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    happyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    thinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    entryFade = CurvedAnimation(parent: entryController, curve: Curves.easeOut);
    entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: entryController, curve: Curves.easeOutCubic),
    );

    breathe = Tween<double>(begin: 0, end: 1).animate(idleController);
    angryShake = Tween<double>(begin: -5, end: 5).animate(angryController);
    sadDroop = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: sadController, curve: Curves.easeOut));
    happyJump = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: happyController, curve: Curves.elasticOut),
    );
    thinkBob = Tween<double>(begin: 0, end: 1).animate(thinkController);
    shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.easeInOut),
    );
    successScale = CurvedAnimation(
      parent: successController,
      curve: Curves.elasticOut,
    );
    successOpacity = CurvedAnimation(
      parent: successController,
      curve: Curves.easeIn,
    );
  }

  void startResendTimer() {
    setState(() => resendSeconds = 30);
    resendTimer?.cancel();
    resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (resendSeconds > 0)
          resendSeconds--;
        else
          t.cancel();
      });
    });
  }

  void startOtpExpiryTimer() {
    setState(() {
      otpExpirySeconds = 600;
      otpExpired = false;
    });
    otpExpiryTimer?.cancel();
    otpExpiryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (otpExpirySeconds > 0) {
          otpExpirySeconds--;
        } else {
          t.cancel();
          otpExpired = true;
          if (!otpVerified) {
            mood = OtpMood.sad;
            otpError = 'OTP has expired. Please request a new code.';
            sadController.forward(from: 0);
          }
        }
      });
    });
  }

  String get expiryDisplay {
    final m = otpExpirySeconds ~/ 60;
    final s = otpExpirySeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void onNewPasswordChanged() {
    if (mood != OtpMood.happy && mood != OtpMood.wrong && mood != OtpMood.sad) {
      setState(() => mood = OtpMood.typing);
    }
    if (confirmTouched) evaluatePasswordMatch();
  }

  void onConfirmPasswordChanged() {
    if (mood != OtpMood.happy && mood != OtpMood.wrong && mood != OtpMood.sad) {
      setState(() => mood = OtpMood.typing);
    }
    if (!confirmTouched && confirmPasswordController.text.isNotEmpty)
      confirmTouched = true;
    if (confirmTouched) evaluatePasswordMatch();
  }

  void evaluatePasswordMatch() {
    final confirmPass = confirmPasswordController.text;
    String? error;
    if (confirmPass.isNotEmpty && newPasswordController.text != confirmPass) {
      error = 'Passwords do not match';
    }
    if (error != passwordMatchError) setState(() => passwordMatchError = error);
  }

  @override
  void dispose() {
    resendTimer?.cancel();
    otpExpiryTimer?.cancel();
    entryController.dispose();
    idleController.dispose();
    angryController.dispose();
    sadController.dispose();
    happyController.dispose();
    thinkController.dispose();
    shakeController.dispose();
    successController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get isOtpComplete => currentOtp.length == 6;

  void onOtpChanged(String value) {
    if (otpVerified) return;
    setState(() {
      currentOtp = value;
      otpError = '';
      if (mood != OtpMood.happy) {
        mood = value.isNotEmpty ? OtpMood.typing : OtpMood.idle;
      }
    });
    if (value.length == 6) autoVerifyOtp(value);
  }

  Future<void> autoVerifyOtp(String otp) async {
    if (otpExpired) {
      setState(() => otpError = 'OTP has expired. Please request a new code.');
      triggerSad();
      return;
    }

    setState(() {
      isLoading = true;
      mood = OtpMood.thinking;
    });

    try {
      final verifyRes = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': otp}),
      );

      if (!mounted) return;

      if (verifyRes.statusCode == 200 || verifyRes.statusCode == 201) {
        otpExpiryTimer?.cancel();
        setState(() {
          otpVerified = true;
          mood = OtpMood.happy;
          otpError = '';
        });
        happyController.forward(from: 0);
        HapticFeedback.lightImpact();
      } else {
        final err = jsonDecode(verifyRes.body);
        setState(() {
          otpError = err['message'] ?? 'Invalid OTP. Please try again.';
          mood = OtpMood.wrong;
          otpVerified = false;
        });
        triggerShake();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) pinFieldKey.currentState?.clearAll();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        otpError = 'Network error. Please try again.';
        mood = OtpMood.sad;
      });
      triggerSad();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> submit() async {
    setState(() {
      confirmTouched = true;
      passwordMatchError = null;
    });
    evaluatePasswordMatch();

    if (!isOtpComplete || !otpVerified) {
      setState(() => otpError = 'Please complete OTP verification first');
      triggerShake();
      return;
    }

    if (!formKey.currentState!.validate()) {
      triggerSad();
      return;
    }
    if (passwordMatchError != null) {
      triggerSad();
      return;
    }

    setState(() {
      isLoading = true;
      mood = OtpMood.thinking;
    });

    try {
      final resetRes = await http.post(
        Uri.parse(ApiConstants.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'new_password': newPasswordController.text,
          'confirm_password': confirmPasswordController.text,
        }),
      );

      if (!mounted) return;

      if (resetRes.statusCode == 200 || resetRes.statusCode == 201) {
        triggerHappy();
        await successController.forward();
        showSnackbar(
          'Password reset successfully! Please log in.',
          isError: false,
        );
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        final err = jsonDecode(resetRes.body);
        showSnackbar(
          err['message'] ?? 'Failed to reset password.',
          isError: true,
        );
        triggerSad();
      }
    } catch (_) {
      showSnackbar(
        'Network error. Please check your connection.',
        isError: true,
      );
      triggerSad();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> resendOtp() async {
    if (resendSeconds > 0 || isResending) return;
    setState(() => isResending = true);

    try {
      final res = await http.post(
        Uri.parse(ApiConstants.resendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        pinFieldKey.currentState?.clearAll();
        setState(() {
          otpVerified = false;
          currentOtp = '';
          otpError = '';
          mood = OtpMood.idle;
        });
        startResendTimer();
        startOtpExpiryTimer();
        HapticFeedback.lightImpact();
        showSnackbar('Verification code resent!', isError: false);
      } else {
        final err = jsonDecode(res.body);
        showSnackbar(err['message'] ?? 'Failed to resend code.', isError: true);
      }
    } catch (_) {
      showSnackbar('Network error. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => isResending = false);
    }
  }

  void triggerShake() {
    HapticFeedback.vibrate();
    shakeController.forward(from: 0);
  }

  void triggerSad() {
    setState(() => mood = OtpMood.sad);
    sadController.forward(from: 0);
  }

  void triggerHappy() {
    setState(() => mood = OtpMood.happy);
    happyController.forward(from: 0);
  }

  void showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget buildCharacter() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        idleController,
        angryController,
        sadController,
        happyController,
        thinkController,
      ]),
      builder: (_, __) {
        double dx = 0, dy = 0;
        if (mood == OtpMood.wrong)
          dx = angryShake.value;
        else if (mood == OtpMood.happy)
          dy = -happyJump.value * 18;
        else if (mood == OtpMood.thinking)
          dy = math.sin(thinkBob.value * math.pi * 2) * 4;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: CustomPaint(
            size: const Size(160, 230),
            painter: OtpPersonPainter(
              mood: mood,
              breathe: breathe.value,
              sadProgress: sadDroop.value,
              happyProgress: happyJump.value,
              thinkProgress: thinkBob.value,
              primaryColor: orange,
            ),
          ),
        );
      },
    );
  }

  Widget buildCaption() {
    String text;
    Color color;
    IconData icon;

    switch (mood) {
      case OtpMood.idle:
        text = 'Enter the code sent to your email';
        color = textGrey;
        icon = Icons.email_outlined;
        break;
      case OtpMood.typing:
        text = 'Keep going, almost there!';
        color = orange;
        icon = Icons.edit_rounded;
        break;
      case OtpMood.thinking:
        text = 'Verifying your code…';
        color = const Color(0xFF1565C0);
        icon = Icons.hourglass_top_rounded;
        break;
      case OtpMood.happy:
        text = 'OTP verified! Set your new password 🎉';
        color = successColor;
        icon = Icons.celebration_rounded;
        break;
      case OtpMood.wrong:
        text = 'Wrong code! Please try again.';
        color = errorColor;
        icon = Icons.mood_bad_rounded;
        break;
      case OtpMood.sad:
        text = 'Hmm, something went wrong…';
        color = const Color(0xFFE65100);
        icon = Icons.sentiment_dissatisfied_rounded;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: Container(
        key: ValueKey(mood),
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
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
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
            color: textGrey,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(
            color: textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.disabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textGrey.withAlpha(130), fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(Icons.lock_outline_rounded, color: orange, size: 20),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: textGrey.withAlpha(160),
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: white,
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
                      ? const BorderSide(color: errorColor, width: 1.5)
                      : BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  realtimeError != null
                      ? const BorderSide(color: errorColor, width: 2)
                      : const BorderSide(color: orange, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: errorColor, width: 2),
            ),
            errorStyle: const TextStyle(
              color: errorColor,
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
                          color: errorColor,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          realtimeError,
                          style: const TextStyle(
                            color: errorColor,
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
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: entryFade,
        child: SlideTransition(
          position: entrySlide,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: orange.withAlpha(22),
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
                            color: orange,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        buildCharacter(),
                        const SizedBox(height: 16),
                        buildCaption(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: white,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: orange.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: orange.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: orange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Code sent to',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VERIFICATION CODE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: textGrey,
                                letterSpacing: 0.9,
                              ),
                            ),
                            if (!otpVerified && !otpExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      otpExpirySeconds < 60
                                          ? errorColor.withAlpha(18)
                                          : orange.withAlpha(18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        otpExpirySeconds < 60
                                            ? errorColor.withAlpha(60)
                                            : orange.withAlpha(60),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 13,
                                      color:
                                          otpExpirySeconds < 60
                                              ? errorColor
                                              : orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      expiryDisplay,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            otpExpirySeconds < 60
                                                ? errorColor
                                                : orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (otpVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: successColor.withAlpha(18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: successColor.withAlpha(60),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_rounded,
                                      size: 13,
                                      color: successColor,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Locked',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: successColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        AnimatedBuilder(
                          animation: shakeAnim,
                          builder:
                              (_, child) => Transform.translate(
                                offset: Offset(shakeAnim.value, 0),
                                child: child,
                              ),
                          child: PinInputField(
                            key: pinFieldKey,
                            length: 6,
                            activeColor:
                                mood == OtpMood.wrong ? errorColor : orange,
                            hasError: mood == OtpMood.wrong,
                            isLocked: otpVerified,
                            onChanged: onOtpChanged,
                          ),
                        ),

                        if (otpError.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFFCDD2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: errorColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    otpError,
                                    style: const TextStyle(
                                      color: errorColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (otpVerified) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: successColor.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: successColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'OTP verified successfully!',
                                  style: TextStyle(
                                    color: successColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        if (!otpVerified)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive it? ",
                                style: TextStyle(fontSize: 13, color: textGrey),
                              ),
                              isResending
                                  ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        orange,
                                      ),
                                    ),
                                  )
                                  : resendSeconds > 0
                                  ? Text(
                                    'Resend in ${resendSeconds}s',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textGrey.withAlpha(160),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                  : GestureDetector(
                                    onTap: resendOtp,
                                    child: const Text(
                                      'Resend Code',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: orange,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                        decorationColor: orange,
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    child:
                        otpVerified
                            ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: white,
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
                                  buildPasswordField(
                                    controller: newPasswordController,
                                    label: 'NEW PASSWORD',
                                    hint: 'Create a strong new password',
                                    obscure: !showNewPassword,
                                    onToggle:
                                        () => setState(
                                          () =>
                                              showNewPassword =
                                                  !showNewPassword,
                                        ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Please enter your new password';
                                      if (v.length < 6)
                                        return 'At least 6 characters required';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  buildPasswordField(
                                    controller: confirmPasswordController,
                                    label: 'CONFIRM NEW PASSWORD',
                                    hint: 'Re-enter your new password',
                                    obscure: !showConfirmPassword,
                                    onToggle:
                                        () => setState(
                                          () =>
                                              showConfirmPassword =
                                                  !showConfirmPassword,
                                        ),
                                    realtimeError: passwordMatchError,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Please confirm your new password';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),

                  if (otpVerified) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          disabledBackgroundColor: orange.withAlpha(120),
                          elevation: 4,
                          shadowColor: orange.withAlpha(80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: white,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_reset_rounded,
                                      color: white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reset Password',
                                      style: TextStyle(
                                        color: white,
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
                        color: orangeLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: orange.withAlpha(60)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_rounded,
                            color: orange,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Use 8+ characters · Mix UPPER & lower case · Add numbers & symbols · Avoid personal info',
                              style: TextStyle(
                                fontSize: 13,
                                color: orange.withAlpha(220),
                                fontWeight: FontWeight.w500,
                                height: 1.55,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: successController,
                    builder: (_, __) {
                      if (successController.value == 0)
                        return const SizedBox.shrink();
                      return Center(
                        child: FadeTransition(
                          opacity: successOpacity,
                          child: ScaleTransition(
                            scale: successScale,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: successColor,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

class OtpPersonPainter extends CustomPainter {
  final OtpMood mood;
  final double breathe;
  final double sadProgress;
  final double happyProgress;
  final double thinkProgress;
  final Color primaryColor;

  OtpPersonPainter({
    required this.mood,
    required this.breathe,
    required this.sadProgress,
    required this.happyProgress,
    required this.thinkProgress,
    required this.primaryColor,
  });

  static const Color skin = Color(0xFFFFD5B0);
  static const Color skinDark = Color(0xFFE8A87C);
  static const Color hair = Color(0xFF3E2723);
  static const Color shirtTop = Color.fromRGBO(244, 135, 6, 1);
  static const Color shirtBot = Color(0xFFE65100);
  static const Color pants = Color(0xFF37474F);
  static const Color pantsDark = Color(0xFF263238);
  static const Color shoeColor = Color(0xFF212121);
  static const Color shoeTrim = Color(0xFF424242);
  static const Color eyeWhite = Colors.white;
  static const Color pupilColor = Color(0xFF1A1A1A);
  static const Color cheekColor = Color(0xFFFFAB91);
  static const Color tearColor = Color(0xFF64B5F6);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final sadOff = sadProgress * 6.0;
    final breathY = breathe * 1.5;

    drawShadow(canvas, cx, size.height, sadOff);
    drawShoes(canvas, cx, size, sadOff);
    drawLegs(canvas, cx, size, sadOff);
    drawTorso(canvas, cx, size, sadOff, breathY);
    drawArms(canvas, cx, size, sadOff, breathY);
    drawHead(canvas, cx, size, sadOff, breathY);
  }

  void drawShadow(Canvas canvas, double cx, double bottom, double sadOff) {
    final scaleX =
        mood == OtpMood.happy ? 0.4 + (1 - happyProgress) * 0.5 : 0.75;
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

  void drawShoes(Canvas canvas, double cx, Size size, double sadOff) {
    final y = size.height - 10 + sadOff;
    final shoePaint = Paint()..color = shoeColor;
    final trimPaint = Paint()..color = shoeTrim;
    final shinePaint = Paint()..color = Colors.white.withAlpha(35);

    final leftPath =
        Path()
          ..moveTo(cx - 34, y - 12)
          ..lineTo(cx - 11, y - 12)
          ..lineTo(cx - 7, y)
          ..lineTo(cx - 40, y)
          ..close();
    canvas.drawPath(leftPath, shoePaint);
    canvas.drawPath(
      leftPath,
      trimPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 26, y - 8), width: 12, height: 4),
      shinePaint,
    );

    final rightPath =
        Path()
          ..moveTo(cx + 11, y - 12)
          ..lineTo(cx + 34, y - 12)
          ..lineTo(cx + 40, y)
          ..lineTo(cx + 7, y)
          ..close();
    canvas.drawPath(rightPath, shoePaint);
    canvas.drawPath(
      rightPath,
      trimPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 26, y - 8), width: 12, height: 4),
      shinePaint,
    );
  }

  void drawLegs(Canvas canvas, double cx, Size size, double sadOff) {
    final top = size.height - 72 + sadOff;
    final bot = size.height - 22 + sadOff;

    canvas.drawPath(
      Path()
        ..moveTo(cx - 24, top)
        ..lineTo(cx - 8, top)
        ..lineTo(cx - 11, bot)
        ..lineTo(cx - 30, bot)
        ..close(),
      Paint()..color = pants,
    );
    canvas.drawPath(
      Path()
        ..moveTo(cx + 8, top)
        ..lineTo(cx + 24, top)
        ..lineTo(cx + 30, bot)
        ..lineTo(cx + 11, bot)
        ..close(),
      Paint()..color = pants,
    );
    canvas.drawLine(
      Offset(cx, top + 2),
      Offset(cx, top + 14),
      Paint()
        ..color = pantsDark
        ..strokeWidth = 1.5,
    );
  }

  void drawTorso(
    Canvas canvas,
    double cx,
    Size size,
    double sadOff,
    double breathY,
  ) {
    final tTop = size.height - 146 + sadOff - breathY;
    final tBot = size.height - 66 + sadOff;
    const w = 52.0;
    final rect = Rect.fromLTWH(cx - w, tTop, w * 2, tBot - tTop);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      ),
      Paint()
        ..shader = LinearGradient(
          colors: [shirtTop, shirtBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawLine(
      Offset(cx, tTop + 2),
      Offset(cx, tBot - 14),
      Paint()
        ..color = shirtBot.withAlpha(80)
        ..strokeWidth = 1,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx - w, tBot - 14, w * 2, 10),
      Paint()..color = pantsDark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, tBot - 9), width: 16, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFBDBDBD),
    );
  }

  void drawArms(
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
          ..color = shirtTop
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 17
          ..style = PaintingStyle.stroke;
    final forearmPaint =
        Paint()
          ..color = skin
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 13
          ..style = PaintingStyle.stroke;
    final handPaint = Paint()..color = skin;

    switch (mood) {
      case OtpMood.wrong:
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 10,
          cx - w - 24,
          shoulderY + 42,
          sleevePaint,
          forearmPaint,
        );
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 10,
          cx + w + 24,
          shoulderY + 42,
          sleevePaint,
          forearmPaint,
        );
        drawFist(canvas, cx - w - 24, shoulderY + 47, handPaint);
        drawFist(canvas, cx + w + 24, shoulderY + 47, handPaint);
        break;
      case OtpMood.happy:
        final raise = happyProgress * 32;
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 10,
          cx - w - 30,
          shoulderY - 18 - raise,
          sleevePaint,
          forearmPaint,
        );
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 10,
          cx + w + 30,
          shoulderY - 18 - raise,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx - w - 30, shoulderY - 22 - raise, handPaint);
        drawHand(canvas, cx + w + 30, shoulderY - 22 - raise, handPaint);
        break;
      case OtpMood.sad:
        final droop = sadProgress * 8;
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 8,
          shoulderY + 72 + droop,
          sleevePaint,
          forearmPaint,
        );
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + w + 8,
          shoulderY + 72 + droop,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx - w - 8, shoulderY + 76 + droop, handPaint);
        drawHand(canvas, cx + w + 8, shoulderY + 76 + droop, handPaint);
        break;
      case OtpMood.thinking:
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 6,
          shoulderY + 54,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx - w - 6, shoulderY + 58, handPaint);
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + 6,
          shoulderY + 22,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx + 6, shoulderY + 26, handPaint);
        break;
      case OtpMood.typing:
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 14,
          cx - w + 14,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx - w + 14, shoulderY + 62, handPaint);
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 14,
          cx + w - 14,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx + w - 14, shoulderY + 62, handPaint);
        break;
      default:
        drawArm(
          canvas,
          cx - w + 4,
          shoulderY + 12,
          cx - w - 16,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        drawArm(
          canvas,
          cx + w - 4,
          shoulderY + 12,
          cx + w + 16,
          shoulderY + 58,
          sleevePaint,
          forearmPaint,
        );
        drawHand(canvas, cx - w - 16, shoulderY + 62, handPaint);
        drawHand(canvas, cx + w + 16, shoulderY + 62, handPaint);
    }
  }

  void drawArm(
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

  void drawHand(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 9, paint);
  }

  void drawFist(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 17, height: 14),
        const Radius.circular(5),
      ),
      paint,
    );
  }

  void drawHead(
    Canvas canvas,
    double cx,
    Size size,
    double sadOff,
    double breathY,
  ) {
    final cy = size.height - 185 + sadOff - breathY;
    drawHair(canvas, cx, cy);
    drawEars(canvas, cx, cy);
    canvas.drawCircle(Offset(cx, cy), 40, Paint()..color = skin);
    canvas.drawRect(
      Rect.fromLTWH(cx - 10, cy + 34, 20, 14),
      Paint()..color = skinDark.withAlpha(170),
    );
    drawEyebrows(canvas, cx, cy);
    drawFaceDetails(canvas, cx, cy);
  }

  void drawHair(Canvas canvas, double cx, double cy) {
    final hairPaint = Paint()..color = hair;
    final hairPath =
        Path()
          ..moveTo(cx - 38, cy - 8)
          ..quadraticBezierTo(cx - 42, cy - 50, cx, cy - 48)
          ..quadraticBezierTo(cx + 42, cy - 50, cx + 38, cy - 8)
          ..quadraticBezierTo(cx + 32, cy - 40, cx, cy - 42)
          ..quadraticBezierTo(cx - 32, cy - 40, cx - 38, cy - 8)
          ..close();
    canvas.drawPath(hairPath, hairPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 39, cy - 14), width: 10, height: 24),
      hairPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 39, cy - 14), width: 10, height: 24),
      hairPaint,
    );
  }

  void drawEars(Canvas canvas, double cx, double cy) {
    final earPaint = Paint()..color = skin;
    final earInner = Paint()..color = skinDark.withAlpha(100);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 40, cy + 2), width: 10, height: 15),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 39, cy + 2), width: 5, height: 8),
      earInner,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 40, cy + 2), width: 10, height: 15),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 39, cy + 2), width: 5, height: 8),
      earInner,
    );
  }

  void drawEyebrows(Canvas canvas, double cx, double cy) {
    final browPaint =
        Paint()
          ..color = hair
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    switch (mood) {
      case OtpMood.wrong:
        canvas.drawLine(
          Offset(cx - 26, cy - 16),
          Offset(cx - 10, cy - 23),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + 10, cy - 23),
          Offset(cx + 26, cy - 16),
          browPaint,
        );
        break;
      case OtpMood.sad:
        canvas.drawLine(
          Offset(cx - 26, cy - 23),
          Offset(cx - 10, cy - 16),
          browPaint,
        );
        canvas.drawLine(
          Offset(cx + 10, cy - 16),
          Offset(cx + 26, cy - 23),
          browPaint,
        );
        break;
      case OtpMood.happy:
        drawArcBrow(canvas, cx - 18, cy - 20, browPaint, raised: true);
        drawArcBrow(canvas, cx + 18, cy - 20, browPaint, raised: true);
        break;
      case OtpMood.thinking:
        drawArcBrow(canvas, cx - 18, cy - 18, browPaint, raised: false);
        canvas.drawLine(
          Offset(cx + 10, cy - 23),
          Offset(cx + 26, cy - 20),
          browPaint,
        );
        break;
      default:
        drawArcBrow(canvas, cx - 18, cy - 19, browPaint, raised: false);
        drawArcBrow(canvas, cx + 18, cy - 19, browPaint, raised: false);
    }
  }

  void drawArcBrow(
    Canvas canvas,
    double cx,
    double cy,
    Paint paint, {
    required bool raised,
  }) {
    final rise = raised ? 6.0 : 2.5;
    canvas.drawPath(
      Path()
        ..moveTo(cx - 12, cy)
        ..quadraticBezierTo(cx, cy - rise, cx + 12, cy),
      paint,
    );
  }

  void drawFaceDetails(Canvas canvas, double cx, double cy) {
    const eyeGap = 15.0;
    final eyeY = cy + 4.0;

    drawEye(canvas, cx - eyeGap, eyeY, isLeft: true);
    drawEye(canvas, cx + eyeGap, eyeY, isLeft: false);

    final nosePaint = Paint()..color = skinDark.withAlpha(100);
    canvas.drawCircle(Offset(cx - 2, cy + 14), 2.5, nosePaint);
    canvas.drawCircle(Offset(cx + 2, cy + 14), 2.5, nosePaint);

    if (mood == OtpMood.happy) {
      canvas.drawCircle(
        Offset(cx - 28, cy + 12),
        9,
        Paint()..color = cheekColor.withAlpha(110),
      );
      canvas.drawCircle(
        Offset(cx + 28, cy + 12),
        9,
        Paint()..color = cheekColor.withAlpha(110),
      );
    }
    if (mood == OtpMood.wrong) {
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

    drawMouth(canvas, cx, cy + 24);

    if (mood == OtpMood.sad && sadProgress > 0.35)
      drawTear(canvas, cx + eyeGap + 4, eyeY + 12);
    if (mood == OtpMood.thinking) drawSweat(canvas, cx + 38, cy - 8);

    if (mood == OtpMood.happy && happyProgress > 0.5) {
      drawStar(canvas, cx - 48, cy - 22, primaryColor);
      drawStar(canvas, cx + 48, cy - 26, primaryColor);
      if (happyProgress > 0.8)
        drawStar(canvas, cx, cy - 52, primaryColor.withAlpha(160));
    }
  }

  void drawEye(Canvas canvas, double x, double y, {required bool isLeft}) {
    final whitePaint = Paint()..color = eyeWhite;
    final pupilPaint = Paint()..color = pupilColor;
    final glintPaint = Paint()..color = Colors.white;

    switch (mood) {
      case OtpMood.happy:
        final arcPaint =
            Paint()
              ..color = pupilColor
              ..strokeWidth = 2.8
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(x - 10, y)
            ..quadraticBezierTo(x, y - 10, x + 10, y),
          arcPaint,
        );
        break;
      case OtpMood.wrong:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 17, height: 10),
          whitePaint,
        );
        canvas.drawCircle(Offset(x, y + 1), 4, pupilPaint);
        canvas.drawCircle(Offset(x - 2, y - 1), 1.5, glintPaint);
        break;
      case OtpMood.sad:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 19, height: 18),
          whitePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y + 7), width: 17, height: 7),
          Paint()..color = tearColor.withAlpha(65),
        );
        canvas.drawCircle(Offset(x, y + 2), 5.5, pupilPaint);
        canvas.drawCircle(Offset(x - 2, y), 1.8, glintPaint);
        break;
      case OtpMood.thinking:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: isLeft ? 19.0 : 17.0,
            height: 18,
          ),
          whitePaint,
        );
        canvas.drawCircle(Offset(x + 3, y + 1), 5.5, pupilPaint);
        canvas.drawCircle(Offset(x + 1, y - 2), 1.8, glintPaint);
        break;
      default:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 19, height: 19),
          whitePaint,
        );
        canvas.drawCircle(Offset(x, y), 6, pupilPaint);
        canvas.drawCircle(Offset(x - 2, y - 2), 2, glintPaint);
    }
  }

  void drawMouth(Canvas canvas, double cx, double my) {
    final mouthPaint =
        Paint()
          ..color = const Color(0xFF5D2A00)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    switch (mood) {
      case OtpMood.happy:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, my + 2), width: 24, height: 8),
            const Radius.circular(4),
          ),
          Paint()..color = Colors.white,
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx - 15, my - 4)
            ..quadraticBezierTo(cx, my + 13, cx + 15, my - 4),
          mouthPaint,
        );
        break;
      case OtpMood.wrong:
        canvas.drawPath(
          Path()
            ..moveTo(cx - 15, my + 4)
            ..quadraticBezierTo(cx, my - 8, cx + 15, my + 4),
          mouthPaint,
        );
        break;
      case OtpMood.sad:
        canvas.drawPath(
          Path()
            ..moveTo(cx - 13, my + 5)
            ..quadraticBezierTo(cx, my - 7, cx + 13, my + 5),
          mouthPaint,
        );
        break;
      case OtpMood.thinking:
        canvas.drawPath(
          Path()
            ..moveTo(cx - 4, my + 1)
            ..quadraticBezierTo(cx + 6, my - 2, cx + 15, my + 5),
          mouthPaint,
        );
        break;
      default:
        canvas.drawPath(
          Path()
            ..moveTo(cx - 11, my)
            ..quadraticBezierTo(cx, my + 7, cx + 11, my),
          mouthPaint,
        );
    }
  }

  void drawTear(Canvas canvas, double x, double y) {
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 7, y + 9, x + 4, y + 17)
        ..quadraticBezierTo(x - 2, y + 19, x - 5, y + 15)
        ..quadraticBezierTo(x - 7, y + 9, x, y)
        ..close(),
      Paint()..color = tearColor.withAlpha(210),
    );
  }

  void drawSweat(Canvas canvas, double x, double y) {
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 5, y + 7, x + 3, y + 13)
        ..quadraticBezierTo(x - 2, y + 15, x - 4, y + 11)
        ..quadraticBezierTo(x - 5, y + 7, x, y)
        ..close(),
      Paint()..color = const Color(0xFF90CAF9).withAlpha(200),
    );
  }

  void drawStar(Canvas canvas, double cx, double cy, Color color) {
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * math.pi / 180;
      final innerAngle = outerAngle + 36 * math.pi / 180;
      final ox = cx + 8 * math.cos(outerAngle);
      final oy = cy + 8 * math.sin(outerAngle);
      final ix = cx + 4 * math.cos(innerAngle);
      final iy = cy + 4 * math.sin(innerAngle);
      if (i == 0)
        starPath.moveTo(ox, oy);
      else
        starPath.lineTo(ox, oy);
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant OtpPersonPainter old) =>
      old.mood != mood ||
      old.breathe != breathe ||
      old.sadProgress != sadProgress ||
      old.happyProgress != happyProgress ||
      old.thinkProgress != thinkProgress;
}
