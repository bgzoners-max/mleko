import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/services.dart';
import '../../utils/seller_registration_validator.dart';

class SellerLegalRegistrationSection extends StatefulWidget {
  const SellerLegalRegistrationSection({super.key});

  @override
  State<SellerLegalRegistrationSection> createState() =>
      _SellerLegalRegistrationSectionState();
}

class _SellerLegalRegistrationSectionState
    extends State<SellerLegalRegistrationSection> {
  ProducerLegalType _legalType = ProducerLegalType.rpg;
  final _bpgController = TextEditingController();
  final _pibController = TextEditingController();
  bool _saving = false;
  String? _error;
  String? _populatedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AppState>().user;
    if (user != null && _populatedUserId != user.id) {
      _populate(user);
    }
  }

  void _populate(UserModel user) {
    _populatedUserId = user.id;
    final parsed = ProducerLegalType.fromDbValue(user.legalType);
    if (parsed != null) {
      _legalType = parsed;
    } else if (user.pib != null && user.pib!.isNotEmpty) {
      _legalType = ProducerLegalType.company;
    } else {
      _legalType = ProducerLegalType.rpg;
    }
    _bpgController.text = user.bpg ?? '';
    _pibController.text = user.pib ?? '';
  }

  @override
  void dispose() {
    _bpgController.dispose();
    _pibController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final usersService = context.read<UsersService>();
    final user = appState.user;
    if (user == null) return;

    final isRpg = _legalType == ProducerLegalType.rpg;
    if (isRpg) {
      final err = SellerRegistrationValidator.validateBpg(_bpgController.text);
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    } else {
      final err = SellerRegistrationValidator.validatePib(_pibController.text);
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final cleanedBpg = isRpg
        ? SellerRegistrationValidator.normalizeDigits(_bpgController.text)
        : null;
    final cleanedPib = !isRpg
        ? SellerRegistrationValidator.normalizeDigits(_pibController.text)
        : null;

    final result = await ErrorHandlerService().executeWithResult(
      'Update seller legal registration',
      () => usersService.upsertProfile(
        user.id,
        legalType: _legalType.dbValue,
        bpg: cleanedBpg,
        pib: cleanedPib,
        legalLiabilityAcceptedAt:
            user.legalLiabilityAcceptedAt ?? DateTime.now().toUtc(),
      ),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.isSuccess) {
      await appState.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Podaci o registraciji proizvođača su sačuvani.'),
          ),
        );
      }
    } else {
      setState(() => _error = result.error?.getUserMessage() ?? 'Greška pri čuvanju.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = !Breakpoints.isPhone(context);
    final user = context.watch<AppState>().user;
    final isRpg = _legalType == ProducerLegalType.rpg;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A281E) : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2C4534) : const Color(0xFFD5E3D9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 20,
                color: user?.isRegisteredProducer == true
                    ? const Color(0xFF2E7D32)
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Status proizvođača (RPG / Pravno lice)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (user?.isRegisteredProducer == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user!.registeredProducerBadgeLabel ?? 'Verifikovano',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Unesite 12-cifreni BPG poljoprivrednog gazdinstva ili 9-cifreni PIB firme/preduzetnika. Kupcima se na vašem profilu prikazuje oznaka registrovanog proizvođača.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<ProducerLegalType>(
            segments: const [
              ButtonSegment<ProducerLegalType>(
                value: ProducerLegalType.rpg,
                icon: Icon(Icons.agriculture_outlined, size: 17),
                label: Text('Poljoprivredno gazdinstvo (BPG)'),
              ),
              ButtonSegment<ProducerLegalType>(
                value: ProducerLegalType.company,
                icon: Icon(Icons.business_outlined, size: 17),
                label: Text('Pravno lice / Preduzetnik (PIB)'),
              ),
            ],
            selected: {_legalType},
            onSelectionChanged: (sel) {
              setState(() {
                _legalType = sel.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),
          if (isRpg)
            TextField(
              controller: _bpgController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: const InputDecoration(
                labelText: 'BPG (Broj poljoprivrednog gazdinstva – 12 cifara)',
                hintText: 'npr. 801234567890',
                helperText: 'Pun broj BPG-a nije javno vidljiv drugim korisnicima.',
              ),
            )
          else
            TextField(
              controller: _pibController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                labelText: 'PIB (Poreski identifikacioni broj – 9 cifara)',
                hintText: 'npr. 100001011',
                helperText: 'Unesite 9-cifreni PIB sa ispravnom kontrolnom cifrom.',
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: isDesktop ? Alignment.centerRight : Alignment.center,
            child: SizedBox(
              width: isDesktop ? null : double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Sačuvaj BPG / PIB'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SellerUnregisteredWarningBanner extends StatelessWidget {
  final VoidCallback onNavigateToSettings;

  const SellerUnregisteredWarningBanner({
    super.key,
    required this.onNavigateToSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF332914) : const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF7A5F28) : const Color(0xFFF3D078),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unesite BPG gazdinstva ili PIB firme kako bi vaš profil dobio oznaku verifikovanog proizvođača.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? Colors.amber.shade100 : const Color(0xFF78350F),
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onNavigateToSettings,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Unesi BPG / PIB'),
          ),
        ],
      ),
    );
  }
}

class ProductLegalLiabilityCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ProductLegalLiabilityCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2B20) : const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D4B37) : const Color(0xFFD2E2D7),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        title: Text(
          SellerRegistrationValidator.legalLiabilityText,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.4,
            color: isDark ? Colors.grey.shade200 : const Color(0xFF26332A),
          ),
        ),
      ),
    );
  }
}
