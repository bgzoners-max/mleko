import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent;
import 'package:url_launcher/url_launcher.dart';

import '../core/responsive.dart';
import '../models/notification_model.dart';
import '../providers/app_state.dart';
import 'package:mleko/services/services.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_retry.dart';
import '../widgets/notifications/notification_card.dart';
import '../widgets/notifications/notification_desktop_panel.dart';
import '../widgets/notifications/notification_quick_actions_card.dart';
import '../widgets/notifications/notification_settings_card.dart';
import '../widgets/skeleton.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  final _service = NotificationsService();
  late final StreamController<List<NotificationModel>> _notificationsController;
  StreamSubscription? _notifEventsSub;
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
    _notifEventsSub?.cancel();
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
    _notifEventsSub?.cancel();
    final appState = context.read<AppState>();
    _notifEventsSub = appState.notificationEvents.listen((payload) async {
      if (!mounted) return;
      if (payload.eventType == PostgresChangeEvent.insert) {
        await _loadAndMarkRead();
      } else if (payload.eventType == PostgresChangeEvent.update) {
        await _load();
      }
    });
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
                    unawaited(_loadAndMarkRead());
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
                  ? NotificationSettingsCard(padding: settingsCardPadding)
                  : null;
              final permissionBanner = !kIsWeb &&
                      Platform.isAndroid &&
                      _notificationPermissionGranted == false
                  ? const NotificationPermissionBanner()
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
                              NotificationQuickActionsCard(
                                totalCount: list.length,
                                onRefresh: _loadAndMarkRead,
                                onMarkAllAsRead: _markAllAsRead,
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
                        child: NotificationDesktopPanel(
                          list: list,
                          onDelete: (n) => _deleteNotification(n, list),
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
                        return NotificationCard(
                          notification: n,
                          onDelete: () => _deleteNotification(n, list),
                          tileHorizontalPadding: tileHorizontalPadding,
                          tileVerticalPadding: tileVerticalPadding,
                          tileBottomMargin: tileBottomMargin,
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
