import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/database_helper.dart';
import '../theme/app_theme.dart';
import 'chat_page.dart';
import 'login_page.dart';

/// Messages tab: lists conversations related to exchange proposals.
/// Uses local storage backed by mock/demo conversation data.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AppState.instance.currentUser;
    if (user == null || user.id == null) {
      setState(() {
        _conversations = [];
        _loading = false;
      });
      return;
    }
    await DatabaseHelper.instance.seedDemoMessagesIfEmpty(user.id!);
    final conversations =
        await DatabaseHelper.instance.getConversations(user.id!);
    if (!mounted) return;
    setState(() {
      _conversations = conversations;
      _loading = false;
    });
  }

  String _timeLabel(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(t);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inHours < 1) return '${diff.inMinutes}m';
      if (diff.inDays < 1) return '${diff.inHours}h';
      return '${t.day}/${t.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = AppState.instance.isGuest;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Messages'),
      ),
      body: isGuest
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Login to view messages',
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
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 55, color: Colors.grey.shade300),
                          const SizedBox(height: 14),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send a message from any product detail page',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final convo = _conversations[index];
                        return _ConversationCard(
                          productName: convo['productName'] as String,
                          counterpartName: convo['counterpartName'] as String,
                          lastText: convo['lastText'] as String,
                          isMine: convo['isMine'] as bool,
                          time: _timeLabel(convo['lastAt'] as String),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  userId: AppState.instance.currentUser!.id!,
                                  productId: convo['productId'] as int,
                                  productName: convo['productName'] as String,
                                  counterpartName:
                                      convo['counterpartName'] as String,
                                ),
                              ),
                            );
                            _load();
                          },
                        );
                      },
                    ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final String productName;
  final String counterpartName;
  final String lastText;
  final bool isMine;
  final String time;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.productName,
    required this.counterpartName,
    required this.lastText,
    required this.isMine,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = counterpartName
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.accentSoft,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
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
                              counterpartName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        productName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${isMine ? 'You: ' : ''}$lastText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}