import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';

String _fontScaleLabel(double scale) {
  if (scale <= 0.95) return 'Manja';
  if (scale <= 1.05) return 'Normalna';
  if (scale <= 1.2) return 'Velika';
  if (scale <= 1.4) return 'Veća';
  return 'Najveća';
}

void _showFontScalePicker(BuildContext context, AppSettingsProvider appSettings) {
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Razmera teksta',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...AppSettingsProvider.fontScalePresets.map((scale) {
            final isSelected = (appSettings.fontScale - scale).abs() < 0.01;
            return ListTile(
              title: Text(_fontScaleLabel(scale)),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary) : null,
              onTap: () {
                appSettings.setFontScale(scale);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Opšta stranica podešavanja aplikacije (tema, animacije, obaveštenja, prodavac, podrška, odjava).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final appSettings = context.watch<AppSettingsProvider>();
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Podešavanja')),
        body: const Center(child: Text('Prijavite se da pristupite podešavanjima.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Podešavanja')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Tamna tema'),
            subtitle: const Text('Uključi tamnu pozadinu i svetle akcente'),
            value: appSettings.themeMode == ThemeMode.dark ||
                (appSettings.themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark),
            onChanged: (value) {
              appSettings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.animation_outlined),
            title: const Text('Animacije'),
            subtitle: const Text('Mikro-animacije na dugmićima i prelazima'),
            value: appSettings.animationsEnabled,
            onChanged: (value) {
              appSettings.setAnimationsEnabled(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.text_fields_outlined),
            title: const Text('Veći font'),
            subtitle: Text(_fontScaleLabel(appSettings.fontScale)),
            onTap: () => _showFontScalePicker(context, appSettings),
          ),
          const Divider(height: 1),
          if (!user.isGuest) ...[
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Obaveštenja'),
              subtitle: const Text('Podešavanja obaveštenja i dozvole'),
              onTap: () => context.push('/notifications'),
            ),
            const Divider(height: 1),
          ],
          if (user.isSeller) ...[
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('Podešavanja prodavca'),
              subtitle: const Text('Lokacija, priča, galerija, brzi odgovori'),
              onTap: () => context.push('/seller-settings'),
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.support_outlined),
            title: const Text('Podrška / prijava problema'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kontakt: support@mleko.rs (MVP)')),
              );
            },
          ),
          if (!user.isGuest) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                'Odjavi se',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Odjavi se?'),
                    content: const Text('Da li ste sigurni da želite da se odjavite?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Odustani'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Odjavi se'),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AppState>().authService.signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
