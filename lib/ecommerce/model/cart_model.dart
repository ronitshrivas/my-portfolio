class CartItemModel {
  final String id;
  final String cart;
  final String product;
  final String productName;
  final double price;
  final int quantity;
  final double total;

  CartItemModel({
    required this.id,
    required this.cart,
    required this.product,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.total,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] ?? '',
      cart: json['cart'] ?? '',
      product: json['product'] ?? '',
      productName: json['product_name'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] as num).toDouble(),
    );
  }

  static List<CartItemModel> fromJsonList(List<dynamic> list) {
    return list.map((e) => CartItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}