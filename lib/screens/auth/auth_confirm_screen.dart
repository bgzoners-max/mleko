import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mleko/core/responsive.dart';

/// Ekran koji vrši klijentsku verifikaciju OTP token heša (za slučaj kada se
/// /auth/confirm ne razreši preko Vercel Edge Serverless funkcije).
class AuthConfirmScreen extends StatefulWidget {
  final String? tokenHash;
  final String? type;
  final String? next;

  const AuthConfirmScreen({
    super.key,
    this.tokenHash,
    this.type,
    this.next,
  });

  @override
  State<AuthConfirmScreen> createState() => _AuthConfirmScreenState();
}

class _AuthConfirmScreenState extends State<AuthConfirmScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final tokenHash = widget.tokenHash;
    final typeStr = widget.type;

    if (tokenHash == null || tokenHash.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Link za potvrdu nije validan ili je nepotpun.';
      });
      return;
    }

    try {
      final OtpType otpType;
      switch (typeStr) {
        case 'signup':
          otpType = OtpType.signup;
          break;
        case 'recovery':
          otpType = OtpType.recovery;
          break;
        case 'invite':
          otpType = OtpType.invite;
          break;
        case 'magiclink':
          otpType = OtpType.magiclink;
          break;
        case 'email_change':
          otpType = OtpType.emailChange;
          break;
        case 'email':
        default:
          otpType = OtpType.email;
          break;
      }

      final response = await Supabase.instance.client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: otpType,
      );

      if (!mounted) return;

      if (response.session != null || response.user != null) {
        final target = widget.next != null && widget.next!.isNotEmpty
            ? widget.next!
            : (otpType == OtpType.recovery ? '/settings' : '/auth/confirmed');
        context.go(target);
      } else {
        setState(() {
          _errorMessage =
              'Link za verifikaciju je nevažeći ili je već iskorišćen.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '').replaceFirst('AuthException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.authContentWidth(
              context,
              tabletWidth: 440,
              desktopWidth: 440,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Neuspešna potvrda',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Idi na prijavu'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Potvrđivanje naloga...',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Molimo sačekajte trenutak.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
