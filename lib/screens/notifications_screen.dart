import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/app_state.dart';
import '../services/notifications_service.dart';
import '../services/push_service.dart';
import '../widgets/app_error_retry.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();
  Future<List<NotificationModel>>? _notificationsFuture;
  String? _lastUserId;
  bool? _notificationPermissionGranted;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isAndroid) {
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
      _notificationsFuture = _service.getNotifications(user.id);
    }
    if (!kIsWeb && Platform.isAndroid && _notificationPermissionGranted == null) {
      Permission.notification.status.then((s) {
        if (mounted) setState(() => _notificationPermissionGranted = s.isGranted);
      });
    }
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
                    setState(() => _notificationsFuture = _service.getNotifications(user.id));
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
      body: FutureBuilder<List<NotificationModel>>(
        future: _notificationsFuture,
        builder: (context, snap) {
          if (snap.hasError) {
            return AppErrorRetry(
              message: 'Greška pri učitavanju obaveštenja.',
              detail: snap.error?.toString(),
              onRetry: () => setState(() => _notificationsFuture = _service.getNotifications(user.id)),
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
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Nemate obaveštenja', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
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
                        await _service.deleteNotification(n.id);
                        if (context.mounted) {
                          setState(() => _notificationsFuture = _service.getNotifications(user.id));
                        }
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
                                  await _service.deleteNotification(n.id);
                                  if (context.mounted) {
                                    setState(() => _notificationsFuture = _service.getNotifications(user.id));
                                  }
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
