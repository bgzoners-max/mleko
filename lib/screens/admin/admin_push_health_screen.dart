import 'package:flutter/material.dart';
import '../../services/services.dart';
import '../../widgets/app_back_button.dart';
import '../../widgets/admin/push_health_cards.dart';
import '../../widgets/admin/push_health_issues.dart';

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
  IssueSort _sortBy = IssueSort.latestNotificationDesc;


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
        leading: const AppBackButton(fallbackRoute: '/admin/tickets'),
        title: const Text('Admin — Push health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Osveži',
            onPressed: _load,
          ),
          const AppHomeButton(),
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

    final issues = filterPushHealthIssues(
      _issues ?? const <PushHealthUserIssueModel>[],
      query: _searchController.text,
      healthFilter: _selectedHealthFilter,
      sortBy: _sortBy,
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          pushHealthStatusHero(context, dashboard),
          if (ClassifiedsService.totalRpcFailures > 0) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Oglasi telemetrija: ${ClassifiedsService.totalRpcFailures} neuspelih RPC poziva',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pregledi: ${ClassifiedsService.failedViewsRpcCount}, Interakcije: ${ClassifiedsService.failedInteractionsRpcCount}. Moguća greška u bazi, RLS-u ili RPC definiciji.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onErrorContainer,
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
          if (_showHistoricalFailureHint(dashboard, issues)) ...[
            const SizedBox(height: 16),
            pushHealthHistoricalFailureHint(context, dashboard),
          ],
          const SizedBox(height: 16),
          pushHealthStatGrid(context, dashboard),
          const SizedBox(height: 16),
          pushHealthMetaCard(context, dashboard),
          const SizedBox(height: 16),
          pushHealthRetentionGuideCard(context),
          const SizedBox(height: 16),
          pushHealthIssuesSection(
            context,
            issues: issues,
            totalIssues: _issues?.length ?? 0,
            searchController: _searchController,
            selectedHealthFilter: _selectedHealthFilter,
            sortBy: _sortBy,
            onFilterChanged: (v) => setState(() => _selectedHealthFilter = v),
            onSortChanged: (v) => setState(() => _sortBy = v),
          ),
        ],
      ),
    );
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
