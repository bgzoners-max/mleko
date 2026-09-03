import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        Supabase,
        PostgresChangeEvent,
        PostgresChangeFilter,
        PostgresChangeFilterType,
        RealtimeChannel;
import '../models/notification_model.dart';
import '../core/notification_types.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/skeleton.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final _service = NotificationsService();
  late final StreamController<List<NotificationModel>> _notificationsController;
  RealtimeChannel? _realtimeChannel;
  String? _lastUserId;
  bool? _notificationPermissionGranted;

  @override
  void initState() {
    super.initState();
    _notificationsController = StreamController.broadcast();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && Platform.isAndroid) {
      Permission.notification.status.then((s) {
        if (mounted) {
          setState(() => _notificationPermissionGranted = s.isGranted);
        }
      });
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _notificationsController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb && Platform.isAndroid) {
      Permission.notification.status.then((s) {
        if (mounted) {
          setState(() => _notificationPermissionGranted = s.isGranted);
        }
      });
    }
  }

  Future<void> _deleteNotification(
      NotificationModel n, List<NotificationModel> list) async {
    final wasUnread = !n.isRead;
    final originalIndex = list.indexWhere((item) => item.id == n.id);
    final optimistic = List<NotificationModel>.from(list)
      ..removeWhere((item) => item.id == n.id);
    if (!_notificationsController.isClosed) {
      _notificationsController.add(optimistic);
    }
    if (wasUnread && mounted) {
      context.read<AppState>().decrementUnreadCount();
    }
    try {
      await _service.deleteNotification(n.id);
    } catch (_) {
      // Rollback — vrati notifikaciju na originalnu poziciju
      final restored = List<NotificationModel>.from(optimistic);
      final insertAt = originalIndex.clamp(0, restored.length);
      restored.insert(insertAt, n);
      if (!_notificationsController.isClosed) {
        _notificationsController.add(restored);
      }
      if (wasUnread && mounted) {
        context.read<AppState>().incrementUnreadCount();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Greška pri brisanju obaveštenja.')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && !user.isGuest && user.id != _lastUserId) {
      _lastUserId = user.id;
      _loadAndMarkRead();
      _subscribeRealtime(user.id);
    }
    if (!kIsWeb &&
        Platform.isAndroid &&
        _notificationPermissionGranted == null) {
      Permission.notification.status.then((s) {
        if (mounted) {
          setState(() => _notificationPermissionGranted = s.isGranted);
        }
      });
    }
  }

  Future<void> _load() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;
    final notifs = await _service.getNotifications(user.id);
    if (!_notificationsController.isClosed) {
      _notificationsController.add(notifs);
    }
  }

  Future<void> _markAllAsRead() async {
    final user = context.read<AppState>().user;
    if (user == null || user.isGuest) return;
    await _service.markAllAsRead(user.id);
    if (mounted) {
      context.read<AppState>().resetUnreadCount();
    }
  }

  Future<void> _loadAndMarkRead() async {
    await _load();
    await _markAllAsRead();
  }

  void _subscribeRealtime(String userId) {
    _realtimeChannel?.unsubscribe();
    final client = Supabase.instance.client;
    _realtimeChannel = client
        .channel('notifications-insert-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) async {
            await _loadAndMarkRead();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) async {
            await _load();
          },
        )
        .subscribe();
  }

  Widget _buildQuickActionsCard(
    BuildContext context, {
    required int totalCount,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(Breakpoints.cardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Brze radnje',
              style: Breakpoints.sectionTitleStyle(
                context,
                Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ukupno obaveštenja: $totalCount',
              style: Breakpoints.supportingTextStyle(
                context,
                Theme.of(context).textTheme.bodyMedium,
                phone: 13,
                largeTabletValue: 14,
                desktop: 14,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _loadAndMarkRead,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Osveži'),
                ),
                OutlinedButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Pročitaj sve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, double settingsCardPadding) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(settingsCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Podešavanja push obaveštenja',
              style: Breakpoints.sectionTitleStyle(
                context,
                Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings, size: 20),
              label: const Text('Otvori podešavanja obaveštenja'),
            ),
            const SizedBox(height: 12),
            Text(
              'Na Xiaomi/HyperOS: uključi Pop-up i Zvuk za oba kanala (Porudžbine i Hitno), jer Xiaomi ume da jedan ostavi silent.',
              style: Breakpoints.supportingTextStyle(
                context,
                Theme.of(context).textTheme.bodySmall,
                phone: 13,
                largeTabletValue: 14,
                desktop: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context) {
    return Card(
      color: Colors.amber.shade100,
      child: const ListTile(
        leading: Icon(Icons.notifications_off),
        title: Text('Obaveštenja su isključena'),
        subtitle: Text(
          'Dozvolite obaveštenja u podešavanjima da primate push obaveštenja.',
        ),
        trailing: TextButton(
          onPressed: openAppSettings,
          child: Text('Podešavanja'),
        ),
      ),
    );
  }

  Widget _buildDesktopNotificationsPanel(
    BuildContext context, {
    required List<NotificationModel> list,
    required double tileVerticalPadding,
    required double tileHorizontalPadding,
    required double tileBottomMargin,
  }) {
    final panelPadding = Breakpoints.cardPadding(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              panelPadding,
              panelPadding,
              panelPadding,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sva obaveštenja',
                    style: Breakpoints.sectionTitleStyle(
                      context,
                      Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '${list.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: AppEmptyState(
                      icon: Icons.notifications_none,
                      title: 'Nemate obaveštenja',
                      subtitle:
                          'Ovde će se prikazivati porudžbine, poruke i ostala obaveštenja.',
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(panelPadding),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final n = list[i];
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
                        onDismissed: (_) => _deleteNotification(n, list),
                        child: Card(
                          margin: EdgeInsets.only(bottom: tileBottomMargin),
                          color: n.isRead
                              ? null
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: tileHorizontalPadding,
                              vertical: tileVerticalPadding,
                            ),
                            leading: Icon(
                              n.isRead
                                  ? Icons.notifications
                                  : Icons.notifications_active,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(
                              n.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontSize: Breakpoints.adaptiveDouble(
                                      context,
                                      phone: 15,
                                      largeTabletValue: 16,
                                      desktop: 16,
                                    ),
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
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
                                  onPressed: () => _deleteNotification(n, list),
                                ),
                                if (n.orderId != null)
                                  IconButton(
                                    tooltip: 'Vidi porudžbinu',
                                    icon: const Icon(Icons.receipt_long),
                                    onPressed: () => context.go('/orders'),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              if (!n.isRead) await _service.markAsRead(n.id);
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
                              } else if (n.orderId != null || notificationTypeIsOrderRelated(n.type)) {
                                context.go('/orders');
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Obaveštenja')),
        body: const Center(child: Text('Prijavite se da vidite obaveštenja.')),
      );
    }

    final isTwoPaneLayout = Breakpoints.useTwoPaneLayout(context);
    final contentPadding = Breakpoints.horizontalPadding(context);
    final settingsCardPadding = Breakpoints.cardPadding(context);
    final panelGap = Breakpoints.panelGap(context);
    final tileHorizontalPadding = Breakpoints.adaptiveDouble(
      context,
      phone: 16,
      largeTabletValue: 18,
      desktop: 20,
    );
    final tileVerticalPadding = Breakpoints.adaptiveDouble(
      context,
      phone: 6,
      largeTabletValue: 8,
      desktop: 8,
    );
    final tileBottomMargin = Breakpoints.adaptiveDouble(
      context,
      phone: 8,
      largeTabletValue: 10,
      desktop: 12,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obaveštenja'),
        actions: [
          if (!kIsWeb &&
              Platform.isAndroid &&
              _notificationPermissionGranted == false)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Omogući obaveštenja',
              onPressed: () => openAppSettings(),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'read') {
                await _service.markAllAsRead(user.id);
                if (context.mounted) {
                  context.read<AppState>().resetUnreadCount();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Označeno kao pročitano.')));
                }
              } else if (value == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Obriši sva obaveštenja?'),
                    content:
                        const Text('Sva obaveštenja će biti trajno obrisana.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Odustani'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Obriši sve'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await _service.deleteAllNotifications(user.id);
                  if (context.mounted) {
                    _loadAndMarkRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Obaveštenja obrisana.')));
                  }
                }
              } else if (value == 'battery') {
                await PushService.requestIgnoreBatteryOptimizations();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Izaberite "Ne ograničavaj" za Domaći market.')),
                  );
                }
              } else if (value == 'help') {
                await launchUrl(Uri.parse('https://dontkillmyapp.com'));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'read', child: Text('Pročitaj sve')),
              const PopupMenuItem(value: 'delete', child: Text('Obriši sve')),
              if (!kIsWeb && Platform.isAndroid) ...[
                const PopupMenuItem(
                    value: 'battery',
                    child: Text('Optimizacija baterije (Xiaomi, Huawei...)')),
                const PopupMenuItem(
                    value: 'help', child: Text('Pomoć: obaveštenja ne stižu')),
              ],
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTwoPaneLayout
                ? Breakpoints.dataContentWidth(context)
                : Breakpoints.maxContentWidth(context),
          ),
          child: StreamBuilder<List<NotificationModel>>(
            stream: _notificationsController.stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return AppErrorRetry(
                  message: 'Greška pri učitavanju obaveštenja.',
                  detail: snap.error?.toString(),
                  onRetry: _loadAndMarkRead,
                );
              }
              if (!snap.hasData) return const NotificationListSkeleton();
              final list = snap.data!;
              final settingsCard = (!kIsWeb && Platform.isAndroid)
                  ? _buildSettingsCard(context, settingsCardPadding)
                  : null;
              final permissionBanner = !kIsWeb &&
                      Platform.isAndroid &&
                      _notificationPermissionGranted == false
                  ? _buildPermissionBanner(context)
                  : null;
              if (isTwoPaneLayout) {
                return Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: Breakpoints.desktopSidebarWidth(context),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildQuickActionsCard(
                                context,
                                totalCount: list.length,
                              ),
                              if (permissionBanner != null) ...[
                                SizedBox(height: panelGap),
                                permissionBanner,
                              ],
                              if (settingsCard != null) ...[
                                SizedBox(height: panelGap),
                                settingsCard,
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: panelGap),
                      Expanded(
                        child: _buildDesktopNotificationsPanel(
                          context,
                          list: list,
                          tileVerticalPadding: tileVerticalPadding,
                          tileHorizontalPadding: tileHorizontalPadding,
                          tileBottomMargin: tileBottomMargin,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (list.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (settingsCard != null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          contentPadding,
                          contentPadding,
                          0,
                        ),
                        child: settingsCard,
                      ),
                    if (permissionBanner != null)
                      Padding(
                        padding: EdgeInsets.all(contentPadding),
                        child: permissionBanner,
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Možeš ih označiti kao pročitana, obrisati ili otvoriti direktno iz porudžbine ili podrške.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Expanded(
                      child: AppEmptyState(
                        icon: Icons.notifications_none,
                        title: 'Nemate obaveštenja',
                        subtitle:
                            'Ovde će se prikazivati porudžbine, poruke i ostala obaveštenja.',
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (settingsCard != null)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        contentPadding,
                        contentPadding,
                        contentPadding,
                        0,
                      ),
                      child: settingsCard,
                    ),
                  if (permissionBanner != null)
                    Padding(
                      padding: EdgeInsets.all(contentPadding),
                      child: permissionBanner,
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: contentPadding),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pritisni obaveštenje da otvoriš povezani sadržaj. Možeš ih i označiti kao pročitana ili obrisati.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(contentPadding),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final n = list[i];
                        return Dismissible(
                          key: Key(n.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete,
                                color: Colors.white, size: 28),
                          ),
                          confirmDismiss: (_) async => true,
                          onDismissed: (_) => _deleteNotification(n, list),
                          child: Card(
                            margin: EdgeInsets.only(bottom: tileBottomMargin),
                            color: n.isRead
                                ? null
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: tileHorizontalPadding,
                                vertical: tileVerticalPadding,
                              ),
                              leading: Icon(
                                  n.isRead
                                      ? Icons.notifications
                                      : Icons.notifications_active,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(
                                n.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontSize: Breakpoints.adaptiveDouble(
                                        context,
                                        phone: 15,
                                        largeTabletValue: 16,
                                        desktop: 16,
                                      ),
                                      fontWeight: n.isRead
                                          ? FontWeight.w500
                                          : FontWeight.w600,
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
                                    onPressed: () =>
                                        _deleteNotification(n, list),
                                  ),
                                  if (n.orderId != null)
                                    IconButton(
                                      tooltip: 'Vidi porudžbinu',
                                      icon: const Icon(Icons.receipt_long),
                                      onPressed: () => context.go('/orders'),
                                    ),
                                ],
                              ),
                              onTap: () async {
                                if (!n.isRead) await _service.markAsRead(n.id);
                                if (!context.mounted) return;
                                if (n.type == 'support_ticket_created') {
                                  context.go('/admin/tickets');
                                } else if (n.type == 'admin_reply') {
                                  if (n.ticketId != null) {
                                    context.go('/support/ticket/${n.ticketId}');
                                  } else {
                                    context.go('/support');
                                  }
                                } else if (n.orderId != null) {
                                  context.go('/orders');
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
