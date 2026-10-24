import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/app_state.dart';
import '../services/auth/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final authService = AuthService();
    final cleanSessionFuture = authService.ensureCleanSession();

    if (!mounted) return;
    final appState = context.read<AppState>();

    // Brza provera dostupnosti mreže u splashu sa 1.5s timeout-om
    await Future.wait([
      cleanSessionFuture,
      appState.connectivity.checkReachability().timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => appState.connectivity.isOnline,
      ),
    ]);

    if (!mounted) return;
    if (appState.justConfirmedEmail) {
      context.go('/auth/confirmed');
      return;
    }

    // Sačekaj da authChecked postane true (najviše 2.5s da ne blokira offline rad)
    int waitMs = 0;
    while (!appState.authChecked && waitMs < 2500 && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      waitMs += 100;
    }

    if (!mounted) return;

    final rawReturnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (rawReturnTo != null && rawReturnTo.isNotEmpty) {
      final decoded = Uri.decodeComponent(rawReturnTo);
      final decodedUri = Uri.tryParse(decoded);
      if (decodedUri != null && decodedUri.path != '/splash') {
        context.go(decoded);
        return;
      }
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/domaci_market_logo_v2.png',
              width: 88,
              height: 88,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.agriculture,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              AppConstants.appTagline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
