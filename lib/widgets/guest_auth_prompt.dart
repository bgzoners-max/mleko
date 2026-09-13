import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system.dart';
import '../core/responsive.dart';

/// Prikazuje elegantan dijalog ili bottom sheet koji obaveštava gosta
/// da je za određenu akciju (npr. postavljanje oglasa, čuvanje pretrage)
/// neophodno da se prijavi ili registruje.
Future<void> showGuestAuthPrompt(
  BuildContext context, {
  String title = 'Potrebna prijava',
  String message =
      'Kao gost možete slobodno pregledati ponudu i kontaktirati oglašivače. Da biste izvršili ovu akciju, potrebno je da se prijavite na svoj nalog ili da se besplatno registrujete.',
  IconData icon = Icons.lock_outline,
}) {
  final isDesktop = Breakpoints.isDesktop(context);

  if (isDesktop) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => _GuestAuthDialog(
        title: title,
        message: message,
        icon: icon,
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesign.radiusL)),
    ),
    builder: (ctx) => _GuestAuthSheet(
      title: title,
      message: message,
      icon: icon,
    ),
  );
}

class _GuestAuthDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _GuestAuthDialog({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesign.radiusL),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.spaceXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppDesign.spaceM),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesign.spaceS),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesign.spaceL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Registruj se'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/register');
                      },
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceM),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Prijavi se'),
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/login');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spaceS),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Nastavi kao gost'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestAuthSheet extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _GuestAuthSheet({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.spaceL,
          AppDesign.spaceS,
          AppDesign.spaceL,
          AppDesign.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppDesign.spaceM),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.spaceS),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesign.spaceL),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Prijavi se na nalog'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/login');
                },
              ),
            ),
            const SizedBox(height: AppDesign.spaceS),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Besplatna registracija'),
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/register');
                },
              ),
            ),
            const SizedBox(height: AppDesign.spaceS),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nastavi kao gost'),
            ),
          ],
        ),
      ),
    );
  }
}
