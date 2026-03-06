import 'package:flutter/material.dart';

/// Dijalog za otkazivanje porudžbine od strane prodavca – traži kratko objašnjenje
class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({super.key});

  /// Vraća objašnjenje ako korisnik potvrdi, null ako odustane
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => const CancelOrderDialog(),
    );
  }

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Otkaži porudžbinu'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Kratko objašnjenje (npr. nedostupna količina)',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        maxLength: 200,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Otkaži'),
        ),
      ],
    );
  }
}
