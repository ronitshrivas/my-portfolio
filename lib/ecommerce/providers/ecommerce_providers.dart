import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/core/cache/hive_cache.dart';
import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/ecommerce/data/models/ecommerce_dtos.dart';
import 'package:innovator/ecommerce/data/models/shop_models.dart';
import 'package:innovator/ecommerce/data/sources/ecommerce_api.dart';

final ecommerceApiProvider = Provider<EcommerceApi>((_) => EcommerceApi());

final ecommerceCacheProvider =
    FutureProvider<HiveCache>((_) => HiveCache.open('ecommerce'));

/// Live product catalog, mapped into the UI's [ShopProduct] so the shop grid
/// renders unchanged. Instant from Hive, then refreshed.
final productsProvider =
    FutureProvider.family<List<ShopProduct>, ProductQuery>((ref, q) async {
  final api = ref.watch(ecommerceApiProvider);
  final cache = ref.watch(ecommerceCacheProvider).valueOrNull;
  final cacheKey = 'products.${q.category ?? ''}.${q.search ?? ''}';

  final dtos = await api.products(category: q.category, search: q.search);
  cache?.put(cacheKey, dtos.map((e) => e.toJson()).toList());
  return dtos.map(mapToShopProduct).toList();
});

final productDetailProvider =
    FutureProvider.family<EcommerceProduct?, String>((ref, id) {
  return ref.watch(ecommerceApiProvider).product(id);
});

final ecommerceCategoriesProvider =
    FutureProvider<List<EcommerceCategory>>((ref) {
  return ref.watch(ecommerceApiProvider).categories();
});

/// Server-backed cart.
final cartItemsProvider = FutureProvider<List<CartItemDto>>((ref) {
  return ref.watch(ecommerceApiProvider).cart();
});

final paymentQrsProvider = FutureProvider<List<PaymentQr>>((ref) {
  return ref.watch(ecommerceApiProvider).paymentQrs();
});

/// Query key for the products family provider.
class ProductQuery {
  const ProductQuery({this.category, this.search});
  final String? category;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.category == category &&
      other.search == search;

  @override
  int get hashCode => Object.hash(category, search);
}

/// Product images are served by the ecommerce service (8004). Prefix relative
/// paths so they load; absolute URLs pass through.
String _resolveProductImage(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${ApiConfig.ecommerceBaseUrl}${path.startsWith('/') ? '' : '/'}$path';
}

/// Maps a backend product into the UI's [ShopProduct]. Icon/tint are assigned
/// deterministically from the id so the grid keeps its look with live data.
ShopProduct mapToShopProduct(EcommerceProduct p) {
  const icons = [
    Icons.shopping_bag_rounded,
    Icons.slideshow_rounded,
    Icons.brush_rounded,
    Icons.devices_rounded,
    Icons.menu_book_rounded,
    Icons.headphones_rounded,
  ];
  const tints = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF0891B2),
  ];
  final bucket = p.id.hashCode.abs() % icons.length;

  final resolved =
      p.images.map(_resolveProductImage).where((e) => e.isNotEmpty).toList();
  return ShopProduct(
    id: p.id,
    name: p.name,
    category: p.categoryName ?? 'General',
    price: p.price,
    rating: 5,
    icon: icons[bucket],
    tint: tints[bucket],
    images: resolved.isNotEmpty ? resolved : const ['Assets/shop/product_01.jpg'],
    description: p.description,
    specifications: [
      if (p.stock > 0) const ProductSpec('Availability', 'In stock')
      else const ProductSpec('Availability', 'Out of stock'),
      if (p.categoryName != null) ProductSpec('Category', p.categoryName!),
    ],
  );
}
