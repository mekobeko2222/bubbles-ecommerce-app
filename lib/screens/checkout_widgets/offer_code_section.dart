import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';

/// A widget for applying offer codes during checkout.
class OfferCodeSection extends StatelessWidget {
  const OfferCodeSection({
    super.key,
    required this.offerCodeController,
    required this.isApplyingOfferCode,
    required this.onApplyOfferCode,
    required this.basket,
    required this.appLocalizations,
  });

  final TextEditingController offerCodeController;
  final bool isApplyingOfferCode;
  final VoidCallback onApplyOfferCode;
  final BasketManager basket;
  final AppLocalizations appLocalizations;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.discount, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.offerCode,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: offerCodeController,
              decoration: InputDecoration(
                labelText: appLocalizations.offerCode,
                hintText: 'Enter your offer code', // This hint text could also be localized
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.local_offer),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: offerCodeController.text.isNotEmpty && !isApplyingOfferCode
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    offerCodeController.clear();
                    onApplyOfferCode(); // Call to clear the applied offer
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                // Trigger a setState in the parent if needed for UI updates
                // This is generally handled by the parent if the controller's text
                // affects parent state (like button enablement or suffix icon visibility)
              },
            ),
            const SizedBox(height: 12),
            isApplyingOfferCode
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onApplyOfferCode,
                icon: const Icon(Icons.redeem),
                label: Text(appLocalizations.applyOfferCode),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
              ),
            ),
            if (basket.appliedOfferCode != null && basket.discountPercentage > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // This string needs full localization with placeholders for code and percentage
                        'Offer code "${basket.appliedOfferCode}" applied! You get ${basket.discountPercentage.toStringAsFixed(0)}% off.', // Localize this!
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            if (basket.appliedOfferCode != null && basket.discountPercentage == 0 && offerCodeController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // This string needs full localization
                        'Offer code "${basket.appliedOfferCode}" is applied but offers 0% discount or is inactive.', // Localize this!
                        style: const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
