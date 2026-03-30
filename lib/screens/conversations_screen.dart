import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/app_network_image.dart';
import '../widgets/skeleton.dart';

String _formatConvTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
  if (diff.inDays == 1) return 'juče';
  if (diff.inDays < 7) return DateFormat('EEE', 'sr').format(dt);
  if (dt.year == now.year) return DateFormat('d. MMM', 'sr').format(dt);
  return DateFormat('d.M.yy', 'sr').format(dt);
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _refreshController = StreamController<void>.broadcast();

  // Stream se čuva kao polje — sprečava re-kreiranje kanala na svakom buildu.
  Stream<List<ConversationModel>>? _conversationsStream;
  String? _streamUserId;

  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  void _initStream(String userId) {
    if (_streamUserId == userId) return;
    _streamUserId = userId;
    _conversationsStream = ChatService()
        .watchConversations(userId, refreshTrigger: _refreshController.stream);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Poruke')),
        body: const Center(child: Text('Prijavite se da vidite poruke.')),
      );
    }

    _initStream(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Poruke')),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _conversationsStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju poruka.',
              detail: snap.error?.toString(),
              onRetry: () => _refreshController.add(null),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const ConversationListSkeleton();
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refreshController.add(null),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Nema poruka',
                    subtitle: 'Poruke sa prodavcima će se pojaviti ovde kada im pošaljete upit.',
                    ctaLabel: 'Pretraži proizvode',
                    ctaIcon: Icons.search,
                    onCtaPressed: () => context.go('/'),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refreshController.add(null),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final conv = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: conv.otherPartyImageUrl != null && conv.otherPartyImageUrl!.isNotEmpty
                        ? ClipOval(
                            child: AppNetworkImage.profileSmall(
                              imageUrl: conv.otherPartyImageUrl!,
                              width: 40,
                              height: 40,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.person, color: Colors.grey.shade600),
                          ),
                    title: Text(
                      conv.otherPartyName ?? 'Korisnik',
                      style: TextStyle(
                        fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      conv.lastMessageBody ?? 'Nema poruka',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatConvTime(conv.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: conv.unreadCount > 0
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (conv.unreadCount > 0)
                          Badge(
                            label: Text('${conv.unreadCount}'),
                            child: const SizedBox(width: 8),
                          )
                        else
                          const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    onTap: () => context.push('/chat/${conv.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

