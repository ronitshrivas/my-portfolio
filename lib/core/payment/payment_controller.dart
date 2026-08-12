import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'khalti_models.dart';
import 'khalti_webview_page.dart';

/// High-level outcome of a full pay-and-verify flow.
enum PaymentOutcome { paid, enrolled, cancelled, failed }

class PaymentState {
  const PaymentState({this.loading = false, this.error, this.outcome});

  final bool loading;
  final String? error;
  final PaymentOutcome? outcome;

  PaymentState copyWith({bool? loading, String? error, PaymentOutcome? outcome}) =>
      PaymentState(
        loading: loading ?? this.loading,
        error: error,
        outcome: outcome,
      );
}

/// Orchestrates: initiate → (open Khalti WebView) → outcome. UI stays identical;
/// callers await [run] from an existing button handler.
class PaymentController extends StateNotifier<PaymentState> {
  PaymentController() : super(const PaymentState());

  /// Runs the payment flow. [initiate] performs the server call and returns the
  /// hosted-payment info; [context] is used to open the WebView.
  ///
  /// Returns [PaymentOutcome.enrolled] for free e-learning courses (no WebView),
  /// [PaymentOutcome.paid] on a successful Khalti return, or cancelled/failed.
  Future<PaymentOutcome> run(
    BuildContext context, {
    required Future<KhaltiInit> Function() initiate,
  }) async {
    state = const PaymentState(loading: true);
    try {
      final init = await initiate();

      // Free course: backend already enrolled, no payment page.
      if (init.alreadyEnrolled || !init.needsWebView) {
        state = const PaymentState(outcome: PaymentOutcome.enrolled);
        return PaymentOutcome.enrolled;
      }

      if (!context.mounted) {
        state = const PaymentState(outcome: PaymentOutcome.cancelled);
        return PaymentOutcome.cancelled;
      }

      final result = await KhaltiWebViewPage.open(
        context,
        paymentUrl: init.paymentUrl,
      );

      // TODO: when the backend adds POST /api/payments/verify {pidx}, call it
      // with init.pidx here and downgrade to failed if it doesn't confirm.

      final outcome = switch (result) {
        KhaltiResult.success => PaymentOutcome.paid,
        KhaltiResult.cancelled => PaymentOutcome.cancelled,
        KhaltiResult.failed => PaymentOutcome.failed,
      };
      state = PaymentState(outcome: outcome);
      return outcome;
    } catch (e) {
      final message = _message(e);
      state = PaymentState(error: message, outcome: PaymentOutcome.failed);
      return PaymentOutcome.failed;
    }
  }

  void reset() => state = const PaymentState();

  String _message(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>(
  (_) => PaymentController(),
);
