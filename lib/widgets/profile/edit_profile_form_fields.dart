import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/serbian_cities.dart';

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
            ? 'npr. Gazdinstvo Petrović ili Eko Farma'
            : 'npr. Milan Jovanović ili Nadimak',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(isSeller
            ? Icons.storefront_outlined
            : Icons.badge_outlined),
        helperText:
            'Ime koje se javno prikazuje na profilu, oglasima i porukama',
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
      decoration: const InputDecoration(
        labelText: 'Puno ime i prezime',
        hintText: 'Vaše lično ime i prezime',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
        helperText: 'Lično ime za porudžbine i dostavu',
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
      decoration: const InputDecoration(
        labelText: 'Broj telefona',
        hintText: 'npr. 064 1234567',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      keyboardType: TextInputType.phone,
      validator: (v) {
        final val = v?.trim() ?? '';
        if (val.isEmpty) return null;
        final digits = val.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
        if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
          return 'Unesite ispravan broj telefona (7-15 cifara)';
        }
        return null;
      },
    );
  }
}

/// Prekidač za javnu vidljivost broja telefona.
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        value ? Icons.lock_open_outlined : Icons.lock_outline,
        size: 20,
        color: value
            ? Colors.green.shade600
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        value ? 'Telefon je vidljiv svima' : 'Telefon je privatan',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: value ? Colors.green.shade700 : null,
        ),
      ),
      subtitle: Text(
        value
            ? 'Kupci i posetioci mogu videti vaš broj u oglasima i na profilu.'
            : 'Broj je sakriven od javnosti i koristi se isključivo za realizaciju narudžbina.',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
      ),
    );
  }
}

/// Grad/mesto sa autocomplete predlozima iz [SerbianCities].
class EditProfileCityField extends StatelessWidget {
  final TextEditingController controller;

  const EditProfileCityField({super.key, required this.controller});

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
          decoration: const InputDecoration(
            labelText: 'Grad ili mesto',
            hintText: 'npr. Beograd, Novi Sad, Čačak...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            if (val.length < 2) {
              return 'Grad mora imati najmanje 2 karaktera';
            }
            if (RegExp(r'^\d+$').hasMatch(val)) {
              return 'Unesite ispravan naziv grada';
            }
            return null;
          },
        );
      },
    );
  }
}

/// Poštanski broj (samo cifre).
class EditProfilePostalCodeField extends StatelessWidget {
  final TextEditingController controller;

  const EditProfilePostalCodeField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Poštanski broj',
        hintText: 'npr. 11000',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.markunread_mailbox_outlined),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        hintText: 'npr. Cara Dušana 12 / Stan 4',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.home_outlined),
        helperText: 'Vidljiva samo tebi i drugoj strani pri naručivanju',
        helperStyle: TextStyle(color: Colors.grey.shade600),
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
