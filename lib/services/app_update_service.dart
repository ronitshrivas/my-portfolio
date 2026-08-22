import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

/// Checks the Play Store for a newer version and guides the user through an
/// in-app update. Uses a flexible (background-download) flow so it never blocks
/// the app, then prompts to restart once the update is ready to install.
///
/// Android only — the Play In-App Update API is a no-op elsewhere.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _checkedThisSession = false;
  StreamSubscription<InstallStatus>? _installSub;

  /// Call once after the app UI is up (e.g. from the home/dashboard shell).
  /// [context] is used to show the "ready to install" prompt.
  Future<void> checkForUpdate(BuildContext context) async {
    if (!Platform.isAndroid || _checkedThisSession) return;
    _checkedThisSession = true;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      // Prefer a flexible update: it downloads in the background so the user
      // keeps using the app, then we prompt to install. Fall back to an
      // immediate (blocking) update if flexible isn't allowed.
      if (info.flexibleUpdateAllowed) {
        _listenForInstall(context);
        await InAppUpdate.startFlexibleUpdate();
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (_) {
      // Not installed from Play, offline, or the API is unavailable — ignore.
    }
  }

  void _listenForInstall(BuildContext context) {
    _installSub?.cancel();
    _installSub = InAppUpdate.installUpdateListener.listen((status) {
      if (status == InstallStatus.downloaded) {
        _promptInstall(context);
      }
    });
  }

  void _promptInstall(BuildContext context) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        behavior: SnackBarBehavior.floating,
        content: const Text('An update is ready to install.'),
        action: SnackBarAction(
          label: 'Restart',
          onPressed: () => InAppUpdate.completeFlexibleUpdate(),
        ),
      ),
    );
  }

  void dispose() {
    _installSub?.cancel();
    _installSub = null;
  }
}
