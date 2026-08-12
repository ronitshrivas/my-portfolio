import 'package:flutter/material.dart';

import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import '../theme/brand_colors.dart';
import '../widgets/animated_blob_background.dart';
import '../widgets/fast_glass.dart';
import 'account_widgets.dart';

/// Change the signed-in user's password: old + new + confirm.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => ChangePasswordPageState();
}

class ChangePasswordPageState extends State<ChangePasswordPage> {
  final _authApi = AuthApi();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final oldPw = _oldCtrl.text;
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (oldPw.isEmpty || newPw.isEmpty) {
      accountToast(context, 'Fill in all fields');
      return;
    }
    if (newPw.length < 6) {
      accountToast(context, 'New password must be at least 6 characters');
      return;
    }
    if (newPw != confirm) {
      accountToast(context, 'Passwords do not match');
      return;
    }
    setState(() => _busy = true);
    try {
      await _authApi.changePassword(oldPassword: oldPw, newPassword: newPw);
      if (!mounted) return;
      accountToast(context, 'Password changed');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) accountToast(context, e.message);
    } catch (_) {
      if (mounted) accountToast(context, 'Could not change password');
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
                  title: 'Change password',
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
                              controller: _oldCtrl,
                              label: 'Current password',
                              obscure: true,
                            ),
                            const SizedBox(height: 12),
                            AccountField(
                              controller: _newCtrl,
                              label: 'New password',
                              obscure: true,
                            ),
                            const SizedBox(height: 12),
                            AccountField(
                              controller: _confirmCtrl,
                              label: 'Confirm new password',
                              obscure: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AccountPrimaryButton(
                        label: 'Update password',
                        busy: _busy,
                        onTap: _submit,
                      ),
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
