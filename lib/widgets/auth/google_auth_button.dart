import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_error.dart';
import '../../providers/app_state.dart';
import '../error_dialog.dart';
import 'auth_error_formatter.dart';
import 'google_icon.dart';

/// Zajedničko dugme za prijavu i registraciju putem Google naloga.
class GoogleAuthButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final ValueChanged<String>? onError;

  const GoogleAuthButton({
    super.key,
    required this.label,
    this.enabled = true,
    this.onError,
  });

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  bool _loading = false;

  Future<void> _handlePressed() async {
    if (!widget.enabled || _loading) return;
    setState(() => _loading = true);
    try {
      await context.read<AppState>().authService.signInWithGoogle();
    } on Exception catch (e) {
      if (mounted) {
        final errorMsg = formatAuthError(e);
        widget.onError?.call(errorMsg);
        final error = AppError.from(
          e,
          stackTrace: StackTrace.current,
          userMessage: errorMsg,
        );
        await ErrorDialog.show(
          context,
          error: error,
          onRetry: _handlePressed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAppLoading = context.watch<AppState>().isLoading;
    final isDisabled = !widget.enabled || isAppLoading || _loading;

    return OutlinedButton(
      onPressed: isDisabled ? null : _handlePressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: isDark ? const Color(0xFF242A25) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1F2937),
        side: BorderSide(
          color: isDark ? Colors.white24 : const Color(0xFFD1D5DB),
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const GoogleLogo(size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
