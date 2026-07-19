import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/services.dart';

class AdminPushHealthScreen extends StatefulWidget {
  const AdminPushHealthScreen({super.key});

  @override
  State<AdminPushHealthScreen> createState() => _AdminPushHealthScreenState();
}

class _AdminPushHealthScreenState extends State<AdminPushHealthScreen> {
  final _service = PushHealthService();
  final _searchController = TextEditingController();

  PushHealthDashboardModel? _dashboard;
  List<PushHealthUserIssueModel>? _issues;
  bool _loading = true;
  String? _error;
  String _selectedHealthFilter = 'all';
  _IssueSort _sortBy = _IssueSort.latestNotificationDesc;

  static const _healthFilterOptions = [
    (value: 'all', label: 'Svi'),
    (value: 'missing_token', label: 'Nema token'),
    (value: 'stalled', label: 'Zastoj'),
    (value: 'error', label: 'Greška'),
    (value: 'partial', label: 'Delimično'),
    (value: 'no_tokens', label: 'Bez tokena'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchDashboard(),
        _service.fetchUserIssues(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as PushHealthDashboardModel;
        _issues = results[1] as List<PushHealthUserIssueModel>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFilterChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Push health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osveži',
            onPressed: _load,
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Greška: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _load, child: const Text('Pokušaj ponovo')),
            ],
          ),
        ),
      );
    }

    final dashboard = _dashboard;
    if (dashboard == null) {
      return const Center(child: Text('Nema podataka za push health.'));
    }

    final issues =
        _filteredAndSortedIssues(_issues ?? const <PushHealthUserIssueModel>[]);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHero(context, dashboard),
          if (_showHistoricalFailureHint(dashboard, issues)) ...[
            const SizedBox(height: 16),
            _buildHistoricalFailureHint(context, dashboard),
          ],
          const SizedBox(height: 16),
          _buildStatGrid(context, dashboard),
          const SizedBox(height: 16),
          _buildMetaCard(context, dashboard),
          const SizedBox(height: 16),
          _buildRetentionGuideCard(context),
          const SizedBox(height: 16),
          _buildIssuesSection(context, issues),
        ],
      ),
    );
  }

  Widget _buildStatusHero(
      BuildContext context, PushHealthDashboardModel dashboard) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = _healthColor(dashboard.health, colorScheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tone.withValues(alpha: 0.16),
              tone.withValues(alpha: 0.04)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _healthLabel(dashboard.health),
                    style: TextStyle(fontWeight: FontWeight.w700, color: tone),
                  ),
                ),
                Text(
                  'Uspešnost ${dashboard.successRatePct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pregled push pipeline-a iz admin aplikacije: konfiguracija, tok isporuke i korisnici sa aktivnim problemima.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(
      BuildContext context, PushHealthDashboardModel dashboard) {
    final items = [
      _StatItem('Tokeni', '${dashboard.totalTokens}', Icons.key_outlined),
      _StatItem('Korisnici sa tokenom', '${dashboard.usersWithTokens}',
          Icons.people_outline),
      _StatItem('Notifikacije 24h', '${dashboard.notifications24h}',
          Icons.notifications_outlined),
      _StatItem(
          'Isporuke 24h', '${dashboard.deliveries24h}', Icons.send_outlined),
      _StatItem('Uspešne', '${dashboard.successfulDeliveries24h}',
          Icons.check_circle_outline),
      _StatItem(
          'Neuspešne', '${dashboard.failedDeliveries24h}', Icons.error_outline),
      _StatItem('Novi tokeni 24h', '${dashboard.tokensCreated24h}',
          Icons.add_reaction_outlined),
      _StatItem(
          'Backlog',
          '${dashboard.deliveryBacklogMinutes.toStringAsFixed(1)} min',
          Icons.schedule_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 900
            ? 4
            : width >= 640
                ? 2
                : 1;

        return GridView.builder(
          itemCount: items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 3.6 : 2.2,
          ),
          itemBuilder: (context, index) =>
              _buildStatCard(context, items[index]),
        );
      },
    );
  }

  Widget _buildHistoricalFailureHint(
      BuildContext context, PushHealthDashboardModel dashboard) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nema aktivnog zastoja, ali postoje skoriji istorijski promašaji.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pipeline trenutno radi i backlog je ${dashboard.deliveryBacklogMinutes.toStringAsFixed(1)} min, ali dashboard ostaje degradiran dok u poslednja 24h postoje stari `error`, `partial` ili `no_tokens` logovi.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, _StatItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                        fontSize: 12, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(
      BuildContext context, PushHealthDashboardModel dashboard) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = [
      ('Edge config', dashboard.edgeConfigOk ? 'Ispravan' : 'Problem'),
      ('Anon key', dashboard.anonKeyPresent ? 'Prisutan' : 'Nedostaje'),
      ('Function URL', dashboard.functionsBaseUrl ?? 'Nije postavljen'),
      ('Poslednja notifikacija', _formatDateTime(dashboard.lastNotificationAt)),
      ('Poslednja isporuka', _formatDateTime(dashboard.lastDeliveryAt)),
      ('Osveženo', _formatDateTime(dashboard.checkedAt)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfiguracija i tok',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        row.$1,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionGuideCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rows = [
      (
        'Uspešni i bez tokena',
        'Čuvaj 30 dana. To je dovoljno za operativni pregled bez nepotrebnog gomilanja logova.'
      ),
      (
        'Delimični i neuspešni',
        'Čuvaj 90 dana, jer su korisni za analizu regresija, token churn-a i FCM grešaka.'
      ),
      (
        'Kad je dashboard degradiran',
        'Ako nema backloga ni aktivnih issue redova, degradacija je često samo istorijska i cleanup vraća realniju sliku.'
      ),
      (
        'SQL alati',
        'Koristi push_delivery_log_cleanup.sql za preview-delete pristup ili push_delivery_log_archive_cleanup.sql kada želiš arhivu pre brisanja.'
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retention vodič',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Preporučena pravila za održavanje push logova i tumačenje istorijskih problema.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.rule_folder_outlined,
                        size: 18, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.$1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.$2,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSection(
      BuildContext context, List<PushHealthUserIssueModel> issues) {
    final totalIssues = _issues?.length ?? 0;

    if (issues.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _buildIssueToolbar(context, totalIssues, issues.length),
              const SizedBox(height: 18),
              Icon(
                Icons.check_circle_outline,
                size: 42,
                color: Colors.green.shade600,
              ),
              const SizedBox(height: 10),
              const Text(
                'Nema aktivnih korisničkih push problema.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIssueToolbar(context, totalIssues, issues.length),
            const SizedBox(height: 12),
            ...issues.map((issue) => _buildIssueTile(context, issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(BuildContext context, PushHealthUserIssueModel issue) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = _healthColor(issue.health, colorScheme);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _shortId(issue.userId),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _healthLabel(issue.health),
                  style: TextStyle(
                      color: tone, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _IssueMeta('Tokena', '${issue.tokenCount}'),
              _IssueMeta('Notifikacije 7d', '${issue.notifications7d}'),
              _IssueMeta(
                  'Poslednji delivery', issue.latestDeliveryStatus ?? 'n/a'),
              _IssueMeta(
                  'Delivery greške', '${issue.latestDeliveryErrorCount}'),
              _IssueMeta(
                  'Poslednji token', _formatDateTime(issue.latestTokenAt)),
              _IssueMeta('Poslednja notifikacija',
                  _formatDateTime(issue.latestNotificationAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIssueToolbar(
      BuildContext context, int totalCount, int visibleCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Korisnici sa problemima',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Prikazano $visibleCount od $totalCount redova iz view-a push_health_user_issues.',
          style:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pretraga po user ID-u ili statusu',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Obriši pretragu',
                    onPressed: () => _searchController.clear(),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._healthFilterOptions.map(
              (option) => FilterChip(
                label: Text(option.label),
                selected: _selectedHealthFilter == option.value,
                onSelected: (_) {
                  setState(() => _selectedHealthFilter = option.value);
                },
              ),
            ),
            PopupMenuButton<_IssueSort>(
              initialValue: _sortBy,
              tooltip: 'Sortiranje',
              onSelected: (value) => setState(() => _sortBy = value),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _IssueSort.latestNotificationDesc,
                  child: Text('Sortiraj: poslednja notifikacija'),
                ),
                PopupMenuItem(
                  value: _IssueSort.latestDeliveryDesc,
                  child: Text('Sortiraj: poslednji delivery'),
                ),
                PopupMenuItem(
                  value: _IssueSort.tokenCountAsc,
                  child: Text('Sortiraj: najmanje tokena'),
                ),
                PopupMenuItem(
                  value: _IssueSort.errorCountDesc,
                  child: Text('Sortiraj: najviše grešaka'),
                ),
                PopupMenuItem(
                  value: _IssueSort.healthSeverity,
                  child: Text('Sortiraj: ozbiljnost'),
                ),
              ],
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 18),
                      const SizedBox(width: 8),
                      Text(_sortLabel(_sortBy)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<PushHealthUserIssueModel> _filteredAndSortedIssues(
      List<PushHealthUserIssueModel> issues) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = issues.where((issue) {
      final matchesFilter = _selectedHealthFilter == 'all' ||
          issue.health == _selectedHealthFilter;
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;
      return issue.userId.toLowerCase().contains(query) ||
          issue.health.toLowerCase().contains(query) ||
          (issue.latestDeliveryStatus?.toLowerCase().contains(query) ?? false);
    }).toList();

    final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
    filtered.sort((left, right) {
      return switch (_sortBy) {
        _IssueSort.latestNotificationDesc =>
          (right.latestNotificationAt ?? epoch)
              .compareTo(left.latestNotificationAt ?? epoch),
        _IssueSort.latestDeliveryDesc => (right.latestDeliveryAt ?? epoch)
            .compareTo(left.latestDeliveryAt ?? epoch),
        _IssueSort.tokenCountAsc => left.tokenCount.compareTo(right.tokenCount),
        _IssueSort.errorCountDesc => right.latestDeliveryErrorCount
            .compareTo(left.latestDeliveryErrorCount),
        _IssueSort.healthSeverity =>
          _healthSeverity(right.health).compareTo(_healthSeverity(left.health)),
      };
    });

    return filtered;
  }

  int _healthSeverity(String health) {
    return switch (health) {
      'misconfigured' => 6,
      'stalled' => 5,
      'error' => 4,
      'missing_token' => 3,
      'no_tokens' => 3,
      'partial' => 2,
      'degraded' => 1,
      _ => 0,
    };
  }

  Color _healthColor(String health, ColorScheme colorScheme) {
    return switch (health) {
      'ok' => Colors.green.shade700,
      'degraded' => Colors.orange.shade700,
      'stalled' => Colors.deepOrange.shade700,
      'missing_token' => Colors.red.shade700,
      'misconfigured' => colorScheme.error,
      'error' => colorScheme.error,
      'partial' => Colors.orange.shade700,
      'no_tokens' => Colors.red.shade700,
      'invalid_request' => colorScheme.error,
      _ => colorScheme.primary,
    };
  }

  String _healthLabel(String health) {
    return switch (health) {
      'ok' => 'OK',
      'degraded' => 'Degradirano',
      'stalled' => 'Zastoj',
      'missing_token' => 'Nema token',
      'misconfigured' => 'Loša konfiguracija',
      'error' => 'Greška',
      'partial' => 'Delimično',
      'no_tokens' => 'Bez tokena',
      'invalid_request' => 'Neispravan zahtev',
      _ => health,
    };
  }

  String _sortLabel(_IssueSort sort) {
    return switch (sort) {
      _IssueSort.latestNotificationDesc => 'Poslednja notifikacija',
      _IssueSort.latestDeliveryDesc => 'Poslednji delivery',
      _IssueSort.tokenCountAsc => 'Najmanje tokena',
      _IssueSort.errorCountDesc => 'Najviše grešaka',
      _IssueSort.healthSeverity => 'Ozbiljnost',
    };
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'n/a';
    return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
  }

  String _shortId(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
  }

  bool _showHistoricalFailureHint(
    PushHealthDashboardModel dashboard,
    List<PushHealthUserIssueModel> issues,
  ) {
    return issues.isEmpty &&
        dashboard.health == 'degraded' &&
        dashboard.deliveryBacklogMinutes <= 0.0 &&
        dashboard.failedDeliveries24h > 0;
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem(this.label, this.value, this.icon);
}

class _IssueMeta extends StatelessWidget {
  final String label;
  final String value;

  const _IssueMeta(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

enum _IssueSort {
  latestNotificationDesc,
  latestDeliveryDesc,
  tokenCountAsc,
  errorCountDesc,
  healthSeverity,
}
