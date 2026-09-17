import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/serbian_cities.dart';
import '../../constants/serbian_districts.dart';
import '../../core/responsive.dart';
import '../../providers/classifieds_provider.dart';
import '../../utils/number_input_utils.dart';

/// Prikazuje modalni prozor za odabir grada ili okruga za pretragu oglasa.
void showClassifiedCityPickerSheet(BuildContext context) {
  final provider = context.read<ClassifiedsProvider>();
  String searchQuery = '';
  int selectedTab = 0; // 0 = Gradovi, 1 = Okruzi

  showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final filteredCities = searchQuery.trim().isEmpty
              ? SerbianCities.all
              : SerbianCities.suggestions(searchQuery);

          final filteredDistricts = searchQuery.trim().isEmpty
              ? SerbianDistricts.all
              : SerbianDistricts.all.where((d) {
                  final q = searchQuery.toLowerCase().trim();
                  return d.name.toLowerCase().contains(q) ||
                      d.region.toLowerCase().contains(q) ||
                      d.cities.any((c) => c.toLowerCase().contains(q));
                }).toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollCtl) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.modalMaxWidth),
                  child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        const Text(
                          'Izaberi lokaciju',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Tabovi za gradove i okruge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Gradovi')),
                        ButtonSegment(value: 1, label: Text('Okruzi (ceo okrug)')),
                      ],
                      selected: {selectedTab},
                      onSelectionChanged: (val) {
                        setModalState(() => selectedTab = val.first);
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: selectedTab == 0 ? 'Pretraži grad...' : 'Pretraži okrug ili grad...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        setModalState(() => searchQuery = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView(
                      controller: scrollCtl,
                      children: [
                        if (searchQuery.trim().isEmpty)
                          ListTile(
                            title: const Text('Cela Srbija (sve lokacije)', style: TextStyle(fontWeight: FontWeight.bold)),
                            leading: const Icon(Icons.public),
                            trailing: (provider.selectedCity == null && provider.selectedDistrict == null)
                                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                : null,
                            onTap: () {
                              provider.selectCity(null);
                              provider.selectDistrict(null);
                              Navigator.pop(ctx);
                            },
                          ),

                        if (selectedTab == 0) ...[
                          ...filteredCities.map((city) {
                            final isSelected = provider.selectedCity == city;
                            return ListTile(
                              title: Text(city),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                  : null,
                              onTap: () {
                                provider.selectCity(city);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ] else ...[
                          ...filteredDistricts.map((dist) {
                            final isSelected = provider.selectedDistrict == dist.id;
                            return ListTile(
                              title: Text(dist.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${dist.region} · ${dist.cities.take(4).join(', ')}...',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                                  : null,
                              onTap: () {
                                provider.selectDistrict(dist.id);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
                  ),
                ),
              );
            },
          );
        },
      );
    },
  );
}

/// Prikazuje modalni prozor za podešavanje raspona cena i kvadrature (za nekretnine).
void showClassifiedPriceAndAreaFilterSheet(BuildContext context, {required bool isRealEstate}) {
  final provider = context.read<ClassifiedsProvider>();
  final colorScheme = Theme.of(context).colorScheme;

  final minPriceController = TextEditingController(
    text: provider.minPrice != null ? provider.minPrice!.toStringAsFixed(0) : '',
  );
  final maxPriceController = TextEditingController(
    text: provider.maxPrice != null ? provider.maxPrice!.toStringAsFixed(0) : '',
  );
  final minAreaController = TextEditingController(
    text: provider.selectedAttributes['min_area_m2']?.toString() ?? '',
  );
  final maxAreaController = TextEditingController(
    text: provider.selectedAttributes['max_area_m2']?.toString() ?? '',
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.modalMaxWidth),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      isRealEstate ? 'Filter cene i kvadrature' : 'Filter cene',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // CENA
                const Text('Cena (€)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Od (€)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Do (€)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // KVADRATURA (za nekretnine)
                if (isRealEstate) ...[
                  const Text('Kvadratura (m²)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minAreaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Od (m²)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: maxAreaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Do (m²)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Dugmad za akciju
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.setPriceRange(minPrice: null, maxPrice: null);
                          provider.removeAttributeFilter('min_area_m2');
                          provider.removeAttributeFilter('max_area_m2');
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Poništi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final minP = parseDecimal(minPriceController.text);
                          final maxP = parseDecimal(maxPriceController.text);
                          provider.setPriceRange(minPrice: minP, maxPrice: maxP);

                          if (isRealEstate) {
                            final minM2 = parseDecimal(minAreaController.text);
                            final maxM2 = parseDecimal(maxAreaController.text);
                            if (minM2 != null) {
                              provider.setAttributeFilter('min_area_m2', minM2);
                            } else {
                              provider.removeAttributeFilter('min_area_m2');
                            }
                            if (maxM2 != null) {
                              provider.setAttributeFilter('max_area_m2', maxM2);
                            } else {
                              provider.removeAttributeFilter('max_area_m2');
                            }
                          }

                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Primeni filtere'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
    },
  ).whenComplete(() {
    minPriceController.dispose();
    maxPriceController.dispose();
    minAreaController.dispose();
    maxAreaController.dispose();
  });
}
