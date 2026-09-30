import 'package:flutter/material.dart';
import '../../../models/classified_ad_model.dart';
import '../../../theme/app_haptics.dart';
import '../../../widgets/classifieds/report_classified_ad_dialog.dart';

class ClassifiedReportButton extends StatelessWidget {
  final ClassifiedAdModel ad;
  final bool isOwner;
  final ColorScheme colorScheme;

  const ClassifiedReportButton({
    super.key,
    required this.ad,
    required this.isOwner,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) return const SizedBox.shrink();

    return Center(
      child: TextButton.icon(
        onPressed: () {
          AppHaptics.light();
          ReportClassifiedAdDialog.show(context, ad: ad);
        },
        icon: Icon(
          Icons.flag_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        label: Text(
          'Prijavi nepravilnost ili sumnjiv oglas',
          style: TextStyle(
            fontSize: 11.5,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
