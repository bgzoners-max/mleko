import 'package:flutter/material.dart';

import '../../models/seller_delivery_models.dart';
import 'buyer_form.dart';

class CheckoutAddressForm extends StatelessWidget {
  final DeliveryMethod deliveryMethod;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool savePhoneToProfile;
  final ValueChanged<bool?> onSavePhoneChanged;
  final bool isUserLoggedIn;

  const CheckoutAddressForm({
    super.key,
    required this.deliveryMethod,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.phoneController,
    required this.noteController,
    required this.savePhoneToProfile,
    required this.onSavePhoneChanged,
    required this.isUserLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return BuyerForm(
      deliveryMethod: deliveryMethod,
      addressController: addressController,
      cityController: cityController,
      postalCodeController: postalCodeController,
      phoneController: phoneController,
      noteController: noteController,
      savePhoneToProfile: savePhoneToProfile,
      onSavePhoneChanged: onSavePhoneChanged,
      isUserLoggedIn: isUserLoggedIn,
    );
  }
}
