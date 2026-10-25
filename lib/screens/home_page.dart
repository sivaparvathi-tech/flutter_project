import 'package:flutter/material.dart';

import 'category_products_page.dart';
import 'search_results_page.dart';
import 'profile_page.dart';
import '../data/app_state.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

/// ReLoop marketplace home: location selector, search, re-homed stat card,
/// filter chips and a two-column curated product grid.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _allProducts = <Product>[];
  bool _loading = true;
  String _filter = 'All Swaps';

  static const List<String> _filters = ['All Swaps', 'Direct Trade', 'Open to Offers'];

  static const List<(String, IconData, Color)> _categories = [
    ('Mobiles', Icons.phone_android_rounded, Color(0xFF4A83C4)),
    ('Laptops', Icons.laptop_mac_rounded, Color(0xFF5D6DB8)),
    ('Cameras', Icons.camera_alt_rounded, Color(0xFF455A64)),
    ('Cars', Icons.directions_car_rounded, Color(0xFF9B5DAA)),
    ('Bikes', Icons.two_wheeler_rounded, Color(0xFFD97757)),
    ('Gaming', Icons.sports_esports_rounded, Color(0xFF7B1FA2)),
    ('Books', Icons.menu_book_rounded, Color(0xFFD08B3E)),
    ('Fashion', Icons.checkroom_rounded, Color(0xFFD05A8A)),
    ('Furniture', Icons.chair_rounded, Color(0xFF9B765F)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await ProductRepository.instance.getProducts();
    if (!mounted) return;
    setState(() {
      _allProducts = products;
      _loading = false;
    });
  }

  List<Product> get _visibleProducts {
    switch (_filter) {
      case 'Direct Trade':
        return _allProducts.where((p) => p.isDirectTrade).toList();
      case 'Open to Offers':
        return _allProducts.where((p) => !p.isDirectTrade).toList();
      default:
        return _allProducts;
    }
  }

  void _openCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage(category: category),
      ),
    );
  }

  void _openCityPicker() {
    final cities = LocationCityHelper.cities;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            const Text(
              'Choose your area',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            for (final city in cities)
              ListTile(
                title: Text(city),
                trailing: AppState.instance.currentCity.value == city
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  AppState.instance.currentCity.value = city;
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ───────── TOP: LOCATION + AVATAR ─────────
                Row(
                  children: [
                    GestureDetector(
                      onTap: _openCityPicker,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 5),
                          ValueListenableBuilder<String>(
                            valueListenable: AppState.instance.currentCity,
                            builder: (context, city, _) {
                              return Text(
                                city,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              );
                            },
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ───────── SEARCH BAR ─────────
                TextField(
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SearchResultsPage(searchQuery: value.trim()),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search vintage, electronics, fashion...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchResultsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ───────── RE-HOMED STAT CARD ─────────
                _RehomedCard(),

                const SizedBox(height: 24),

                // ───────── CURATED FOR YOU + FILTERS ─────────
                const Text(
                  'Curated for you',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final filter in _filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _filter == filter,
                            showCheckmark: false,
                            onSelected: (_) {
                              setState(() => _filter = filter);
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ───────── CATEGORIES ─────────
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final (name, icon, color) in _categories)
                        _CategoryItem(
                          icon: icon,
                          title: name,
                          color: color,
                          onTap: () => _openCategory(name),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ───────── PRODUCT GRID ─────────
                if (_loading)
                  const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_visibleProducts.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: Center(
                      child: Text('No products match this filter yet'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final count = _visibleProducts.length < 6
                          ? _visibleProducts.length
                          : 6;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: productGridDelegate(context),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _visibleProducts[index],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared list of areas used by the location picker.
class LocationCityHelper {
  LocationCityHelper._();

  static const List<String> cities = [
    'Brooklyn',
    'Manhattan',
    'Queens',
    'Hyderabad',
    'Visakhapatnam',
    'Vijayawada',
    'Vizianagaram',
    'Srikakulam',
  ];
}

// ═══════════════════════════════════════════════════════════════════════
// RE-HOMED STAT CARD
// ═══════════════════════════════════════════════════════════════════════
class _RehomedCard extends StatelessWidget {
  const _RehomedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF124C3A), Color(0xFF237A59)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4 items re-homed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Great progress! Every swap keeps\nanother product out of landfill.',
                  style: TextStyle(
                    color: Color(0xFFBFD9CE),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _ProgressRing(progress: 0.4),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;

  const _ProgressRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
            strokeCap: StrokeCap.round,
          ),
          const Center(
            child: Text(
              '♻️',
              style: TextStyle(fontSize: 26),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CATEGORY ITEM
// ═══════════════════════════════════════════════════════════════════════
class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}