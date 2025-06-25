import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'basket_manager.dart';
import 'basket_screen.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/models/product.dart'; // Import Product model

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  static final List<String> _cancellableStatuses = ['Pending', 'Processing'];

  static IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  // Changed to static and accepts AppLocalizations
  static String _formatDate(Timestamp? timestamp, AppLocalizations appLocalizations) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return appLocalizations.todayAt(date.hour.toString().padLeft(2, '0'), date.minute.toString().padLeft(2, '0'));
    } else if (difference.inDays == 1) {
      return appLocalizations.yesterdayAt(date.hour.toString().padLeft(2, '0'), date.minute.toString().padLeft(2, '0'));
    } else if (difference.inDays < 7) {
      final weekdays = [
        appLocalizations.mon,
        appLocalizations.tue,
        appLocalizations.wed,
        appLocalizations.thu,
        appLocalizations.fri,
        appLocalizations.sat,
        appLocalizations.sun
      ];
      return '${weekdays[date.weekday - 1]} ${appLocalizations.at} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _deleteOrder(BuildContext context, String orderId, String orderStatus) async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!MyOrdersScreen._cancellableStatuses.contains(orderStatus)) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 8),
              Text(appLocalizations.orderCannotBeCancelled), // Localized
            ],
          ),
          content: Text(appLocalizations.orderCurrently(orderStatus)), // Positional arg
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(appLocalizations.cancel), // Localized
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(appLocalizations.cancelOrder), // Localized
          ],
        ),
        content: Text(appLocalizations.areYouSureDeleteProduct(appLocalizations.orderId)), // Positional arg
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: Text(appLocalizations.cancel), // Localized
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(appLocalizations.delete), // Localized
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Text(appLocalizations.cancelOrder), // Localized
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        await FirebaseFirestore.instance.collection('orders').doc(orderId).delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(appLocalizations.orderPlacedSuccessfully), // Localized
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text(appLocalizations.failedToCancelOrder(e.toString())), // Positional arg
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
        print('Error cancelling order: $e');
      }
    }
  }

  Future<void> _reorder(BuildContext context, List<dynamic> orderItems) async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (orderItems.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Text(appLocalizations.cannotReorderEmptyList), // Localized
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text(appLocalizations.addingItemsToBasket), // Localized
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    final basketManager = Provider.of<BasketManager>(context, listen: false);
    basketManager.clearBasket(); // Clear existing basket before reordering

    for (var itemData in orderItems) {
      final productId = itemData['productId'] as String? ?? '';
      final quantity = (itemData['quantity'] as num?)?.toInt() ?? 1;

      if (productId.isNotEmpty) {
        try {
          // Fetch the full product details to ensure correct Product object
          final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
          if (productDoc.exists) {
            final product = Product.fromFirestore(productDoc);
            basketManager.addItem(product, quantity); // Pass Product object and quantity
          } else {
            // Handle case where product might no longer exist in inventory
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(appLocalizations.productDoesNotExistInInventory(itemData['name'] ?? ''))),
            );
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding product to basket: $e')),
          );
        }
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_basket, color: Colors.white),
            const SizedBox(width: 8),
            Text(appLocalizations.uniqueItemsAddedToBasket(orderItems.length)), // Positional arg
          ],
        ),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: appLocalizations.view, // Localized
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BasketScreen()));
          },
        ),
      ),
    );

    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BasketScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final appLocalizations = AppLocalizations.of(context)!;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.myOrdersTitle), // Localized
          backgroundColor: Theme.of(context).colorScheme.primary,
          centerTitle: true,
          elevation: 2,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizations.pleaseLoginToViewOrders, // Localized
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.myOrdersTitle), // Localized
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(appLocalizations.loadingOrders), // Localized
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appLocalizations.errorLoadingOrders, // Localized
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appLocalizations.noOrdersYet, // Localized
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.orderHistoryWillAppearHere, // Localized
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderDoc = orders[index];
                final orderData = orderDoc.data() as Map<String, dynamic>;
                final orderItems = orderData['items'] as List<dynamic>;
                final String orderStatus = orderData['orderStatus'] ?? 'Pending';
                final totalPrice = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;

                Color statusColor = Colors.grey;
                if (orderStatus == 'Delivered') {
                  statusColor = Colors.green;
                } else if (orderStatus == 'Pending') {
                  statusColor = Colors.orange;
                } else if (orderStatus == 'Processing') {
                  statusColor = Colors.blue;
                } else if (orderStatus == 'Shipped') {
                  statusColor = Colors.purple;
                } else if (orderStatus == 'Cancelled') {
                  statusColor = Colors.red;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [statusColor.withOpacity(0.8), statusColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        childrenPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(_getStatusIcon(orderStatus), color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${appLocalizations.orderId}#${orderDoc.id.substring(0, 8).toUpperCase()}', // Localized
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]), // Removed const
                                  Text(
                                    'EGP ${totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                  Text(
                                    appLocalizations.itemCount(orderItems.length), // Positional arg
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${appLocalizations.status}: ', // Localized
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      orderStatus,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(orderData['orderDate'] as Timestamp?, appLocalizations), // Localized date formatting
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (orderStatus == 'Delivered')
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () => _reorder(context, orderItems),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: Text(appLocalizations.reorder, style: const TextStyle(fontSize: 12)), // Localized
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.green[50], // Removed const
                                    foregroundColor: Colors.green[700], // Removed const
                                    elevation: 0,
                                    side: BorderSide(color: Colors.green[300]!), // Removed const
                                  ),
                                ),
                              ),
                            if (MyOrdersScreen._cancellableStatuses.contains(orderStatus))
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[50], // Removed const
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  onPressed: () => _deleteOrder(context, orderDoc.id, orderStatus),
                                  tooltip: appLocalizations.cancelOrder, // Localized
                                  splashRadius: 20,
                                ),
                              ),
                          ],
                        ),
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.shopping_cart, color: Colors.green[700], size: 20), // Removed const
                                    const SizedBox(width: 8),
                                    Text(
                                      appLocalizations.orderItems(orderItems.length), // Positional arg
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: orderItems.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, itemIndex) {
                                    final item = orderItems[itemIndex];
                                    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
                                    final itemQuantity = (item['quantity'] as num?)?.toInt() ?? 1;
                                    final totalItemPrice = itemPrice * itemQuantity;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[200]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Image.network(
                                                item['imageUrl'] ?? 'https://placehold.co/50x50/CCCCCC/000000?text=No+Img',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  print(appLocalizations.imageLoadingError(item['name'] ?? 'N/A', item['imageUrl'] ?? 'N/A', error.toString()));
                                                  return Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['name'] ?? 'Unknown Product',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50], // Removed const
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        '${appLocalizations.quantity}: $itemQuantity', // Localized
                                                        style: TextStyle(
                                                          color: Colors.blue[700], // Removed const
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  appLocalizations.totalItemPrice(totalItemPrice.toStringAsFixed(2)), // Positional arg
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700], // Removed const
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}