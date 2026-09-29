import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_back_button.dart';

class ChatScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? otherPartyName;
  final String? otherPartyId;
  final bool isBuyer;

  const ChatScreenAppBar({
    super.key,
    required this.otherPartyName,
    required this.otherPartyId,
    required this.isBuyer,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const AppBackButton(fallbackRoute: '/conversations'),
      title: Text(otherPartyName ?? 'Razgovor'),
      actions: [
        if (otherPartyId != null)
          IconButton(
            tooltip: isBuyer ? 'Profil prodavca' : 'Profil kupca',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push(
              isBuyer ? '/seller/$otherPartyId' : '/buyer/$otherPartyId',
            ),
          ),
        const AppHomeButton(),
      ],
    );
  }
}
