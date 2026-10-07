import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/services.dart';

/// UI kartice za Admin Push Health panel — izdvojeno iz ekrana radi
/// smanjenja veličine ispod CI limita (bez promene ponašanja).

/// Formatira datum/vreme za prikaz (`dd.MM.yyyy HH:mm`) ili `n/a`.
String pushFormatDateTime(DateTime? value) {
  if (value == null) return 'n/a';
  return DateFormat('dd.MM.yyyy HH:mm').format(value.toLocal());
}

/// Boja tona po health statusu.
Color pushHealthColor(String health, ColorScheme colorScheme) {
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

/// Ljudski naziv health statusa.
String pushHealthLabel(String health) {
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

/// Jedna stavka u gridu statistike.
class StatItem {
  final String label;
  final String value;
  final IconData icon;

  const StatItem(this.label, this.value, this.icon);
}

/// Hero kartica sa health statusom i uspešnošću.
Widget pushHealthStatusHero(
    BuildContext context, PushHealthDashboardModel dashboard) {
  final colorScheme = Theme.of(context).colorScheme;
  final tone = pushHealthColor(dashboard.health, colorScheme);

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
                  pushHealthLabel(dashboard.health),
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
            'Pregled push pipeline-a iz admin aplikacije: konfiguracija, tok '
            'isporuke i korisnici sa aktivnim problemima.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    ),
  );
}

/// Grid statističkih kartica (responsivan: 1/2/4 kolone).
Widget pushHealthStatGrid(
    BuildContext context, PushHealthDashboardModel dashboard) {
  final items = [
    StatItem('Tokeni', '${dashboard.totalTokens}', Icons.key_outlined),
    StatItem('Korisnici sa tokenom', '${dashboard.usersWithTokens}',
        Icons.people_outline),
    StatItem('Notifikacije 24h', '${dashboard.notifications24h}',
        Icons.notifications_outlined),
    StatItem(
        'Isporuke 24h', '${dashboard.deliveries24h}', Icons.send_outlined),
    StatItem('Uspešne', '${dashboard.successfulDeliveries24h}',
        Icons.check_circle_outline),
    StatItem(
        'Neuspešne', '${dashboard.failedDeliveries24h}', Icons.error_outline),
    StatItem('Novi tokeni 24h', '${dashboard.tokensCreated24h}',
        Icons.add_reaction_outlined),
    StatItem(
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
            pushHealthStatCard(context, items[index]),
      );
    },
  );
}

/// Jedna statistička kartica.
Widget pushHealthStatCard(BuildContext context, StatItem item) {
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

/// Hint o istorijskim promašajima kada nema aktivnog zastoja.
Widget pushHealthHistoricalFailureHint(
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
                  'Pipeline trenutno radi i backlog je '
                  '${dashboard.deliveryBacklogMinutes.toStringAsFixed(1)} min, '
                  'ali dashboard ostaje degradiran dok u poslednja 24h postoje '
                  'stari `error`, `partial` ili `no_tokens` logovi.',
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

/// Kartica konfiguracije i toka (edge config, anon key, vremena).
Widget pushHealthMetaCard(
    BuildContext context, PushHealthDashboardModel dashboard) {
  final colorScheme = Theme.of(context).colorScheme;
  final rows = [
    ('Edge config', dashboard.edgeConfigOk ? 'Ispravan' : 'Problem'),
    ('Anon key', dashboard.anonKeyPresent ? 'Prisutan' : 'Nedostaje'),
    ('Function URL', dashboard.functionsBaseUrl ?? 'Nije postavljen'),
    ('Poslednja notifikacija', pushFormatDateTime(dashboard.lastNotificationAt)),
    ('Poslednja isporuka', pushFormatDateTime(dashboard.lastDeliveryAt)),
    ('Osveženo', pushFormatDateTime(dashboard.checkedAt)),
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


/// Retention vodič za održavanje push logova.
Widget pushHealthRetentionGuideCard(BuildContext context) {
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


