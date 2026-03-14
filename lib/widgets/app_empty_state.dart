import 'package:flutter/material.dart';

/// Prazno stanje – jasna poruka i opciono CTA dugme kada nema podataka za prikaz.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  /// Opciono CTA dugme (npr. "Pretraži proizvode", "Dodaj prvi proizvod").
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final IconData? ctaIcon;
  /// Ako želiš custom widget umesto ctaLabel (npr. više dugmadi).
  final Widget? cta;

  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.ctaIcon,
    this.cta,
  }) : assert(cta == null || (ctaLabel == null && onCtaPressed == null),
             'Koristi ili cta ili (ctaLabel + onCtaPressed).');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (cta != null) ...[
              const SizedBox(height: 24),
              cta!,
            ] else if (ctaLabel != null && onCtaPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCtaPressed,
                icon: Icon(ctaIcon ?? Icons.search, size: 20),
                label: Text(ctaLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
