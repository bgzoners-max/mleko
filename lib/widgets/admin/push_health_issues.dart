import 'package:flutter/material.dart';

import '../../services/services.dart';
import 'push_health_cards.dart';

/// Issues deo Admin Push Health panela — pretraga, filteri, sortiranje
/// i prikaz korisničkih problema (izdvojeno iz ekrana).

/// Redosled sortiranja issues liste.
enum IssueSort {
  latestNotificationDesc,
  latestDeliveryDesc,
  tokenCountAsc,
  errorCountDesc,
  healthSeverity,
}

/// Opcije health filtera (vrednost + labela).
const pushHealthFilterOptions = [
  (value: 'all', label: 'Svi'),
  (value: 'missing_token', label: 'Nema token'),
  (value: 'stalled', label: 'Zastoj'),
  (value: 'error', label: 'Greška'),
  (value: 'partial', label: 'Delimično'),
  (value: 'no_tokens', label: 'Bez tokena'),
];

/// Ozbiljnost health statusa za sortiranje (veće = ozbiljnije).
int pushHealthSeverity(String health) {
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

/// Naziv sortiranja za prikaz u dugmetu.
String pushSortLabel(IssueSort sort) {
  return switch (sort) {
    IssueSort.latestNotificationDesc => 'Poslednja notifikacija',
    IssueSort.latestDeliveryDesc => 'Poslednji delivery',
    IssueSort.tokenCountAsc => 'Najmanje tokena',
    IssueSort.errorCountDesc => 'Najviše grešaka',
    IssueSort.healthSeverity => 'Ozbiljnost',
  };
}

/// Skraćen prikaz user ID-a (`abcd1234...wxyz`).
String pushShortId(String value) {
  if (value.length <= 12) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 4)}';
}

/// Filtrira i sortira issues listu po upitu, filteru i sortu.
List<PushHealthUserIssueModel> filterPushHealthIssues(
  List<PushHealthUserIssueModel> issues, {
  required String query,
  required String healthFilter,
  required IssueSort sortBy,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  final filtered = issues.where((issue) {
    final matchesFilter =
        healthFilter == 'all' || issue.health == healthFilter;
    if (!matchesFilter) return false;

    if (normalizedQuery.isEmpty) return true;
    return issue.userId.toLowerCase().contains(normalizedQuery) ||
        issue.health.toLowerCase().contains(normalizedQuery) ||
        (issue.latestDeliveryStatus?.toLowerCase()
                .contains(normalizedQuery) ??
            false);
  }).toList();

  final DateTime epoch = DateTime.fromMillisecondsSinceEpoch(0);
  filtered.sort((left, right) {
    return switch (sortBy) {
      IssueSort.latestNotificationDesc =>
        (right.latestNotificationAt ?? epoch)
            .compareTo(left.latestNotificationAt ?? epoch),
      IssueSort.latestDeliveryDesc => (right.latestDeliveryAt ?? epoch)
          .compareTo(left.latestDeliveryAt ?? epoch),
      IssueSort.tokenCountAsc => left.tokenCount.compareTo(right.tokenCount),
      IssueSort.errorCountDesc => right.latestDeliveryErrorCount
          .compareTo(left.latestDeliveryErrorCount),
      IssueSort.healthSeverity => pushHealthSeverity(right.health)
          .compareTo(pushHealthSeverity(left.health)),
    };
  });

  return filtered;
}


/// Jedan meta podatak (labela + vrednost) u issue tile-u.
class IssueMeta extends StatelessWidget {
  final String label;
  final String value;

  const IssueMeta(this.label, this.value, {super.key});

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

/// Toolbar sa pretragom, health filter čipovima i sort menijem.
Widget pushHealthIssueToolbar(
  BuildContext context, {
  required int totalCount,
  required int visibleCount,
  required TextEditingController searchController,
  required String selectedHealthFilter,
  required IssueSort sortBy,
  required ValueChanged<String> onFilterChanged,
  required ValueChanged<IssueSort> onSortChanged,
}) {
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
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Pretraga po user ID-u ili statusu',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Obriši pretragu',
                  onPressed: () => searchController.clear(),
                ),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ...pushHealthFilterOptions.map(
            (option) => FilterChip(
              label: Text(option.label),
              selected: selectedHealthFilter == option.value,
              onSelected: (_) => onFilterChanged(option.value),
            ),
          ),
          PopupMenuButton<IssueSort>(
            initialValue: sortBy,
            tooltip: 'Sortiranje',
            onSelected: onSortChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: IssueSort.latestNotificationDesc,
                child: Text('Sortiraj: poslednja notifikacija'),
              ),
              PopupMenuItem(
                value: IssueSort.latestDeliveryDesc,
                child: Text('Sortiraj: poslednji delivery'),
              ),
              PopupMenuItem(
                value: IssueSort.tokenCountAsc,
                child: Text('Sortiraj: najmanje tokena'),
              ),
              PopupMenuItem(
                value: IssueSort.errorCountDesc,
                child: Text('Sortiraj: najviše grešaka'),
              ),
              PopupMenuItem(
                value: IssueSort.healthSeverity,
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
                    Text(pushSortLabel(sortBy)),
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

/// Sekcija issues liste (prazno stanje + toolbar + tile-ovi).
Widget pushHealthIssuesSection(
  BuildContext context, {
  required List<PushHealthUserIssueModel> issues,
  required int totalIssues,
  required TextEditingController searchController,
  required String selectedHealthFilter,
  required IssueSort sortBy,
  required ValueChanged<String> onFilterChanged,
  required ValueChanged<IssueSort> onSortChanged,
}) {
  Widget toolbar() => pushHealthIssueToolbar(
        context,
        totalCount: totalIssues,
        visibleCount: issues.length,
        searchController: searchController,
        selectedHealthFilter: selectedHealthFilter,
        sortBy: sortBy,
        onFilterChanged: onFilterChanged,
        onSortChanged: onSortChanged,
      );

  if (issues.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            toolbar(),
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
          toolbar(),
          const SizedBox(height: 12),
          ...issues.map((issue) => pushHealthIssueTile(context, issue)),
        ],
      ),
    ),
  );
}


/// Jedan tile sa korisničkim push problemom.
Widget pushHealthIssueTile(
    BuildContext context, PushHealthUserIssueModel issue) {
  final colorScheme = Theme.of(context).colorScheme;
  final tone = pushHealthColor(issue.health, colorScheme);

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
                pushShortId(issue.userId),
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
                pushHealthLabel(issue.health),
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
            IssueMeta('Tokena', '${issue.tokenCount}'),
            IssueMeta('Notifikacije 7d', '${issue.notifications7d}'),
            IssueMeta(
                'Poslednji delivery', issue.latestDeliveryStatus ?? 'n/a'),
            IssueMeta(
                'Delivery greške', '${issue.latestDeliveryErrorCount}'),
            IssueMeta('Poslednji token',
                pushFormatDateTime(issue.latestTokenAt)),
            IssueMeta('Poslednja notifikacija',
                pushFormatDateTime(issue.latestNotificationAt)),
          ],
        ),
      ],
    ),
  );
}


