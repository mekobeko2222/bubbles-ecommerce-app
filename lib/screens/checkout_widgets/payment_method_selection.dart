import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/checkout_screen.dart'; // Import PaymentMethod enum

/// A widget for selecting a payment method.
class PaymentMethodSelection extends StatelessWidget {
  const PaymentMethodSelection({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.appLocalizations,
  });

  final PaymentMethod? selectedPaymentMethod;
  final Function(PaymentMethod?) onPaymentMethodChanged;
  final AppLocalizations appLocalizations;

  String _getPaymentMethodDisplayName(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return appLocalizations.cashOnDelivery;
      case PaymentMethod.vodafoneCash:
        return appLocalizations.vodafoneCash;
      case PaymentMethod.etisalatCash:
        return appLocalizations.etisalatCash;
      case PaymentMethod.weCash:
        return appLocalizations.weCash;
      case PaymentMethod.instapay:
        return appLocalizations.instapay;
      default:
        return appLocalizations.selectPaymentMethod;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.paymentMethod,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: PaymentMethod.values.map((PaymentMethod method) {
                return RadioListTile<PaymentMethod>(
                  title: Text(_getPaymentMethodDisplayName(method)),
                  value: method,
                  groupValue: selectedPaymentMethod,
                  onChanged: onPaymentMethodChanged,
                  activeColor: Theme.of(context).primaryColor,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizations.paymentInstruction,
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
