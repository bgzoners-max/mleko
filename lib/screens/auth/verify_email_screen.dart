import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mleko/core/responsive.dart';
import 'package:mleko/providers/app_state.dart';
import 'package:mleko/widgets/app_back_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _resending = false;
  bool _resent = false;

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resent = false;
    });
    try {
      await context
          .read<AppState>()
          .authService
          .resendConfirmationEmail(widget.email);
      if (mounted) setState(() => _resent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Greška: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackRoute: '/login'),
        title: const Text('Potvrda emaila'),
        actions: const [AppHomeButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.authContentWidth(
              context,
              tabletWidth: 480,
              desktopWidth: 480,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(
              Breakpoints.horizontalPadding(context),
            ).copyWith(
              top: Breakpoints.adaptiveDouble(
                context,
                phone: 40,
                largeTabletValue: 48,
                desktop: 48,
              ),
              bottom: Breakpoints.adaptiveDouble(
                context,
                phone: 24,
                largeTabletValue: 32,
                desktop: 32,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Proverite inbox',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Poslali smo link za verifikaciju na:',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Kliknite na link u emailu da biste završili registraciju.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Proverite i spam / junk folder ako ne vidite email.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (_resent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Email je ponovo poslat.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _resending ? null : _resend,
                  icon: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: const Text('Ponovo pošalji link'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Već imate nalog? Prijavite se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
