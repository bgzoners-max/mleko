import 'package:flutter/material.dart';
import '../../core/design_system.dart';

class SearchHistoryPanel extends StatelessWidget {
  final Future<List<String>> historyFuture;
  final bool isSearchEmpty;
  final VoidCallback onClearAll;
  final void Function(String) onSelectHistory;
  final void Function(String) onRemoveHistory;

  const SearchHistoryPanel({
    super.key,
    required this.historyFuture,
    required this.isSearchEmpty,
    required this.onClearAll,
    required this.onSelectHistory,
    required this.onRemoveHistory,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: historyFuture,
      builder: (context, snap) {
        final history = snap.data ?? [];
        if (history.isEmpty) return const SizedBox.shrink();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          color: (isDark ? AmazonColors.darkCard : Colors.white)
              .withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isSearchEmpty ? 'Nedavne pretrage' : 'Predlozi',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  TextButton(
                    onPressed: onClearAll,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Obriši sve',
                        style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: history.take(6).map((h) {
                  return InputChip(
                    label: Text(h, style: const TextStyle(fontSize: 12)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => onSelectHistory(h),
                    onDeleted: () => onRemoveHistory(h),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
