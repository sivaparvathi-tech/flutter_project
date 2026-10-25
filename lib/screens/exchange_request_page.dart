import 'package:flutter/material.dart';
import 'order_confirmation_page.dart';
import '../models/product.dart';
import '../models/exchange_item.dart';
import '../data/app_state.dart';
import '../data/database_helper.dart';

class ExchangeRequestPage extends StatefulWidget {
  final Product product;

  const ExchangeRequestPage({
    super.key,
    required this.product,
  });

  @override
  State<ExchangeRequestPage> createState() => _ExchangeRequestPageState();
}

class _ExchangeRequestPageState extends State<ExchangeRequestPage> {
  String? _exchangeType;
  final TextEditingController _offerController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_exchangeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an exchange type'),
        ),
      );
      return;
    }
    if (_offerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe what you will exchange'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;
      final user = AppState.instance.currentUser;
      if (user != null) {
        final exchange = ExchangeItem(
          userId: user.id!,
          productId: widget.product.id!,
          name: widget.product.name,
          category: widget.product.category,
          offerType: _exchangeType!,
          description: _offerController.text.trim(),
          status: 'Pending',
          createdAt: DateTime.now().toIso8601String(),
        );
        await DatabaseHelper.instance.insertExchange(exchange);
      }
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const OrderConfirmationPage(
            isExchange: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Exchange Request',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade500,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exchange your item for ${widget.product.name} '
                      'instead of buying new. Save money and e-waste.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'What do you want to exchange?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            _ExchangeOption(
              icon: Icons.phone_android_rounded,
              title: 'Another Product',
              subtitle: 'Exchange an old product you own',
              selected: _exchangeType == 'product',
              onTap: () {
                setState(() => _exchangeType = 'product');
              },
            ),
            _ExchangeOption(
              icon: Icons.construction_rounded,
              title: 'Repair / Service',
              subtitle: 'Offer repair work in exchange',
              selected: _exchangeType == 'service',
              onTap: () {
                setState(() => _exchangeType = 'service');
              },
            ),
            _ExchangeOption(
              icon: Icons.currency_rupee_rounded,
              title: 'Partial Cash + Product',
              subtitle: 'Old product plus some cash',
              selected: _exchangeType == 'partial',
              onTap: () {
                setState(() => _exchangeType = 'partial');
              },
            ),

            const SizedBox(height: 26),

            const Text(
              'Describe Your Offer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _offerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'e.g. I have a Samsung phone in good condition. '
                    'I would like to exchange it for this.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Exchange Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ExchangeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.green.shade700 : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              offset: const Offset(0, 3),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.green.shade700
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? Colors.green.shade700
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}