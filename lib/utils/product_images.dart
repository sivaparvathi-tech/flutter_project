import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/product.dart';
import 'platform_image.dart';

String categoryEmoji(String category) {
  switch (category.toLowerCase()) {
    case 'mobiles':
      return '📱';
    case 'cars':
      return '🚗';
    case 'bikes':
      return '🏍️';
    case 'laptops':
      return '💻';
    case 'cameras':
      return '📷';
    case 'gaming':
      return '🎮';
    case 'electronics':
      return '📺';
    case 'furniture':
      return '🪑';
    case 'fashion':
      return '👕';
    case 'books':
      return '📚';
    default:
      return '🛍️';
  }
}

List<Color> categoryGradient(String category) {
  switch (category.toLowerCase()) {
    case 'mobiles':
      return const [Color(0xFF2196F3), Color(0xFF64B5F6)];
    case 'cars':
      return const [Color(0xFFAB47BC), Color(0xFFCE93D8)];
    case 'bikes':
      return const [Color(0xFFFF7043), Color(0xFFFFAB91)];
    case 'laptops':
      return const [Color(0xFF3F51B5), Color(0xFF7986CB)];
    case 'cameras':
      return const [Color(0xFF455A64), Color(0xFF78909C)];
    case 'gaming':
      return const [Color(0xFF7B1FA2), Color(0xFFBA68C8)];
    case 'electronics':
      return const [Color(0xFF00897B), Color(0xFF4DB6AC)];
    case 'furniture':
      return const [Color(0xFF8D6E63), Color(0xFFBCAAA4)];
    case 'fashion':
      return const [Color(0xFFE91E8C), Color(0xFFF48FB1)];
    case 'books':
      return const [Color(0xFFFF8F00), Color(0xFFFFB74D)];
    default:
      return const [Color(0xFF43A047), Color(0xFF81C784)];
  }
}

/// Builds a placeholder image URL for a product (used until a real backend
/// serves product photos).
String productImageUrl(Product product, {int width = 800}) {
  final id = product.id ?? product.name.hashCode;
  return 'https://picsum.photos/seed/reexchange_$id/$width/$width';
}

/// Renders a single product image. The image value can be:
///  - a base64 data URI   (data:image/...;base64,....)  -> Image.memory
///  - an http(s) URL       (future backend)             -> Image.network
///  - a local file path    (native device)              -> Image.file
/// When nothing is available (or decoding fails) it falls back to a clean
/// category-gradient + emoji placeholder.
class ProductImage extends StatelessWidget {
  final String? image;
  final Product? product;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double emojiSize;

  const ProductImage({
    super.key,
    this.image,
    this.product,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.emojiSize = 52,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? const BorderRadius.all(Radius.circular(14));
    final fallback = _FallbackImage(
      product: product,
      emojiSize: emojiSize,
      borderRadius: radius,
    );

    final source = image ?? product?.coverImage ?? '';

    Widget? content;
    if (source.toLowerCase().startsWith('data:')) {
      content = Image.memory(
        base64Decode(source.substring(source.indexOf(',') + 1)),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stack) => fallback,
        gaplessPlayback: true,
      );
    } else if (source.toLowerCase().startsWith('http://') ||
        source.toLowerCase().startsWith('https://')) {
      content = Image.network(
        source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stack) => fallback,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return fallback;
        },
        gaplessPlayback: true,
      );
    } else if (source.isNotEmpty) {
      content = platformImage(
        source: source,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        color: Colors.green.shade50,
        child: content ?? fallback,
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  final Product? product;
  final double emojiSize;
  final BorderRadius borderRadius;

  const _FallbackImage({
    this.product,
    required this.emojiSize,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: categoryGradient(product?.category ?? 'Others'),
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Text(
          categoryEmoji(product?.category ?? 'Others'),
          style: TextStyle(fontSize: emojiSize),
        ),
      ),
    );
  }
}

/// Backwards-compatible thumbnail wrapper used on cards.
/// Uses the product cover image (first image) or the category fallback.
class ProductThumbnail extends StatelessWidget {
  final Product product;
  final double? height;
  final double? width;
  final double iconSize;
  final double emojiSize;
  final BorderRadius? borderRadius;

  const ProductThumbnail({
    super.key,
    required this.product,
    this.height,
    this.width,
    this.iconSize = 46,
    this.emojiSize = 52,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? const BorderRadius.all(Radius.circular(14));
    return ProductImage(
      product: product,
      width: width,
      height: height,
      fit: BoxFit.contain,
      borderRadius: radius,
      emojiSize: emojiSize,
    );
  }
}