/// Result of a payment-initiate call (ecommerce order or e-learning course).
///
/// Backends: ecommerce `KhaltiPaymentResponse {pidx, payment_url, order_id,
/// amount}`; e-learning `InitiatePaymentResponse {pidx, payment_url,
/// course_id, amount, status}`.
class KhaltiInit {
  const KhaltiInit({
    this.pidx = '',
    this.paymentUrl = '',
    this.targetId = '',
    this.amount = '',
    this.status = '',
  });

  final String pidx;
  final String paymentUrl;

  /// order_id (ecommerce) or course_id (e-learning).
  final String targetId;
  final String amount;
  final String status;

  /// True when there is a hosted Khalti page to open.
  bool get needsWebView => paymentUrl.trim().isNotEmpty;

  /// E-learning free courses come back already enrolled with no URL.
  bool get alreadyEnrolled =>
      status.toLowerCase() == 'enrolled' && paymentUrl.trim().isEmpty;

  factory KhaltiInit.fromJson(Map<String, dynamic> json) {
    return KhaltiInit(
      pidx: json['pidx']?.toString() ?? '',
      paymentUrl: (json['payment_url'] ?? json['url'])?.toString() ?? '',
      targetId:
          (json['order_id'] ?? json['course_id'] ?? json['id'])?.toString() ??
              '',
      amount: json['amount']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
