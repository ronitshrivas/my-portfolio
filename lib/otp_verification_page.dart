import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme/brand_colors.dart';
import 'login_page.dart';
import 'models/api_response.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_orb_logo.dart';
import 'widgets/glass_text_field.dart';
import 'widgets/liquid_button.dart';

const _ink = BrandColors.ink;

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0, .8, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, .06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));

  final _codeController = TextEditingController();
  final _authApi = AuthApi();

  bool _busy = false;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _entrance.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _toast('Enter the 6-digit code');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.verifyEmail(email: widget.email, code: code);
      if (!mounted) return;
      _toast('Email verified — please sign in');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not verify the code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0 || _busy) return;
    try {
      await _authApi.resendVerificationOtp(email: widget.email);
      if (!mounted) return;
      _toast('A new code has been sent');
      _startCooldown();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not resend the code');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: GlassCard(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const GlassOrbLogo(size: 52),
                          const SizedBox(height: 8),
                          const Text(
                            'Verify your email',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.5,
                              height: 1.15,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter the 6-digit code sent to ${widget.email}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              color: _ink.withValues(alpha: .5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            controller: _codeController,
                            hint: '6-digit code',
                            icon: Icons.password_rounded,
                            keyboardType: TextInputType.number,
                            dense: true,
                          ),
                          const SizedBox(height: 8),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          else
                            LiquidButton(
                              label: 'Verify',
                              dense: true,
                              onTap: _verify,
                            ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: _resendIn > 0 ? null : _resend,
                            style: TextButton.styleFrom(
                              foregroundColor: _ink.withValues(alpha: .55),
                            ),
                            child: Text(
                              _resendIn > 0
                                  ? 'Resend in ${_resendIn}s'
                                  : 'Resend code',
                              style: const TextStyle(fontSize: 12.5),
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
        ],
      ),
    );
  }
}
