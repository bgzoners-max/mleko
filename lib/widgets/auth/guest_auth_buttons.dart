import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Zajednički par CTA dugmadi za neprijavljene goste:
/// „Registruj se” (`/login?tab=register`) i „Prijavi se” (`/login`).
class GuestAuthButtons extends StatelessWidget {
  final bool useGoNavigation;
  final bool compact;

  const GuestAuthButtons({
    super.key,
    this.useGoNavigation = true,
    this.compact = false,
  });

  void _openAuth(BuildContext context, String route) {
    if (useGoNavigation) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          FilledButton(
            onPressed: () => _openAuth(context, '/login?tab=register'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Registruj se'),
          ),
          OutlinedButton(
            onPressed: () => _openAuth(context, '/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Prijavi se'),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () => _openAuth(context, '/login?tab=register'),
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Registruj se'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openAuth(context, '/login'),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Prijavi se'),
        ),
      ],
    );
  }
}
