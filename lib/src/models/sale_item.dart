class SaleItem {
  const SaleItem({
    this.id,
    this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final int? id;
  final int? saleId;
  final int productId;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  factory SaleItem.fromMap(Map<String, Object?> map) {
    return SaleItem(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}
