import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pomoćne funkcije za korisničke interakcije i eksterne akcije (npr. pozivi).
///
/// Koristi se u [OrderInboxCard], [SellerOrderDraftBar] i [SellerOrdersScreen].
class ActionUtils {
  ActionUtils._();

  /// Pokreće telefonski poziv na zadati broj telefona uz bezbednu proveru `canLaunchUrl`.
  static Future<void> launchCall(BuildContext context, String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poziv nije moguć na ovom uređaju.')),
        );
      }
      return;
    }
    await launchUrl(uri);
  }
}
