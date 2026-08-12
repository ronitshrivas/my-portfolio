import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import '../services/auth_session.dart';
import '../theme/brand_colors.dart';
import '../widgets/animated_blob_background.dart';
import '../widgets/fast_glass.dart';
import 'account_widgets.dart';

const _ink = BrandColors.ink;

/// Permanently deletes the account after password + explicit confirmation.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.onDeleted});

  /// Runs after a successful delete so the host can sign out + route to login.
  final VoidCallback? onDeleted;

  @override
  State<DeleteAccountPage> createState() => DeleteAccountPageState();
}

class DeleteAccountPageState extends State<DeleteAccountPage> {
  final _authApi = AuthApi();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    if (_busy) return;
    if (_passwordCtrl.text.isEmpty) {
      accountToast(context, 'Enter your password to continue');
      return;
    }
    HapticFeedback.selectionClick();
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently removes your profile, posts and data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _busy = true);
    try {
      await _authApi.deleteAccount(password: _passwordCtrl.text);
      if (!mounted) return;
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      } else {
        await AuthSession.instance.clear();
        if (mounted) Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        accountToast(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        accountToast(context, 'Could not delete account');
      }
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
                  title: 'Delete account',
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deleting your account is permanent. Your profile, '
                              'posts, comments and messages will be removed.',
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: _ink.withValues(alpha: .7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AccountField(
                              controller: _passwordCtrl,
                              label: 'Confirm with your password',
                              obscure: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      AccountPrimaryButton(
                        label: 'Delete my account',
                        busy: _busy,
                        destructive: true,
                        onTap: _confirmAndDelete,
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
