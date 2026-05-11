class ProductDetailModel {
  final String id;
  final String name;
  final String? description;
  final String price;
  final int stock;
  final bool isActive;
  final String? category;
  final CategoryDetailModel? categoryDetails;
  final String? image;
  final List<ProductImageModel> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductDetailModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.isActive = true,
    this.category,
    this.categoryDetails,
    this.image,
    required this.images,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final imagesList = (json['images'] as List<dynamic>? ?? [])
        .map((e) => ProductImageModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProductDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description']?.toString(),
      price: json['price'] as String,
      stock: json['stock'] as int,
      isActive: json['is_active'] as bool? ?? true,
      category: json['category'] as String?,
      categoryDetails: json['category_details'] != null
          ? CategoryDetailModel.fromJson(
              json['category_details'] as Map<String, dynamic>)
          : null,
      image: json['image'] as String?,
      images: imagesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Returns all image URLs — falls back to single `image` if `images` is empty
  List<String> get allImageUrls {
    if (images.isNotEmpty) return images.map((e) => e.image).toList();
    if (image != null) return [image!];
    return [];
  }

  /// Parses price to double for arithmetic operations
  double get parsedPrice => double.tryParse(price) ?? 0.0;

  /// Returns true if the product is in stock
  bool get inStock => stock > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'is_active': isActive,
      'category': category,
      'category_details': categoryDetails?.toJson(),
      'image': image,
      'images': images.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class CategoryDetailModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final DateTime? createdAt;

  CategoryDetailModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.createdAt,
  });

  factory CategoryDetailModel.fromJson(Map<String, dynamic> json) {
    return CategoryDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class ProductImageModel {
  final int id;
  final String image;

  ProductImageModel({required this.id, required this.image});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as int,
      image: json['image'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'image': image};
}