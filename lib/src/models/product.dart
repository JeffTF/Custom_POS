class Product {
  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.stockQuantity,
    this.categoryId,
    this.imagePath,
    this.sku,
    this.lowStockThreshold = 5,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String name;
  final double price;
  final int stockQuantity;
  final int? categoryId;
  final String? imagePath;
  final String? sku;
  final int lowStockThreshold;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOutOfStock => stockQuantity <= 0;
  bool get isLowStock => stockQuantity <= lowStockThreshold;

  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stockQuantity,
    int? categoryId,
    String? imagePath,
    String? sku,
    int? lowStockThreshold,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      categoryId: categoryId ?? this.categoryId,
      imagePath: imagePath ?? this.imagePath,
      sku: sku ?? this.sku,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'] as int,
      categoryId: map['category_id'] as int?,
      imagePath: map['image_path'] as String?,
      sku: map['sku'] as String?,
      lowStockThreshold: (map['low_stock_threshold'] as int?) ?? 5,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: _readDate(map['created_at']),
      updatedAt: _readDate(map['updated_at']),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'image_path': imagePath,
      'sku': sku,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
