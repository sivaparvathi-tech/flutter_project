import 'package:flutter/material.dart';

import 'chat_page.dart';
import 'propose_exchange_page.dart';
import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../data/mock_sellers.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/impact_service.dart';
import '../utils/location_service.dart';
import '../widgets/product_gallery.dart';

/// ReLoop product details: gallery, exchange value, circular impact, seller
/// profile, condition & lineage, chain of custody and the Propose Exchange
/// action.
class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _loadFavourite();
    _bumpViews();
  }

  Future<void> _loadFavourite() async {
    final fav = await AppState.instance.isFavourite(widget.product);
    if (!mounted) return;
    setState(() => _isFavourite = fav);
  }

  Future<void> _bumpViews() async {
    final id = widget.product.id;
    if (id == null) return;
    await DatabaseHelper.instance.incrementViews(id);
  }

  Future<void> _toggleFavourite() async {
    await AppState.instance.toggleFavourite(widget.product);
    setState(() => _isFavourite = !_isFavourite);
  }

  Future<void> _addToCart() async {
    await AppState.instance.addToCart(widget.product);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  void _openProposeExchange() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProposeExchangePage(product: widget.product),
      ),
    );
  }

  void _openChat(String sellerName) {
    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login to message the seller')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          userId: user.id!,
          productId: widget.product.id ?? 0,
          productName: widget.product.name,
          counterpartName: sellerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final seller = mockSellerForProduct(product.id ?? 0);
    final impact = estimatedImpactFor(product);
    final distance = LocationService.instance.distanceToCity(product.location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: _CircleAction(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _CircleAction(
                icon: _isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _isFavourite ? AppColors.coral : null,
                onTap: _toggleFavourite,
              ),
              const SizedBox(width: 6),
              _CircleAction(
                icon: Icons.share_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share link copied')),
                  );
                },
              ),
              const SizedBox(width: 14),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ProductGallery(
                    product: product,
                    borderRadius: BorderRadius.zero,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x22000000),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ───────── NAME + VALUE ─────────
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.category}  ·  ${product.condition}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.exchangeValueLabel,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Used value',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (product.price * 0.82)
                                .toStringAsFixed(0)
                                .replaceFirst(
                                    RegExp(r'^'), Product.currencySymbol),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ───────── QUICK INFO TILES ─────────
                  _InfoTileGrid(
                    product: product,
                    seller: seller,
                    distance: distance,
                  ),

                  const SizedBox(height: 26),

                  // ───────── CIRCULAR IMPACT ─────────
                  _CircularImpactCard(impact: impact),

                  const SizedBox(height: 26),

                  // ───────── DESCRIPTION ─────────
                  const _SectionTitle('Description'),
                  const SizedBox(height: 8),
                  Text(
                    product.description.isEmpty
                        ? 'This pre-owned find is ready for a new home. '
                            'In ${product.condition.toLowerCase()} condition, '
                            'perfect for a direct swap.'
                        : product.description,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ───────── CONDITION & LINEAGE ─────────
                  const _SectionTitle('Condition & Lineage'),
                  const SizedBox(height: 12),
                  _DetailCard(
                    icon: Icons.settings_input_component_rounded,
                    title: 'Key Specs',
                    lines: [
                      '${product.condition} physical condition',
                      'Category · ${product.category}',
                      _formatListed(product.createdAt),
                    ],
                  ),
                  _DetailCard(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Bundle Inclusions',
                    lines: [
                      'Original accessories included',
                      'Cleaned & tested before listing',
                    ],
                  ),
                  _DetailCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Sale / Exchange Expectations',
                    lines: [
                      '${product.tradeType} only · no-fee swap',
                      'Meet nearby for a pickup exchange',
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ───────── CHAIN OF CUSTODY ─────────
                  const _SectionTitle('Chain of Custody'),
                  const SizedBox(height: 12),
                  _CustodyTimeline(product: product),

                  const SizedBox(height: 26),

                  // ───────── SELLER ─────────
                  const _SectionTitle('Seller'),
                  const SizedBox(height: 12),
                  _SellerCard(
                    seller: seller,
                    onContact: () => _openChat(seller.name),
                    onViewProfile: () => _showSellerSheet(seller),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      // ───────── BOTTOM ACTION BAR ─────────
      bottomNavigationBar: _BottomActions(
        onPropose: _openProposeExchange,
        onCart: _addToCart,
        onContact: () =>
            _openChat(mockSellerForProduct(product.id ?? 0).name),
      ),
    );
  }

  String _formatListed(String iso) {
    if (iso.isEmpty) return 'Recently listed';
    try {
      final date = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return 'Listed ${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Recently listed';
    }
  }

  void _showSellerSheet(SellerInfo seller) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.accentSoft,
                    child: Text(
                      seller.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Member · Verified seller',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  _RatingBadge(rating: seller.rating),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _SellerStat(icon: Icons.swap_horiz_rounded,
                      value: '${seller.completedSwaps}', label: 'Swaps'),
                  const SizedBox(width: 12),
                  _SellerStat(icon: Icons.schedule_rounded,
                      value: seller.responseTime, label: 'Response'),
                  const SizedBox(width: 12),
                  _SellerStat(icon: Icons.location_on_outlined,
                      value: seller.location, label: 'Location'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SMALL ROUND ACTION (app bar)
// ═══════════════════════════════════════════════════════════════════════
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _CircleAction({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 21, color: color ?? AppColors.textDark),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
        letterSpacing: -0.3,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK INFO TILES
// ═══════════════════════════════════════════════════════════════════════
class _InfoTileGrid extends StatelessWidget {
  final Product product;
  final SellerInfo seller;
  final double? distance;

  const _InfoTileGrid({
    required this.product,
    required this.seller,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final d = distance;
    final distanceLabel = d == null
        ? 'Nearby'
        : '${LocationService.instance.formatDistanceKm(d)} away';

    return Row(
      children: [
        Expanded(
          child: _QuickTile(
            icon: Icons.verified_user_rounded,
            label: 'Seller',
            value: product.userId <= 0 ? seller.name : 'Verified user',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            icon: Icons.miscellaneous_services_rounded,
            label: 'Condition',
            value: product.condition,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickTile(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: distanceLabel,
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CIRCULAR IMPACT CARD
// ═══════════════════════════════════════════════════════════════════════
class _CircularImpactCard extends StatelessWidget {
  final ImpactEstimate impact;

  const _CircularImpactCard({required this.impact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4636), Color(0xFF1AAA4A)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_rounded, color: AppColors.amber, size: 22),
              SizedBox(width: 8),
              Text(
                'Circular Impact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By choosing reuse, this swap saves resources compared to buying new.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _ImpactStat(
                icon: Icons.cloud_outlined,
                value: '${impact.co2Kg.toStringAsFixed(0)} kg',
                label: 'CO₂ avoided',
              ),
              _divider(),
              _ImpactStat(
                icon: Icons.delete_outline_rounded,
                value: '${impact.wasteKg.toStringAsFixed(0)} kg',
                label: 'Waste saved',
              ),
              _divider(),
              _ImpactStat(
                icon: Icons.water_drop_outlined,
                value: '${impact.waterLitres.toStringAsFixed(0)} L',
                label: 'Water saved',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '* Estimated values',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.amber, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CONDITION & LINEAGE DETAIL CARD
// ═══════════════════════════════════════════════════════════════════════
class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;

  const _DetailCard({
    required this.icon,
    required this.title,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $line',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CHAIN OF CUSTODY TIMELINE
// ═══════════════════════════════════════════════════════════════════════
class _CustodyTimeline extends StatelessWidget {
  final Product product;

  const _CustodyTimeline({required this.product});

  @override
  Widget build(BuildContext context) {
    final steps = _custodySteps(product);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _TimelineRow(
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              title: steps[i],
            ),
          ],
        ],
      ),
    );
  }

  List<String> _custodySteps(Product product) {
    final listed = product.createdAt.isEmpty
        ? 'Recently'
        : _monthYear(product.createdAt);
    return [
      'Manufactured & first sale',
      'Pre-owned and well cared for',
      'Validated on ReLoop · scanned & tested',
      'Ready to reloop · $listed',
    ];
  }

  String _monthYear(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _TimelineRow extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final String title;

  const _TimelineRow({
    required this.isFirst,
    required this.isLast,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isFirst ? AppColors.coral : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: AppColors.outline,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SELLER CARD
// ═══════════════════════════════════════════════════════════════════════
class _SellerCard extends StatelessWidget {
  final SellerInfo seller;
  final VoidCallback onContact;
  final VoidCallback onViewProfile;

  const _SellerCard({
    required this.seller,
    required this.onContact,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.accentSoft,
                child: Text(
                  seller.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seller.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: AppColors.amber,
                        ),
                        Text(
                          '${seller.rating.toStringAsFixed(1)}  ·  '
                          '${seller.completedSwaps} swaps  ·  '
                          '${seller.responseTime}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _RatingBadge(rating: seller.rating),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onContact,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('View profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 15, color: AppColors.amber),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFB07A38),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SellerStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BOTTOM ACTIONS
// ═══════════════════════════════════════════════════════════════════════
class _BottomActions extends StatelessWidget {
  final VoidCallback onPropose;
  final VoidCallback onCart;
  final VoidCallback onContact;

  const _BottomActions({
    required this.onPropose,
    required this.onCart,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton.outlined(
              onPressed: onContact,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              iconSize: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPropose,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: const Text(
                  'Propose Exchange',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 2,
                  shadowColor: AppColors.coral.withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: onCart,
              icon: const Icon(Icons.shopping_bag_outlined),
              iconSize: 22,
            ),
          ],
        ),
      ),
    );
  }
}