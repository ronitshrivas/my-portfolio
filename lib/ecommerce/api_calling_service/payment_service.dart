import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:innovator/ecommerce/model/check_out_summary_model.dart';
import 'package:innovator/ecommerce/model/khalti_payment_model.dart';
import 'package:innovator/ecommerce/model/payment_model.dart';
import 'package:path/path.dart' as path;
import 'package:innovator/ecommerce/core/constants/api_constants.dart';
import 'package:innovator/ecommerce/core/constants/network/base_api_service.dart';
import 'package:innovator/ecommerce/core/constants/network/dio_client.dart';

class PaymentService extends EcommerBaseApiService {
  PaymentService() : super(dio: DioClient.instance);

  Future<List<PaymentModel>> getPaymentQRs() async {
    final data = await get<List<dynamic>>(EcommerceApi.payment);
    final payments = PaymentModel.fromJsonList(data);
    log('Payments loaded: ${payments.length}');
    return payments;
  }

  Future<CheckoutSummaryResponse> checkout({
    required String fullName,
    required String address,
    required String phoneNumber,
    String? notes,
    required String paymentType,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'address': address,
      'phone_number': phoneNumber,
      'payment_type': paymentType,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    log('Checkout payload: $body');
    final data = await post<Map<String, dynamic>>(
      EcommerceApi.checkoutSummary,
      data: body,
    );
    final response = CheckoutSummaryResponse.fromJson(data);
    log('Order placed: ${response.orderId}');
    return response;
  }

  Future<void> confirmPayment({
    required String orderId,
    required File screenshot,
  }) async {
    final formData = FormData.fromMap({
      'payment_screenshot': await MultipartFile.fromFile(
        screenshot.path,
        filename: path.basename(screenshot.path),
      ),
    });
    await DioClient.instance.post(EcommerceApi.orders(orderId), data: formData);
    log('Payment confirmed for order: $orderId');
  }

  Future<KhaltiPaymentResponse> initiateKhaltiPayment({
    required String orderId,
  }) async {
    log('Initiating Khalti payment for order: $orderId');
    final data = await post<Map<String, dynamic>>(
      EcommerceApi.khaltiPayment,
      data: {'order_id': orderId},
    );
    final response = KhaltiPaymentResponse.fromJson(data);
    log('Khalti pidx: ${response.pidx}  url: ${response.paymentUrl}');
    return response;
  }
}
