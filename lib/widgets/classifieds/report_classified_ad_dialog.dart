import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_system.dart';
import '../../core/haptic.dart';
import '../../core/responsive.dart';
import '../../models/classified_ad_model.dart';
import '../../models/classified_report_model.dart';
import '../../providers/app_state.dart';
import '../../services/classifieds/classified_reports_service.dart';

/// Modalni dijalog za prijavu sumnjivog ili nepravilnog oglasa
class ReportClassifiedAdDialog extends StatefulWidget {
  final ClassifiedAdModel ad;

  const ReportClassifiedAdDialog({super.key, required this.ad});

  /// Statička pomoćna metoda za prikaz dijaloga
  static Future<bool?> show(BuildContext context, {required ClassifiedAdModel ad}) async {
    final appState = context.read<AppState>();
    final user = appState.user;

    if (user == null || user.isGuest) {
      AppHaptics.light();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prijavite se da biste prijavili nepravilnost u oglasu.'),
          action: SnackBarAction(
            label: 'Prijava',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return null;
    }

    if (user.id == ad.userId) {
      AppHaptics.light();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ne možete prijaviti sopstveni oglas.')),
      );
      return null;
    }

    final isDesktop = Breakpoints.isDesktop(context);

    if (isDesktop) {
      return showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ReportClassifiedAdDialog(ad: ad),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: ReportClassifiedAdDialog(ad: ad),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  State<ReportClassifiedAdDialog> createState() => _ReportClassifiedAdDialogState();
}

class _ReportClassifiedAdDialogState extends State<ReportClassifiedAdDialog> {
  String _selectedReason = ClassifiedReportReason.fraudScam;
  final _detailsController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    AppHaptics.medium();

    try {
      final reportsService = context.read<ClassifiedReportsService>();
      await reportsService.submitReport(
        adId: widget.ad.id,
        reason: _selectedReason,
        details: _detailsController.text,
      );

      if (mounted) {
        Navigator.pop(context, true);
        AppHaptics.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hvala vam na prijavi. Naš tim će pregledati oglas u najkraćem roku.',
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final msg = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Došlo je do greške pri prijavljivanju oglasa.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDesign.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle (za bottom sheet)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Zaglavlje
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prijavi oglas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.ad.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Izaberite razlog prijave:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Lista razloga
          ...ClassifiedReportReason.all.map((reason) {
            final isSelected = _selectedReason == reason;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                    : colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    setState(() => _selectedReason = reason);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          ClassifiedReportReason.iconFor(reason),
                          size: 20,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ClassifiedReportReason.labelFor(reason),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Dodatni detalji
          TextField(
            controller: _detailsController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Dodatni opis (opciono)',
              hintText: 'Opišite detaljnije problem...',
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dugmad za akciju
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Odustani'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.flag_rounded, size: 18),
                  label: Text(
                    _loading ? 'Slanje...' : 'Pošalji prijavu',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
