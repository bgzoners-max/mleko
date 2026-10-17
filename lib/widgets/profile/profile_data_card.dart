import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/design_system.dart';
import '../../core/responsive.dart';
import '../../models/user_model.dart';
import 'edit_profile_sheet.dart';

class ProfileDataCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onEdit;
  const ProfileDataCard({super.key, required this.user, this.onEdit});

  void _showEditSheet(BuildContext context, UserModel user) {
    if (onEdit != null) {
      onEdit!();
      return;
    }
    if (Breakpoints.useTwoPaneLayout(context)) {
      context.push('/profile/edit');
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditProfileSheet(user: user),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressVal = user.address ?? user.location;
    final hasAnyData = (user.farmName != null && user.farmName!.trim().isNotEmpty) ||
        (user.displayName != null && user.displayName!.trim().isNotEmpty) ||
        (user.phone != null && user.phone!.trim().isNotEmpty) ||
        (user.city != null && user.city!.trim().isNotEmpty) ||
        (addressVal != null && addressVal.trim().isNotEmpty);

    return Card(
      child: InkWell(
        onTap: !user.isGuest ? () => _showEditSheet(context, user) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Moji podaci',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!user.isGuest)
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Uredi'),
                      onPressed: () => _showEditSheet(context, user),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              if (user.createdAt != null && !user.isGuest) ...[
                Text(
                  'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(user.createdAt!)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
              ],
              if (!hasAnyData && !user.isGuest) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dodajte ime, broj telefona i adresu za brže poručivanje.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (user.farmName != null && user.farmName!.trim().isNotEmpty)
                DataRowWidget(label: 'Prikazano ime', value: user.farmName!),
              if (user.displayName != null && user.displayName!.trim().isNotEmpty)
                DataRowWidget(label: 'Ime i prezime', value: user.displayName!),
              if (user.phone != null && user.phone!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                                text: 'Telefon: ',
                                style: TextStyle(color: Colors.grey.shade600)),
                            TextSpan(text: user.phone!),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: user.phonePublic
                            ? 'Vidljivo svima'
                            : 'Vidljivo samo tebi',
                        child: Icon(
                          user.phonePublic
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                          size: 13,
                          color: user.phonePublic
                              ? Colors.green.shade600
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (user.city != null && user.city!.trim().isNotEmpty)
                DataRowWidget(label: 'Grad', value: user.city!),
              if (user.postalCode != null && user.postalCode!.trim().isNotEmpty)
                DataRowWidget(label: 'Poštanski broj', value: user.postalCode!),
              if (addressVal != null && addressVal.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                                text: 'Adresa: ',
                                style: TextStyle(color: Colors.grey.shade600)),
                            TextSpan(text: addressVal),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Vidljivo samo tebi i prodavcu',
                        child: Icon(Icons.lock_outline,
                            size: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              if (user.email != null && !user.isGuest)
                DataRowWidget(label: 'Email', value: user.email!),
              if (user.isSeller && user.sellerTags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.sellerTags
                      .map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DataRowWidget extends StatelessWidget {
  final String label;
  final String value;
  const DataRowWidget({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceXS - 3),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(color: Colors.grey.shade600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
