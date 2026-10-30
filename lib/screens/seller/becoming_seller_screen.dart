import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../providers/app_state.dart';
import '../../utils/seller_registration_validator.dart';
import '../../widgets/app_back_button.dart';

class BecomingSellerScreen extends StatefulWidget {
  const BecomingSellerScreen({super.key});

  @override
  State<BecomingSellerScreen> createState() => _BecomingSellerScreenState();
}

class _BecomingSellerScreenState extends State<BecomingSellerScreen> {
  ProducerLegalType _legalType = ProducerLegalType.rpg;
  final _farmNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _bpgController = TextEditingController();
  final _pibController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _acceptedLiability = false;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user;
    if (user != null) {
      _farmNameController.text = user.farmName ?? '';
      _holderNameController.text = user.displayName ?? '';
      _locationController.text = user.city ?? user.location ?? '';
      _phoneController.text = user.phone ?? '';
      _bpgController.text = user.bpg ?? '';
      _pibController.text = user.pib ?? '';
      final parsedType = ProducerLegalType.fromDbValue(user.legalType);
      if (parsedType != null) {
        _legalType = parsedType;
      }
    }
  }

  Future<void> _submit() async {
    final farmName = _farmNameController.text.trim();
    final holderName = _holderNameController.text.trim();
    final location = _locationController.text.trim();
    final phone = _phoneController.text.trim();

    if (farmName.isEmpty || location.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Naziv, mesto i telefon su obavezni.');
      return;
    }

    if (_legalType == ProducerLegalType.rpg) {
      if (holderName.isEmpty) {
        setState(() => _error = 'Unesite ime i prezime nosioca gazdinstva.');
        return;
      }
      final bpgError = SellerRegistrationValidator.validateBpg(_bpgController.text);
      if (bpgError != null) {
        setState(() => _error = bpgError);
        return;
      }
    } else {
      final pibError = SellerRegistrationValidator.validatePib(_pibController.text);
      if (pibError != null) {
        setState(() => _error = pibError);
        return;
      }
    }

    if (!_acceptedLiability) {
      setState(() => _error =
          'Morate potvrditi izjavu o tačnosti podataka i ispravnosti proizvoda.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    final appState = context.read<AppState>();
    try {
      final cleanedBpg = _legalType == ProducerLegalType.rpg
          ? SellerRegistrationValidator.normalizeDigits(_bpgController.text)
          : null;
      final cleanedPib = _legalType == ProducerLegalType.company
          ? SellerRegistrationValidator.normalizeDigits(_pibController.text)
          : null;

      await appState.authService.switchToSeller(
        farmName: farmName,
        location: location,
        phone: phone,
        displayName: _legalType == ProducerLegalType.rpg ? holderName : null,
        legalType: _legalType.dbValue,
        bpg: cleanedBpg,
        pib: cleanedPib,
        legalLiabilityAcceptedAt: DateTime.now().toUtc(),
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
    _holderNameController.dispose();
    _bpgController.dispose();
    _pibController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRpg = _legalType == ProducerLegalType.rpg;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 46,
        centerTitle: false,
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
        title: Text(
          'Postani prodavac',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1B201C),
          ),
        ),
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
                    'Unesite podatke o registrovanom poljoprivrednom gazdinstvu (BPG) ili pravnom licu / preduzetniku (PIB) kako biste mogli da oglašavate proizvode na platformi.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Status proizvođača *',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ProducerLegalType>(
                    segments: const [
                      ButtonSegment<ProducerLegalType>(
                        value: ProducerLegalType.rpg,
                        icon: Icon(Icons.agriculture_outlined, size: 18),
                        label: Text('Poljoprivredno gazdinstvo'),
                      ),
                      ButtonSegment<ProducerLegalType>(
                        value: ProducerLegalType.company,
                        icon: Icon(Icons.business_outlined, size: 18),
                        label: Text('Pravno lice / Preduzetnik'),
                      ),
                    ],
                    selected: {_legalType},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _legalType = selection.first;
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _farmNameController,
                    decoration: InputDecoration(
                      labelText: isRpg
                          ? 'Naziv gazdinstva *'
                          : 'Naziv firme / preduzetnika *',
                    ),
                  ),
                  if (isRpg) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _holderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ime i prezime nosioca gazdinstva *',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bpgController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: const InputDecoration(
                        labelText:
                            'BPG (Broj poljoprivrednog gazdinstva – 12 cifara) *',
                        helperText:
                            'Pun BPG nije javno vidljiv (kupci vide samo status verifikovanog gazdinstva).',
                        helperMaxLines: 2,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pibController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'PIB (Poreski identifikacioni broj – 9 cifara) *',
                        helperText:
                            'Unesite važeći 9-cifreni PIB registrovan u APR-u.',
                      ),
                    ),
                  ],
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
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2B20)
                          : const Color(0xFFF3F7F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2D4B37)
                            : const Color(0xFFD2E2D7),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _acceptedLiability,
                      onChanged: _loading
                          ? null
                          : (val) => setState(() {
                                _acceptedLiability = val ?? false;
                                if (_acceptedLiability) _error = null;
                              }),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      title: Text(
                        SellerRegistrationValidator.legalLiabilityText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: isDark
                              ? Colors.grey.shade200
                              : const Color(0xFF26332A),
                        ),
                      ),
                    ),
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
