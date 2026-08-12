import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account/change_email_page.dart';
import 'account/change_password_page.dart';
import 'account/delete_account_page.dart';
import 'account/follow_requests_page.dart';
import 'account/blocked_users_page.dart';
import 'privacy_policy_page.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/models/settings_models.dart';
import 'package:innovator/innovator/data/sources/settings_api.dart';
import 'services/auth_session.dart';
import 'theme/brand_colors.dart';
import 'widgets/animated_blob_background.dart';
import 'widgets/fast_glass.dart';

const _ink = BrandColors.ink;

/// Full settings surface in the liquid-glass language: a frosted scaffold with
/// grouped cards for the account, notifications and app preferences. Toggles are
/// in-memory for now and can be wired to the settings backend when it lands.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    this.appVersion = '1.0.0',
    this.onLoggedOut,
  });

  final String appVersion;

  /// Called after the user confirms logout, so the host can run its own
  /// sign-out + navigation flow. Falls back to clearing the session locally.
  final VoidCallback? onLoggedOut;

  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _settingsApi = SettingsApi();

  SettingsModel _settings = const SettingsModel();
  bool _loading = true;
  String? _loadError;

  /// True while a PATCH/reset is in flight — blocks concurrent writes.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await _settingsApi.getSettings();
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Could not load settings';
      });
    }
  }

  /// Optimistically applies [next], PATCHes only [changed], and reverts on
  /// failure. Ignored while another write is in flight.
  Future<void> _patch(SettingsModel next, Map<String, dynamic> changed) async {
    if (_saving) return;
    final previous = _settings;
    setState(() {
      _settings = next;
      _saving = true;
    });
    try {
      final updated = await _settingsApi.updateSettings(changed);
      if (!mounted) return;
      setState(() => _settings = updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _settings = previous);
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _settings = previous);
      _toast('Could not save. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToDefaults() async {
    if (_saving) return;
    HapticFeedback.selectionClick();
    final yes = await _confirmSheet(
      title: 'Reset settings?',
      message: 'All preferences return to their default values.',
      confirmLabel: 'Reset',
    );
    if (yes != true) return;
    setState(() => _saving = true);
    try {
      final defaults = await _settingsApi.resetSettings();
      if (!mounted) return;
      setState(() => _settings = defaults);
      _toast('Settings reset to defaults');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } catch (_) {
      if (mounted) _toast('Could not reset settings');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pushPage(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: page,
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        backgroundColor: _ink.withValues(alpha: .92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
        ),
      ),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: const PrivacyPolicyPage(),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    HapticFeedback.selectionClick();
    final yes = await _confirmSheet(
      title: 'Log out?',
      message: 'You can sign back in anytime with your account.',
      confirmLabel: 'Log out',
      destructive: true,
    );
    if (yes != true) return;
    if (widget.onLoggedOut != null) {
      widget.onLoggedOut!();
      return;
    }
    await AuthSession.instance.clear();
    if (mounted) Navigator.of(context).pop();
  }

  void _openDeleteAccount() {
    _pushPage(DeleteAccountPage(onDeleted: widget.onLoggedOut));
  }

  Future<bool?> _confirmSheet({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) {
    final accent = destructive ? const Color(0xFFC0392B) : _ink;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FastGlass(
            borderRadius: BorderRadius.circular(24),
            opacity: .7,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: _ink.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FastTap(
                        onTap: () => Navigator.pop(ctx, false),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withValues(alpha: .5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .9),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: _ink.withValues(alpha: .8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FastTap(
                        onTap: () => Navigator.pop(ctx, true),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: accent.withValues(alpha: .95),
                          ),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthSession.instance;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final s = _settings;

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
                _Header(onBack: () => Navigator.of(context).pop()),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (_loadError != null)
                  Expanded(child: _ErrorState(message: _loadError!, onRetry: _loadSettings))
                else
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
                      children: [
                        _AccountCard(
                          name: session.username ?? 'Innovator',
                          email: session.email ?? '',
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('Account'),
                        _GroupCard(
                          children: [
                            _ActionRow(
                              icon: Icons.lock_outline_rounded,
                              label: 'Change password',
                              onTap: () => _pushPage(const ChangePasswordPage()),
                            ),
                            _divider(),
                            _ActionRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Change email',
                              onTap: () => _pushPage(const ChangeEmailPage()),
                            ),
                            _divider(),
                            _ActionRow(
                              icon: Icons.person_add_disabled_outlined,
                              label: 'Follow requests',
                              onTap: () => _pushPage(const FollowRequestsPage()),
                            ),
                            _divider(),
                            _ActionRow(
                              icon: Icons.block_outlined,
                              label: 'Blocked users',
                              onTap: () => _pushPage(const BlockedUsersPage()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('Notifications'),
                        _GroupCard(
                          children: [
                            _SwitchRow(
                              icon: Icons.notifications_none_rounded,
                              label: 'Push notifications',
                              subtitle: 'Master switch for all alerts',
                              value: s.pushEnabled,
                              onChanged: _saving
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(pushEnabled: v),
                                        {'push_enabled': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.favorite_border_rounded,
                              label: 'Likes & reactions',
                              value: s.notifyLikes && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyLikes: v),
                                        {'notify_likes': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.mode_comment_outlined,
                              label: 'Comments',
                              value: s.notifyComments && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyComments: v),
                                        {'notify_comments': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.person_add_alt_1_outlined,
                              label: 'New followers',
                              value: s.notifyFollows && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyFollows: v),
                                        {'notify_follows': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Mentions',
                              value: s.notifyMentions && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyMentions: v),
                                        {'notify_mentions': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: 'Messages',
                              value: s.notifyMessages && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyMessages: v),
                                        {'notify_messages': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.repeat_rounded,
                              label: 'Reposts',
                              value: s.notifyReposts && s.pushEnabled,
                              onChanged: (!s.pushEnabled || _saving)
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(notifyReposts: v),
                                        {'notify_reposts': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.mark_email_read_outlined,
                              label: 'Email digest',
                              subtitle: 'A weekly summary by email',
                              value: s.emailDigest,
                              onChanged: _saving
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(emailDigest: v),
                                        {'email_digest': v},
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('Privacy'),
                        _GroupCard(
                          children: [
                            _SwitchRow(
                              icon: Icons.lock_person_outlined,
                              label: 'Private account',
                              subtitle: s.privateAccount
                                  ? 'New followers must be approved'
                                  : 'Anyone can follow you',
                              value: s.privateAccount,
                              onChanged: _saving
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(privateAccount: v),
                                        {'private_account': v},
                                      ),
                            ),
                            _divider(),
                            _SelectorRow(
                              icon: Icons.forum_outlined,
                              label: 'Who can message me',
                              value: s.whoCanMessage,
                              options: const ['everyone', 'followers', 'none'],
                              enabled: !_saving,
                              onSelected: (v) => _patch(
                                s.copyWith(whoCanMessage: v),
                                {'who_can_message': v},
                              ),
                            ),
                            _divider(),
                            _SelectorRow(
                              icon: Icons.mode_comment_outlined,
                              label: 'Who can comment',
                              value: s.whoCanComment,
                              options: const ['everyone', 'followers', 'none'],
                              enabled: !_saving,
                              onSelected: (v) => _patch(
                                s.copyWith(whoCanComment: v),
                                {'who_can_comment': v},
                              ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.circle_outlined,
                              label: 'Show activity status',
                              value: s.showActivityStatus,
                              onChanged: _saving
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(showActivityStatus: v),
                                        {'show_activity_status': v},
                                      ),
                            ),
                            _divider(),
                            _SwitchRow(
                              icon: Icons.search_rounded,
                              label: 'Show me in search',
                              value: s.showInSearch,
                              onChanged: _saving
                                  ? null
                                  : (v) => _patch(
                                        s.copyWith(showInSearch: v),
                                        {'show_in_search': v},
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('App'),
                        _GroupCard(
                          children: [
                            _SelectorRow(
                              icon: Icons.brightness_6_outlined,
                              label: 'Theme',
                              value: s.theme,
                              options: const ['system', 'light', 'dark'],
                              enabled: !_saving,
                              onSelected: (v) => _patch(
                                s.copyWith(theme: v),
                                {'theme': v},
                              ),
                            ),
                            _divider(),
                            _SelectorRow(
                              icon: Icons.language_rounded,
                              label: 'Language',
                              value: s.language,
                              options: const ['en', 'ne', 'hi'],
                              enabled: !_saving,
                              onSelected: (v) => _patch(
                                s.copyWith(language: v),
                                {'language': v},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('About'),
                        _GroupCard(
                          children: [
                            _ActionRow(
                              icon: Icons.shield_outlined,
                              label: 'Privacy & Policy',
                              onTap: _openPrivacy,
                            ),
                            _divider(),
                            _ActionRow(
                              icon: Icons.info_outline_rounded,
                              label: 'App version',
                              trailing: Text(
                                widget.appVersion,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _ink.withValues(alpha: .5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _GroupCard(
                          children: [
                            _ActionRow(
                              icon: Icons.restart_alt_rounded,
                              label: 'Reset to defaults',
                              onTap: _saving ? null : _resetToDefaults,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _GroupCard(
                          children: [
                            _ActionRow(
                              icon: Icons.logout_rounded,
                              label: 'Log out',
                              destructive: true,
                              onTap: _confirmLogout,
                            ),
                            _divider(),
                            _ActionRow(
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete account',
                              destructive: true,
                              onTap: _openDeleteAccount,
                            ),
                          ],
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

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 56),
        child: Container(height: 1, color: _ink.withValues(alpha: .06)),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 8),
      child: Row(
        children: [
          FastTap(
            onTap: () {
              HapticFeedback.selectionClick();
              onBack();
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(color: Colors.white.withValues(alpha: .95)),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: _ink.withValues(alpha: .85),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: -.3,
              ),
            ),
          ),
          Icon(
            Icons.settings_outlined,
            size: 22,
            color: _ink.withValues(alpha: .45),
          ),
        ],
      ),
    );
  }
}

/// Signed-in identity card at the top of the settings list.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(22),
      opacity: .42,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [BrandColors.secondarySurface, Color(0xFF8A93A8)],
              ),
            ),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _ink.withValues(alpha: .55),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
          color: _ink.withValues(alpha: .45),
        ),
      ),
    );
  }
}

/// A frosted card that groups rows with hairline dividers between them.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(20),
      opacity: .42,
      child: Column(children: children),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFC0392B) : _ink;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .55),
              border: Border.all(color: Colors.white.withValues(alpha: .9)),
            ),
            child: Icon(icon, size: 18, color: color.withValues(alpha: .75)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: destructive ? .9 : .85),
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (trailing == null && onTap != null && !destructive)
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _ink.withValues(alpha: .3),
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return FastTap(
      onTap: onTap!,
      borderRadius: BorderRadius.circular(16),
      child: row,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(color: Colors.white.withValues(alpha: .9)),
              ),
              child: Icon(icon, size: 18, color: _ink.withValues(alpha: .75)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _ink.withValues(alpha: .45),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: BrandColors.accent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _ink.withValues(alpha: .18),
              onChanged: enabled
                  ? (v) {
                      HapticFeedback.selectionClick();
                      onChanged!(v);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A row that shows a label and a small segmented control of string options.
class _SelectorRow extends StatelessWidget {
  const _SelectorRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool enabled;

  String _labelFor(String option) {
    switch (option) {
      case 'everyone':
        return 'Everyone';
      case 'followers':
        return 'Followers';
      case 'none':
        return 'No one';
      case 'system':
        return 'System';
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'en':
        return 'EN';
      case 'ne':
        return 'NE';
      case 'hi':
        return 'HI';
      default:
        return option;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .55),
                border: Border.all(color: Colors.white.withValues(alpha: .9)),
              ),
              child: Icon(icon, size: 18, color: _ink.withValues(alpha: .75)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: .45),
                border: Border.all(color: Colors.white.withValues(alpha: .85)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    FastTap(
                      onTap: enabled && option != value
                          ? () {
                              HapticFeedback.selectionClick();
                              onSelected(option);
                            }
                          : () {},
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: option == value
                              ? BrandColors.secondarySurface
                              : Colors.transparent,
                        ),
                        child: Text(
                          _labelFor(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: option == value
                                ? Colors.white
                                : _ink.withValues(alpha: .6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple retryable error state for the settings load.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: _ink.withValues(alpha: .35),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _ink.withValues(alpha: .6)),
            ),
            const SizedBox(height: 16),
            FastTap(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: BrandColors.secondarySurface,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
