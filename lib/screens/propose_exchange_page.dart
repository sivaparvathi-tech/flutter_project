import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/exchange.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/product_images.dart';
import 'exchange_page.dart';
import 'login_page.dart';

/// ReLoop "Propose Exchange" flow: pick one of your products, choose a direct
/// swap or a trade with a cash sweetener, then submit the proposal.
class ProposeExchangePage extends StatefulWidget {
  final Product product;

  const ProposeExchangePage({super.key, required this.product});

  @override
  State<ProposeExchangePage> createState() => _ProposeExchangePageState();
}

class _ProposeExchangePageState extends State<ProposeExchangePage> {
  List<Product> _myProducts = [];
  int? _selectedIndex;
  bool _loading = true;
  bool _submitting = false;

  /// true = "Trade + Cash", false = "Direct Swap".
  bool _withCash = false;
  double _cash = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) {
      setState(() {
        _myProducts = [];
        _loading = false;
      });
      return;
    }
    await DatabaseHelper.instance.seedDemoProductsIfNone(user.id!);
    final products = await DatabaseHelper.instance
        .getUserProducts(user.id!);
    if (!mounted) return;
    setState(() {
      _myProducts = products;
      _selectedIndex = products.isNotEmpty ? 0 : null;
      _loading = false;
    });
  }

  Product get _target => widget.product;

  Product? get _selected =>
      (_selectedIndex == null || _selectedIndex! >= _myProducts.length)
          ? null
          : _myProducts[_selectedIndex!];

  double get _targetValue => _target.price;

  double get _myValue => (_selected?.price ?? 0);

  /// Maximum sensible cash sweetener: enough to close any value gap.
  int get _cashMax =>
      (_targetValue - _myValue).clamp(0, double.infinity).toInt();

  Future<void> _submit() async {
    final user = AppState.instance.currentUser;
    final selected = _selected;
    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login to propose an exchange')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (selected == null || selected.id == null) return;

    setState(() => _submitting = true);
    final cash = _withCash ? _cash : 0.0;
    final id = await DatabaseHelper.instance.insertProposal(ExchangeModel(
      userId: user.id!,
      myProductId: selected.id!,
      myProductName: selected.name,
      targetProductId: _target.id ?? 0,
      targetProductName: _target.name,
      cashAmount: cash,
      status: 'Pending',
      createdAt: DateTime.now().toIso8601String(),
    ));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExchangeSuccessPage(
          proposalId: id,
          myProductName: selected.name,
          targetProductName: _target.name,
          cashAmount: cash,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Propose Exchange'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myProducts.isEmpty
              ? _buildEmptyMessage()
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'I want this',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _TargetCard(product: target),
                            const SizedBox(height: 26),
                            Row(
                              children: [
                                const Text(
                                  'Swap my',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${_myProducts.length} available)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _MyProductSelector(
                              products: _myProducts,
                              selectedIndex: _selectedIndex,
                              onSelect: (i) => setState(() {
                                _selectedIndex = i;
                                _cash = 0;
                              }),
                            ),
                            const SizedBox(height: 26),

                            // ───────── TRADE MODE ─────────
                            _TradeModeToggle(
                              withCash: _withCash,
                              onChanged: (v) => setState(() {
                                _withCash = v;
                                _cash = 0;
                              }),
                            ),
                            if (_withCash) ...[
                              const SizedBox(height: 18),
                              _CashSweetenerSlider(
                                value: _cash,
                                max: _cashMax,
                                onChanged: (v) =>
                                    setState(() => _cash = v.roundToDouble()),
                              ),
                            ],
                            const SizedBox(height: 22),

                            // ───────── TRADE BALANCE ─────────
                            _TradeBalance(
                              my: _selected,
                              target: target,
                              cash: _withCash ? _cash : 0,
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading || _myProducts.isEmpty
          ? null
          : SafeArea(
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
                child: ElevatedButton(
                  onPressed:
                      _selected == null || _submitting || _myselfOwnsTarget()
                          ? null
                          : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 2,
                    shadowColor: AppColors.coral.withValues(alpha: 0.35),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Exchange Proposal',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  bool _myselfOwnsTarget() =>
      AppState.instance.currentUser?.id != null &&
      _target.userId > 0 &&
      _target.userId == AppState.instance.currentUser!.id;

  Widget _buildEmptyMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text(
            'Add a product to get started',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TARGET PRODUCT CARD
// ═══════════════════════════════════════════════════════════════════════
class _TargetCard extends StatelessWidget {
  final Product product;

  const _TargetCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ProductThumbnail(
            product: product,
            width: 76,
            height: 76,
            emojiSize: 40,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${product.category} · ${product.condition}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              product.exchangeValueLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MY PRODUCT SELECTOR
// ═══════════════════════════════════════════════════════════════════════
class _MyProductSelector extends StatelessWidget {
  final List<Product> products;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  const _MyProductSelector({
    required this.products,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final selected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 124,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEAF7EE) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.outline,
                  width: selected ? 2 : 1,
                ),
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
                  Stack(
                    children: [
                      ProductThumbnail(
                        product: product,
                        width: double.infinity,
                        height: 74,
                        emojiSize: 34,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      if (selected)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.accent,
                            child: Icon(
                              Icons.check_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.exchangeValueLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TRADE MODE TOGGLE
// ═══════════════════════════════════════════════════════════════════════
class _TradeModeToggle extends StatelessWidget {
  final bool withCash;
  final ValueChanged<bool> onChanged;

  const _TradeModeToggle({required this.withCash, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            icon: Icons.swap_horiz_rounded,
            label: 'Direct Swap',
            selected: !withCash,
            onTap: () => onChanged(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeChip(
            icon: Icons.currency_exchange_rounded,
            label: 'Trade + Cash',
            selected: withCash,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CASH SWEETENER SLIDER
// ═══════════════════════════════════════════════════════════════════════
class _CashSweetenerSlider extends StatelessWidget {
  final double value;
  final int max;
  final ValueChanged<double> onChanged;

  const _CashSweetenerSlider({
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final needsCash = max > 0;
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
      child: needsCash
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.currency_exchange_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Cash sweetener',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '₹${value.round()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: value.clamp(0, max.toDouble()).toDouble(),
                  max: max.toDouble(),
                  divisions: max.clamp(1, 100),
                  activeColor: AppColors.coral,
                  inactiveColor: AppColors.outline,
                  onChanged: onChanged,
                ),
                Text(
                  'Adds up to ₹$max to balance the trade',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have cash on top',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
                Text(
                  '₹${value.round()}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// TRADE BALANCE
// ═══════════════════════════════════════════════════════════════════════
class _TradeBalance extends StatelessWidget {
  final Product? my;
  final Product target;
  final double cash;

  const _TradeBalance({
    required this.my,
    required this.target,
    required this.cash,
  });

  @override
  Widget build(BuildContext context) {
    final myValue = my?.price ?? 0;
    final totalOffered = myValue + cash;
    final balanced = totalOffered >= target.price;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.scale_rounded,
                  size: 18, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text(
                'Trade balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceCol(
                  label: 'You offer',
                  value: '$currency${myValue.toStringAsFixed(0)}',
                  bold: false,
                ),
              ),
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              Expanded(
                child: _BalanceCol(
                  label: 'Target item',
                  value: '$currency${target.price.toStringAsFixed(0)}',
                  bold: false,
                ),
              ),
            ],
          ),
          if (cash > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+ ₹${cash.toStringAsFixed(0)} cash sweetener',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB07A38),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: balanced
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  balanced
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: balanced ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  balanced
                      ? 'Balanced swap — ready to propose'
                      : 'Add cash sweetener to balance the trade',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color:
                        balanced ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const String currency = '₹';
}

class _BalanceCol extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _BalanceCol({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: bold ? AppColors.coral : AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SUCCESS SCREEN
// ═══════════════════════════════════════════════════════════════════════
class ExchangeSuccessPage extends StatelessWidget {
  final int proposalId;
  final String myProductName;
  final String targetProductName;
  final double cashAmount;

  const ExchangeSuccessPage({
    super.key,
    required this.proposalId,
    required this.myProductName,
    required this.targetProductName,
    required this.cashAmount,
  });

  void _viewRequests(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ExchangePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F9F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Your exchange\nproposal is live',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'The seller has been notified and can accept, decline or '
                'counter your offer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'You offer', value: myProductName),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'For their',
                      value: targetProductName,
                    ),
                    if (cashAmount > 0) ...[
                      const SizedBox(height: 10),
                      _SummaryRow(
                        label: 'Plus cash',
                        value: '₹${cashAmount.toStringAsFixed(0)}',
                      ),
                    ],
                    const Divider(height: 22),
                    Text(
                      'Proposal #$proposalId',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _viewRequests(context),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text(
                    'View Exchange Requests',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}