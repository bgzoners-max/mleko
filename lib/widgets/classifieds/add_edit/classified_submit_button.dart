import 'package:flutter/material.dart';

class ClassifiedSubmitButton extends StatelessWidget {
  final bool loading;
  final bool isEdit;
  final String? uploadStatusText;
  final VoidCallback? onSubmit;

  const ClassifiedSubmitButton({
    super.key,
    required this.loading,
    required this.isEdit,
    this.uploadStatusText,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onSubmit,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
                if (uploadStatusText != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    uploadStatusText!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            )
          : Text(
              isEdit ? 'Sačuvaj izmene' : 'Objavi oglas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
