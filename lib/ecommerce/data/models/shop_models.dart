import 'package:flutter/material.dart';

/// A product sold in the shop. Prices are in Nepali rupees.
class ShopProduct {
  const ShopProduct({
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.icon,
    required this.tint,
    required this.images,
    required this.description,
    required this.specifications,
    this.id = '',
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final IconData icon;
  final Color tint;

  /// Gallery of relative asset paths (cover is [images.first]).
  final List<String> images;
  final String description;
  final List<ProductSpec> specifications;

  /// Cover image used in grids, cart, and search.
  String get imageAsset => images.first;
}

class ProductSpec {
  const ProductSpec(this.label, this.value);

  final String label;
  final String value;
}

class CartItem {
  CartItem(this.product, {this.quantity = 1});

  final ShopProduct product;
  int quantity;

  double get total => product.price * quantity;
}

/// App-wide cart. 13% VAT and a flat Rs 200 delivery charge that covers
/// all of Nepal are applied on top of the subtotal.
class Cart extends ChangeNotifier {
  Cart._();

  static final Cart instance = Cart._();

  static const vatRate = .13;
  static const deliveryCharge = 200.0;

  final List<CartItem> items = [];

  bool get isEmpty => items.isEmpty;
  int get count => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get vat => subtotal * vatRate;
  double get delivery => items.isEmpty ? 0 : deliveryCharge;
  double get grandTotal => subtotal + vat + delivery;

  void add(ShopProduct product) {
    for (final item in items) {
      if (item.product.name == product.name) {
        item.quantity++;
        notifyListeners();
        return;
      }
    }
    items.add(CartItem(product));
    notifyListeners();
  }

  void increment(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  /// Dropping below one removes the line from the cart.
  void decrement(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      items.remove(item);
    }
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }
}

/// 12400 -> "12,400"
String groupNum(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write(',');
  }
  return buffer.toString();
}

/// 12400 -> "Rs 12,400"
String formatRs(num value) => 'Rs ${groupNum(value)}';
