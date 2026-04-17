import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mleko/services/services.dart';
class AddBuyerReviewDialog extends StatefulWidget {
  final String sellerId;
  final String buyerId;
  final String orderId;
  final String buyerName;
  final VoidCallback? onSubmitted;

  const AddBuyerReviewDialog({
    super.key,
    required this.sellerId,
    required this.buyerId,
    required this.orderId,
    required this.buyerName,
    this.onSubmitted,
  });

  @override
  State<AddBuyerReviewDialog> createState() => _AddBuyerReviewDialogState();
}

class _AddBuyerReviewDialogState extends State<AddBuyerReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await context.read<ReviewsService>().addBuyerReview(
        sellerId: widget.sellerId,
        buyerId: widget.buyerId,
        orderId: widget.orderId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted) return;
      widget.onSubmitted?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocena za kupca je poslata.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greska: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Oceni kupca'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.buyerName,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            const Text('Ocena:'),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  tooltip: 'Ocena ${i + 1} od 5',
                  icon: Icon(i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber),
                  onPressed: () => setState(() => _rating = i + 1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'Komentar (opciono)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Posalji'),
        ),
      ],
    );
  }
}

