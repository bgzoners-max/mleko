import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/amazon_theme.dart';
import '../../core/haptic.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';

class SellerChatButton extends StatelessWidget {
  final String productId;
  final String sellerId;
  final bool isDesktop;
  final bool compact;

  const SellerChatButton({
    super.key,
    required this.productId,
    required this.sellerId,
    this.isDesktop = false,
    this.compact = false,
  });

  Future<void> _openChat(BuildContext context) async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) {
      unawaited(context.push('/login'));
      return;
    }
    if (user.id == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ovo je vaš proizvod.')),
      );
      return;
    }
    try {
      final convId = await context.read<ChatService>().getOrCreateConversation(
            user.id,
            sellerId,
            productId: productId,
          );
      if (context.mounted) unawaited(context.push('/chat/$convId'));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nije moguće otvoriti ćaskanje.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppState s) => s.user);
    if (user != null && !user.isGuest && user.id == sellerId) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AmazonColors.lightGreen : AmazonColors.green;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Tooltip(
          message: 'Pošalji poruku prodavcu',
          child: OutlinedButton.icon(
            onPressed: () => withHaptic(() => _openChat(context)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: accentColor,
              backgroundColor:
                  accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
              side: BorderSide(color: accentColor, width: 1.2),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
            label: const Text(
              'Pošalji poruku',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    final button = SizedBox(
      height: 46,
      width: isDesktop ? null : double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => withHaptic(() => _openChat(context)),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          backgroundColor: accentColor.withValues(alpha: isDark ? 0.14 : 0.08),
          side: BorderSide(color: accentColor, width: 1.4),
          minimumSize: isDesktop ? const Size(220, 46) : null,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
        label: const Text(
          'Pošalji poruku',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );

    return isDesktop
        ? Align(
            alignment: Alignment.centerLeft,
            child: button,
          )
        : button;
  }
}
