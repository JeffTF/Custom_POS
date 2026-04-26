import 'product.dart';
import 'sale_item.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => quantity * product.price;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  SaleItem toSaleItem() {
    return SaleItem(
      productId: product.id!,
      quantity: quantity,
      unitPrice: product.price,
    );
  }
}
