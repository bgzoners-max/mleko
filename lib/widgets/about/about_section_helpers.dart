import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/amazon_theme.dart';

/// Pomoćni graditelji sekcija za `AboutScreen` — izdvojeno iz ekrana
/// radi smanjenja veličine ispod CI limita (bez promene ponašanja).

Widget aboutSectionCard({
  required BuildContext context,
  required Color cardBg,
  required Color borderColor,
  required Widget child,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: AmazonColors.getCardShadow(context),
    ),
    child: child,
  );
}

Widget aboutComprehensiveSectionCard({
  required BuildContext context,
  required Color cardBg,
  required Color borderColor,
  required Color accentColor,
  required String tagText,
  required IconData badgeIcon,
  required String title,
  required String subtitle,
  required Widget content,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.4),
      boxShadow: AmazonColors.getCardShadow(context),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(badgeIcon, size: 24, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tagText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: GoogleFonts.bitter(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        content,
      ],
    ),
  );
}

Widget aboutCategoryBullet(
  BuildContext context,
  String label,
  String description,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: AmazonColors.amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget aboutAdvantageRow(
  BuildContext context,
  String label,
  String text,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2E7D32)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget aboutPillTag(BuildContext context, IconData icon, String text) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1B241E) : const Color(0xFFE8EFEA),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFF245938).withValues(alpha: 0.3),
        width: 0.8,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF245938)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF99D19C) : const Color(0xFF1B5E20),
          ),
        ),
      ],
    ),
  );
}

Widget aboutSubsectionHeader(
  BuildContext context,
  IconData icon,
  String title,
  Color color,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

Widget aboutFeatureRow(
  BuildContext context,
  IconData icon,
  String title,
  String description,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF245938).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF245938)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget aboutManifestItem(
  BuildContext context,
  String number,
  String title,
  String description,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD97724).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD97724).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFFD97724),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AmazonColors.darkTextPrimary : AmazonColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? AmazonColors.darkTextSecondary : AmazonColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}


