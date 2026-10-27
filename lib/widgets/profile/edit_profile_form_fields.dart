import 'package:flutter/material.dart';

import '../../constants/serbian_cities.dart';
import '../../constants/serbian_postal_codes.dart';
import '../common/postal_code_autocomplete_field.dart';

// Polja forme za izmenu profila — izdvojena iz EditProfileForm radi
// održavanja fajla ispod limita od 700 linija (tool/check_file_size.dart).
// Svako polje prima sopstveni TextEditingController iz forme.

/// „Naziv gazdinstva / Prikazano ime" za prodavce, odnosno prikazano ime za kupce.
class EditProfileDisplayNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSeller;

  const EditProfileDisplayNameField({
    super.key,
    required this.controller,
    required this.isSeller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isSeller
            ? 'Naziv gazdinstva / Prikazano ime'
            : 'Prikazano ime (Display name)',
        hintText: isSeller
            ? 'npr. Gazdinstvo Petrović'
            : 'npr. Milan Jovanović',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: Icon(
          isSeller ? Icons.storefront_outlined : Icons.badge_outlined,
          size: 20,
        ),
        helperText: 'Javno ime na profilu i oglasima',
        helperMaxLines: 1,
        helperStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }
}

/// Puno ime i prezime (za porudžbine i dostavu).
class EditProfileFullNameField extends StatelessWidget {
  final TextEditingController controller;

  const EditProfileFullNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Puno ime i prezime',
        hintText: 'Vaše lično ime i prezime',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: const Icon(Icons.person_outline, size: 20),
        helperText: 'Lično ime za porudžbine i dostavu',
        helperMaxLines: 1,
        helperStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
      textCapitalization: TextCapitalization.words,
    );
  }
}

/// Broj telefona sa validacijom formata (7-15 cifara).
class EditProfilePhoneField extends StatelessWidget {
  final TextEditingController controller;

  const EditProfilePhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Broj telefona',
        hintText: 'npr. 064 1234567',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
      ),
      keyboardType: TextInputType.phone,
      validator: (v) {
        final val = v?.trim() ?? '';
        if (val.isEmpty) return null;
        final digits = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
        if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
          return 'Unesite ispravan broj (7-15 cifara)';
        }
        return null;
      },
    );
  }
}

/// Prekidač za javnu vidljivost broja telefona (kompaktan, visina usklađena sa poljem).
class EditProfilePhonePrivacySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const EditProfilePhonePrivacySwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: value
          ? 'Kupci i posetioci mogu videti vaš broj u oglasima i na profilu.'
          : 'Broj je sakriven od javnosti i koristi se isključivo za realizaciju narudžbina.',
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
          color: value
              ? Colors.green.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.lock_open_outlined : Icons.lock_outline,
              size: 18,
              color: value
                  ? Colors.green.shade600
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value ? 'Telefon je vidljiv svima' : 'Telefon je privatan',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: value ? Colors.green.shade700 : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value ? 'Javno prikazan' : 'Samo za porudžbine',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.82,
              child: Switch(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grad/mesto sa autocomplete predlozima iz [SerbianCities] i dvosmernom vezom ka poštanskom broju.
class EditProfileCityField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController? postalCodeController;

  const EditProfileCityField({
    super.key,
    required this.controller,
    this.postalCodeController,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }
        return SerbianCities.suggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        controller.text = selection;
        if (postalCodeController != null &&
            postalCodeController!.text.trim().isEmpty) {
          final matchedCode = SerbianPostalCodes.codeForCity(selection);
          if (matchedCode != null) {
            postalCodeController!.text = matchedCode;
          }
        }
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        if (controller.text.isNotEmpty &&
            fieldTextEditingController.text.isEmpty) {
          fieldTextEditingController.text = controller.text;
        }
        fieldTextEditingController.addListener(() {
          controller.text = fieldTextEditingController.text;
        });

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            labelText: 'Grad ili mesto',
            hintText: 'npr. Beograd, Novi Sad...',
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIcon:
                const Icon(Icons.location_city_outlined, size: 20),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            if (val.length < 2) {
              return 'Najmanje 2 karaktera';
            }
            if (RegExp(r'^\d+$').hasMatch(val)) {
              return 'Unesite ispravan naziv';
            }
            return null;
          },
        );
      },
    );
  }
}

/// Poštanski broj (samo cifre, kompaktan format sa pametnim autocomplete predlozima).
class EditProfilePostalCodeField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController? cityController;
  final String labelText;

  const EditProfilePostalCodeField({
    super.key,
    required this.controller,
    this.cityController,
    this.labelText = 'Poštanski broj',
  });

  @override
  Widget build(BuildContext context) {
    return PostalCodeAutocompleteField(
      controller: controller,
      cityController: cityController,
      labelText: labelText,
    );
  }
}

/// Adresa (ulica i broj) — privatna, vidljiva samo pri naručivanju.
class EditProfileAddressField extends StatelessWidget {
  final TextEditingController controller;

  const EditProfileAddressField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Adresa (ulica i broj)',
        hintText: 'npr. Cara Dušana 12',
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        prefixIcon: const Icon(Icons.home_outlined, size: 20),
        helperText: 'Privatno — vidljivo samo pri naručivanju',
        helperMaxLines: 1,
        helperStyle: TextStyle(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
        suffixIcon: Tooltip(
          message: 'Adresa nikada nije javno vidljiva posetiocima',
          child: Icon(Icons.lock_outline,
              size: 18, color: Colors.grey.shade500),
        ),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
