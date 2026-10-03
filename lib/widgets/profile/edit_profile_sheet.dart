import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import 'edit_profile_form.dart';

export 'edit_profile_form.dart';

/// Modal bottom sheet za izmenu podataka profila.
class EditProfileSheet extends StatelessWidget {
  final UserModel user;

  const EditProfileSheet({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Uredi profil',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Zatvori',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: EditProfileForm(
                user: user,
                isFullScreen: false,
                onSaved: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
