import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_empty_state.dart';

class ClassifiedGuestEmptyState extends StatelessWidget {
  const ClassifiedGuestEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AppEmptyState(
          icon: Icons.account_circle_outlined,
          title: 'Potrebna prijava za postavljanje oglasa',
          subtitle:
              'Kao gost možete slobodno pregledati oglase i kontaktirati prodavce. Za objavu sopstvenog oglasa potrebno je da se prijavite ili besplatno registrujete.',
          ctaLabel: 'Prijavi se',
          ctaIcon: Icons.login,
          onCtaPressed: () => context.push('/login'),
        ),
      ),
    );
  }
}
