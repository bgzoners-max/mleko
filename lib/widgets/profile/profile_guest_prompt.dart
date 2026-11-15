import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/amazon_theme.dart';
import '../app_back_button.dart';
import '../auth/guest_auth_buttons.dart';

/// Ekran za neprijavljene korisnike: poziv na prijavu umesto profila.
/// Izdvojeno iz `ProfileScreen` (guest grana `build` metode).
class ProfileGuestPrompt extends StatelessWidget {
  const ProfileGuestPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: true,
        backgroundColor:
            isDark ? AmazonColors.navNavy : theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: isDark
            ? null
            : Border(
                bottom: BorderSide(
                    color: AmazonColors.getBorder(context), width: 1),
              ),
        leading: const AppBackButton(fallbackRoute: '/'),
        title: Text(
          'Prijava',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AmazonColors.getTextPrimary(context),
          ),
        ),
        actions: const [AppHomeButton()],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 64),
              SizedBox(height: 16),
              Text(
                'Za pristup profilu, oglasima i porudžbinama potrebno je da se prijavite na svoj nalog ili registrujete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 24),
              GuestAuthButtons(useGoNavigation: true),
            ],
          ),
        ),
      ),
    );
  }
}
