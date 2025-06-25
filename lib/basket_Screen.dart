import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/models/cart_item.dart';
import 'package:bubbles_ecommerce_app/checkout_screen.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  // Helper method for remove item confirmation dialog
  Future<void> _showRemoveConfirmationDialog(
      BuildContext context,
      String productId,
      String productName,
      AppLocalizations appLocalizations
      ) async {
    final bool confirmed = await ErrorHandler.showConfirmationDialog(
      context,
      title: appLocalizations.removeProduct,
      content: appLocalizations.areYouSureDeleteProduct(productName),
      confirmText: appLocalizations.delete,
      cancelText: appLocalizations.cancel,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      Provider.of<BasketManager>(context, listen: false).removeItem(productId);
      ErrorHandler.showSuccessSnackBar(
        context,
        appLocalizations.itemRemoved(productName),
      );
    }
  }

  // Helper method for clear basket confirmation dialog
  Future<void> _showClearConfirmationDialog(
      BuildContext context,
      AppLocalizations appLocalizations
      ) async {
    final bool confirmed = await ErrorHandler.showConfirmationDialog(
      context,
      title: appLocalizations.clearBasketConfirmTitle,
      content: appLocalizations.clearBasketConfirmContent,
      confirmText: appLocalizations.clear,
      cancelText: appLocalizations.cancel,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      Provider.of<BasketManager>(context, listen: false).clearBasket();
      ErrorHandler.showSuccessSnackBar(
        context,
        appLocalizations.basketCleared,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basket = Provider.of<BasketManager>(context);
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                appLocalizations.myBasketTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (basket.totalQuantity > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${basket.totalQuantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          if (basket.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearConfirmationDialog(context, appLocalizations),
              tooltip: appLocalizations.clearBasket,
            ),
        ],
      ),
      body: basket.items.isEmpty
          ? _buildEmptyBasket(context, appLocalizations)
          : Column(
        children: [
          // Basket items
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Simulate refresh action
                await Future.delayed(const Duration(milliseconds: 500));
                ErrorHandler.showInfoSnackBar(context, 'Basket refreshed');
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: basket.items.length,
                itemBuilder: (context, index) {
                  final cartItem = basket.items.values.elementAt(index);
                  return _buildCartItemCard(context, cartItem, basket, appLocalizations);
                },
              ),
            ),
          ),

          // Summary and Action Buttons
          _buildBottomSection(context, basket, appLocalizations),
        ],
      ),
    );
  }

  Widget _buildEmptyBasket(BuildContext context, AppLocalizations appLocalizations) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appLocalizations.basketIsEmpty,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              appLocalizations.addProductsToGetStarted,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(
                appLocalizations.continueShopping,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
      BuildContext context,
      CartItem cartItem,
      BasketManager basket,
      AppLocalizations appLocalizations
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0), // Increased margin
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16.0), // Increased padding
        child: Column( // Changed from Row to Column for better space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    cartItem.imageUrl,
                    width: 80, // Slightly reduced image size
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 35, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        cartItem.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Price per item
                      Text(
                        '${AppConfig.currency} ${cartItem.discountedPricePerItem.toStringAsFixed(2)} per item',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),

                      // Show discount if applicable
                      if (cartItem.product.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${AppConfig.currency} ${cartItem.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${cartItem.product.discount}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    _showRemoveConfirmationDialog(context, cartItem.productId, cartItem.name, appLocalizations);
                  },
                  tooltip: appLocalizations.removeProduct,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quantity controls and total (moved to separate row)
            Row(
              children: [
                // Decrease quantity
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: cartItem.quantity > 1
                        ? () {
                      basket.updateItemQuantity(cartItem.productId, cartItem.quantity - 1);
                    }
                        : null,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),

                // Quantity display
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${cartItem.quantity}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // Increase quantity
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: cartItem.quantity < cartItem.product.quantity
                        ? () {
                      basket.updateItemQuantity(cartItem.productId, cartItem.quantity + 1);
                    }
                        : () {
                      ErrorHandler.showWarningSnackBar(
                        context,
                        appLocalizations.notEnoughStock(
                          cartItem.name,
                          cartItem.product.quantity,
                          cartItem.quantity + 1,
                        ),
                      );
                    },
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),

                const Spacer(),

                // Total price for this item
                Text(
                  'Total: ${AppConfig.currency} ${(cartItem.discountedPricePerItem * cartItem.quantity).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(
      BuildContext context,
      BasketManager basket,
      AppLocalizations appLocalizations
      ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price breakdown
            if (basket.discountPercentage > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appLocalizations.subtotal),
                  Text('${AppConfig.currency} ${basket.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${appLocalizations.discount} (${basket.discountPercentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(color: Colors.green),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '-${AppConfig.currency} ${(basket.subtotal - basket.discountedSubtotal).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Shipping fee (if any)
            if (basket.shippingFee > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(appLocalizations.shippingFee),
                  Text('${AppConfig.currency} ${basket.shippingFee.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Total price
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      appLocalizations.totalPrice,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${AppConfig.currency} ${basket.grandTotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Column( // Changed to Column for better mobile layout
              children: [
                // Continue shopping button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text(appLocalizations.continueShopping),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Checkout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: basket.items.isNotEmpty
                        ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                      );
                    }
                        : () {
                      ErrorHandler.showWarningSnackBar(
                        context,
                        appLocalizations.basketIsEmptyCanNotCheckout,
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(appLocalizations.proceedToCheckout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}