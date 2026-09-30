import 'package:flutter/material.dart';
import '../../../models/category_attribute_model.dart';
import 'package:flutter/services.dart';
import '../../../utils/number_input_utils.dart';
import '../../../utils/classified_attributes_engine.dart';

class ClassifiedAttributesWrapper extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String? categoryId;
  final Map<String, dynamic> currentAttributes;
  final void Function(String key, dynamic value) onChanged;

  const ClassifiedAttributesWrapper({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.categoryId,
    required this.currentAttributes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categoryAttributes = ClassifiedAttributesEngine.getAttributesForCategory(categoryId);
    if (categoryAttributes.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClassifiedAttributesSection(
      theme: theme,
      colorScheme: colorScheme,
      attributes: categoryAttributes,
      currentAttributes: currentAttributes,
      onChanged: onChanged,
    );
  }
}

class ClassifiedAttributesSection extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final List<CategoryAttribute> attributes;
  final Map<String, dynamic> currentAttributes;
  final void Function(String key, dynamic value) onChanged;

  const ClassifiedAttributesSection({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.attributes,
    required this.currentAttributes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Karakteristike predmeta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final attr in attributes) ...[
              if (attr.type == AttributeType.number) ...[
                TextFormField(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: currentAttributes[attr.key]?.toString() ?? '',
                  keyboardType: attr.isDecimal
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.number,
                  inputFormatters: [
                    if (!attr.isDecimal)
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: attr.label,
                    hintText: attr.hint,
                    suffixText: attr.unit,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  onChanged: (val) {
                    final n = attr.isDecimal
                        ? NumberInputUtils.parseDecimal(val)
                        : NumberInputUtils.parseInteger(val);
                    onChanged(attr.key, n);
                  },
                ),
                const SizedBox(height: 12),
              ] else if (attr.type == AttributeType.select) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: currentAttributes[attr.key]?.toString(),
                  decoration: InputDecoration(
                    labelText: attr.label,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Nije izabrano',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    ...(attr.options ?? const []).map(
                      (opt) => DropdownMenuItem(
                        value: opt.value,
                        child: Text(opt.label),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val == null || val.isEmpty) {
                      onChanged(attr.key, null);
                    } else {
                      onChanged(attr.key, val);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ] else if (attr.type == AttributeType.boolean) ...[
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  title: Text(attr.label),
                  subtitle: attr.hint != null ? Text(attr.hint!) : null,
                  value: currentAttributes[attr.key] == true,
                  onChanged: (val) {
                    onChanged(attr.key, val);
                  },
                ),
                const SizedBox(height: 8),
              ] else ...[
                TextFormField(
                  key: ValueKey('attr_${attr.key}'),
                  initialValue: currentAttributes[attr.key]?.toString() ?? '',
                  decoration: InputDecoration(
                    labelText: attr.label,
                    hintText: attr.hint,
                    suffixText: attr.unit,
                    prefixIcon:
                        attr.icon != null ? Icon(attr.icon, size: 20) : null,
                  ),
                  onChanged: (val) {
                    final t = val.trim();
                    if (t.isNotEmpty) {
                      onChanged(attr.key, t);
                    } else {
                      onChanged(attr.key, null);
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
