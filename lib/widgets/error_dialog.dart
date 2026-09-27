import 'package:flutter/material.dart';
import '../models/app_error.dart';

/// Dialog za prikazivanje greške sa retry opcijom
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getColor(context),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Greška')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              error.getUserMessage(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (showDetails && error.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalji',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (error.code != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Kod: ${error.code}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (error.isRetryable)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Možeš pokušati ponovno.',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.blue[700],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDismiss?.call();
          },
          child: const Text('Zatvori'),
        ),
        if (error.isRetryable && onRetry != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRetry?.call();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Pokušaj ponovno'),
          ),
      ],
    );
  }

  IconData _getIcon() {
    return switch (error.type) {
      ErrorType.network => Icons.wifi_off,
      ErrorType.timeout => Icons.schedule,
      ErrorType.unauthorized => Icons.lock,
      ErrorType.forbidden => Icons.block,
      ErrorType.notFound => Icons.search_off,
      ErrorType.validation => Icons.warning,
      ErrorType.conflict => Icons.close,
      _ => Icons.error,
    };
  }

  Color _getColor(BuildContext context) {
    return switch (error.type) {
      ErrorType.network => Colors.orange,
      ErrorType.timeout => Colors.orange,
      ErrorType.unauthorized => Colors.red,
      ErrorType.forbidden => Colors.red,
      _ => Theme.of(context).colorScheme.error,
    };
  }

  /// Prikaži error dialog
  static Future<void> show(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showDetails: _shouldShowDetails(error),
      ),
    );
  }

  static bool _shouldShowDetails(AppError error) {
    return false;
  }
}

/// SnackBar za error notifikacije
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required AppError error,
    VoidCallback? onRetry,
  }) : super(
          content: Row(
            children: [
              Icon(
                _getIcon(error.type),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(error.getUserMessage()),
              ),
            ],
          ),
          backgroundColor: _getColor(error.type),
          behavior: SnackBarBehavior.fixed,
          duration: error.isRetryable
              ? const Duration(seconds: 5)
              : const Duration(seconds: 3),
          action: error.isRetryable && onRetry != null
              ? SnackBarAction(
                  label: 'Pokušaj',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        );

  static IconData _getIcon(ErrorType type) {
    return switch (type) {
      ErrorType.network => Icons.wifi_off,
      ErrorType.timeout => Icons.schedule,
      ErrorType.unauthorized => Icons.lock,
      ErrorType.forbidden => Icons.block,
      _ => Icons.error_outline,
    };
  }

  static Color _getColor(ErrorType type) {
    return switch (type) {
      ErrorType.network => Colors.orange,
      ErrorType.timeout => Colors.orange,
      ErrorType.unauthorized => Colors.red,
      ErrorType.forbidden => Colors.red,
      _ => Colors.red,
    };
  }

  /// Prikaži error snackbar
  static void show(
    BuildContext context, {
    required AppError error,
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      ErrorSnackBar(error: error, onRetry: onRetry),
    );
  }
}
