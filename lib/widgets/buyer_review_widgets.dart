import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/buyer_review_model.dart';
import '../services/services.dart';

/// Primljena ocena od prodavca — kupac može jednom da odgovori (bez dalje rasprave).
class BuyerReceivedReviewListItem extends StatelessWidget {
  final BuyerReviewModel review;
  final String sellerName;
  final bool isOwner;
  final VoidCallback onRefresh;

  const BuyerReceivedReviewListItem({
    super.key,
    required this.review,
    required this.sellerName,
    required this.isOwner,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final canAct = isOwner && review.isReplyEditable;
    final hasReply = !review.hasNoReply;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              context.push('/seller/${review.sellerId}'),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_outlined,
                                  size: 16, color: scheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sellerName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.primary,
                                      ),
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  size: 18, color: scheme.primary),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('d. MMM yyyy.', 'sr').format(review.createdAt),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ],
              ),
            ),
            if (canAct) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: Icon(
                  hasReply ? Icons.edit_outlined : Icons.reply_outlined,
                  size: 16,
                ),
                label: Text(
                  hasReply ? 'Izmeni' : 'Odgovori',
                  style: const TextStyle(fontSize: 13),
                ),
                onPressed: () => _showReplyDialog(context),
              ),
            ],
          ],
        ),
        if (hasReply) ...[
          const SizedBox(height: 8),
          BuyerReplyPublicBlock(
            reply: review.buyerReply!,
            replyAt: review.buyerReplyAt,
          ),
        ],
      ],
    );
  }

  void _showReplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BuyerReplyDialog(
        review: review,
        sellerName: sellerName,
        onSaved: onRefresh,
      ),
    );
  }
}

/// Prikaz sačuvanog odgovora kupca (javno na profilu kupca).
class BuyerReplyPublicBlock extends StatelessWidget {
  final String reply;
  final DateTime? replyAt;

  const BuyerReplyPublicBlock({super.key, required this.reply, this.replyAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.secondary.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: scheme.secondary),
              const SizedBox(width: 4),
              Text(
                'Vaš odgovor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
              if (replyAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  DateFormat('d. MMM yyyy.', 'sr').format(replyAt!),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(reply, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class BuyerReplyDialog extends StatefulWidget {
  final BuyerReviewModel review;
  final String sellerName;
  final VoidCallback onSaved;

  const BuyerReplyDialog({
    super.key,
    required this.review,
    required this.sellerName,
    required this.onSaved,
  });

  @override
  State<BuyerReplyDialog> createState() => _BuyerReplyDialogState();
}

class _BuyerReplyDialogState extends State<BuyerReplyDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.review.buyerReply ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<ReviewsService>().addBuyerReply(
        buyerReviewId: widget.review.id,
        reply: text,
      );
      if (mounted) {
        widget.onSaved();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Odgovor sačuvan.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('reply_not_editable_after_24h')
          ? 'Odgovor nije moguće menjati nakon 24h.'
          : 'Greška: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = !widget.review.hasNoReply;
    return AlertDialog(
      title: Text(hasExisting ? 'Izmeni odgovor' : 'Odgovori prodavcu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sellerName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < widget.review.rating ? Icons.star : Icons.star_border,
                        size: 14,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  if (widget.review.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.review.comment,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Vaš odgovor (zahvalnica, pojašnjenje…)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (hasExisting)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Izmena je moguća samo unutar 24h od prvog odgovora.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
