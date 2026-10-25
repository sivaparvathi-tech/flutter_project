import 'package:flutter/material.dart';

import 'home_page.dart';
import 'browse_page.dart';
import 'exchange_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';

/// Main authenticated shell with the five ReLoop tabs:
/// Home · Browse · Exchange · Messages · Profile
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  // Tabs that require a signed-in (non-guest) account.
  static const Set<int> _loginRequiredTabs = {2, 3};

  void _onTabTapped(int index) {
    if (_loginRequiredTabs.contains(index) && AppState.instance.isGuest) {
      _showLoginPrompt();
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.login_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Login Required'),
          ],
        ),
        content: const Text(
          'Please login or create an account to access this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      const HomePage(),
      const BrowsePage(),
      const ExchangePage(),
      const MessagesPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, -4),
              color: Colors.black.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppColors.primary,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                ),
                label: 'Browse',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                ),
                label: 'Exchange',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.primary,
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}