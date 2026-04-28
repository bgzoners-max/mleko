import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mleko/services/services.dart';
import '../core/utils/error_messages.dart';
/// Dijalog za ocenjivanje prodavca (1–5 zvezdica + komentar).
/// Prikazuje se kupcima koji su imali isporučenu porudžbinu.
class AddReviewDialog extends StatefulWidget {
  final String buyerId;
  final String sellerId;
  final String productId;
  final String orderId;
  final String productName;
  final VoidCallback? onSubmitted;

  const AddReviewDialog({
    super.key,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.orderId,
    required this.productName,
    this.onSubmitted,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
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
      await context.read<ReviewsService>().addReview(
        buyerId: widget.buyerId,
        sellerId: widget.sellerId,
        orderId: widget.orderId,
        productId: widget.productId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (mounted) {
        widget.onSubmitted?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recenzija poslata.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ostavi recenziju'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            const Text('Ocena:'),
            Row(
              children: List.generate(5, (i) => IconButton(
                tooltip: 'Ocena ${i + 1} od 5',
                icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: Colors.amber),
                onPressed: () => setState(() => _rating = i + 1),
              )),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Komentar (opciono)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Odustani')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Pošalji'),
        ),
      ],
    );
  }
}

