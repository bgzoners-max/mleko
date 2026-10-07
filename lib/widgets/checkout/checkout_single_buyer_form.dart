import 'package:flutter/material.dart';

import '../../models/seller_delivery_models.dart';
import 'buyer_form.dart';
import 'delivery_selector.dart';

class CheckoutSingleBuyerForm extends StatelessWidget {
  final DeliveryMethod deliveryMethod;
  final ValueChanged<DeliveryMethod> onDeliveryMethodChanged;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool showSavePhone;
  final bool savePhoneToProfile;
  final ValueChanged<bool> onSavePhoneChanged;

  const CheckoutSingleBuyerForm({
    super.key,
    required this.deliveryMethod,
    required this.onDeliveryMethodChanged,
    required this.addressController,
    required this.cityController,
    required this.postalCodeController,
    required this.phoneController,
    required this.noteController,
    required this.showSavePhone,
    required this.savePhoneToProfile,
    required this.onSavePhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeliverySelector(
          selectedMethod: deliveryMethod,
          onMethodChanged: onDeliveryMethodChanged,
          dense: true,
        ),
        const SizedBox(height: 8),
        BuyerForm(
          deliveryMethod: deliveryMethod,
          addressController: addressController,
          cityController: cityController,
          postalCodeController: postalCodeController,
          phoneController: phoneController,
          noteController: noteController,
          savePhoneToProfile: savePhoneToProfile,
          onSavePhoneChanged: (v) => onSavePhoneChanged(v ?? false),
          isUserLoggedIn: showSavePhone,
          showNoticeBox: true,
        ),
      ],
    );
  }
}
