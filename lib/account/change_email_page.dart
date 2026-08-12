import 'package:flutter/material.dart';

import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import '../services/auth_session.dart';
import '../theme/brand_colors.dart';
import '../widgets/animated_blob_background.dart';
import '../widgets/fast_glass.dart';
import 'account_widgets.dart';

const _ink = BrandColors.ink;

/// Two-step email change: enter new email + password to receive an OTP, then
/// enter the code to confirm and swap the email.
class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  State<ChangeEmailPage> createState() => ChangeEmailPageState();
}

class ChangeEmailPageState extends State<ChangeEmailPage> {
  final _authApi = AuthApi();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _busy = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (!email.contains('@') || password.isEmpty) {
      accountToast(context, 'Enter a valid email and your password');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.changeEmail(newEmail: email, password: password);
      if (!mounted) return;
      setState(() => _codeSent = true);
      accountToast(context, 'Code sent to $email');
    } on ApiException catch (e) {
      if (mounted) accountToast(context, e.message);
    } catch (_) {
      if (mounted) accountToast(context, 'Could not send code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    final code = _codeCtrl.text.trim();
    if (code.length < 4) {
      accountToast(context, 'Enter the code from your email');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.verifyChangeEmail(code: code);
      if (!mounted) return;
      AuthSession.instance.email = _emailCtrl.text.trim();
      accountToast(context, 'Email updated');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) accountToast(context, e.message);
    } catch (_) {
      if (mounted) accountToast(context, 'Could not verify code');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(animate: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AccountHeader(
                  title: 'Change email',
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
                    children: [
                      FastGlass(
                        borderRadius: BorderRadius.circular(20),
                        opacity: .42,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            AccountField(
                              controller: _emailCtrl,
                              label: 'New email',
                              keyboardType: TextInputType.emailAddress,
                              hint: 'you@example.com',
                            ),
                            const SizedBox(height: 12),
                            AccountField(
                              controller: _passwordCtrl,
                              label: 'Current password',
                              obscure: true,
                            ),
                            if (_codeSent) ...[
                              const SizedBox(height: 12),
                              AccountField(
                                controller: _codeCtrl,
                                label: 'Verification code',
                                keyboardType: TextInputType.number,
                                hint: '6-digit code',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!_codeSent)
                        AccountPrimaryButton(
                          label: 'Send verification code',
                          busy: _busy,
                          onTap: _sendCode,
                        )
                      else ...[
                        AccountPrimaryButton(
                          label: 'Confirm new email',
                          busy: _busy,
                          onTap: _verify,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: FastTap(
                            onTap: _busy ? () {} : _sendCode,
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'Resend code',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _ink.withValues(alpha: .6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
