import 'package:flutter/material.dart';

import 'cart_page.dart';
import 'edit_profile_page.dart';
import 'favourite_page.dart';
import 'login_page.dart';
import 'messages_page.dart';
import 'my_exchanges_page.dart';
import 'my_location_page.dart';
import 'my_orders_page.dart';
import 'my_products_page.dart';
import 'notifications_page.dart';
import 'seller_dashboard_page.dart';
import 'settings_page.dart';
import 'welcome_screen.dart';
import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../theme/app_theme.dart';

/// ReLoop Profile: premium header with avatar, username, location and trust
/// stats, followed by grouped sections for marketplace and settings.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _listedItems = 0;
  int _completedSwaps = 0;
  int _incomingRequests = 0;
  int _messageThreads = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) return;
    final db = DatabaseHelper.instance;
    final products = await db.getUserProducts(user.id!);
    final proposals = await db.getUserProposals(user.id!);
    final conversations = await db.getConversations(user.id!);
    if (!mounted) return;
    setState(() {
      _listedItems = products.length;
      _completedSwaps = proposals
          .where((p) => p.status == 'Accepted')
          .length;
      _incomingRequests =
          proposals.where((p) => p.status == 'Incoming').length;
      _messageThreads = conversations.length;
    });
  }

  String get _displayName {
    final name = AppState.instance.currentUser?.fullName;
    if (name == null || name.trim().isEmpty) return 'Guest';
    return name;
  }

  String get _username {
    final email = AppState.instance.currentUser?.email;
    if (email == null || email.trim().isEmpty) return '@guest';
    return '@${email.split('@').first}';
  }

  String get _location =>
      AppState.instance.currentCity.value;

  bool get _isGuest => AppState.instance.isGuest;

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    ).then((_) {
      if (mounted) _loadStats();
    });
  }

  void _loginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Login Required'),
          ],
        ),
        content:
            const Text('Please login to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _guard(BuildContext context, Widget Function() page) {
    if (_isGuest) {
      _loginRequired(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  isGuest: _isGuest,
                  displayName: _displayName,
                  username: _username,
                  location: _location,
                  onEdit: _editProfile,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.star_rounded,
                          color: AppColors.amber,
                          value: _isGuest ? '—' : '4.8',
                          label: 'Trust rating',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.swap_horiz_rounded,
                          color: AppColors.coral,
                          value: _isGuest ? '—' : '$_completedSwaps',
                          label: 'Swaps done',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          value: _isGuest ? '—' : '$_listedItems',
                          label: 'Listings',
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isGuest) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GuestBanner(),
                  ),
                ],

                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('Marketplace'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ProfileOption(
                        icon: Icons.inventory_2_outlined,
                        title: 'My Products',
                        subtitle: 'Listings you have posted',
                        onTap: () =>
                            _guard(context, () => const MyProductsPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.favorite_border_rounded,
                        title: 'Favourites',
                        subtitle: 'Products you saved',
                        onTap: () =>
                            _guard(context, () => const FavouritePage()),
                      ),
                      _ProfileOption(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Messages',
                        subtitle: _isGuest
                            ? 'Login to see conversations'
                            : '$_messageThreads conversations',
                        badge: _isGuest ? null : _messageThreads,
                        onTap: () =>
                            _guard(context, () => const MessagesPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.swap_horiz_rounded,
                        title: 'Exchange Requests',
                        subtitle: _isGuest
                            ? 'Login to see exchanges'
                            : '$_incomingRequests incoming requests',
                        badge: _isGuest ? null : _incomingRequests,
                        onTap: () =>
                            _guard(context, () => const MyExchangesPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Orders',
                        subtitle: 'Track your orders',
                        onTap: () =>
                            _guard(context, () => const MyOrdersPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Cart',
                        subtitle: 'Products in your cart',
                        onTap: () => _guard(context, () => const CartPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.storefront_outlined,
                        title: 'Seller Dashboard',
                        subtitle: 'Manage your shop and listings',
                        onTap: () =>
                            _guard(context, () => const SellerDashboardPage()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionLabel('Preferences'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ProfileOption(
                        icon: Icons.location_on_outlined,
                        title: 'My Location',
                        subtitle: _location,
                        onTap: () =>
                            _guard(context, () => const MyLocationPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        subtitle: 'Exchange and message alerts',
                        onTap: () => _guard(
                            context, () => const NotificationsPage()),
                      ),
                      _ProfileOption(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'App preferences',
                        onTap: () =>
                            _guard(context, () => const SettingsPage()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(
                          _isGuest
                              ? Icons.exit_to_app_rounded
                              : Icons.logout_rounded,
                          color: Colors.red.shade500,
                        ),
                        title: Text(
                          _isGuest ? 'Exit Guest Mode' : 'Logout',
                          style: TextStyle(
                            color: Colors.red.shade500,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _isGuest
                              ? 'Return to welcome screen'
                              : 'Sign out of your account',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                        ),
                        onTap: () {
                          AppState.instance.clear().then((_) {
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WelcomeScreen(),
                              ),
                              (route) => false,
                            );
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text(
                    'ReLoop · Give pre-loved goods a second story',
                    style: TextStyle(
                      fontSize: 11.5,
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
// HEADER
// ═══════════════════════════════════════════════════════════════════════
class _HeaderCard extends StatelessWidget {
  final bool isGuest;
  final String displayName;
  final String username;
  final String location;
  final VoidCallback? onEdit;

  const _HeaderCard({
    required this.isGuest,
    required this.displayName,
    required this.username,
    required this.location,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        displayName.trim().isEmpty ? 'G' : displayName.trim()[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B4D3E), Color(0xFF1AAA4A)],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                ),
                tooltip: 'Settings',
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuest ? 'Guest' : displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isGuest ? '@guestmode' : username,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                  ),
                  tooltip: 'Edit profile',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STAT TILES
// ═══════════════════════════════════════════════════════════════════════
class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// GUEST BANNER
// ═══════════════════════════════════════════════════════════════════════
class _GuestBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B4D3E), Color(0xFF1AAA4A)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.login_rounded, size: 42, color: Colors.white),
          const SizedBox(height: 10),
          const Text(
            'Want full access?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Login to swap, message sellers and manage your listings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Login Now',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION LABEL
// ═══════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROFILE OPTION
// ═══════════════════════════════════════════════════════════════════════
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badge;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          trailing: badge != null && badge! > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }
}