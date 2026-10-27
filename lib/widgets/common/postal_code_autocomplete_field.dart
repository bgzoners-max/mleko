import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/serbian_postal_codes.dart';

/// Autocomplete polje za unos poštanskog broja u Srbiji sa automatskim predlozima
/// i opcionim automatskim popunjavanjem grada.
class PostalCodeAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController? cityController;
  final ValueChanged<PostalCodeEntry>? onSelected;
  final String labelText;
  final String hintText;
  final bool isDense;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;

  final Widget? prefixIcon;

  const PostalCodeAutocompleteField({
    super.key,
    required this.controller,
    this.cityController,
    this.onSelected,
    this.labelText = 'Poštanski broj',
    this.hintText = '11000',
    this.isDense = true,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.decoration,
    this.validator,
    this.prefixIcon = const Icon(
      Icons.markunread_mailbox_outlined,
      size: 18,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Autocomplete<PostalCodeEntry>(
      initialValue: TextEditingValue(text: controller.text),
      displayStringForOption: (PostalCodeEntry option) => option.code,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text.trim();
        if (text.isEmpty) {
          return const Iterable<PostalCodeEntry>.empty();
        }
        return SerbianPostalCodes.suggestions(text, limit: 8);
      },
      onSelected: (PostalCodeEntry selection) {
        controller.text = selection.code;
        if (cityController != null) {
          cityController!.text = selection.city;
        }
        onSelected?.call(selection);
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<PostalCodeEntry> onSelectedOption,
        Iterable<PostalCodeEntry> options,
      ) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = constraints.maxWidth;
            // Padajući meni mora biti dovoljno širok (min 300px) da prikaže pun naziv mesta i sela
            final overlayWidth = fieldWidth < 300.0 ? 300.0 : fieldWidth;
            // Za uska polja poravnaj udesno kako meni ne bi prešao desnu ivicu ekrana/kartice
            final alignment =
                fieldWidth < 220.0 ? Alignment.topRight : Alignment.topLeft;

            return Align(
              alignment: alignment,
              child: OverflowBox(
                alignment: alignment,
                minWidth: 0,
                maxWidth: overlayWidth,
                minHeight: 0,
                maxHeight: 240,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(10),
                  color: isDark ? const Color(0xFF1E2822) : Colors.white,
                  surfaceTintColor: Colors.transparent,
                  child: SizedBox(
                    width: overlayWidth,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.5,
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => onSelectedOption(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      option.code,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      option.city,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController fieldTextEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sinhronizacija sa spoljnim kontrolerom
        if (controller.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
          fieldTextEditingController.text = controller.text;
        }

        fieldTextEditingController.addListener(() {
          controller.text = fieldTextEditingController.text;
          // Ako korisnik unese tačno 5 cifara, automatski popuni grad ako je prazan
          final trimmed = fieldTextEditingController.text.trim();
          if (trimmed.length == 5 && cityController != null && cityController!.text.trim().isEmpty) {
            final detectedCity = SerbianPostalCodes.cityForCode(trimmed);
            if (detectedCity != null) {
              cityController!.text = detectedCity;
            }
          }
        });

        // Takođe prati promene na spoljnom kontroleru (npr. ako ga resetuje spoljni kod)
        controller.addListener(() {
          if (controller.text != fieldTextEditingController.text) {
            fieldTextEditingController.text = controller.text;
          }
        });

        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: decoration ??
              InputDecoration(
                labelText: labelText,
                hintText: hintText,
                isDense: isDense,
                contentPadding: contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: border ??
                    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                enabledBorder: enabledBorder ??
                    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                focusedBorder: focusedBorder ??
                    OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                prefixIcon: prefixIcon,
                prefixIconConstraints: prefixIcon != null
                    ? const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      )
                    : null,
              ),
          validator: validator,
        );
      },
    );
  }
}
