import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/Authorization/otp.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/ui/ui.dart';

enum ForgotMood { idle, typing, thinking, happy, sad }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool isLoading = false;
  ForgotMood mood = ForgotMood.idle;

  late AnimationController entryController;
  late AnimationController idleController;
  late AnimationController sadController;
  late AnimationController happyController;
  late AnimationController thinkController;

  late Animation<double> entryFade;
  late Animation<Offset> entrySlide;
  late Animation<double> breathe;
  late Animation<double> sadDroop;
  late Animation<double> happyJump;
  late Animation<double> thinkBob;

  static const Color orange = BrandColors.secondarySurface;
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
    entryController.forward();
    emailController.addListener(onEmailTyping);
  }

  void initAnimations() {
    entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    idleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);
    sadController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    happyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    thinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);

    entryFade = CurvedAnimation(parent: entryController, curve: Curves.easeOut);
    entrySlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: entryController, curve: Curves.easeOutCubic));
    breathe = Tween<double>(begin: 0, end: 1).animate(idleController);
    sadDroop = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: sadController, curve: Curves.easeOut));
    happyJump = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: happyController, curve: Curves.elasticOut));
    thinkBob = Tween<double>(begin: 0, end: 1).animate(thinkController);
  }

  void onEmailTyping() {
    if (mood != ForgotMood.thinking && mood != ForgotMood.happy && mood != ForgotMood.sad) {
      final next = emailController.text.isEmpty ? ForgotMood.idle : ForgotMood.typing;
      if (next != mood) setState(() => mood = next);
    }
  }

  @override
  void dispose() {
    entryController.dispose();
    idleController.dispose();
    sadController.dispose();
    happyController.dispose();
    thinkController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    if (!formKey.currentState!.validate()) {
      setState(() => mood = ForgotMood.sad);
      sadController.forward(from: 0);
      return;
    }

    setState(() { isLoading = true; mood = ForgotMood.thinking; });

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => mood = ForgotMood.happy);
        happyController.forward(from: 0);
        showSnackbar(data['message'] ?? 'OTP sent to your email!', isError: false);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => OtpResetPasswordScreen(email: emailController.text.trim()),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                child: child,
              );
            },
          ),
        );
      } else {
        setState(() => mood = ForgotMood.sad);
        sadController.forward(from: 0);
        showSnackbar(data['message'] ?? 'Failed to send OTP. Please try again.', isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => mood = ForgotMood.sad);
      sadController.forward(from: 0);
      showSnackbar('Network error. Please check your connection.', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded, color: white, size: 18),
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
      animation: Listenable.merge([idleController, sadController, happyController, thinkController]),
      builder: (_, __) {
        double dy = 0;
        if (mood == ForgotMood.happy) dy = -happyJump.value * 18;
        else if (mood == ForgotMood.thinking) dy = math.sin(thinkBob.value * math.pi * 2) * 4;

        return Transform.translate(
          offset: Offset(0, dy),
          child: CustomPaint(
            size: const Size(160, 230),
            painter: ForgotPersonPainter(
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
      case ForgotMood.idle:
        text = 'Enter your email to get started';
        color = textGrey;
        icon = Icons.lock_reset_rounded;
        break;
      case ForgotMood.typing:
        text = 'Looks good, keep going!';
        color = orange;
        icon = Icons.edit_rounded;
        break;
      case ForgotMood.thinking:
        text = 'Sending your code…';
        color = const Color(0xFF1565C0);
        icon = Icons.hourglass_top_rounded;
        break;
      case ForgotMood.happy:
        text = 'Code sent! Check your inbox 🎉';
        color = successColor;
        icon = Icons.mark_email_read_rounded;
        break;
      case ForgotMood.sad:
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
              child: Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
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
          'Forgot Password',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
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
                      boxShadow: [BoxShadow(color: orange.withAlpha(22), blurRadius: 22, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 4, width: 56,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: orange, borderRadius: BorderRadius.circular(2)),
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
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forgot Password?',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your registered email and we\'ll send you a verification code.',
                          style: TextStyle(fontSize: 14, height: 1.5, color: textGrey),
                        ),
                        const SizedBox(height: 28),

                        Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textGrey, letterSpacing: 0.9)),
                        const SizedBox(height: 8),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w500),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Email is required';
                            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,}$').hasMatch(v.trim())) return 'Enter a valid email address';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            hintStyle: TextStyle(color: textGrey.withAlpha(130), fontSize: 14),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Icon(Icons.alternate_email_rounded, color: orange, size: 20),
                            ),
                            filled: true,
                            fillColor: white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: orange, width: 2)),
                            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: errorColor, width: 1.5)),
                            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: errorColor, width: 2)),
                            errorStyle: const TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        disabledBackgroundColor: orange.withAlpha(120),
                        elevation: 4,
                        shadowColor: orange.withAlpha(80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, color: white, size: 20),
                                SizedBox(width: 10),
                                Text('Send Verification Code', style: TextStyle(color: white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.info_outline_rounded, color: orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A 6-digit verification code will be sent to your email. The code is valid for 10 minutes.',
                            style: TextStyle(fontSize: 13, color: orange.withAlpha(220), fontWeight: FontWeight.w500, height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16, color: orange),
                      label: const Text('Back to Login', style: TextStyle(color: orange, fontWeight: FontWeight.w600, fontSize: 14)),
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

class ForgotPersonPainter extends CustomPainter {
  final ForgotMood mood;
  final double breathe;
  final double sadProgress;
  final double happyProgress;
  final double thinkProgress;
  final Color primaryColor;

  ForgotPersonPainter({
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
  static const Color shirtTop = BrandColors.secondarySurface;
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
    final scaleX = mood == ForgotMood.happy ? 0.4 + (1 - happyProgress) * 0.5 : 0.75;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bottom - 4 + sadOff), width: 72 * scaleX, height: 9),
      Paint()..color = Colors.black.withAlpha(25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  void drawShoes(Canvas canvas, double cx, Size size, double sadOff) {
    final y = size.height - 10 + sadOff;
    final shoePaint = Paint()..color = shoeColor;
    final trimPaint = Paint()..color = shoeTrim;
    final shinePaint = Paint()..color = Colors.white.withAlpha(35);

    final leftPath = Path()..moveTo(cx - 34, y - 12)..lineTo(cx - 11, y - 12)..lineTo(cx - 7, y)..lineTo(cx - 40, y)..close();
    canvas.drawPath(leftPath, shoePaint);
    canvas.drawPath(leftPath, trimPaint..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 26, y - 8), width: 12, height: 4), shinePaint);

    final rightPath = Path()..moveTo(cx + 11, y - 12)..lineTo(cx + 34, y - 12)..lineTo(cx + 40, y)..lineTo(cx + 7, y)..close();
    canvas.drawPath(rightPath, shoePaint);
    canvas.drawPath(rightPath, trimPaint..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 26, y - 8), width: 12, height: 4), shinePaint);
  }

  void drawLegs(Canvas canvas, double cx, Size size, double sadOff) {
    final top = size.height - 72 + sadOff;
    final bot = size.height - 22 + sadOff;
    canvas.drawPath(Path()..moveTo(cx - 24, top)..lineTo(cx - 8, top)..lineTo(cx - 11, bot)..lineTo(cx - 30, bot)..close(), Paint()..color = pants);
    canvas.drawPath(Path()..moveTo(cx + 8, top)..lineTo(cx + 24, top)..lineTo(cx + 30, bot)..lineTo(cx + 11, bot)..close(), Paint()..color = pants);
    canvas.drawLine(Offset(cx, top + 2), Offset(cx, top + 14), Paint()..color = pantsDark..strokeWidth = 1.5);
  }

  void drawTorso(Canvas canvas, double cx, Size size, double sadOff, double breathY) {
    final tTop = size.height - 146 + sadOff - breathY;
    final tBot = size.height - 66 + sadOff;
    const w = 52.0;
    final rect = Rect.fromLTWH(cx - w, tTop, w * 2, tBot - tTop);

    canvas.drawRRect(
      RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4)),
      Paint()..shader = LinearGradient(colors: [shirtTop, shirtBot], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect),
    );
    canvas.drawLine(Offset(cx, tTop + 2), Offset(cx, tBot - 14), Paint()..color = shirtBot.withAlpha(80)..strokeWidth = 1);
    canvas.drawRect(Rect.fromLTWH(cx - w, tBot - 14, w * 2, 10), Paint()..color = pantsDark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, tBot - 9), width: 16, height: 8), const Radius.circular(2)),
      Paint()..color = const Color(0xFFBDBDBD),
    );
  }

  void drawArms(Canvas canvas, double cx, Size size, double sadOff, double breathY) {
    final shoulderY = size.height - 144 + sadOff - breathY;
    const w = 52.0;
    final sleevePaint = Paint()..color = shirtTop..strokeCap = StrokeCap.round..strokeWidth = 17..style = PaintingStyle.stroke;
    final forearmPaint = Paint()..color = skin..strokeCap = StrokeCap.round..strokeWidth = 13..style = PaintingStyle.stroke;
    final handPaint = Paint()..color = skin;

    switch (mood) {
      case ForgotMood.happy:
        final raise = happyProgress * 32;
        drawArm(canvas, cx - w + 4, shoulderY + 10, cx - w - 30, shoulderY - 18 - raise, sleevePaint, forearmPaint);
        drawArm(canvas, cx + w - 4, shoulderY + 10, cx + w + 30, shoulderY - 18 - raise, sleevePaint, forearmPaint);
        drawHand(canvas, cx - w - 30, shoulderY - 22 - raise, handPaint);
        drawHand(canvas, cx + w + 30, shoulderY - 22 - raise, handPaint);
        break;
      case ForgotMood.sad:
        final droop = sadProgress * 8;
        drawArm(canvas, cx - w + 4, shoulderY + 12, cx - w - 8, shoulderY + 72 + droop, sleevePaint, forearmPaint);
        drawArm(canvas, cx + w - 4, shoulderY + 12, cx + w + 8, shoulderY + 72 + droop, sleevePaint, forearmPaint);
        drawHand(canvas, cx - w - 8, shoulderY + 76 + droop, handPaint);
        drawHand(canvas, cx + w + 8, shoulderY + 76 + droop, handPaint);
        break;
      case ForgotMood.thinking:
        drawArm(canvas, cx - w + 4, shoulderY + 12, cx - w - 6, shoulderY + 54, sleevePaint, forearmPaint);
        drawHand(canvas, cx - w - 6, shoulderY + 58, handPaint);
        drawArm(canvas, cx + w - 4, shoulderY + 12, cx + 6, shoulderY + 22, sleevePaint, forearmPaint);
        drawHand(canvas, cx + 6, shoulderY + 26, handPaint);
        break;
      case ForgotMood.typing:
        drawArm(canvas, cx - w + 4, shoulderY + 14, cx - w + 14, shoulderY + 58, sleevePaint, forearmPaint);
        drawHand(canvas, cx - w + 14, shoulderY + 62, handPaint);
        drawArm(canvas, cx + w - 4, shoulderY + 14, cx + w - 14, shoulderY + 58, sleevePaint, forearmPaint);
        drawHand(canvas, cx + w - 14, shoulderY + 62, handPaint);
        break;
      default:
        drawArm(canvas, cx - w + 4, shoulderY + 12, cx - w - 16, shoulderY + 58, sleevePaint, forearmPaint);
        drawArm(canvas, cx + w - 4, shoulderY + 12, cx + w + 16, shoulderY + 58, sleevePaint, forearmPaint);
        drawHand(canvas, cx - w - 16, shoulderY + 62, handPaint);
        drawHand(canvas, cx + w + 16, shoulderY + 62, handPaint);
    }
  }

  void drawArm(Canvas canvas, double x1, double y1, double x2, double y2, Paint sleevePaint, Paint forearmPaint) {
    final mx = x1 + (x2 - x1) * 0.58;
    final my = y1 + (y2 - y1) * 0.58;
    canvas.drawLine(Offset(x1, y1), Offset(mx, my), sleevePaint);
    canvas.drawLine(Offset(mx, my), Offset(x2, y2), forearmPaint);
  }

  void drawHand(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawCircle(Offset(x, y), 9, paint);
  }

  void drawHead(Canvas canvas, double cx, Size size, double sadOff, double breathY) {
    final cy = size.height - 185 + sadOff - breathY;
    drawHair(canvas, cx, cy);
    drawEars(canvas, cx, cy);
    canvas.drawCircle(Offset(cx, cy), 40, Paint()..color = skin);
    canvas.drawRect(Rect.fromLTWH(cx - 10, cy + 34, 20, 14), Paint()..color = skinDark.withAlpha(170));
    drawEyebrows(canvas, cx, cy);
    drawFaceDetails(canvas, cx, cy);
  }

  void drawHair(Canvas canvas, double cx, double cy) {
    final hairPaint = Paint()..color = hair;
    final hairPath = Path()
      ..moveTo(cx - 38, cy - 8)
      ..quadraticBezierTo(cx - 42, cy - 50, cx, cy - 48)
      ..quadraticBezierTo(cx + 42, cy - 50, cx + 38, cy - 8)
      ..quadraticBezierTo(cx + 32, cy - 40, cx, cy - 42)
      ..quadraticBezierTo(cx - 32, cy - 40, cx - 38, cy - 8)
      ..close();
    canvas.drawPath(hairPath, hairPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 39, cy - 14), width: 10, height: 24), hairPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 39, cy - 14), width: 10, height: 24), hairPaint);
  }

  void drawEars(Canvas canvas, double cx, double cy) {
    final earPaint = Paint()..color = skin;
    final earInner = Paint()..color = skinDark.withAlpha(100);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 40, cy + 2), width: 10, height: 15), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 39, cy + 2), width: 5, height: 8), earInner);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 40, cy + 2), width: 10, height: 15), earPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 39, cy + 2), width: 5, height: 8), earInner);
  }

  void drawEyebrows(Canvas canvas, double cx, double cy) {
    final browPaint = Paint()..color = hair..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    switch (mood) {
      case ForgotMood.sad:
        canvas.drawLine(Offset(cx - 26, cy - 23), Offset(cx - 10, cy - 16), browPaint);
        canvas.drawLine(Offset(cx + 10, cy - 16), Offset(cx + 26, cy - 23), browPaint);
        break;
      case ForgotMood.happy:
        drawArcBrow(canvas, cx - 18, cy - 20, browPaint, raised: true);
        drawArcBrow(canvas, cx + 18, cy - 20, browPaint, raised: true);
        break;
      case ForgotMood.thinking:
        drawArcBrow(canvas, cx - 18, cy - 18, browPaint, raised: false);
        canvas.drawLine(Offset(cx + 10, cy - 23), Offset(cx + 26, cy - 20), browPaint);
        break;
      default:
        drawArcBrow(canvas, cx - 18, cy - 19, browPaint, raised: false);
        drawArcBrow(canvas, cx + 18, cy - 19, browPaint, raised: false);
    }
  }

  void drawArcBrow(Canvas canvas, double cx, double cy, Paint paint, {required bool raised}) {
    final rise = raised ? 6.0 : 2.5;
    canvas.drawPath(Path()..moveTo(cx - 12, cy)..quadraticBezierTo(cx, cy - rise, cx + 12, cy), paint);
  }

  void drawFaceDetails(Canvas canvas, double cx, double cy) {
    const eyeGap = 15.0;
    final eyeY = cy + 4.0;

    drawEye(canvas, cx - eyeGap, eyeY);
    drawEye(canvas, cx + eyeGap, eyeY);

    final nosePaint = Paint()..color = skinDark.withAlpha(100);
    canvas.drawCircle(Offset(cx - 2, cy + 14), 2.5, nosePaint);
    canvas.drawCircle(Offset(cx + 2, cy + 14), 2.5, nosePaint);

    if (mood == ForgotMood.happy) {
      canvas.drawCircle(Offset(cx - 28, cy + 12), 9, Paint()..color = cheekColor.withAlpha(110));
      canvas.drawCircle(Offset(cx + 28, cy + 12), 9, Paint()..color = cheekColor.withAlpha(110));
    }

    drawMouth(canvas, cx, cy + 24);

    if (mood == ForgotMood.sad && sadProgress > 0.35) drawTear(canvas, cx + eyeGap + 4, eyeY + 12);
    if (mood == ForgotMood.thinking) drawSweat(canvas, cx + 38, cy - 8);

    if (mood == ForgotMood.happy && happyProgress > 0.5) {
      drawStar(canvas, cx - 48, cy - 22, primaryColor);
      drawStar(canvas, cx + 48, cy - 26, primaryColor);
      if (happyProgress > 0.8) drawStar(canvas, cx, cy - 52, primaryColor.withAlpha(160));
    }
  }

  void drawEye(Canvas canvas, double x, double y) {
    final whitePaint = Paint()..color = eyeWhite;
    final pupilPaint = Paint()..color = pupilColor;
    final glintPaint = Paint()..color = Colors.white;

    switch (mood) {
      case ForgotMood.happy:
        final arcPaint = Paint()..color = pupilColor..strokeWidth = 2.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
        canvas.drawPath(Path()..moveTo(x - 10, y)..quadraticBezierTo(x, y - 10, x + 10, y), arcPaint);
        break;
      case ForgotMood.sad:
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 19, height: 18), whitePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 7), width: 17, height: 7), Paint()..color = tearColor.withAlpha(65));
        canvas.drawCircle(Offset(x, y + 2), 5.5, pupilPaint);
        canvas.drawCircle(Offset(x - 2, y), 1.8, glintPaint);
        break;
      case ForgotMood.thinking:
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 19, height: 18), whitePaint);
        canvas.drawCircle(Offset(x + 3, y + 1), 5.5, pupilPaint);
        canvas.drawCircle(Offset(x + 1, y - 2), 1.8, glintPaint);
        break;
      default:
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 19, height: 19), whitePaint);
        canvas.drawCircle(Offset(x, y), 6, pupilPaint);
        canvas.drawCircle(Offset(x - 2, y - 2), 2, glintPaint);
    }
  }

  void drawMouth(Canvas canvas, double cx, double my) {
    final mouthPaint = Paint()..color = const Color(0xFF5D2A00)..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    switch (mood) {
      case ForgotMood.happy:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, my + 2), width: 24, height: 8), const Radius.circular(4)), Paint()..color = Colors.white);
        canvas.drawPath(Path()..moveTo(cx - 15, my - 4)..quadraticBezierTo(cx, my + 13, cx + 15, my - 4), mouthPaint);
        break;
      case ForgotMood.sad:
        canvas.drawPath(Path()..moveTo(cx - 13, my + 5)..quadraticBezierTo(cx, my - 7, cx + 13, my + 5), mouthPaint);
        break;
      case ForgotMood.thinking:
        canvas.drawPath(Path()..moveTo(cx - 4, my + 1)..quadraticBezierTo(cx + 6, my - 2, cx + 15, my + 5), mouthPaint);
        break;
      default:
        canvas.drawPath(Path()..moveTo(cx - 11, my)..quadraticBezierTo(cx, my + 7, cx + 11, my), mouthPaint);
    }
  }

  void drawTear(Canvas canvas, double x, double y) {
    canvas.drawPath(
      Path()..moveTo(x, y)..quadraticBezierTo(x + 7, y + 9, x + 4, y + 17)..quadraticBezierTo(x - 2, y + 19, x - 5, y + 15)..quadraticBezierTo(x - 7, y + 9, x, y)..close(),
      Paint()..color = tearColor.withAlpha(210),
    );
  }

  void drawSweat(Canvas canvas, double x, double y) {
    canvas.drawPath(
      Path()..moveTo(x, y)..quadraticBezierTo(x + 5, y + 7, x + 3, y + 13)..quadraticBezierTo(x - 2, y + 15, x - 4, y + 11)..quadraticBezierTo(x - 5, y + 7, x, y)..close(),
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
      if (i == 0) starPath.moveTo(ox, oy); else starPath.lineTo(ox, oy);
      starPath.lineTo(ix, iy);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ForgotPersonPainter old) =>
      old.mood != mood || old.breathe != breathe || old.sadProgress != sadProgress ||
      old.happyProgress != happyProgress || old.thinkProgress != thinkProgress;
}