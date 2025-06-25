import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// A widget that displays the order summary, including items, pricing,
/// and estimated delivery.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.basket,
    required this.appLocalizations,
    required this.isLoadingShippingFee,
    required this.calculatedDeliveryDateTime,
  });

  final BasketManager basket;
  final AppLocalizations appLocalizations;
  final bool isLoadingShippingFee;
  final DateTime? calculatedDeliveryDateTime;

  // Helper to format the delivery date.
  String _formatDeliveryDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dateOnly == today) {
      return appLocalizations.today;
    } else if (dateOnly == tomorrow) {
      return appLocalizations.tomorrow;
    } else {
      return DateFormat('dd MMM', appLocalizations.localeName).format(dateTime);
    }
  }

  // Helper to build a price row
  Widget _buildPriceRow(String label, double amount, {bool isLoading = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isDiscount ? Colors.green : null,
          ),
        ),
        isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Text(
          '${isDiscount ? '' : 'EGP '}${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDiscount ? Colors.green : null,
          ),
        ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  appLocalizations.orderSummary,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: basket.items.length,
              separatorBuilder: (context, index) => const Divider(height: 20),
              itemBuilder: (context, index) {
                final item = basket.items.values.elementAt(index);
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.imageUrls.isNotEmpty ? item.product.imageUrls[0] : 'https://placehold.co/100x100/CCCCCC/000000?text=No+Img',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${appLocalizations.quantity}: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'EGP ${(item.product.discountedPrice * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 30, thickness: 1),
            _buildPriceRow(appLocalizations.subtotal, basket.subtotal),
            if (basket.discountPercentage > 0) ...[
              const SizedBox(height: 8),
              _buildPriceRow(
                '${appLocalizations.discount} (${basket.discountPercentage.toStringAsFixed(0)}%)',
                -(basket.subtotal - basket.discountedSubtotal),
                isDiscount: true,
              ),
            ],
            const SizedBox(height: 8),
            _buildPriceRow(appLocalizations.shippingFee, basket.shippingFee, isLoading: isLoadingShippingFee), // Corrected call
            if (calculatedDeliveryDateTime != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(appLocalizations.estimatedDelivery, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeliveryDate(calculatedDeliveryDateTime!),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 30, thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appLocalizations.grandTotal,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'EGP ${basket.grandTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (basket.shippingFee == 0 && basket.shippingArea != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      appLocalizations.freeShipping,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
