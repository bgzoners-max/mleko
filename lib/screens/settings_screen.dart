import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';

String _fontScaleLabel(double scale) {
  if (scale <= 0.95) return 'Manja';
  if (scale <= 1.05) return 'Normalna';
  if (scale <= 1.2) return 'Velika';
  if (scale <= 1.4) return 'Veća';
  return 'Najveća';
}

void _showFontScalePicker(
    BuildContext context, AppSettingsProvider appSettings) {
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
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
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
        body: const Center(
            child: Text('Prijavite se da pristupite podešavanjima.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Podešavanja')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: Breakpoints.maxContentWidth(context)),
          child: ListView(
            padding: EdgeInsets.all(Breakpoints.horizontalPadding(context)),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        'Ovde možeš prilagoditi izgled aplikacije, obaveštenja i opcije za kupovinu ili prodaju.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Tamna tema'),
                subtitle: const Text('Uključi tamnu pozadinu i svetle akcente'),
                value: appSettings.themeMode == ThemeMode.dark ||
                    (appSettings.themeMode == ThemeMode.system &&
                        MediaQuery.platformBrightnessOf(context) ==
                            Brightness.dark),
                onChanged: (value) {
                  appSettings
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.animation_outlined),
                title: const Text('Animacije'),
                subtitle:
                    const Text('Mikro-animacije na dugmićima i prelazima'),
                value: appSettings.animationsEnabled,
                onChanged: (value) {
                  appSettings.setAnimationsEnabled(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.density_small_outlined),
                title: const Text('Kompaktan prikaz'),
                subtitle: const Text(
                    'Manji razmaci i dugmad — više sadržaja na ekranu'),
                value: appSettings.compactMode,
                onChanged: (value) {
                  appSettings.setCompactMode(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields_outlined),
                title: const Text('Veličina teksta'),
                subtitle: Text(_fontScaleLabel(appSettings.fontScale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showFontScalePicker(context, appSettings),
              ),
              const Divider(height: 1),
              if (!user.isGuest) ...[
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Obaveštenja'),
                  subtitle: const Text('Podešavanja obaveštenja i dozvole'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
              ],
              if (user.isSeller) ...[
                ListTile(
                  leading: const Icon(Icons.store_outlined),
                  title: const Text('Podešavanja prodavca'),
                  subtitle:
                      const Text('Lokacija, priča, galerija, brzi odgovori'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/seller-settings'),
                ),
                const Divider(height: 1),
              ],
              if (user.isAdmin) ...[
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Admin panel'),
                  subtitle: const Text('Tiketi podrške'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/tickets'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Push health'),
                  subtitle:
                      const Text('Pregled isporuke i korisnika sa problemima'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin/push-health'),
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.support_outlined),
                title: const Text('Podrška / prijava problema'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/support'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Uslovi korišćenja'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/uslovi-koriscenja'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Politika privatnosti'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/politika-privatnosti'),
              ),
              if (!user.isGuest) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout,
                      color: Theme.of(context).colorScheme.error),
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
                        content: const Text(
                            'Da li ste sigurni da želite da se odjavite?'),
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
        ),
      ),
    );
  }
}
