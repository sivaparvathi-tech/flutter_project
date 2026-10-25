import 'package:flutter/material.dart';
import 'product_details_page.dart';
import 'order_confirmation_page.dart';
import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/cart_line.dart';
import '../models/order_item.dart';
import '../utils/product_images.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _placingOrder = false;

  void _openProduct(CartLine line) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(
          product: line.product,
        ),
      ),
    );
  }

  Future<void> _increase(CartLine line) async {
    await AppState.instance.updateCartQuantity(line, line.quantity + 1);
  }

  Future<void> _decrease(CartLine line) async {
    if (line.quantity > 1) {
      await AppState.instance
          .updateCartQuantity(line, line.quantity - 1);
    }
  }

  Future<void> _remove(CartLine line) async {
    await AppState.instance.removeFromCart(line);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${line.product.name} removed from cart'),
      ),
    );
  }

  Future<void> _proceed(List<CartLine> lines) async {
    if (lines.isEmpty) return;
    if (_placingOrder) return;

    setState(() => _placingOrder = true);

    final user = AppState.instance.currentUser;
    if (user != null) {
      for (final line in lines) {
        await DatabaseHelper.instance.insertOrder(
          OrderItem(
            userId: user.id!,
            productId: line.product.id!,
            name: line.product.name,
            price: line.product.price,
            category: line.product.category,
            status: 'Pending Pickup',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
        await DatabaseHelper.instance.markSold(line.product.id!);
      }
      await AppState.instance.clearCart();
    }

    if (!mounted) return;
    setState(() => _placingOrder = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrderConfirmationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartLine>>(
      valueListenable: AppState.instance.cart,
      builder: (context, lines, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FBF8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'My Cart',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: lines.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: lines.length,
                        itemBuilder: (context, index) {
                          final line = lines[index];
                          return _CartProductCard(
                            line: line,
                            onTap: () {
                              _openProduct(line);
                            },
                            onIncrease: () {
                              _increase(line);
                            },
                            onDecrease: () {
                              _decrease(line);
                            },
                            onRemove: () {
                              _remove(line);
                            },
                          );
                        },
                      ),
                    ),
                    _buildBottomSummary(lines),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBottomSummary(List<CartLine> lines) {
    final subtotal = lines.fold<double>(
      0,
      (sum, line) => sum + line.lineTotal,
    );
    const delivery = 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, -3),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '₹${subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                '₹${delivery.toStringAsFixed(0)} (Nearby Pickup)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(),

          const SizedBox(height: 8),

          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '₹${(subtotal + delivery).toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed:
                  _placingOrder ? null : () => _proceed(lines),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _placingOrder
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Proceed',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 60,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Your Cart is Empty',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Products you add to your cart will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartProductCard extends StatelessWidget {
  final CartLine line;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartProductCard({
    required this.line,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTap,
              child: SizedBox(
                width: 80,
                height: 80,
                child: ProductThumbnail(
                  product: product,
                  emojiSize: 34,
                  iconSize: 32,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onTap,
                          child: Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: onRemove,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product.priceLabel,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.location,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: onDecrease,
                              icon: const Icon(
                                Icons.remove,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 35,
                                minHeight: 35,
                              ),
                              padding: EdgeInsets.zero,
                            ),

                            Text(
                              '${line.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            IconButton(
                              onPressed: onIncrease,
                              icon: const Icon(
                                Icons.add,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 35,
                                minHeight: 35,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}