import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase, PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType, RealtimeChannel;
import '../models/notification_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';

import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
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
        if (mounted) setState(() => _notificationPermissionGranted = s.isGranted);
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
        if (mounted) setState(() => _notificationPermissionGranted = s.isGranted);
      });
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
    if (!kIsWeb && Platform.isAndroid && _notificationPermissionGranted == null) {
      Permission.notification.status.then((s) {
        if (mounted) setState(() => _notificationPermissionGranted = s.isGranted);
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
        .subscribe();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Obaveštenja'),
        actions: [
          if (!kIsWeb && Platform.isAndroid && _notificationPermissionGranted == false)
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Označeno kao pročitano.')));
                }
              } else if (value == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Obriši sva obaveštenja?'),
                    content: const Text('Sva obaveštenja će biti trajno obrisana.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Odustani'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Obriši sve'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await _service.deleteAllNotifications(user.id);
                  if (context.mounted) {
                    _loadAndMarkRead();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obaveštenja obrisana.')));
                  }
                }
              } else if (value == 'battery') {
                await PushService.requestIgnoreBatteryOptimizations();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Izaberite "Ne ograničavaj" za Naše Selo.')),
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
                const PopupMenuItem(value: 'battery', child: Text('Optimizacija baterije (Xiaomi, Huawei...)')),
                const PopupMenuItem(value: 'help', child: Text('Pomoć: obaveštenja ne stižu')),
              ],
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationsController.stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju obaveštenja.',
              detail: snap.error?.toString(),
              onRetry: _loadAndMarkRead,
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          final settingsCard = (!kIsWeb && Platform.isAndroid)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Podešavanja push obaveštenja',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null;
          final permissionBanner = !kIsWeb && Platform.isAndroid && _notificationPermissionGranted == false
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Colors.amber.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.notifications_off),
                      title: const Text('Obaveštenja su isključena'),
                      subtitle: const Text('Dozvolite obaveštenja u podešavanjima da primate push obaveštenja.'),
                      trailing: TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('Podešavanja'),
                      ),
                    ),
                  ),
                )
              : null;
          if (list.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (settingsCard != null) settingsCard,
                if (permissionBanner != null) permissionBanner,
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
              if (settingsCard != null) settingsCard,
              if (permissionBanner != null) permissionBanner,
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                        child: const Icon(Icons.delete, color: Colors.white, size: 28),
                      ),
                      confirmDismiss: (_) async => true,
                      onDismissed: (_) async {
                        // Optimistički ukloni iz liste i ažuriraje badge
                        final removedWasUnread = !n.isRead;
                        final currentList = List<NotificationModel>.from(list);
                        currentList.removeWhere((item) => item.id == n.id);
                        if (!_notificationsController.isClosed) {
                          _notificationsController.add(currentList);
                        }
                        if (removedWasUnread && context.mounted) {
                          context.read<AppState>().decrementUnreadCount();
                        }
                        // Pokreni delete na serveru u backgroundu
                        unawaited(_service.deleteNotification(n.id));
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: n.isRead ? null : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        child: ListTile(
                          leading: Icon(n.isRead ? Icons.notifications : Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
                          title: Text(n.title),
                          subtitle: Text(n.body),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  // Optimistički ukloni iz liste
                                  final wasUnread = !n.isRead;
                                  final currentList = List<NotificationModel>.from(list);
                                  currentList.removeWhere((item) => item.id == n.id);
                                  if (!_notificationsController.isClosed) {
                                    _notificationsController.add(currentList);
                                  }
                                  if (wasUnread && context.mounted) {
                                    context.read<AppState>().decrementUnreadCount();
                                  }
                                  // Pokreni delete na serveru u backgroundu
                                  unawaited(_service.deleteNotification(n.id));
                                },
                              ),
                              if (n.orderId != null)
                                IconButton(
                                  icon: const Icon(Icons.receipt_long),
                                  onPressed: () => context.go('/orders'),
                                ),
                            ],
                          ),
                          onTap: () async {
                            if (!n.isRead) await _service.markAsRead(n.id);
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
    );
  }
}

