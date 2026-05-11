import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/ecommerce/api_calling_service/payment_service.dart';
import 'package:innovator/ecommerce/model/check_out_summary_model.dart';
import 'package:innovator/ecommerce/model/khalti_payment_model.dart';
import 'package:innovator/ecommerce/model/payment_model.dart';

final paymentServiceProvider = Provider<PaymentService>(
  (_) => PaymentService(),
);
 

final paymentProvider = FutureProvider<List<PaymentModel>>((ref) {
  return ref.watch(paymentServiceProvider).getPaymentQRs();
});
 

typedef CheckoutArgs =
    ({
      String fullName,
      String address,
      String phoneNumber,
      String? notes,
      String paymentType,
    });

final checkoutSummaryProvider =
    FutureProvider.family<CheckoutSummaryResponse, CheckoutArgs>(
      (ref, args) => ref
          .read(paymentServiceProvider)
          .checkout(
            fullName: args.fullName,
            address: args.address,
            phoneNumber: args.phoneNumber,
            notes: args.notes,
            paymentType: args.paymentType,
          ),
    );
 

typedef ConfirmPaymentArgs = ({String orderId, File screenshot});

final confirmPaymentProvider = FutureProvider.family<void, ConfirmPaymentArgs>(
  (ref, args) => ref
      .read(paymentServiceProvider)
      .confirmPayment(orderId: args.orderId, screenshot: args.screenshot),
);
final khaltiPaymentProvider =
    FutureProvider.family<KhaltiPaymentResponse, String>(
  (ref, orderId) =>
      ref.read(paymentServiceProvider).initiateKhaltiPayment(orderId: orderId),
);