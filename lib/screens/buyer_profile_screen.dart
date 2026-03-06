import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../providers/app_state.dart';
import '../services/chat_service.dart';
import '../services/reviews_service.dart';
import '../services/users_service.dart';
import '../widgets/app_error_retry.dart';

/// Profil kupca — vidi prodavac kada klikne na kupca u poruci ili porudžbini.
class BuyerProfileScreen extends StatefulWidget {
  final String buyerId;

  const BuyerProfileScreen({super.key, required this.buyerId});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  late Future<Map<String, dynamic>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load(widget.buyerId);
  }

  void _retry() => setState(() => _loadFuture = _load(widget.buyerId));

  static Future<Map<String, dynamic>> _load(String buyerId) async {
    final results = await Future.wait([
      UsersService().getUser(buyerId),
      ReviewsService().getReviewsByBuyer(buyerId),
      _loadDeliveredOrdersCount(buyerId),
    ]);
    final reviews = results[1] as List<ReviewModel>;

    // Batch-load seller names — jedan upit umesto N FutureBuilder poziva
    final sellerIds = reviews.map((r) => r.sellerId).toSet().toList();
    final Map<String, String> sellerNames = {};
    if (sellerIds.isNotEmpty) {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, farm_name, display_name')
          .inFilter('id', sellerIds);
      for (final p in profiles as List) {
        sellerNames[p['id'] as String] =
            (p['farm_name'] ?? p['display_name']) as String? ?? 'Prodavac';
      }
    }

    return {
      'user': results[0],
      'reviews': reviews,
      'sellerNames': sellerNames,
      'ordersCount': results[2] as int,
    };
  }

  static Future<int> _loadDeliveredOrdersCount(String buyerId) async {
    final list = await Supabase.instance.client
        .from('orders')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('status', 'delivered');
    return (list as List).length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil kupca')),
            body: AppErrorRetry(
              message: 'Greška pri učitavanju profila.',
              detail: snap.error?.toString(),
              onRetry: _retry,
            ),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil kupca')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data!['user'] as UserModel?;
        final reviews = snap.data!['reviews'] as List<ReviewModel>;
        final sellerNames = snap.data!['sellerNames'] as Map<String, String>;
        final ordersCount = snap.data!['ordersCount'] as int;
        final displayName = user?.displayName ?? user?.farmName ?? 'Kupac';

        return Scaffold(
          appBar: AppBar(title: Text(displayName)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BuyerHeaderCard(
                user: user,
                displayName: displayName,
                ordersCount: ordersCount,
                buyerId: widget.buyerId,
              ),
              const SizedBox(height: 16),
              Text(
                'Ocene kao kupac',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (reviews.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Kupac još nije ostavio recenzije.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                ...reviews.map((r) => _ReviewTile(
                      review: r,
                      sellerName: sellerNames[r.sellerId] ?? 'Prodavac',
                    )),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header sa statistikom i kontakt dugmetom ─────────────────────────────────

class _BuyerHeaderCard extends StatelessWidget {
  final UserModel? user;
  final String displayName;
  final int ordersCount;
  final String buyerId;

  const _BuyerHeaderCard({
    required this.user,
    required this.displayName,
    required this.ordersCount,
    required this.buyerId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AppState>().user;
    final canContact = currentUser != null &&
        !currentUser.isGuest &&
        currentUser.id != buyerId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Icon(Icons.person, size: 32, color: Colors.grey.shade600)
                      : null,
                ),
                const SizedBox(width: 16),
                        } catch (e, st) {
                          setState(() {
                            _loading = false;
                            _error = 'Greška pri učitavanju profila.';
                          });
                          final error = AppError.from(e, stackTrace: st, userMessage: 'Greška pri učitavanju profila.');
                          await ErrorDialog.show(context, error: error, onRetry: _loadProfile);
                        }
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (user?.location != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(user!.location!,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ],
                      if (user?.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Član od ${DateFormat('MMM yyyy.', 'sr').format(user!.createdAt!)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Statistika kupca
            if (ordersCount > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '$ordersCount isporučen${ordersCount == 1 ? 'a' : 'ih'} porudžbin${ordersCount == 1 ? 'a' : 'a'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            // Kontakt dugme — vidljivo prodavcima i svima koji nisu taj kupac
            if (canContact) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _ContactBuyerButton(buyerId: buyerId),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactBuyerButton extends StatefulWidget {
  final String buyerId;
  const _ContactBuyerButton({required this.buyerId});

  @override
  State<_ContactBuyerButton> createState() => _ContactBuyerButtonState();
}

class _ContactBuyerButtonState extends State<_ContactBuyerButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.chat_outlined, size: 18),
      label: const Text('Pošalji poruku'),
      onPressed: _loading ? null : _openChat,
    );
  }

  Future<void> _openChat() async {
    final currentUser = context.read<AppState>().user;
    if (currentUser == null) return;
    setState(() => _loading = true);
    try {
      final convId = await ChatService().getOrCreateConversation(
        widget.buyerId,
        currentUser.id,
      );
      if (mounted) context.push('/chat/$convId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Review tile (ime prodavca unapred prosleđeno, bez N+1) ───────────────────

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  final String sellerName;

  const _ReviewTile({required this.review, required this.sellerName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sellerName,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  DateFormat('d. MMM yyyy.', 'sr').format(review.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating ? Icons.star : Icons.star_border,
                  size: 18,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
