import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/error_messages.dart';
import '../models/seller_delivery_models.dart';
import '../providers/app_state.dart';
import '../services/services.dart';

class SellerDeliverySettingsTab extends StatefulWidget {
  const SellerDeliverySettingsTab({super.key});

  @override
  State<SellerDeliverySettingsTab> createState() =>
      _SellerDeliverySettingsTabState();
}

class _SellerDeliverySettingsTabState extends State<SellerDeliverySettingsTab> {
  final SellerDeliveryService _service = SellerDeliveryService();
  bool _loading = true;
  String? _error;
  List<SellerDeliveryPointModel> _points = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sellerId = context.read<AppState>().user?.id;
    if (sellerId == null) {
      setState(() {
        _loading = false;
        _error = 'Prodavac nije prijavljen.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final points = await _service.getSellerDeliveryPoints(sellerId);
      if (!mounted) return;
      setState(() {
        _points = points;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openPointDialog([SellerDeliveryPointModel? existing]) async {
    final sellerId = context.read<AppState>().user?.id;
    if (sellerId == null) return;

    final cityController = TextEditingController(text: existing?.city ?? '');
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var isActive = existing?.isActive ?? true;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nova lokacija' : 'Izmeni lokaciju'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'Grad'),
                    validator: (value) =>
                        (value ?? '').trim().isEmpty ? 'Unesi grad.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Naziv mesta',
                      hintText: 'Pijaca centar, parking kod hale...',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Unesi naziv mesta.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Adresa ili opis lokacije',
                    ),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Unesi adresu ili opis lokacije.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Napomena',
                      hintText: 'Primer: stižemo kod glavnog ulaza.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: isActive,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktivna lokacija'),
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final point = SellerDeliveryPointModel(
                  id: existing?.id ?? '',
                  sellerId: sellerId,
                  city: cityController.text.trim(),
                  label: labelController.text.trim(),
                  address: addressController.text.trim(),
                  notes: notesController.text.trim(),
                  isActive: isActive,
                  slots: existing?.slots ?? const [],
                );
                try {
                  if (existing == null) {
                    await _service.createDeliveryPoint(point);
                  } else {
                    await _service.updateDeliveryPoint(point);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(friendlyError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    cityController.dispose();
    labelController.dispose();
    addressController.dispose();
    notesController.dispose();

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existing == null
                ? 'Lokacija je dodata.'
                : 'Lokacija je ažurirana.'),
          ),
        );
      }
    }
  }

  Future<void> _openSlotDialog(
    SellerDeliveryPointModel point, [
    SellerDeliverySlotModel? existing,
  ]) async {
    final feeController = TextEditingController(
      text: existing?.deliveryFeeRsd?.toStringAsFixed(0) ?? '',
    );
    final minOrderController = TextEditingController(
      text: existing?.minOrderAmountRsd?.toStringAsFixed(0) ?? '',
    );
    final maxOrdersController = TextEditingController(
      text: existing?.maxOrders?.toString() ?? '',
    );
    var weekday = existing?.weekday ?? 1;
    var timeFrom = _parseTime(existing?.timeFrom ?? '08:00');
    var timeTo = _parseTime(existing?.timeTo ?? '12:00');
    var isActive = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Novi termin' : 'Izmeni termin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: weekday,
                  decoration: const InputDecoration(labelText: 'Dan'),
                  items: List.generate(
                    7,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(sellerDeliveryWeekdayLabel(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => weekday = value);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: dialogContext,
                            initialTime: timeFrom,
                          );
                          if (selected == null) return;
                          setDialogState(() => timeFrom = selected);
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text('Od ${_formatTimeOfDay(timeFrom)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: dialogContext,
                            initialTime: timeTo,
                          );
                          if (selected == null) return;
                          setDialogState(() => timeTo = selected);
                        },
                        icon: const Icon(Icons.schedule_send),
                        label: Text('Do ${_formatTimeOfDay(timeTo)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Doplata za dostavu (RSD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minimalna porudžbina (RSD)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxOrdersController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Maksimalno porudžbina',
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktivan termin'),
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Otkaži'),
            ),
            FilledButton(
              onPressed: () async {
                final fromMinutes = timeFrom.hour * 60 + timeFrom.minute;
                final toMinutes = timeTo.hour * 60 + timeTo.minute;
                if (fromMinutes >= toMinutes) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vreme početka mora biti pre kraja.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final slot = SellerDeliverySlotModel(
                  id: existing?.id ?? '',
                  deliveryPointId: point.id,
                  weekday: weekday,
                  timeFrom: _formatTimeOfDay(timeFrom),
                  timeTo: _formatTimeOfDay(timeTo),
                  deliveryFeeRsd: double.tryParse(feeController.text.trim()),
                  minOrderAmountRsd:
                      double.tryParse(minOrderController.text.trim()),
                  maxOrders: int.tryParse(maxOrdersController.text.trim()),
                  isActive: isActive,
                );

                try {
                  if (existing == null) {
                    await _service.createDeliverySlot(slot);
                  } else {
                    await _service.updateDeliverySlot(slot);
                  }
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(friendlyError(e)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );

    feeController.dispose();
    minOrderController.dispose();
    maxOrdersController.dispose();

    if (saved == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                existing == null ? 'Termin je dodat.' : 'Termin je ažuriran.'),
          ),
        );
      }
    }
  }

  Future<void> _deletePoint(SellerDeliveryPointModel point) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Obriši lokaciju?'),
            content: Text(
              'Lokacija "${point.label}" i svi njeni termini biće uklonjeni.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Otkaži'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Obriši'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _service.deleteDeliveryPoint(point.id);
    await _load();
  }

  Future<void> _deleteSlot(SellerDeliverySlotModel slot) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Obriši termin?'),
            content: Text(
              'Termin ${slot.weekdayLabel}, ${slot.timeRangeLabel} biće uklonjen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Otkaži'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Obriši'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    await _service.deleteDeliverySlot(slot.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Dodaj gradove, mesta preuzimanja i termine u kojima lično dostavljaš. Kupac će u checkout-u birati tačan grad, lokaciju i termin.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _loading ? null : () => _openPointDialog(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Dodaj lokaciju'),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child:
                  Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            )
          else if (_points.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Još nemaš definisane lokacije. Dodaj prvo mesto isporuke, pa zatim termine za svaki grad ili punkt.',
              ),
            )
          else
            ..._points.map(_buildPointCard),
        ],
      ),
    );
  }

  Widget _buildPointCard(SellerDeliveryPointModel point) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  point.label,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Chip(label: Text(point.city)),
                if (!point.isActive) const Chip(label: Text('Neaktivno')),
              ],
            ),
            const SizedBox(height: 6),
            Text(point.address),
            if ((point.notes ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                point.notes!,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openSlotDialog(point),
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('Dodaj termin'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openPointDialog(point),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Izmeni'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _deletePoint(point),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Obriši'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (point.slots.isEmpty)
              Text(
                'Nema termina za ovu lokaciju.',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ...point.slots.map(
                (slot) => Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: slot.isActive
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: slot.isActive
                          ? theme.colorScheme.outlineVariant
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${slot.weekdayLabel}, ${slot.timeRangeLabel}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!slot.isActive)
                            Text(
                              'Neaktivan',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (slot.deliveryFeeRsd != null)
                            'Dostava ${formatRsdAmount(slot.deliveryFeeRsd)}',
                          if (slot.minOrderAmountRsd != null)
                            'Minimum ${formatRsdAmount(slot.minOrderAmountRsd)}',
                          if (slot.maxOrders != null) 'Maks ${slot.maxOrders}',
                        ].join(' • '),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _openSlotDialog(point, slot),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Izmeni'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _deleteSlot(slot),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Obriši'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
