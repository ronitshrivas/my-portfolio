import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/models/banner_models.dart';
import 'package:innovator/core/payment/khalti_models.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/ecommerce/data/models/ecommerce_dtos.dart';

/// Ecommerce service — http://36.253.137.34:8004/swagger
///
/// Customer-facing surface: products, categories, cart, checkout, payments,
/// notifications. Admin endpoints are intentionally omitted from the app.
class EcommerceApi {
  EcommerceApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;
  static const _base = ApiConfig.ecommerceBaseUrl;

  // ----------------------------------------------------------- products

  Future<List<EcommerceProduct>> products({
    String? category,
    String? search,
  }) async {
    final envelope = await _client.get<List<EcommerceProduct>>(
      _base,
      '/api/products',
      auth: false,
      query: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      },
      parse: _parseProducts,
    );
    return envelope.data ?? const [];
  }

  Future<EcommerceProduct?> product(String productId) async {
    final envelope = await _client.get<EcommerceProduct?>(
      _base,
      '/api/products/$productId',
      auth: false,
      parse: (raw) => raw is Map
          ? EcommerceProduct.fromJson(Map<String, dynamic>.from(raw))
          : null,
    );
    return envelope.data;
  }

  /// Admin-managed promo banners shown atop the Shop section.
  Future<List<AppBanner>> banners() async {
    final envelope = await _client.get<List<AppBanner>>(
      _base,
      '/api/banners',
      auth: false,
      parse: (raw) => parseBanners(raw, baseUrl: _base),
    );
    return envelope.data ?? const [];
  }

  Future<List<EcommerceCategory>> categories() async {
    final envelope = await _client.get<List<EcommerceCategory>>(
      _base,
      '/api/categories',
      auth: false,
      parse: (raw) => _list(raw)
          .map((e) => EcommerceCategory.fromJson(e))
          .toList(),
    );
    return envelope.data ?? const [];
  }

  // ---------------------------------------------------------------- cart

  Future<List<CartItemDto>> cart() async {
    final envelope = await _client.get<List<CartItemDto>>(
      _base,
      '/api/cart-items',
      parse: (raw) =>
          _list(raw).map((e) => CartItemDto.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  Future<void> addToCart(String productId) async {
    await _client.post<Object?>(
      _base,
      '/api/cart-items',
      body: {'product': productId},
      parse: (_) => null,
    );
  }

  Future<void> updateCartItem(String cartItemId, int quantity) async {
    await _client.patch<Object?>(
      _base,
      '/api/cart-items/$cartItemId',
      body: {'quantity': quantity},
      parse: (_) => null,
    );
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _client.delete<Object?>(
      _base,
      '/api/cart-items/$cartItemId',
      parse: (_) => null,
    );
  }

  /// Pushes the local cart to the server so `checkout/summary` (which reads the
  /// server-side cart) has the items. Clears the server cart first, then adds
  /// each product and sets its exact quantity.
  ///
  /// [items] maps productId -> quantity.
  Future<void> syncCart(Map<String, int> items) async {
    // Clear whatever is already on the server.
    final existing = await cart();
    for (final it in existing) {
      if (it.id.isNotEmpty) {
        try {
          await removeCartItem(it.id);
        } catch (_) {}
      }
    }
    if (items.isEmpty) return;

    // Add each product, then read back the server cart to set quantities.
    for (final productId in items.keys) {
      if (productId.trim().isEmpty) continue;
      await addToCart(productId);
    }
    final serverItems = await cart();
    for (final it in serverItems) {
      final qty = items[it.productId] ?? 1;
      if (qty > 1 && it.id.isNotEmpty) {
        await updateCartItem(it.id, qty);
      }
    }
  }

  // ---------------------------------------------------------- checkout

  Future<OrderSummary> checkout({
    required String fullName,
    required String address,
    required String phoneNumber,
    String? notes,
    String paymentType = 'cod',
  }) async {
    final envelope = await _client.post<OrderSummary>(
      _base,
      '/api/checkout/summary',
      body: {
        'full_name': fullName,
        'address': address,
        'phone_number': phoneNumber,
        'notes': notes,
        'payment_type': paymentType,
      },
      parse: (raw) => OrderSummary.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Checkout failed');
    return data;
  }

  Future<void> confirmPayment(
    String orderId,
    Uint8List screenshot, {
    String filename = 'payment.jpg',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'paymentScreenshot',
      MultipartFile.fromBytes(screenshot, filename: filename),
    ));
    await _client.upload<Object?>(
      _base,
      '/api/orders/$orderId/confirm-payment',
      formData: formData,
      parse: (_) => null,
    );
  }

  /// Starts a Khalti payment for [orderId]; returns pidx + hosted payment URL.
  Future<KhaltiInit> initiateKhalti(String orderId) async {
    final envelope = await _client.post<KhaltiInit>(
      _base,
      '/api/payments/initiate',
      body: {'order_id': orderId},
      parse: (raw) {
        // ignore: avoid_print
        print('[Khalti] initiate raw response: $raw');
        return KhaltiInit.fromJson(
          Map<String, dynamic>.from(raw as Map? ?? const {}),
        );
      },
    );
    final data = envelope.data;
    // ignore: avoid_print
    print('[Khalti] success=${envelope.success} msg=${envelope.message} '
        'url=${data?.paymentUrl} pidx=${data?.pidx}');
    if (data == null || !envelope.success) {
      throw ApiException(envelope.message ?? 'Could not start payment');
    }
    return data;
  }

  Future<List<PaymentQr>> paymentQrs() async {
    final envelope = await _client.get<List<PaymentQr>>(
      _base,
      '/api/payment-qrs/public-list',
      parse: (raw) => _list(raw).map((e) => PaymentQr.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  // ------------------------------------------------------- notifications

  Future<void> registerFcmToken(String token, {String platform = 'android'}) async {
    await _client.post<Object?>(
      _base,
      '/api/fcm-tokens',
      body: {'token': token, 'platform': platform},
      parse: (_) => null,
    );
  }

  // -------------------------------------------------------------- helpers

  List<EcommerceProduct> _parseProducts(Object? raw) =>
      _list(raw).map((e) => EcommerceProduct.fromJson(e)).toList();

  /// Accepts a bare list or a `{ results: [...] }` / `{ data: [...] }` wrapper.
  List<Map<String, dynamic>> _list(Object? raw) {
    Object? node = raw;
    if (node is Map) {
      node = node['results'] ?? node['data'] ?? node['items'] ?? node;
    }
    if (node is! List) return const [];
    return node
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
