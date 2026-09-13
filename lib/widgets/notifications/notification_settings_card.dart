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
    return Card(
      color: Colors.amber.shade100,
      child: const ListTile(
        leading: Icon(Icons.notifications_off),
        title: Text('Obaveštenja su isključena'),
        subtitle: Text(
          'Dozvolite obaveštenja u podešavanjima da primate push obaveštenja.',
        ),
        trailing: TextButton(
          onPressed: openAppSettings,
          child: Text('Podešavanja'),
        ),
      ),
    );
  }
}
