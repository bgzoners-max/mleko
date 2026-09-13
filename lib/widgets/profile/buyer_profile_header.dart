import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_messages.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/communication/chat_service.dart';

class BuyerProfileHeader extends StatelessWidget {
  final UserModel? user;
  final String displayName;
  final int ordersCount;
  final String buyerId;
  final double? avgBuyerRating;
  final int buyerReviewCount;

  const BuyerProfileHeader({
    super.key,
    required this.user,
    required this.displayName,
    required this.ordersCount,
    required this.buyerId,
    required this.avgBuyerRating,
    required this.buyerReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user;
    final canContact = currentUser != null &&
        !currentUser.isGuest &&
        currentUser.id != buyerId;

    final hasStats = ordersCount > 0 || avgBuyerRating != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (hasStats) ...[
              _BuyerReputationStrip(
                ordersCount: ordersCount,
                avgBuyerRating: avgBuyerRating,
                buyerReviewCount: buyerReviewCount,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Icon(Icons.person,
                          size: 32, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (user?.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Član od ${DateFormat('MMM yyyy.', 'sr').format(user!.createdAt!)}',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (canContact) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _ContactBuyerButton(buyerId: buyerId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuyerReputationStrip extends StatelessWidget {
  final int ordersCount;
  final double? avgBuyerRating;
  final int buyerReviewCount;

  const _BuyerReputationStrip({
    required this.ordersCount,
    required this.avgBuyerRating,
    required this.buyerReviewCount,
  });

  String? _deliveredLabel() {
    final n = ordersCount;
    if (n <= 0) return null;
    if (n == 1) return '1 uspešno isporučena porudžbina';
    if (n >= 2 && n <= 4) return '$n uspešno isporučene porudžbine';
    return '$n uspešno isporučenih porudžbina';
  }

  @override
  Widget build(BuildContext context) {
    final delivered = _deliveredLabel();
    final rating = avgBuyerRating;

    if (delivered == null && rating == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (rating != null)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.star_rounded,
                    size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Prosečna ocena',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rating.toStringAsFixed(1)} ($buyerReviewCount)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (delivered != null)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.green.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Uspešne porudžbine',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        delivered,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContactBuyerButton extends StatefulWidget {
  final String buyerId;
  const _ContactBuyerButton({required this.buyerId});

  @override
  State<_ContactBuyerButton> createState() => _ContactBuyerButtonState();
}

class _ContactBuyerButtonState extends State<_ContactBuyerButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(48, 48),
      ),
      icon: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat_outlined, size: 18),
      label: const Text('Pošalji poruku'),
      onPressed: _loading ? null : _openChat,
    );
  }

  Future<void> _openChat() async {
    final currentUser = context.read<AppState>().user;
    final chatService = context.read<ChatService>();
    if (currentUser == null) return;
    setState(() => _loading = true);
    try {
      final convId = await chatService.getOrCreateConversation(
        widget.buyerId,
        currentUser.id,
      );
      if (mounted) context.push('/chat/$convId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
