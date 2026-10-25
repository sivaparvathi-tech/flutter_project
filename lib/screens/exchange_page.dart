import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../models/exchange.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

/// Exchange Requests tab shown in the bottom navigation. Displays incoming
/// and outgoing proposals with real database state.
class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<ExchangeModel> _outgoing = <ExchangeModel>[];
  List<ExchangeModel> _incoming = <ExchangeModel>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) {
      setState(() {
        _outgoing = [];
        _incoming = [];
        _loading = false;
      });
      return;
    }
    await DatabaseHelper.instance.seedDemoProposalsIfEmpty(user.id!);
    final proposals = await DatabaseHelper.instance.getUserProposals(user.id!);
    if (!mounted) return;
    setState(() {
      _outgoing = proposals;
      _incoming = proposals
          .where((p) => p.status == 'Incoming')
          .toList(); // demo mock of proposals "from others"
      _loading = false;
    });
  }

  Future<void> _acceptProposal(ExchangeModel proposal) async {
    await DatabaseHelper.instance
        .updateProposalStatus(proposal.id!, 'Accepted');
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Proposal accepted'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Future<void> _rejectProposal(ExchangeModel proposal) async {
    await DatabaseHelper.instance
        .updateProposalStatus(proposal.id!, 'Rejected');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = AppState.instance.isGuest;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Exchange Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Outgoing'),
            Tab(text: 'Incoming'),
          ],
        ),
      ),
      body: isGuest
          ? _buildGuestPrompt()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _ProposalList(
                      proposals: _outgoing,
                      emptyMessage: 'No outgoing exchange proposals yet',
                      emptyIcon: Icons.upload_rounded,
                      onTapAccept: _acceptProposal,
                      onTapReject: _rejectProposal,
                      outgoing: true,
                    ),
                    _ProposalList(
                      proposals: _incoming,
                      emptyMessage: 'No incoming exchange requests yet',
                      emptyIcon: Icons.download_rounded,
                      onTapAccept: _acceptProposal,
                      onTapReject: _rejectProposal,
                      outgoing: false,
                    ),
                  ],
                ),
    );
  }

  Widget _buildGuestPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Login to view exchanges',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
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

class _ProposalList extends StatelessWidget {
  final List<ExchangeModel> proposals;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool outgoing;
  final Future<void> Function(ExchangeModel) onTapAccept;
  final Future<void> Function(ExchangeModel) onTapReject;

  const _ProposalList({
    required this.proposals,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onTapAccept,
    required this.onTapReject,
    required this.outgoing,
  });

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 55, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        final p = proposals[index];
        return _ProposalCard(
          proposal: p,
          outgoing: outgoing,
          onTapAccept: onTapAccept,
          onTapReject: onTapReject,
        );
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final ExchangeModel proposal;
  final bool outgoing;
  final Future<void> Function(ExchangeModel) onTapAccept;
  final Future<void> Function(ExchangeModel) onTapReject;

  const _ProposalCard({
    required this.proposal,
    required this.outgoing,
    required this.onTapAccept,
    required this.onTapReject,
  });

  Color get _statusColor {
    switch (proposal.status) {
      case 'Accepted':
        return AppColors.accent;
      case 'Rejected':
        return Colors.red.shade400;
      case 'Incoming':
        return const Color(0xFF4A83C4);
      default:
        return AppColors.amber;
    }
  }

  String get _statusLabel => proposal.status == 'Incoming' ? 'New Request' : proposal.status;

  @override
  Widget build(BuildContext context) {
    final showActions = outgoing
        ? proposal.status == 'Pending'
        : proposal.status == 'Incoming';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.myProductName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '→ ${proposal.targetProductName}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (proposal.cashAmount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cash sweetener: ₹${proposal.cashAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB07A38),
                ),
              ),
            ),
          ],
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: OutlinedButton(
                      onPressed: () => onTapReject(proposal),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade500,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => onTapAccept(proposal),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}