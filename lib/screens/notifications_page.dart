import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _filterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
            child: Text(
              'Read All',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _filterButton('All', _filterIndex == 0),
                _filterButton('Orders', _filterIndex == 1),
                _filterButton('Exchanges', _filterIndex == 2),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_filterIndex == 0 || _filterIndex == 2)
                  _NotificationCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'New Exchange Offer',
                    subtitle: 'A seller accepted your exchange '
                        'offer for Samsung Galaxy S20.',
                    time: '2 hours ago',
                    color: Colors.green,
                    unread: true,
                  ),
                if (_filterIndex == 0 || _filterIndex == 1)
                  _NotificationCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Order Confirmed',
                    subtitle: 'Your order for Havells Iron '
                        'has been confirmed.',
                    time: '5 hours ago',
                    color: Colors.blue,
                    unread: true,
                  ),
                if (_filterIndex == 0 || _filterIndex == 2)
                  _NotificationCard(
                    icon: Icons.location_on_outlined,
                    title: 'Product Near You',
                    subtitle: 'A new office chair was listed '
                        '1.5 km from you.',
                    time: 'Yesterday',
                    color: Colors.orange,
                    unread: false,
                  ),
                if (_filterIndex == 0 || _filterIndex == 1)
                  _NotificationCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'Out for Delivery',
                    subtitle: 'Your exchange item is out for '
                        'nearby delivery.',
                    time: '2 days ago',
                    color: Colors.teal,
                    unread: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterIndex = text == 'All'
                ? 0
                : text == 'Orders'
                    ? 1
                    : 2;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [
                    BoxShadow(
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ]
                : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.green.shade700
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool unread;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: unread
            ? Border.all(color: color.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: unread
                              ? Colors.black87
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
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