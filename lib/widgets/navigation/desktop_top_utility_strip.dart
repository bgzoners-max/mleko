import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/design_system.dart';
import '../../providers/location_provider.dart';

/// Pomoćna funkcija za otvaranje modalnog dijaloga za izbor regiona u Srbiji.
Future<void> openLocationDialog(BuildContext context) async {
  final loc = context.read<LocationProvider>();
  final currentRegion = loc.selectedRegion;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final selected = await showDialog<String>(
    context: context,
    builder: (ctx) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: isDark ? AmazonColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? AmazonColors.lightGreen : AmazonColors.green).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: isDark ? AmazonColors.lightGreen : AmazonColors.green,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Izaberite region u Srbiji',
                            style: AppFonts.display(
                              isDark ? Colors.white : AmazonColors.darkNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Prikazujte ponude domaćih gazdinstava u vašoj blizini',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => Navigator.pop(ctx, ''),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentRegion == null
                          ? AmazonColors.green.withValues(alpha: isDark ? 0.2 : 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentRegion == null
                            ? AmazonColors.green
                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🇷🇸', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cela Srbija (Svi regioni)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : AmazonColors.darkNavy,
                                ),
                              ),
                              Text(
                                'Prikaz svih domaćih proizvođača bez geografskog filtera',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentRegion == null)
                          Icon(Icons.check_circle_rounded,
                              color: isDark ? AmazonColors.lightGreen : AmazonColors.green, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.regions.map((reg) {
                    final isSel = currentRegion == reg;
                    return InkWell(
                      onTap: () => Navigator.pop(ctx, reg),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AmazonColors.green.withValues(alpha: isDark ? 0.25 : 0.1)
                              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAF8)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? AmazonColors.green
                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pin_drop_outlined,
                              size: 16,
                              color: isSel ? (isDark ? AmazonColors.lightGreen : AmazonColors.green) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reg,
                              style: TextStyle(
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                                color: isSel
                                    ? (isDark ? AmazonColors.lightGreen : AmazonColors.green)
                                    : (isDark ? Colors.white : AmazonColors.darkNavy),
                              ),
                            ),
                            if (isSel) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check, size: 16, color: isDark ? AmazonColors.lightGreen : AmazonColors.green),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  if (selected != null && context.mounted) {
    if (selected.isEmpty) {
      unawaited(loc.clearRegion());
    } else {
      await loc.setRegion(selected);
    }
  }
}

/// Gornja traka za desktop (slogan, izbor regiona, kontakt email i instagram).
class DesktopTopUtilityStrip extends StatelessWidget {
  final bool isDark;
  final String? selectedRegion;

  const DesktopTopUtilityStrip({
    super.key,
    required this.isDark,
    required this.selectedRegion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF0F1711) : const Color(0xFF1E3A27),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Row(
            children: [
              // Poruka poverenja
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    '100% domaća hrana i proizvodi direktno od poljoprivrednih gazdinstava širom Srbije',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Lokacija brzi selektor
              InkWell(
                onTap: () => openLocationDialog(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AmazonColors.amber),
                      const SizedBox(width: 4),
                      Text(
                        selectedRegion != null ? 'Region: $selectedRegion' : 'Srbija: Svi regioni',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Email
              InkWell(
                onTap: () => launchUrl(Uri.parse('mailto:kontakt@domacimarket.rs')),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outline, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Text(
                        'kontakt@domacimarket.rs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Instagram
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse('https://www.instagram.com/domacimarket.rs'),
                  mode: LaunchMode.externalApplication,
                ),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 13, color: Colors.white.withValues(alpha: 0.85)),
                      const SizedBox(width: 4),
                      Text(
                        '@domacimarket.rs',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
