import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system.dart';

/// Prijateljski i responsivni fallback widget koji zamenjuje crveni/sivi ekran greške u Flutteru.
///
/// Koristi se kao povratna vrednost za [ErrorWidget.builder].
class AppErrorWidget extends StatefulWidget {
  final FlutterErrorDetails? details;
  final VoidCallback? onRetry;
  final String? customMessage;

  const AppErrorWidget({
    super.key,
    this.details,
    this.onRetry,
    this.customMessage,
  });

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget> {
  bool _showDetails = false;

  void _copyDetailsToClipboard(BuildContext context) {
    final errorText = widget.details?.exceptionAsString() ?? 'Nema detalja o grešci.';
    final stackText = widget.details?.stack?.toString() ?? '';
    final fullText = stackText.isNotEmpty ? '$errorText\n\nStack Trace:\n$stackText' : errorText;

    Clipboard.setData(ClipboardData(text: fullText));
    try {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Detalji greške su kopirani u privremenu memoriju.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {}
  }

  void _navigateToHome(BuildContext context) {
    try {
      context.go('/');
    } catch (_) {
      try {
        Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Kompaktni prikaz ako je prostor unutar roditeljskog widgeta ograničen
        final isCompact = constraints.maxHeight < 200 || constraints.maxWidth < 240;

        if (isCompact) {
          return Container(
            padding: AppDesign.paddingS,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDesign.radiusS),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colorScheme.error,
                  size: AppDesign.iconM,
                ),
                AppDesign.boxS,
                Flexible(
                  child: Text(
                    widget.customMessage ?? 'Greška u prikazu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onRetry != null) ...[
                  AppDesign.boxS,
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    iconSize: AppDesign.iconM,
                    color: colorScheme.error,
                    tooltip: 'Pokušaj ponovo',
                    onPressed: widget.onRetry,
                  ),
                ],
              ],
            ),
          );
        }

        // Standardni ili pun ekran
        return Material(
          color: theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesign.spaceXL),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ikona greške
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sentiment_dissatisfied_outlined,
                          size: 40,
                          color: colorScheme.error,
                        ),
                      ),
                      AppDesign.boxL,

                      // Naslov
                      Text(
                        'Došlo je do greške u prikazu',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppDesign.boxS,

                      // Opis
                      Text(
                        widget.customMessage ??
                            'Izvinjavamo se na neprijatnosti. Došlo je do neočekivanog problema pri iscrtavanju ovog dela aplikacije.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppDesign.boxL,

                      // Akciona dugmad
                      Wrap(
                        spacing: AppDesign.spaceM,
                        runSpacing: AppDesign.spaceS,
                        alignment: WrapAlignment.center,
                        children: [
                          if (widget.onRetry != null)
                            FilledButton.icon(
                              onPressed: widget.onRetry,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Pokušaj ponovo'),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => _navigateToHome(context),
                            icon: const Icon(Icons.home_outlined, size: 18),
                            label: const Text('Početna strana'),
                          ),
                        ],
                      ),

                      // Detalji o grešci (u debug režimu ili na zahtev)
                      if (widget.details != null) ...[
                        AppDesign.boxL,
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDetails = !_showDetails;
                            });
                          },
                          icon: Icon(
                            _showDetails ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                            size: 18,
                          ),
                          label: Text(
                            _showDetails ? 'Sakrij tehničke detalje' : 'Prikaži tehničke detalje',
                          ),
                        ),
                        if (_showDetails) ...[
                          AppDesign.boxS,
                          Container(
                            width: double.infinity,
                            padding: AppDesign.paddingM,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(AppDesign.radiusM),
                              border: Border.all(
                                color: theme.dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Detalji izuzetka',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 16),
                                      tooltip: 'Kopiraj detalje',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => _copyDetailsToClipboard(context),
                                    ),
                                  ],
                                ),
                                const Divider(height: 12),
                                SelectableText(
                                  widget.details?.exceptionAsString() ?? 'Nema opisa',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
