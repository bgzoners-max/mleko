import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notification_types.dart';
import '../../core/responsive.dart';
import '../../models/notification_model.dart';
import '../../providers/app_state.dart';
import 'package:mleko/services/services.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final double? tileHorizontalPadding;
  final double? tileVerticalPadding;
  final double? tileBottomMargin;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
    this.onTap,
    this.tileHorizontalPadding,
    this.tileVerticalPadding,
    this.tileBottomMargin,
  });

  static Future<void> defaultOnTap(
    BuildContext context,
    NotificationModel n, {
    NotificationsService? service,
  }) async {
    final s = service ?? NotificationsService();
    if (!n.isRead) {
      await s.markAsRead(n.id);
    }
    if (!context.mounted) return;
    final uid = context.read<AppState>().user?.id;
    if (n.type == 'support_ticket_created') {
      context.go('/admin/tickets');
    } else if (n.type == 'admin_reply') {
      if (n.ticketId != null) {
        context.go('/support/ticket/${n.ticketId}');
      } else {
        context.go('/support');
      }
    } else if (n.type == 'new_message') {
      if (n.conversationId != null) {
        context.push('/chat/${n.conversationId}');
      } else {
        context.go('/conversations');
      }
    } else if (n.type == 'new_review' && uid != null) {
      context.go('/seller/$uid/reviews');
    } else if (n.type == 'new_buyer_review' && uid != null) {
      context.go('/buyer/$uid/reviews');
    } else if (notificationTypeIsClassifiedRelated(n.type) ||
        n.classifiedAdId != null) {
      if (n.classifiedAdId != null) {
        context.push('/classifieds/ad/${n.classifiedAdId}');
      } else {
        context.go('/classifieds');
      }
    } else if (n.orderId != null || notificationTypeIsOrderRelated(n.type)) {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final hPad = tileHorizontalPadding ??
        Breakpoints.adaptiveDouble(
          context,
          phone: 16,
          largeTabletValue: 18,
          desktop: 20,
        );
    final vPad = tileVerticalPadding ??
        Breakpoints.adaptiveDouble(
          context,
          phone: 6,
          largeTabletValue: 8,
          desktop: 8,
        );
    final bottomMargin = tileBottomMargin ??
        Breakpoints.adaptiveDouble(
          context,
          phone: 8,
          largeTabletValue: 10,
          desktop: 12,
        );

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.only(bottom: bottomMargin),
        color: n.isRead
            ? null
            : Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: vPad,
          ),
          leading: Icon(
            n.isRead ? Icons.notifications : Icons.notifications_active,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            n.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: Breakpoints.adaptiveDouble(
                    context,
                    phone: 15,
                    largeTabletValue: 16,
                    desktop: 16,
                  ),
                  fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w600,
                ),
          ),
          subtitle: Text(
            n.body,
            style: Breakpoints.supportingTextStyle(
              context,
              Theme.of(context).textTheme.bodyMedium,
              phone: 13,
              largeTabletValue: 14,
              desktop: 14,
              height: 1.35,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Obriši obaveštenje',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
              if (n.classifiedAdId != null)
                IconButton(
                  tooltip: 'Vidi oglas',
                  icon: const Icon(Icons.campaign_outlined),
                  onPressed: () =>
                      context.push('/classifieds/ad/${n.classifiedAdId}'),
                ),
              if (n.orderId != null)
                IconButton(
                  tooltip: 'Vidi porudžbinu',
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => context.go('/orders'),
                ),
            ],
          ),
          onTap: onTap ?? () => defaultOnTap(context, n),
        ),
      ),
    );
  }
}
