import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/utils/action_utils.dart';
import '../../core/utils/error_messages.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../providers/cart_provider.dart';
import 'package:mleko/services/services.dart';

class SellerOrderDraftBar extends StatelessWidget {
  final String sellerId;
  final UserModel seller;

  const SellerOrderDraftBar({super.key, required this.sellerId, required this.seller});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AppState, UserModel?>((s) => s.user);
    final canContact = user != null && !user.isGuest && user.id != sellerId;

    final draft = context.select<CartProvider, Map<String, double>>(
      (cart) => cart.getSellerDraft(sellerId),
    );
    final hasDraft = draft.isNotEmpty;

    if (!canContact && !hasDraft) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasDraft) ...[
              Text(
                '${draft.length} proizvoda u porudžbini kod ovog prodavca',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              FutureBuilder<List<({ProductModel product, double quantity})>>(
                future:
                    context.read<CartProvider>().getProductsBySeller(sellerId),
                builder: (_, snap) {
                  final items = snap.data ?? [];
                  if (items.isEmpty) return const SizedBox.shrink();
                  final preview =
                      items.take(3).map((e) => e.product.name).join(', ');
                  final suffix =
                      items.length > 3 ? ' +${items.length - 3}' : '';
                  return Text(
                    '$preview$suffix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  );
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => context.push('/checkout-seller/$sellerId'),
                icon: const Icon(Icons.send),
                label: const Text('Nastavi porudžbinu'),
              ),
              if (canContact) const SizedBox(height: 8),
            ],
            if (canContact)
              Builder(
                builder: (context) {
                  final hasPhone = seller.phone?.trim().isNotEmpty == true;
                  final chatButton = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final convId = await context.read<ChatService>()
                            .getOrCreateConversation(user.id, sellerId);
                        if (context.mounted) context.push('/chat/$convId');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(friendlyError(e)),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Pošalji poruku'),
                  );
                  if (hasPhone) {
                    return Row(
                      children: [
                        Expanded(child: SellerCallButton(seller: seller)),
                        const SizedBox(width: 8),
                        Expanded(child: chatButton),
                      ],
                    );
                  }
                  return chatButton;
                },
              ),
          ],
        ),
      ),
    );
  }
}

class SellerCallButton extends StatelessWidget {
  final UserModel seller;

  const SellerCallButton({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final phone = seller.phone?.trim();
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();

    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(48, 48),
      ),
      onPressed: () => ActionUtils.launchCall(context, seller.phone),
      icon: const Icon(Icons.phone, size: 18), 
      label: const Text('Pozovi'),
    );
  }
}
