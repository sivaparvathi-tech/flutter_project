import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_sellers.dart';
import '../models/product.dart';
import '../screens/product_details_page.dart';
import '../theme/app_theme.dart';
import '../utils/location_service.dart';
import '../utils/product_images.dart';

/// Responsive grid delegate: 2 columns on phones, 3 on tablets, 4 on wide
/// screens. Every card gets the same height so the grid stays clean without
/// overflow.
SliverGridDelegate productGridDelegate(
  BuildContext context, {
  double mainAxisExtent = 258,
  double spacing = 14,
  int? maxColumns,
}) {
  final width = MediaQuery.sizeOf(context).width;
  var columns = width >= 900 ? 4 : (width >= 600 ? 3 : 2);
  if (maxColumns != null) columns = math.min(columns, maxColumns);
  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    mainAxisExtent: mainAxisExtent,
  );
}

/// Compact marketplace product card used across Home, Browse, Categories,
/// Search and Favourites. Shows a live favourite toggle and the mock seller.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final bool showDistance;
  final bool showFavourite;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showDistance = true,
    this.showFavourite = true,
  });

  void _openProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = showDistance
        ? LocationService.instance.distanceToCity(product.location)
        : null;
    final seller = mockSellerForProduct(product.id ?? 0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      shadowColor: AppColors.primary.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap ?? () => _openProduct(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 124,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductThumbnail(
                    product: product,
                    emojiSize: 42,
                    iconSize: 40,
                    borderRadius: BorderRadius.zero,
                  ),
                  if (showFavourite) _FavouriteButton(product: product),
                  if (product.sold == 1)
                    const Positioned(left: 9, top: 9, child: _SoldBadge()),
                  if (product.isDirectTrade)
                    Positioned(
                      left: 9,
                      bottom: 9,
                      child: _TradeBadge(label: 'Direct Trade'),
                    ),
                  if (distance != null)
                    Positioned(
                      right: 9,
                      bottom: 9,
                      child: _DistanceBadge(
                        text:
                            LocationService.instance.formatDistanceKm(distance),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 8, 11, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.exchangeValueLabel,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    // Seller row
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            seller.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            seller.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: AppColors.amber,
                        ),
                        Text(
                          seller.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            product.condition,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Live favourite toggle that reflects and updates AppState.favourites.
class _FavouriteButton extends StatefulWidget {
  final Product product;

  const _FavouriteButton({required this.product});

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton> {
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fav = await AppState.instance.isFavourite(widget.product);
    if (!mounted) return;
    setState(() => _isFavourite = fav);
  }

  Future<void> _toggle() async {
    if (AppState.instance.currentUser == null) return;
    await AppState.instance.toggleFavourite(widget.product);
    setState(() => _isFavourite = !_isFavourite);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 7,
      right: 7,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17,
            color: _isFavourite ? AppColors.coral : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  final String text;

  const _DistanceBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me_outlined, size: 11, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeBadge extends StatelessWidget {
  final String label;

  const _TradeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SoldBadge extends StatelessWidget {
  const _SoldBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        'SOLD',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}