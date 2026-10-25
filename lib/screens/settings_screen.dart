import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/responsive.dart';
import '../models/user_model.dart';
import '../providers/app_settings_provider.dart';
import '../providers/app_state.dart';
import '../widgets/app_back_button.dart';

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
        appBar: AppBar(
          leading: const AppBackButton(fallbackRoute: '/'),
          title: const Text('Podešavanja'),
          actions: const [AppHomeButton()],
        ),
        body: const Center(
            child: Text('Prijavite se da pristupite podešavanjima.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Podešavanja'),
        actions: const [AppHomeButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.maxContentWidth(context).clamp(0, 960),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumn = constraints.maxWidth >= 600;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBanner(context),
                    if (isTwoColumn)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAppearanceCard(context, appSettings),
                                if (user.isAdmin) _buildAdminCard(context),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!user.isGuest) _buildAccountCard(context, user),
                                _buildSupportAndLegalCard(context),
                                if (!user.isGuest) _buildSignOutCard(context),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAppearanceCard(context, appSettings),
                          if (!user.isGuest) _buildAccountCard(context, user),
                          if (user.isAdmin) _buildAdminCard(context),
                          _buildSupportAndLegalCard(context),
                          if (!user.isGuest) _buildSignOutCard(context),
                        ],
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ovde možeš prilagoditi izgled aplikacije, obaveštenja i opcije za kupovinu ili prodaju.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                fontSize: 12,
                color: isDark ? null : const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? theme.dividerColor.withValues(alpha: 0.25)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 7),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(
      BuildContext context, AppSettingsProvider appSettings) {
    return _buildSectionCard(
      context: context,
      title: 'Izgled i prikaz',
      icon: Icons.palette_outlined,
      children: [
        SwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          secondary: const Icon(Icons.dark_mode_outlined, size: 20),
          title: const Text('Tamna tema',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Uključi tamnu pozadinu i svetle akcente',
              style: TextStyle(fontSize: 11)),
          value: appSettings.themeMode == ThemeMode.dark ||
              (appSettings.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark),
          onChanged: (value) {
            appSettings.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        SwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          secondary: const Icon(Icons.animation_outlined, size: 20),
          title: const Text('Animacije',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Mikro-animacije na dugmićima i prelazima',
              style: TextStyle(fontSize: 11)),
          value: appSettings.animationsEnabled,
          onChanged: (value) {
            appSettings.setAnimationsEnabled(value);
          },
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        SwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          secondary: const Icon(Icons.density_small_outlined, size: 20),
          title: const Text('Kompaktan prikaz',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text(
              'Manji razmaci i dugmad — više sadržaja na ekranu',
              style: TextStyle(fontSize: 11)),
          value: appSettings.compactMode,
          onChanged: (value) {
            appSettings.setCompactMode(value);
          },
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.text_fields_outlined, size: 20),
          title: const Text('Veličina teksta',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(_fontScaleLabel(appSettings.fontScale),
              style: const TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _showFontScalePicker(context, appSettings),
        ),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, UserModel user) {
    return _buildSectionCard(
      context: context,
      title: 'Nalog i profil',
      icon: Icons.person_outline,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.badge_outlined, size: 20),
          title: const Text('Podaci profila',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text(
              'Izmena imena, broja telefona, adrese i fotografije',
              style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/profile/edit'),
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.notifications_outlined, size: 20),
          title: const Text('Obaveštenja',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Podešavanja obaveštenja i dozvole',
              style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/notifications'),
        ),
        if (user.isSeller) ...[
          const Divider(height: 1, indent: 48, thickness: 0.5),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            leading: const Icon(Icons.store_outlined, size: 20),
            title: const Text('Podešavanja prodavca',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Lokacija, priča, galerija, brzi odgovori',
                style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.push('/seller-settings'),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Administracija',
      icon: Icons.admin_panel_settings_outlined,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.confirmation_number_outlined, size: 20),
          title: const Text('Admin panel',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Tiketi podrške',
              style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/admin/tickets'),
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.notifications_active_outlined, size: 20),
          title: const Text('Push health',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Pregled isporuke i korisnika sa problemima',
              style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/admin/push-health'),
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.shield_outlined, size: 20),
          title: const Text('Moderacija oglasa',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: const Text('Pregled i rešavanje prijava malih oglasa',
              style: TextStyle(fontSize: 11)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/admin/classifieds'),
        ),
      ],
    );
  }

  Widget _buildSupportAndLegalCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Podrška i pravno',
      icon: Icons.help_outline,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.support_outlined, size: 20),
          title: const Text('Podrška / prijava problema',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/support'),
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.gavel_outlined, size: 20),
          title: const Text('Uslovi korišćenja',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/uslovi-koriscenja'),
        ),
        const Divider(height: 1, indent: 48, thickness: 0.5),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          leading: const Icon(Icons.privacy_tip_outlined, size: 20),
          title: const Text('Politika privatnosti',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => context.push('/politika-privatnosti'),
        ),
      ],
    );
  }

  Widget _buildSignOutCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Material(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
          title: Text(
            'Odjavi se',
            style: TextStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          subtitle: const Text(
            'Završi sesiju na ovom uređaju',
            style: TextStyle(fontSize: 11),
          ),
          trailing: Icon(Icons.chevron_right,
              size: 18, color: theme.colorScheme.error),
          onTap: () => _confirmSignOut(context),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().authService.signOut();
      if (context.mounted) context.go('/login');
    }
  }
}
