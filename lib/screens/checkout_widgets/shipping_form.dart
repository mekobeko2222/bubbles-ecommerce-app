import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For FilteringTextInputFormatter
import 'package:cloud_firestore/cloud_firestore.dart'; // For StreamBuilder
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';

/// A widget that displays and manages the shipping address form.
class ShippingForm extends StatelessWidget {
  const ShippingForm({
    super.key,
    required this.formKey,
    required this.selectedArea,
    required this.onAreaChanged,
    required this.buildingNumberController,
    required this.floorNumberController,
    required this.apartmentNumberController,
    required this.phoneNumberController,
    required this.buildingFocusNode,
    required this.floorFocusNode,
    required this.apartmentFocusNode,
    required this.phoneFocusNode,
    required this.appLocalizations,
    required this.validateGenericField,
    required this.validatePhoneNumber,
  });

  final GlobalKey<FormState> formKey;
  final String? selectedArea;
  final Function(String?) onAreaChanged;
  final TextEditingController buildingNumberController;
  final TextEditingController floorNumberController;
  final TextEditingController apartmentNumberController;
  final TextEditingController phoneNumberController;
  final FocusNode buildingFocusNode;
  final FocusNode floorFocusNode;
  final FocusNode apartmentFocusNode;
  final FocusNode phoneFocusNode;
  final AppLocalizations appLocalizations;
  final String? Function(String?, String) validateGenericField; // Pass the validation function
  final String? Function(String?) validatePhoneNumber; // Pass the validation function

  Widget _buildSkeletonLoader() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    appLocalizations.shippingInformation,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('areas').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildSkeletonLoader();
                  }
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(appLocalizations.errorLoadingData(snapshot.error.toString())),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Text(appLocalizations.noShippingAreasAvailable),
                    );
                  }

                  final List<String> availableAreas = snapshot.data!.docs
                      .map((doc) => doc['name'] as String)
                      .toList();

                  // Important: The parent (_CheckoutScreenState) needs to handle
                  // updating _selectedArea and _currentShippingFee based on
                  // the onAreaChanged callback. The parent also manages the
                  // logic for resetting _selectedArea if it's no longer available.
                  // This widget just triggers the change.

                  return DropdownButtonFormField<String>(
                    value: selectedArea,
                    hint: Text(appLocalizations.selectShippingArea),
                    decoration: InputDecoration(
                      labelText: '${appLocalizations.shippingArea} *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_city),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    items: availableAreas.map((String area) {
                      return DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      );
                    }).toList(),
                    onChanged: onAreaChanged, // Use the passed callback
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations.pleaseSelectShippingArea;
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: buildingNumberController,
                focusNode: buildingFocusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: '${appLocalizations.buildingNumber} *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.apartment),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'e.g., 123 or Building A', // Could be localized
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => floorFocusNode.requestFocus(),
                validator: (value) => validateGenericField(value, appLocalizations.buildingNumber),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: floorNumberController,
                focusNode: floorFocusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: '${appLocalizations.floorNumber} *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.layers),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'e.g., 1, 2, G (Ground)', // Could be localized
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => apartmentFocusNode.requestFocus(),
                validator: (value) => validateGenericField(value, appLocalizations.floorNumber),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: apartmentNumberController,
                focusNode: apartmentFocusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: '${appLocalizations.apartmentNumber} *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.door_front_door),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'e.g., 101, A, B', // Could be localized
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => phoneFocusNode.requestFocus(),
                validator: (value) => validateGenericField(value, appLocalizations.apartmentNumber),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: phoneNumberController,
                focusNode: phoneFocusNode,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: '${appLocalizations.phoneNumber} *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.phone),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: '010xxxxxxxx', // Could be localized
                  helperText: appLocalizations.egyptianMobileNumberHint,
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: validatePhoneNumber,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
