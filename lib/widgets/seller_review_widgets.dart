import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/review_model.dart';
import '../services/services.dart';

/// Jedna recenzija na profilu prodavca ili na stranici „Recenzije“ (odgovor / izmena).
class SellerReviewListItem extends StatelessWidget {
  final ReviewModel review;
  final bool isSeller;
  final VoidCallback onRefresh;
  /// Kupac koji je ostavio recenziju (prikazno ime).
  final String reviewerDisplayName;
  /// Otvara profil kupca (`/buyer/...`).
  final VoidCallback onReviewerTap;

  const SellerReviewListItem({
    super.key,
    required this.review,
    required this.isSeller,
    required this.onRefresh,
    required this.reviewerDisplayName,
    required this.onReviewerTap,
  });

  @override
  Widget build(BuildContext context) {
    final canAct = isSeller && review.isReplyEditable;
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
                  InkWell(
                    onTap: onReviewerTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline, size: 18, color: scheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              reviewerDisplayName.isNotEmpty ? reviewerDisplayName : 'Kupac',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.primary,
                                  ),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 18, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
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
                    const SizedBox(height: 4),
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
          SellerReplyBlock(
            reply: review.sellerReply!,
            replyAt: review.sellerReplyAt,
          ),
        ],
      ],
    );
  }

  void _showReplyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => SellerReplyDialog(
        review: review,
        onSaved: onRefresh,
      ),
    );
  }
}

class SellerReplyBlock extends StatelessWidget {
  final String reply;
  final DateTime? replyAt;

  const SellerReplyBlock({super.key, required this.reply, this.replyAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: scheme.primary.withValues(alpha: 0.4), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Text(
                'Odgovor prodavca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
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

class SellerReplyDialog extends StatefulWidget {
  final ReviewModel review;
  final VoidCallback onSaved;

  const SellerReplyDialog({
    super.key,
    required this.review,
    required this.onSaved,
  });

  @override
  State<SellerReplyDialog> createState() => _SellerReplyDialogState();
}

class _SellerReplyDialogState extends State<SellerReplyDialog> {
  late final TextEditingController _ctrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.review.sellerReply ?? '');
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
      await ReviewsService().addSellerReply(
        reviewId: widget.review.id,
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
      title: Text(hasExisting ? 'Izmeni odgovor' : 'Odgovori na recenziju'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              labelText: 'Vaš odgovor',
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
