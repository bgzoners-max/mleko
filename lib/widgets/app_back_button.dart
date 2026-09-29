import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pametno dugme za povratak nazad koje garantuje da korisnik nikada ne ostaje
/// zarobljen na stranici (posebno za Web PWA, deep linkove ili browser refresh
/// gde je standardni `Navigator.canPop(context)` false).
class AppBackButton extends StatelessWidget {
  /// Ruta na koju se ide ukoliko u steku navigacije ne postoji prethodni ekran.
  final String fallbackRoute;

  /// Opcioni callback za prilagođeno ponašanje pre izlaska.
  final VoidCallback? onPressed;

  /// Boja ikonice. Ako nije zadata, preuzima se iz teme.
  final Color? color;

  /// Prilagođeni tooltip tekst.
  final String? tooltip;

  /// Prilagođena ikonica (podrazumevano adaptive arrow back).
  final IconData? icon;

  const AppBackButton({
    super.key,
    this.fallbackRoute = '/',
    this.onPressed,
    this.color,
    this.tooltip,
    this.icon,
  });

  void _handlePress(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final defaultTooltip = canPop
        ? 'Nazad'
        : (fallbackRoute == '/' ? 'Početna strana' : 'Nazad');

    return IconButton(
      icon: Icon(icon ?? Icons.arrow_back),
      color: color,
      tooltip: tooltip ?? defaultTooltip,
      onPressed: () => _handlePress(context),
    );
  }
}

/// Dugme za direktan povratak na početnu stranu (Home) iz akcija AppBar-a.
class AppHomeButton extends StatelessWidget {
  final Color? color;
  final String tooltip;
  final VoidCallback? onPressed;

  const AppHomeButton({
    super.key,
    this.color,
    this.tooltip = 'Početna strana',
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cottage_outlined),
      tooltip: tooltip,
      color: color,
      onPressed: onPressed ?? () => context.go('/'),
    );
  }
}
