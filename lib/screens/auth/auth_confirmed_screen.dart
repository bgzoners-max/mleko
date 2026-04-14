import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mleko/core/responsive.dart';
import 'package:mleko/providers/app_state.dart';

class AuthConfirmedScreen extends StatefulWidget {
  const AuthConfirmedScreen({super.key});

  @override
  State<AuthConfirmedScreen> createState() => _AuthConfirmedScreenState();
}

class _AuthConfirmedScreenState extends State<AuthConfirmedScreen> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _goHome();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goHome() {
    context.read<AppState>().clearJustConfirmedEmail();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
          child: Padding(
            padding: EdgeInsets.all(
              Breakpoints.horizontalPadding(context),
            ).copyWith(
              top: Breakpoints.adaptiveDouble(
                context,
                phone: 64,
                largeTabletValue: 80,
                desktop: 80,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 56),
                ),
                const SizedBox(height: 32),
                Text(
                  'Uspešno ste registrovani!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Dobro došli u Domaći market. Vaš nalog je potvrđen i spremni ste da istražujete ponudu.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _goHome,
                  icon: const Icon(Icons.home_outlined),
                  label: Text('Idi na početnu ($_countdown)'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
