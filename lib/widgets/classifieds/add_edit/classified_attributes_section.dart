import 'package:flutter/material.dart';
import '../../../core/lucide_icons.dart';
import '../../../models/category_attribute_model.dart';
import 'package:flutter/services.dart';
import '../../../utils/number_input_utils.dart';
import '../../../utils/classified_attributes_engine.dart';

import '../../../models/classified_category_model.dart';

class ClassifiedAttributesWrapper extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String? categoryId;
  final List<ClassifiedCategoryModel>? breadcrumbs;
  final Map<String, dynamic> currentAttributes;
  final void Function(String key, dynamic value) onChanged;

  const ClassifiedAttributesWrapper({
    super.key,
    required this.theme,
    required this.colorScheme,
    required this.categoryId,
    this.breadcrumbs,
    required this.currentAttributes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categoryAttributes = ClassifiedAttributesEngine.getAttributesForCategory(
      categoryId,
      breadcrumbs: breadcrumbs,
    );
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
    final isWide = MediaQuery.sizeOf(context).width >= 600;
    final isPhone = attributes.any((a) => a.key == 'storage_gb');

    final List<Widget> items = [];
    if (isPhone) {
      final storageAttr = attributes.firstWhere((a) => a.key == 'storage_gb');
      final ramAttr = attributes.firstWhere((a) => a.key == 'ram_gb');
      final batteryAttr = attributes.where((a) => a.key == 'battery_capacity_mah').firstOrNull;

      // 1. Red sa memorijom i baterijom
      if (isWide && batteryAttr != null) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildField(storageAttr)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(ramAttr)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(batteryAttr)),
              ],
            ),
          ),
        );
      } else {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildField(storageAttr)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(ramAttr)),
              ],
            ),
          ),
        );
        if (batteryAttr != null) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildField(batteryAttr),
            ),
          );
        }
      }

      // 2. SIM i povezivanje (Checkbox opcije)
      items
        ..add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.radio,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SIM kartica i povezivanje',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'SIM Free',
                    icon: LucideIcons.unlock,
                    value: currentAttributes['sim_free'] == true,
                    onChanged: (val) => onChanged('sim_free', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: '1x SIM slot',
                    icon: LucideIcons.smartphone,
                    value: currentAttributes['sim_single'] == true,
                    onChanged: (val) {
                      onChanged('sim_single', val ? true : null);
                      if (val) onChanged('sim_dual', null);
                    },
                  ),
                  _buildCheckboxChip(
                    label: '2x SIM slota',
                    icon: LucideIcons.layers,
                    value: currentAttributes['sim_dual'] == true,
                    onChanged: (val) {
                      onChanged('sim_dual', val ? true : null);
                      if (val) onChanged('sim_single', null);
                    },
                  ),
                  _buildCheckboxChip(
                    label: 'eSIM',
                    icon: LucideIcons.nfc,
                    value: currentAttributes['sim_esim'] == true,
                    onChanged: (val) => onChanged('sim_esim', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: '5G',
                    icon: LucideIcons.signal,
                    value: currentAttributes['net_5g'] == true,
                    onChanged: (val) => onChanged('net_5g', val ? true : null),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
        // 3. Garancija (Checkbox opcije)
        ..add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Garancija',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'Zvanična garancija',
                    icon: LucideIcons.badgeCheck,
                    value: currentAttributes['warranty_official'] == true ||
                        currentAttributes['warranty'] == 'zvanicna',
                    onChanged: (val) {
                      onChanged('warranty_official', val ? true : null);
                      if (currentAttributes['warranty'] != null) {
                        onChanged('warranty', null);
                      }
                    },
                  ),
                  _buildCheckboxChip(
                    label: 'Garancija operatera',
                    icon: LucideIcons.radioTower,
                    value: currentAttributes['warranty_operator'] == true ||
                        currentAttributes['warranty'] == 'operater',
                    onChanged: (val) {
                      onChanged('warranty_operator', val ? true : null);
                      if (currentAttributes['warranty'] != null) {
                        onChanged('warranty', null);
                      }
                    },
                  ),
                  _buildCheckboxChip(
                    label: 'Garancija radnje / servisa',
                    icon: LucideIcons.store,
                    value: currentAttributes['warranty_shop'] == true ||
                        currentAttributes['warranty'] == 'servis_radnja',
                    onChanged: (val) {
                      onChanged('warranty_shop', val ? true : null);
                      if (currentAttributes['warranty'] != null) {
                        onChanged('warranty', null);
                      }
                    },
                  ),
                  _buildCheckboxChip(
                    label: 'Radna garancija',
                    icon: LucideIcons.wrench,
                    value: currentAttributes['warranty_working'] == true,
                    onChanged: (val) {
                      onChanged('warranty_working', val ? true : null);
                      if (currentAttributes['warranty'] != null) {
                        onChanged('warranty', null);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      )
        // 4. Prateća oprema (Checkbox opcije)
        ..add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.packageCheck,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prateća oprema',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'Originalna kutija',
                    icon: LucideIcons.package,
                    value: currentAttributes['acc_box'] == true,
                    onChanged: (val) => onChanged('acc_box', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Punjač',
                    icon: LucideIcons.plug,
                    value: currentAttributes['acc_charger'] == true,
                    onChanged: (val) => onChanged('acc_charger', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'USB kabl',
                    icon: LucideIcons.usb,
                    value: currentAttributes['acc_cable'] == true,
                    onChanged: (val) => onChanged('acc_cable', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Zaštitna maska',
                    icon: LucideIcons.shield,
                    value: currentAttributes['acc_case'] == true,
                    onChanged: (val) => onChanged('acc_case', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Zaštitno staklo',
                    icon: LucideIcons.sparkles,
                    value: currentAttributes['acc_glass'] == true,
                    onChanged: (val) => onChanged('acc_glass', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Slušalice',
                    icon: LucideIcons.headphones,
                    value: currentAttributes['acc_headphones'] == true,
                    onChanged: (val) => onChanged('acc_headphones', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Fiskalni račun',
                    icon: LucideIcons.receipt,
                    value: currentAttributes['acc_receipt'] == true,
                    onChanged: (val) => onChanged('acc_receipt', val ? true : null),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else if (isWide) {
      for (int i = 0; i < attributes.length; i += 2) {
        final first = attributes[i];
        final second = (i + 1 < attributes.length) ? attributes[i + 1] : null;

        if (second != null) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildField(first)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildField(second)),
                ],
              ),
            ),
          );
        } else {
          items.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildField(first)),
                  const SizedBox(width: 12),
                  const Spacer(),
                ],
              ),
            ),
          );
        }
      }
    } else {
      for (final attr in attributes) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildField(attr),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Karakteristike predmeta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildField(CategoryAttribute attr) {
    if (attr.type == AttributeType.number) {
      return TextFormField(
        key: ValueKey('attr_${attr.key}'),
        initialValue: currentAttributes[attr.key]?.toString() ?? '',
        keyboardType: attr.isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          if (!attr.isDecimal) FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          labelText: attr.label,
          hintText: attr.hint,
          suffixText: attr.unit,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: attr.icon != null ? Icon(attr.icon, size: 18) : null,
        ),
        onChanged: (val) {
          final n = attr.isDecimal
              ? NumberInputUtils.parseDecimal(val)
              : NumberInputUtils.parseInteger(val);
          onChanged(attr.key, n);
        },
      );
    } else if (attr.type == AttributeType.select) {
      return DropdownButtonFormField<String>(
        key: ValueKey('attr_${attr.key}'),
        initialValue: currentAttributes[attr.key]?.toString(),
        isExpanded: true,
        decoration: InputDecoration(
          labelText: attr.label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: attr.icon != null ? Icon(attr.icon, size: 18) : null,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Izaberi',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ...(attr.options ?? const []).map(
            (opt) => DropdownMenuItem(
              value: opt.value,
              child: Text(opt.label, overflow: TextOverflow.ellipsis),
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
      );
    } else if (attr.type == AttributeType.boolean) {
      return SwitchListTile.adaptive(
        dense: true,
        contentPadding: EdgeInsets.zero,
        secondary: attr.icon != null ? Icon(attr.icon, size: 18) : null,
        title: Text(attr.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: attr.hint != null ? Text(attr.hint!, style: const TextStyle(fontSize: 11)) : null,
        value: currentAttributes[attr.key] == true,
        onChanged: (val) => onChanged(attr.key, val),
      );
    } else {
      return TextFormField(
        key: ValueKey('attr_${attr.key}'),
        initialValue: currentAttributes[attr.key]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: attr.label,
          hintText: attr.hint,
          suffixText: attr.unit,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          prefixIcon: attr.icon != null ? Icon(attr.icon, size: 18) : null,
        ),
        onChanged: (val) {
          final t = val.trim();
          if (t.isNotEmpty) {
            onChanged(attr.key, t);
          } else {
            onChanged(attr.key, null);
          }
        },
      );
    }
  }

  Widget _buildCheckboxChip({
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: value
              ? colorScheme.primary.withValues(alpha: isDark ? 0.22 : 0.08)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.025)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.45),
            width: value ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 7),
            // Mikro flat Lucid ikonica pored checkbox-a
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? colorScheme.primary.withValues(alpha: isDark ? 0.32 : 0.14)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.045)),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: value
                      ? colorScheme.primary.withValues(alpha: 0.35)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.06)),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 13,
                color: value
                    ? (isDark ? Colors.white : colorScheme.primary)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                color: value
                    ? (isDark ? Colors.white : colorScheme.primary)
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
