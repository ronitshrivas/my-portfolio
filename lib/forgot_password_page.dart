import 'package:flutter/material.dart';

import 'theme/brand_colors.dart';
import 'models/api_response.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/glass_card.dart';
import 'widgets/glass_orb_logo.dart';
import 'widgets/glass_text_field.dart';
import 'widgets/liquid_button.dart';

const _ink = BrandColors.ink;

/// Forgot-password flow: request an OTP by email, then verify it and set a new
/// password — all in one glass card, revealed step by step.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
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

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authApi = AuthApi();

  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _entrance.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _toast('Enter your email');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.forgotPassword(email: email);
      if (!mounted) return;
      _toast('A reset code has been sent to your email');
      setState(() => _codeSent = true);
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not send the reset code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (code.length != 6) {
      _toast('Enter the 6-digit code');
      return;
    }
    if (password.length < 8) {
      _toast('Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      _toast('Passwords do not match');
      return;
    }

    setState(() => _busy = true);
    try {
      await _authApi.resetPassword(
        email: email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      _toast('Password reset — please sign in');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not reset password');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            'Reset password',
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
                            _codeSent
                                ? 'Enter the code and your new password'
                                : 'We\'ll email you a reset code',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              color: _ink.withValues(alpha: .5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            dense: true,
                          ),
                          if (_codeSent) ...[
                            const SizedBox(height: 8),
                            GlassTextField(
                              controller: _codeController,
                              hint: '6-digit code',
                              icon: Icons.password_rounded,
                              keyboardType: TextInputType.number,
                              dense: true,
                            ),
                            const SizedBox(height: 8),
                            GlassTextField(
                              controller: _passwordController,
                              hint: 'New password',
                              icon: Icons.key_rounded,
                              obscure: true,
                              dense: true,
                            ),
                            const SizedBox(height: 8),
                            GlassTextField(
                              controller: _confirmController,
                              hint: 'Confirm password',
                              icon: Icons.key_rounded,
                              obscure: true,
                              dense: true,
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (_busy)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            )
                          else
                            LiquidButton(
                              label: _codeSent ? 'Reset password' : 'Send code',
                              dense: true,
                              onTap: _codeSent ? _reset : _sendCode,
                            ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              foregroundColor: _ink.withValues(alpha: .55),
                            ),
                            child: const Text(
                              'Back to sign in',
                              style: TextStyle(fontSize: 12.5),
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
