import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/classified_report_model.dart';
import '../../services/classifieds/classified_reports_service.dart';
import '../../core/responsive.dart';

class ClassifiedsModerationScreen extends StatefulWidget {
  const ClassifiedsModerationScreen({
    super.key,
    this.reportsService,
  });

  final ClassifiedReportsService? reportsService;

  @override
  State<ClassifiedsModerationScreen> createState() =>
      _ClassifiedsModerationScreenState();
}

class _ClassifiedsModerationScreenState extends State<ClassifiedsModerationScreen>
    with SingleTickerProviderStateMixin {
  late final ClassifiedReportsService _reportsService;
  late final TabController _tabController;

  List<ClassifiedAdReportModel> _reports = [];
  bool _loading = true;
  String? _error;
  String? _selectedReason;
  String _searchQuery = '';

  int _pendingCount = 0;
  int _removedCount = 0;
  int _reviewedCount = 0;

  static const _tabs = [
    (status: 'pending', label: 'Na čekanju', icon: Icons.hourglass_top_rounded),
    (status: 'ad_removed', label: 'Uklonjeni', icon: Icons.block_rounded),
    (status: 'reviewed', label: 'Pregledani', icon: Icons.verified_rounded),
    (status: null, label: 'Sve prijave', icon: Icons.list_alt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _reportsService = widget.reportsService ?? ClassifiedReportsService();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadReports();
      }
    });
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? get _currentStatusFilter => _tabs[_tabController.index].status;

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = _currentStatusFilter;
      final reports = await _reportsService.getModerationReports(
        status: status,
        reason: _selectedReason,
      );

      // Prebrojavanje za KPI kartice
      int pending = 0;
      int removed = 0;
      int reviewed = 0;

      // Ako imamo sve, izračunaj tačno, inače pozovi pending count
      final allReports = status == null
          ? reports
          : await _reportsService.getModerationReports();
      for (final r in allReports) {
        if (r.isPending) pending++;
        if (r.isAdRemoved) removed++;
        if (r.isReviewed) reviewed++;
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _pendingCount = pending;
          _removedCount = removed;
          _reviewedCount = reviewed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Greška pri učitavanju prijava: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ClassifiedAdReportModel> get _filteredReports {
    if (_searchQuery.trim().isEmpty) return _reports;
    final q = _searchQuery.trim().toLowerCase();
    return _reports.where((r) {
      final titleMatch = (r.adTitle ?? '').toLowerCase().contains(q);
      final detailsMatch = (r.details ?? '').toLowerCase().contains(q);
      final reporterMatch = (r.reporterName ?? '').toLowerCase().contains(q);
      return titleMatch || detailsMatch || reporterMatch;
    }).toList();
  }

  Future<void> _handleModerateAction({
    required ClassifiedAdReportModel report,
    required String action,
    String? note,
  }) async {
    try {
      final success = await _reportsService.moderateReport(
        reportId: report.id,
        adId: report.adId,
        action: action,
        note: note,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'deactivate_ad'
                  ? 'Oglas je uspešno uklonjen, a oglašivač je obavešten.'
                  : action == 'dismiss'
                      ? 'Prijava je odbačena.'
                      : 'Prijava je označena kao pregledana.',
            ),
            backgroundColor: action == 'deactivate_ad'
                ? Colors.red.shade700
                : Colors.green.shade700,
          ),
        );
        unawaited(_loadReports());
      } else {
        throw Exception('Server nije potvrdio moderatorsku akciju.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showDeactivateDialog(ClassifiedAdReportModel report) {
    final noteController = TextEditingController(
      text:
          'Vaš oglas "${report.adTitle ?? ''}" je uklonjen iz pretrage jer krši pravila i bezbednosne smernice platforme.',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Ukloni oglas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Oglas "${report.adTitle ?? report.adId}" biće deaktiviran i označen kao odbijen.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Poruka oglašivaču (notifikacija):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Unesite obrazloženje za uklanjanje oglasa...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Odustani'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleModerateAction(
                report: report,
                action: 'deactivate_ad',
                note: noteController.text.trim(),
              );
            },
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Ukloni oglas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderacija oglasa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Osveži',
            onPressed: _loadReports,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) {
            return Tab(
              icon: Icon(t.icon, size: 18),
              text: t.label,
            );
          }).toList(),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context),
          ),
          child: Column(
            children: [
              // KPI statistike
              _buildKpiSection(colorScheme),

              // Search & Filter po razlogu
              _buildFilterBar(colorScheme),

              // Lista prijava
              Expanded(
                child: _buildBody(colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              title: 'Na čekanju',
              count: _pendingCount,
              icon: Icons.pending_actions_rounded,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              title: 'Uklonjeni',
              count: _removedCount,
              icon: Icons.remove_circle_outline_rounded,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              title: 'Pregledani',
              count: _reviewedCount,
              icon: Icons.check_circle_outline_rounded,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          // Pretraga
          TextField(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Pretraži po naslovu oglasa ili korisniku...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 6),

          // Filter po razlozima
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Svi razlozi'),
                  selected: _selectedReason == null,
                  onSelected: (_) {
                    setState(() => _selectedReason = null);
                    _loadReports();
                  },
                ),
                const SizedBox(width: 6),
                ...ClassifiedReportReason.all.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: Icon(
                        ClassifiedReportReason.iconFor(reason),
                        size: 16,
                      ),
                      label: Text(ClassifiedReportReason.labelFor(reason)),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          _selectedReason = val ? reason : null;
                        });
                        _loadReports();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
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
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadReports,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Pokušaj ponovo'),
              ),
            ],
          ),
        ),
      );
    }

    final items = _filteredReports;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nema prijava za prikaz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Sve prijave u ovoj kategoriji su obrađene.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _buildReportCard(items[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildReportCard(
    ClassifiedAdReportModel report,
    ColorScheme colorScheme,
  ) {
    final statusColor = report.statusColor;
    final hasMultipleReports = (report.adReportsCount ?? 0) > 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: report.isPending
              ? Colors.orange.shade300
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gornji red: status prijave + broj prijava za ovaj oglas
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    report.statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasMultipleReports) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded,
                            size: 13, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${report.adReportsCount} prijave za oglas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _formatDate(report.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Podaci o oglasu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail slike
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: colorScheme.surfaceContainerHighest,
                    child: report.adImages.isNotEmpty
                        ? Image.network(
                            report.adImages.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              size: 24,
                            ),
                          )
                        : const Icon(Icons.campaign_outlined, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.adTitle ?? 'Oglas: ${report.adId}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (report.adPrice != null) ...[
                        Text(
                          '${report.adPrice!.toStringAsFixed(0)} ${report.adCurrency ?? 'RSD'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                      if (report.adStatus != null) ...[
                        Text(
                          'Status oglasa: ${report.adStatus}',
                          style: TextStyle(
                            fontSize: 11,
                            color: report.adStatus == 'rejected'
                                ? Colors.red.shade700
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Razlog prijave
            Row(
              children: [
                Icon(
                  ClassifiedReportReason.iconFor(report.reason),
                  size: 16,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ClassifiedReportReason.labelFor(report.reason),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),

            // Detalji koje je korisnik upisao
            if (report.details != null && report.details!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"${report.details!}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            if (report.reporterName != null) ...[
              const SizedBox(height: 6),
              Text(
                'Prijavio: ${report.reporterName}',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Dugmad za akciju
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/classifieds/ad/${report.adId}'),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Pogledaj oglas'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                if (report.isPending) ...[
                  FilledButton.icon(
                    onPressed: () => _showDeactivateDialog(report),
                    icon: const Icon(Icons.block_rounded, size: 16),
                    label: const Text('Ukloni oglas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _handleModerateAction(
                      report: report,
                      action: 'resolve_reviewed',
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Ispravan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _handleModerateAction(
                      report: report,
                      action: 'dismiss',
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Odbaci prijavu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}.${dt.month}.${dt.year}.';
  }
}
