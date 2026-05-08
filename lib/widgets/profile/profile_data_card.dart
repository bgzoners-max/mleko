import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../core/design_system.dart';
import 'edit_profile_sheet.dart';

class ProfileDataCard extends StatelessWidget {
  final UserModel user;
  const ProfileDataCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Moji podaci',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
            if (user.createdAt != null) ...[
              Text(
                'Član od ${DateFormat('dd.MM.yyyy', 'sr').format(user.createdAt!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 2),
            ],
            if (user.displayName != null)
              DataRowWidget(label: 'Ime', value: user.displayName!),
            if (user.phone != null)
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
            if (user.city != null) DataRowWidget(label: 'Grad', value: user.city!),
            if (user.postalCode != null) DataRowWidget(label: 'Poštanski broj', value: user.postalCode!),
            if (user.address != null)
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
                          TextSpan(text: user.address!),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'Vidljivo samo tebi',
                      child: Icon(Icons.lock_outline,
                          size: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            if (user.email != null && !user.isGuest)
              DataRowWidget(label: 'Email', value: user.email!),
            if (user.isSeller && user.farmName != null)
              DataRowWidget(label: 'Gazdinstvo', value: user.farmName!),
            if (user.isSeller && user.sellerTags.isNotEmpty) ...[
              const SizedBox(height: 2),
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
    );
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditProfileSheet(user: user),
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
      padding: const EdgeInsets.only(bottom: AppDesign.spaceXS - 3), // very tight
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
