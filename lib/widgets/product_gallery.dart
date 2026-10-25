import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/product_images.dart';

/// Swipeable image carousel used on the Product Details page.
/// Shows every product image; falls back to a single cover/placeholder.
class ProductGallery extends StatefulWidget {
  final Product product;
  final BorderRadius? borderRadius;

  const ProductGallery({
    super.key,
    required this.product,
    this.borderRadius,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;
    final count = images.length;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (count <= 1)
          ProductImage(
            image: count == 1 ? images.first : null,
            product: widget.product,
            emojiSize: 90,
            borderRadius: widget.borderRadius,
          )
        else
          PageView.builder(
            itemCount: count,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return ProductImage(
                image: images[index],
                product: widget.product,
                emojiSize: 90,
                borderRadius: widget.borderRadius,
              );
            },
          ),
        if (count > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                final selected = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          ),
        if (count > 1)
          Positioned(
            right: 14,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_index + 1}/$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}