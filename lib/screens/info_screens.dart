import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A simple sectioned content page used by the legal / help screens.
class _InfoScreen extends StatelessWidget {
  final String title;
  final String leadingIcon;
  final List<_Section> sections;
  final String footer;

  const _InfoScreen({
    required this.title,
    required this.leadingIcon,
    required this.sections,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B4D3E), Color(0xFF1AAA4A)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Text(leadingIcon,
                    style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          for (final section in sections) ...[
            Text(
              section.heading,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              section.body,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.65,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 10),
          Center(
            child: Text(
              footer,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String heading;
  final String body;

  const _Section(this.heading, this.body);
}

const String _termsFooter =
    'ReLoop · Give pre-loved goods a second story';

/// Terms & Conditions for using the ReLoop marketplace.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      '1. Accepting the Terms',
      'By creating an account or browsing the ReLoop marketplace you agree '
          'to these Terms & Conditions. If you do not agree, please do not '
          'use the service. We may update these terms from time to time and '
          'will post the latest version here.',
    ),
    _Section(
      '2. Listings & Accuracy',
      'All products listed on ReLoop are owned by their respective users. '
          'You agree to provide accurate, truthful details including the '
          'condition, price and photos of every item you list. Misleading '
          'listings may be removed.',
    ),
    _Section(
      '3. Exchanges & Payments',
      'An exchange is an agreement between two users. ReLoop provides the '
          'platform for that agreement but is not a party to it unless '
          'stated otherwise. You are responsible for inspecting items before '
          'completing an exchange and for settling any agreed cash sweetener '
          'directly.',
    ),
    _Section(
      '4. Prohibited Items',
      'You may not list or trade illegal items, replicas, stolen goods, '
          'dangerous or hazardous materials, or anything that violates '
          'applicable laws. Offending listings will be taken down and '
          'accounts may be suspended.',
    ),
    _Section(
      '5. Accounts & Security',
      'You are responsible for keeping your login details secure. Notify us '
          'immediately if you believe your account has been compromised. '
          'Each account is for a single individual unless otherwise agreed.',
    ),
    _Section(
      '6. Limitation of Liability',
      'ReLoop is provided on an “as is” basis. To the maximum extent '
          'permitted by law we are not liable for loss arising from user '
          'listings, offline exchanges, or your use of the platform.',
    ),
    _Section(
      '7. Contact',
      'For questions about these terms, write to support@reloop.app. '
          'We normally reply within 2 working days.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _InfoScreen(
      title: 'Terms & Conditions',
      leadingIcon: '📄',
      sections: _sections,
      footer: _termsFooter,
    );
  }
}

/// Privacy Policy for the ReLoop marketplace.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      'What we collect',
      'We collect the details you provide when creating an account (name, '
          'email, phone) and the information you add to listings such as '
          'photos, descriptions and your local area.',
    ),
    _Section(
      'How we use it',
      'Your data is used to run the marketplace: showing your listings, '
          'matching nearby products, enabling exchanges and messages, and '
          'improving the service. We never sell your personal information.',
    ),
    _Section(
      'Location',
      'Your chosen market area (e.g. "Brooklyn") is used to surface nearby '
          'products. Precise GPS is only accessed when you explicitly opt in '
          'and is never shared without consent.',
    ),
    _Section(
      'Storage & security',
      'Your data is stored locally on your device in a secure database. '
          'We keep only what is needed to provide the service.',
    ),
    _Section(
      'Your choices',
      'You can edit or delete your data from the app at any time. To delete '
          'your account completely, contact support@reloop.app and we will '
          'remove your records within 14 days.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const _InfoScreen(
      title: 'Privacy Policy',
      leadingIcon: '🔒',
      sections: _sections,
      footer: _termsFooter,
    );
  }
}

/// Help & Support: FAQ and contact options.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const List<_Section> _faq = [
    _Section(
      'How do I propose an exchange?',
      'Open any product and tap “Propose Exchange”. Choose one of your own '
          'products, add a cash sweetener if needed, then submit. The seller '
          'can accept or counter your offer.',
    ),
    _Section(
      'How are exchanges completed?',
      'Once accepted, message the seller to arrange a nearby meet-up or '
          'shipment. Verify the item meets its description before completing '
          'the swap. Both users then mark the exchange as done.',
    ),
    _Section(
      'What does “Circular Impact” mean?',
      'It is an estimate of the CO2, waste and water saved by reusing a '
          'product instead of buying new. Values are indicative estimates.',
    ),
    _Section(
      'How do I report a problem listing?',
      'Use the in-app support link below or email support@reloop.app with '
          'the product name and reason. We review reports within 24 hours.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScreen(
      title: 'Help & Support',
      leadingIcon: '🎧',
      sections: _faq,
      footer: 'ReLoop · support@reloop.app · we reply within 2 working days',
    );
  }
}

/// About ReLoop: the story and version.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<_Section> _sections = [
    _Section(
      'Our mission',
      'ReLoop is a second-hand product exchange platform. Our goal is simple: '
          'give pre-loved goods a second story, keep products in use, and '
          'reduce waste one swap at a time.',
    ),
    _Section(
      'Who we are',
      'We are builders who believe the most sustainable product is the one '
          'already made. Through direct swaps, traded goods and a little '
          'cash, we make re-use the easy choice.',
    ),
    _Section(
      'How it works',
      'Browse nearby products, propose an exchange with something you own, '
          'and meet to complete the trade. Every completed swap saves '
          'CO2, water and waste — tracked right on the product page.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _InfoScreen(
      title: 'About ReLoop',
      leadingIcon: '🌱',
      sections: _sections,
      footer: 'ReLoop · Version 1.0.0',
    );
  }
}