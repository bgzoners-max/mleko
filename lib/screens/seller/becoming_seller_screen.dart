import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_back_button.dart';

class BecomingSellerScreen extends StatefulWidget {
  const BecomingSellerScreen({super.key});

  @override
  State<BecomingSellerScreen> createState() => _BecomingSellerScreenState();
}

class _BecomingSellerScreenState extends State<BecomingSellerScreen> {
  final _farmNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _submit() async {
    if (_farmNameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Naziv profila, mesto i telefon su obavezni.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final appState = context.read<AppState>();
    try {
      await appState.authService.switchToSeller(
        farmName: _farmNameController.text.trim(),
        location: _locationController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil prodavca je aktivan.')),
        );
        context.go('/search?view=products');
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg =
            e.toString().replaceFirst('Exception: ', '').split('\n').first;
        setState(() => _error = msg);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1E3424) : theme.colorScheme.surface,
        foregroundColor: isDark ? Colors.white : theme.colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: isDark
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
        leading: const AppBackButton(fallbackRoute: '/'),
        title: const Text('Postani prodavac'),
        actions: const [AppHomeButton()],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.formContentWidth(context),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Unesite osnovne podatke o prodajnom profilu da biste mogli da objavljujete proizvode i budete vidljivi kupcima.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _farmNameController,
                    decoration: const InputDecoration(
                        labelText: 'Ime / Naziv profila *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Mesto *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon *'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Postani prodavac'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
