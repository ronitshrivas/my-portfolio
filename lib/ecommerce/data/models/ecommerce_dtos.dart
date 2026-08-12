// Backend DTOs for the Ecommerce service (http://36.253.137.34:8016).
//
// These mirror the API's snake_case payloads. The UI keeps using its own
// `ShopProduct`/`Cart` types; a mapper converts these DTOs into those so the
// presentation layer is untouched.

import 'package:innovator/core/config/api_config.dart';

/// The API returns prices as strings ("600.00"), so parse defensively — a
/// hard `as num` cast on a String throws and drops the whole product list.
double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Product media is stored under an older host/port (8004). Rewrite it onto the
/// live ecommerce host so images resolve instead of failing to load.
String? resolveEcommerceImage(String? url) {
  if (url == null || url.isEmpty) return null;
  const liveHost = ApiConfig.ecommerceBaseUrl; // http://36.253.137.34:8016
  final uri = Uri.tryParse(url);
  if (uri != null && uri.host == '36.253.137.34' && uri.port != 8016) {
    final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$liveHost$tail$query';
  }
  if (!url.startsWith('http')) {
    return '$liveHost${url.startsWith('/') ? '' : '/'}$url';
  }
  return url;
}

class EcommerceProduct {
  const EcommerceProduct({
    required this.id,
    required this.name,
    this.description = '',
    this.price = 0,
    this.stock = 0,
    this.isActive = true,
    this.categoryId,
    this.categoryName,
    this.images = const [],
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool isActive;
  final String? categoryId;
  final String? categoryName;
  final List<String> images;

  String? get coverImage => images.isNotEmpty ? images.first : null;

  factory EcommerceProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] ?? json['product_images'];
    final images = <String>[];
    if (rawImages is List) {
      for (final img in rawImages) {
        final url = img is String
            ? img
            : (img is Map
                ? (img['image'] ?? img['url'] ?? img['file'])?.toString()
                : null);
        final resolved = resolveEcommerceImage(url);
        if (resolved != null) images.add(resolved);
      }
    }
    final single = resolveEcommerceImage(
      (json['image'] ?? json['cover_image'])?.toString(),
    );
    if (images.isEmpty && single != null) {
      images.add(single);
    }

    final category =
        json['category_details'] ?? json['category'] ?? json['category_detail'];
    return EcommerceProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _toDouble(json['price']),
      stock: _toInt(json['stock']),
      isActive: json['is_active'] != false,
      categoryId: (json['category_id'] ??
              (category is Map ? category['id'] : category))
          ?.toString(),
      categoryName: category is Map
          ? category['name']?.toString()
          : json['category_name']?.toString(),
      images: images,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'is_active': isActive,
        'category_id': categoryId,
        'category_name': categoryName,
        'images': images,
      };
}

class EcommerceCategory {
  const EcommerceCategory({required this.id, required this.name, this.slug});

  final String id;
  final String name;
  final String? slug;

  factory EcommerceCategory.fromJson(Map<String, dynamic> json) =>
      EcommerceCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString(),
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class CartItemDto {
  const CartItemDto({
    required this.id,
    required this.productId,
    this.productName = '',
    this.price = 0,
    this.quantity = 1,
    this.image,
  });

  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? image;

  double get lineTotal => price * quantity;

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json['product_detail'];
    final productMap = product is Map ? Map<String, dynamic>.from(product) : null;
    return CartItemDto(
      id: json['id']?.toString() ?? '',
      productId:
          (json['product_id'] ?? productMap?['id'] ?? product)?.toString() ?? '',
      productName:
          (json['product_name'] ?? productMap?['name'])?.toString() ?? '',
      price: _toDouble(json['price'] ?? productMap?['price']),
      quantity: _toInt(json['quantity']).clamp(1, 1 << 30),
      image: resolveEcommerceImage(
        (json['image'] ?? productMap?['image'])?.toString(),
      ),
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.orderId,
    this.total = 0,
    this.status = '',
    this.paymentType = '',
  });

  final String orderId;
  final double total;
  final String status;
  final String paymentType;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        orderId: (json['order_id'] ?? json['id'])?.toString() ?? '',
        total: _toDouble(json['total']),
        status: json['status']?.toString() ?? '',
        paymentType: json['payment_type']?.toString() ?? '',
      );
}

class PaymentQr {
  const PaymentQr({required this.id, this.name = '', this.image});

  final String id;
  final String name;
  final String? image;

  factory PaymentQr.fromJson(Map<String, dynamic> json) => PaymentQr(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        image: json['image']?.toString(),
      );
}
