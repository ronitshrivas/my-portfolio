class KhaltiPaymentResponse {
  final String pidx;
  final String paymentUrl;
  final String orderId;
  final double amount;

  const KhaltiPaymentResponse({
    required this.pidx,
    required this.paymentUrl,
    required this.orderId,
    required this.amount,
  });

  factory KhaltiPaymentResponse.fromJson(Map<String, dynamic> json) {
    return KhaltiPaymentResponse(
      pidx: json['pidx'] as String,
      paymentUrl: json['payment_url'] as String,
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}