class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String price;
  final int stock;
  final bool isActive;
  final String? category;
  final CategoryDetails? categoryDetails;
  final String? image;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.category,
    this.categoryDetails,
    this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category_details'];
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: (json['price'] ?? 0).toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      category: json['category']?.toString(),
      categoryDetails: rawCategory is Map<String, dynamic>
          ? CategoryDetails.fromJson(rawCategory)
          : null,
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'is_active': isActive,
      'category': category,
      'category_details': categoryDetails,
      'image': image,
    };
  }

  static List<ProductModel> fromJsonList(List<dynamic> jsonList) {
    final products = <ProductModel>[];
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      try {
        products.add(ProductModel.fromJson(item));
      } catch (_) {
        // Skip a malformed entry rather than dropping the whole list.
      }
    }
    return products;
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, stock: $stock)';
  }
}

class CategoryDetails {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String createdAt;

  CategoryDetails({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.createdAt,
  });

  factory CategoryDetails.fromJson(Map<String, dynamic> json) {
    return CategoryDetails(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

