import 'package:flutter/material.dart';

import 'info_screens.dart';
import '../theme/app_theme.dart';

/// ReLoop Settings: notification toggles, preferences and app information.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;
  bool _nearbyAlerts = true;
  bool _exchangeUpdates = true;
  String _language = 'English';

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('Notifications'),
          const SizedBox(height: 10),
          _buildSwitchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Exchange & message updates',
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          _buildSwitchTile(
            icon: Icons.near_me_outlined,
            title: 'Nearby Alerts',
            subtitle: 'New products near your location',
            value: _nearbyAlerts,
            onChanged: (v) => setState(() => _nearbyAlerts = v),
          ),
          _buildSwitchTile(
            icon: Icons.swap_horiz_rounded,
            title: 'Exchange Updates',
            subtitle: 'When someone requests an exchange',
            value: _exchangeUpdates,
            onChanged: (v) => setState(() => _exchangeUpdates = v),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Preferences'),
          const SizedBox(height: 10),

          _tapTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: _language,
            onTap: () => _showLanguagePicker(),
          ),

          const SizedBox(height: 24),
          _sectionTitle('About'),
          const SizedBox(height: 10),

          _tapTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'FAQ and contact support',
            onTap: () => _open(const HelpSupportScreen()),
          ),
          _tapTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            onTap: () => _open(const PrivacyPolicyScreen()),
          ),
          _tapTile(
            icon: Icons.verified_user_outlined,
            title: 'Terms & Conditions',
            subtitle: 'Rules for using ReLoop',
            onTap: () => _open(const TermsScreen()),
          ),
          _tapTile(
            icon: Icons.info_outline_rounded,
            title: 'About ReLoop',
            subtitle: 'Version 1.0.0',
            onTap: () => _open(const AboutScreen()),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'ReLoop · Reduce · Reuse · Exchange',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('English'),
              trailing: _language == 'English'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _language = 'English');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('हिन्दी (Hindi)'),
              trailing: _language == 'Hindi'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _language = 'Hindi');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('తెలుగు (Telugu)'),
              trailing: _language == 'Telugu'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _language = 'Telugu');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _tileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _tapTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return _tileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: Colors.grey,
      ),
    );
  }

  Widget _tileShell({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        trailing: trailing,
      ),
    );
  }
}