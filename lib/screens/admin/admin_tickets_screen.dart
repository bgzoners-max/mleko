import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/services.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final _service = SupportService();
  final _db = Supabase.instance.client;

  String? _statusFilter;
  List<SupportTicketModel>? _tickets;
  bool _loading = true;
  String? _error;

  _DashboardStats? _stats;
  bool _statsLoading = true;

  static const _statusOptions = [
    (value: null, label: 'Svi'),
    (value: 'otvoren', label: 'Otvoreni'),
    (value: 'u_obradi', label: 'U obradi'),
    (value: 'zatvoren', label: 'Zatvoreni'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _loadStats();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tickets = await _service.fetchAllTickets(status: _statusFilter);
      if (mounted) setState(() => _tickets = tickets);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final results = await Future.wait([
        _db.from('public_profiles').count(CountOption.exact).eq('is_guest', false),
        _db.from('public_profiles').count(CountOption.exact).eq('role', 'seller').eq('is_guest', false),
        _db.from('public_profiles').count(CountOption.exact).eq('role', 'buyer').eq('is_guest', false),
        _db.from('waitlist').count(CountOption.exact),
        _db.from('orders').count(CountOption.exact),
        _db.from('orders').count(CountOption.exact).eq('status', 'pending'),
      ]);
      if (mounted) {
        setState(() {
          _stats = _DashboardStats(
            totalMembers: results[0],
            sellers: results[1],
            buyers: results[2],
            waitlist: results[3],
            totalOrders: results[4],
            pendingOrders: results[5],
          );
        });
      }
    } catch (_) {
      // Stats su informativni — tiho ignorišemo grešku
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Color _statusColor(TicketStatus status) {
    return switch (status) {
      TicketStatus.otvoren => Colors.orange,
      TicketStatus.uObradi => Colors.blue,
      TicketStatus.zatvoren => Colors.green,
    };
  }

  IconData _categoryIcon(SupportCategory cat) {
    return switch (cat) {
      SupportCategory.bug => Icons.bug_report_outlined,
      SupportCategory.pitanje => Icons.help_outline,
      SupportCategory.sugestija => Icons.lightbulb_outline,
      SupportCategory.ostalo => Icons.inbox_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Pregled'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Push health',
            onPressed: () => context.push('/admin/push-health'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osveži',
            onPressed: () {
              _load();
              _loadStats();
            },
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              _buildDashboard(),
              _buildFilterBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pregled', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
          const SizedBox(height: 8),
          if (_statsLoading)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else if (_stats != null) ...[
            Row(children: [
              _StatCard(label: 'Članovi', value: _stats!.totalMembers, icon: Icons.people_outline, color: Colors.indigo),
              const SizedBox(width: 8),
              _StatCard(label: 'Prodavci', value: _stats!.sellers, icon: Icons.storefront_outlined, color: Colors.teal, onTap: () => _showUserList('seller', 'Prodavci')),
              const SizedBox(width: 8),
              _StatCard(label: 'Kupci', value: _stats!.buyers, icon: Icons.person_outline, color: Colors.blue, onTap: () => _showUserList('buyer', 'Kupci')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _StatCard(label: 'Waitlist', value: _stats!.waitlist, icon: Icons.mark_email_unread_outlined, color: Colors.deepPurple, onTap: _showWaitlist),
              const SizedBox(width: 8),
              _StatCard(label: 'Narudžbine', value: _stats!.totalOrders, icon: Icons.receipt_long_outlined, color: Colors.orange),
              const SizedBox(width: 8),
              _StatCard(label: 'Na čekanju', value: _stats!.pendingOrders, icon: Icons.hourglass_empty_outlined, color: Colors.amber),
            ]),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 4),
          Text('Tiketi podrške', style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final selected = _statusFilter == opt.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(opt.label),
                selected: selected,
                onSelected: (_) {
                  setState(() => _statusFilter = opt.value);
                  _load();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Greška: $_error'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }
    final tickets = _tickets ?? [];
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 56, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 12),
            const Text('Nema tiketa'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _buildTicketCard(tickets[i]),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    final statusColor = _statusColor(ticket.status);
    final hasReply = ticket.adminNote != null && ticket.adminNote!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/admin/tickets/${ticket.id}');
          unawaited(_load());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon(ticket.category),
                      size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    ticket.ticketNumber,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '·',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket.userName ?? ticket.userEmail ?? 'Anonimno',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (hasReply)
                    Icon(Icons.reply, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month}.${dt.year}';
  }

  Future<void> _showUserList(String role, String title) async {
    final res = await _db
        .from('public_profiles')
        .select('id, display_name, farm_name, email, city, created_at')
        .eq('role', role)
        .eq('is_guest', false)
        .order('created_at', ascending: false);

    final users = res as List<dynamic>;

    if (!mounted) return;
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${users.length}', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: users.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final u = users[i] as Map<String, dynamic>;
                  final name = (u['farm_name'] ?? u['display_name'] ?? 'Bez imena') as String;
                  final email = u['email'] as String?;
                  final city = u['city'] as String?;
                  final createdAt = u['created_at'] != null
                      ? DateTime.tryParse(u['created_at'] as String)
                      : null;
                  return ListTile(
                    dense: true,
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text([
                      if (email != null) email,
                      if (city != null) city,
                    ].join(' · ')),
                    trailing: createdAt != null
                        ? Text(
                            '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                            style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.outlineVariant),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _showWaitlist() async {
    final res = await _db
        .from('waitlist')
        .select('email, created_at')
        .order('created_at', ascending: false);

    final entries = res as List<dynamic>;

    if (!mounted) return;
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('Waitlist', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${entries.length}', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: controller,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                itemBuilder: (_, i) {
                  final e = entries[i] as Map<String, dynamic>;
                  final email = e['email'] as String? ?? '';
                  final createdAt = e['created_at'] != null
                      ? DateTime.tryParse(e['created_at'] as String)
                      : null;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.email_outlined, size: 18),
                    title: Text(email),
                    trailing: createdAt != null
                        ? Text(
                            '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                            style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.outlineVariant),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _DashboardStats {
  final int totalMembers;
  final int sellers;
  final int buyers;
  final int waitlist;
  final int totalOrders;
  final int pendingOrders;

  const _DashboardStats({
    required this.totalMembers,
    required this.sellers,
    required this.buyers,
    required this.waitlist,
    required this.totalOrders,
    required this.pendingOrders,
  });
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap != null ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
