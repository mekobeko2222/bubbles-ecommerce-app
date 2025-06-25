import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';

/// A widget for the "Place Order" button, including processing state.
class PlaceOrderButton extends StatelessWidget {
  const PlaceOrderButton({
    super.key,
    required this.basket,
    required this.isProcessingOrder,
    required this.onPressed,
    required this.appLocalizations,
    required this.isButtonEnabled, // Pass the computed enabled state
  });

  final BasketManager basket;
  final bool isProcessingOrder;
  final VoidCallback onPressed;
  final AppLocalizations appLocalizations;
  final bool isButtonEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isButtonEnabled
            ? LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        )
            : LinearGradient(
          colors: [
            Colors.grey.shade400,
            Colors.grey.shade500,
          ],
        ),
        boxShadow: isButtonEnabled
            ? [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isButtonEnabled ? onPressed : null, // Use the passed enabled state and callback
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isProcessingOrder
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              appLocalizations.processingOrder,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '${appLocalizations.placeOrder} - EGP ${basket.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
