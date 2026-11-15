import 'package:flutter/material.dart';

import '../../app_empty_state.dart';
import '../../auth/guest_auth_buttons.dart';

class ClassifiedGuestEmptyState extends StatelessWidget {
  const ClassifiedGuestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: AppEmptyState(
          icon: Icons.account_circle_outlined,
          title: 'Potrebna prijava za postavljanje oglasa',
          subtitle:
              'Kao gost možete slobodno pregledati oglase i kontaktirati prodavce. Za objavu sopstvenog oglasa potrebno je da se prijavite ili besplatno registrujete.',
          cta: GuestAuthButtons(useGoNavigation: false),
        ),
      ),
    );
  }
}
