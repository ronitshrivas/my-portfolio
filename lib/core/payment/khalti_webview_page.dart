import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:innovator/theme/brand_colors.dart';

/// Result of a Khalti hosted-checkout session.
enum KhaltiResult { success, cancelled, failed }

/// Opens a Khalti hosted payment URL in an in-app WebView and resolves once the
/// browser returns to the backend callback (or Khalti reports completion).
///
/// Detection is intentionally port-agnostic: the ecommerce callback is on 8004
/// and the e-learning one on 8003, but both paths contain `/khalti/callback`.
/// Khalti's own redirect also carries `pidx=` and `status=Completed`.
class KhaltiWebViewPage extends StatefulWidget {
  const KhaltiWebViewPage({
    super.key,
    required this.paymentUrl,
    this.returnUrlContains = '/khalti/callback',
    this.title = 'Khalti Payment',
  });

  final String paymentUrl;
  final String returnUrlContains;
  final String title;

  /// Convenience launcher — returns the [KhaltiResult] (never null; a
  /// dismissed route resolves to [KhaltiResult.cancelled]).
  static Future<KhaltiResult> open(
    BuildContext context, {
    required String paymentUrl,
    String returnUrlContains = '/khalti/callback',
    String title = 'Khalti Payment',
  }) async {
    final result = await Navigator.of(context).push<KhaltiResult>(
      MaterialPageRoute(
        builder: (_) => KhaltiWebViewPage(
          paymentUrl: paymentUrl,
          returnUrlContains: returnUrlContains,
          title: title,
        ),
      ),
    );
    return result ?? KhaltiResult.cancelled;
  }

  @override
  State<KhaltiWebViewPage> createState() => _KhaltiWebViewPageState();
}

class _KhaltiWebViewPageState extends State<KhaltiWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => _inspect(url),
          onNavigationRequest: (request) {
            if (_inspect(request.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// Returns true when [url] is the backend callback we resolve on.
  ///
  /// IMPORTANT: only the callback URL ends the flow. Khalti's own payment page
  /// also carries `pidx=` in its URL, so matching on `pidx` alone would close
  /// the WebView the instant it opened. We wait for the redirect back to the
  /// backend's `/khalti/callback`, then read `status` from its query.
  bool _inspect(String url) {
    if (_resolved) return true;
    final lower = url.toLowerCase();

    final onCallback = lower.contains(widget.returnUrlContains.toLowerCase());
    if (!onCallback) return false;

    _resolved = true;
    // Khalti appends status to the return URL: Completed / Pending / Refunded
    // / User canceled / Expired / Failed.
    final cancelled = lower.contains('status=user%20canceled') ||
        lower.contains('status=user+canceled') ||
        lower.contains('status=canceled') ||
        lower.contains('status=cancelled');
    final failed = lower.contains('status=failed') ||
        lower.contains('status=expired');

    final result = cancelled
        ? KhaltiResult.cancelled
        : (failed ? KhaltiResult.failed : KhaltiResult.success);

    // TODO: when the backend adds POST /api/payments/verify {pidx}, extract
    // pidx from this callback URL and verify before returning success.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back-press before completion = cancelled.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted) {
          Navigator.of(context).pop(KhaltiResult.cancelled);
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.canvas,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: BrandColors.ink,
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () =>
                Navigator.of(context).pop(KhaltiResult.cancelled),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          ],
        ),
      ),
    );
  }
}
