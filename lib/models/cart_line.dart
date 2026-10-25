import 'product.dart';

class CartLine {
  final int id;
  final Product product;
  final int quantity;

  const CartLine({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.price * quantity;
}