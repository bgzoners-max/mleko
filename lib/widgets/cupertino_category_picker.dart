import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/categories_provider.dart';

/// Cupertino-style picker for category selection.
/// Uses categoryNames from provider (flat list).
/// Shown in bottom sheet modal.
class CupertinoCategoryPicker extends StatefulWidget {
  final String? initialCategory;
  final ValueChanged<String?> onCategoryChanged;
  final String label;
  final FormFieldValidator<String?>? validator;

  const CupertinoCategoryPicker({
    super.key,
    this.initialCategory,
    required this.onCategoryChanged,
    this.label = 'Kategorija *',
    this.validator,
  });

  @override
  State<CupertinoCategoryPicker> createState() =>
      _CupertinoCategoryPickerState();
}

class _CupertinoCategoryPickerState extends State<CupertinoCategoryPicker> {
  late FixedExtentScrollController _controller;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriesProvider>(
      builder: (context, provider, child) {
        final categoryNames = provider.categoryNames;
        final isLoading = provider.isLoading;

        if (categoryNames.isEmpty && !isLoading) {
          return TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: 'Nema kategorija',
            ),
          );
        }

        // Find initial index
        _selectedIndex = categoryNames.indexOf(widget.initialCategory ?? '');
        if (_selectedIndex < 0) _selectedIndex = 0;

        return GestureDetector(
          onTap: () => _showPicker(context, categoryNames),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.initialCategory ?? 'Izaberite kategoriju',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context, List<String> categoryNames) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.separator),
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  CupertinoButton(
                    child: const Text('Gotovo'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  widget.onCategoryChanged(categoryNames[index]);
                },
                scrollController: _controller,
                children: categoryNames
                    .map((name) => Center(
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 17),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
