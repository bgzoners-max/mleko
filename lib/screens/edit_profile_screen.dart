import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/responsive.dart';
import '../providers/app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/profile/edit_profile_form.dart';

/// Ekran za izmenu podataka profila korisnika (/profile/edit).
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.watch<AppState>().user;

    if (user == null || user.isGuest) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          centerTitle: false,
          backgroundColor:
              isDark ? const Color(0xFF1E3424) : theme.colorScheme.surface,
          foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shape: isDark
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
          leading: const AppBackButton(fallbackRoute: '/profile'),
          title: Text(
            'Izmena profila',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1B201C),
            ),
          ),
          actions: const [AppHomeButton()],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Potrebno je da se prijavite da biste menjali podatke profila.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Prijavi se'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: false,
        backgroundColor:
            isDark ? const Color(0xFF1E3424) : theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: isDark
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
        leading: const AppBackButton(fallbackRoute: '/profile'),
        title: Text(
          'Uredi profil',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1B201C),
          ),
        ),
        actions: const [AppHomeButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context).clamp(0, 720),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: EditProfileForm(
              user: user,
              isFullScreen: true,
              onSaved: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
