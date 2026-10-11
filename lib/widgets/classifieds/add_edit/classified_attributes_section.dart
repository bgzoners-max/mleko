import 'package:flutter/material.dart';
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
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'SIM kartica i povezivanje',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'SIM Free',
                    icon: Icons.lock_open_outlined,
                    value: currentAttributes['sim_free'] == true,
                    onChanged: (val) => onChanged('sim_free', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: '1x SIM slot',
                    icon: Icons.sim_card_outlined,
                    value: currentAttributes['sim_single'] == true,
                    onChanged: (val) {
                      onChanged('sim_single', val ? true : null);
                      if (val) onChanged('sim_dual', null);
                    },
                  ),
                  _buildCheckboxChip(
                    label: '2x SIM slota',
                    icon: Icons.sim_card_outlined,
                    value: currentAttributes['sim_dual'] == true,
                    onChanged: (val) {
                      onChanged('sim_dual', val ? true : null);
                      if (val) onChanged('sim_single', null);
                    },
                  ),
                  _buildCheckboxChip(
                    label: 'eSIM',
                    icon: Icons.contactless_outlined,
                    value: currentAttributes['sim_esim'] == true,
                    onChanged: (val) => onChanged('sim_esim', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: '5G',
                    icon: Icons.five_g_outlined,
                    value: currentAttributes['net_5g'] == true,
                    onChanged: (val) => onChanged('net_5g', val ? true : null),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // 3. Garancija (Checkbox opcije)
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Garancija',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'Zvanična garancija',
                    icon: Icons.verified_outlined,
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
                    icon: Icons.cell_tower_outlined,
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
                    icon: Icons.storefront_outlined,
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
                    icon: Icons.security_outlined,
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
      );

      // 4. Prateća oprema (Checkbox opcije)
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Prateća oprema',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCheckboxChip(
                    label: 'Originalna kutija',
                    icon: Icons.inventory_2_outlined,
                    value: currentAttributes['acc_box'] == true,
                    onChanged: (val) => onChanged('acc_box', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Punjač',
                    icon: Icons.electrical_services_outlined,
                    value: currentAttributes['acc_charger'] == true,
                    onChanged: (val) => onChanged('acc_charger', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'USB kabl',
                    icon: Icons.cable_outlined,
                    value: currentAttributes['acc_cable'] == true,
                    onChanged: (val) => onChanged('acc_cable', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Zaštitna maska',
                    icon: Icons.phone_android_outlined,
                    value: currentAttributes['acc_case'] == true,
                    onChanged: (val) => onChanged('acc_case', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Zaštitno staklo',
                    icon: Icons.shield_outlined,
                    value: currentAttributes['acc_glass'] == true,
                    onChanged: (val) => onChanged('acc_glass', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Slušalice',
                    icon: Icons.headphones_outlined,
                    value: currentAttributes['acc_headphones'] == true,
                    onChanged: (val) => onChanged('acc_headphones', val ? true : null),
                  ),
                  _buildCheckboxChip(
                    label: 'Fiskalni račun',
                    icon: Icons.receipt_long_outlined,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: value ? 1.5 : 1.0,
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
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 16,
              color: value ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
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
