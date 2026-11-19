import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/responsive.dart';

class NotificationSettingsCard extends StatelessWidget {
  final double? padding;

  const NotificationSettingsCard({super.key, this.padding});

  @override
  Widget build(BuildContext context) {
    final pad = padding ?? Breakpoints.cardPadding(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(pad),
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
}

class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.amber.shade100 : Colors.amber.shade900;
    return Card(
      color: isDark
          ? Colors.amber.withValues(alpha: 0.18)
          : Colors.amber.shade100,
      child: ListTile(
        leading: Icon(Icons.notifications_off, color: fgColor),
        title: Text(
          'Obaveštenja su isključena',
          style: TextStyle(color: fgColor, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Dozvolite obaveštenja u podešavanjima da primate push obaveštenja.',
          style: TextStyle(color: fgColor.withValues(alpha: 0.9)),
        ),
        trailing: TextButton(
          onPressed: openAppSettings,
          child: Text('Podešavanja', style: TextStyle(color: fgColor)),
        ),
      ),
    );
  }
}
