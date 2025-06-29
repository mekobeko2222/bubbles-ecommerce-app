import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config
import 'package:awesome_notifications/awesome_notifications.dart'; // For local notifications

class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  String? _selectedOrderStatusFilter;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppLocalizations _appLocalizations;
  String _sortBy = 'orderDate'; // Default sort by order date
  bool _isDescending = true; // Newest first by default

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  Stream<QuerySnapshot> _buildOrderStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('orders');

    // Apply status filter
    if (_selectedOrderStatusFilter != null && _selectedOrderStatusFilter != 'All Statuses') {
      query = query.where('orderStatus', isEqualTo: _selectedOrderStatusFilter);
    }

    // Apply sorting
    query = query.orderBy(_sortBy, descending: _isDescending);

    return query.snapshots();
  }

  Future<void> _updateOrderStatus(String orderId, String currentStatus) async {
    final String? newStatus = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(_appLocalizations.updateOrderStatus),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current status: $currentStatus'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: currentStatus,
              decoration: InputDecoration(
                labelText: _appLocalizations.newStatus,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: AppConfig.orderStatuses.map((status) {
                IconData icon;
                Color color;
                switch (status) {
                  case 'Pending':
                    icon = Icons.pending_actions;
                    color = Colors.orange;
                    break;
                  case 'Processing':
                    icon = Icons.sync;
                    color = Colors.blue;
                    break;
                  case 'Shipped':
                    icon = Icons.local_shipping;
                    color = Colors.purple;
                    break;
                  case 'Delivered':
                    icon = Icons.check_circle;
                    color = Colors.green;
                    break;
                  case 'Cancelled':
                    icon = Icons.cancel;
                    color = Colors.red;
                    break;
                  default:
                    icon = Icons.info_outline;
                    color = Colors.grey;
                }

                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(width: 8),
                      Text(status),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                Navigator.of(ctx).pop(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_appLocalizations.cancel),
          ),
        ],
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      await ErrorHandler.handleAsyncError(
        context,
            () async {
          // Update order status in Firestore
          await _firestore.collection('orders').doc(orderId).update({
            'orderStatus': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Send customer notification about status change
          await _sendCustomerStatusNotification(orderId, newStatus);
        },
        successMessage: _appLocalizations.orderStatusUpdated(newStatus, orderId),
        errorPrefix: 'Failed to update order status',
      );
    }
  }

  /// Send local notification to customer about order status change
  Future<void> _sendCustomerStatusNotification(String orderId, String newStatus) async {
    try {
      debugPrint('📱 Sending customer notification for order: $orderId, status: $newStatus');

      String title;
      String body;
      String emoji;

      // Customize message based on status
      switch (newStatus.toLowerCase()) {
        case 'processing':
          title = '⚙️ Order Update';
          body = 'Your order is now being processed!';
          emoji = '⚙️';
          break;
        case 'shipped':
          title = '🚚 Order Shipped';
          body = 'Your order has been shipped and is on its way!';
          emoji = '🚚';
          break;
        case 'delivered':
          title = '✅ Order Delivered';
          body = 'Your order has been delivered successfully!';
          emoji = '✅';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          body = 'Your order has been cancelled.';
          emoji = '❌';
          break;
        default:
          title = '📦 Order Update';
          body = 'Your order status has been updated to $newStatus';
          emoji = '📦';
      }

      // Create notification using AwesomeNotifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'order_notifications',
          title: title,
          body: '$body\nOrder #${orderId.substring(0, 8).toUpperCase()}',
          wakeUpScreen: true,
          category: NotificationCategory.Status,
          payload: {
            'type': 'order_update',
            'orderId': orderId,
            'newStatus': newStatus,
          },
        ),
      );

      debugPrint('✅ Customer notification sent for order status change');
    } catch (e) {
      debugPrint('❌ Error sending customer notification: $e');
      // Don't fail the status update if notification fails
    }
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ErrorHandler.showErrorSnackBar(
          context,
          _appLocalizations.couldNotLaunchDialer(phoneNumber),
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error launching dialer: $e',
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'Pending':
        return Icons.pending_actions;
      case 'Processing':
        return Icons.sync;
      case 'Shipped':
        return Icons.local_shipping;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final orders = snapshot.data!.docs;
        final totalOrders = orders.length;
        final pendingOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['orderStatus'] == 'Pending';
        }).length;
        final deliveredOrders = orders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['orderStatus'] == 'Delivered';
        }).length;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.dashboard, color: Theme.of(context).primaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $totalOrders • Pending: $pendingOrders • Delivered: $deliveredOrders',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats Overview
        _buildStatsOverview(),

        // Filters and Sorting Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Order Status Filter
                  Row(
                    children: [
                      Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedOrderStatusFilter ?? 'All Statuses',
                          hint: const Text('Filter by Status'),
                          decoration: InputDecoration(
                            labelText: 'Order Status Filter',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['All Statuses', ...AppConfig.orderStatuses].map((status) {
                            if (status == 'All Statuses') {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Row(
                                  children: [
                                    Icon(Icons.list, color: Colors.grey[600], size: 20),
                                    const SizedBox(width: 8),
                                    Text(status),
                                  ],
                                ),
                              );
                            }

                            return DropdownMenuItem<String>(
                              value: status,
                              child: Row(
                                children: [
                                  Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 20),
                                  const SizedBox(width: 8),
                                  Text(status),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedOrderStatusFilter = (newValue == 'All Statuses') ? null : newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sort Options
                  Row(
                    children: [
                      Icon(Icons.sort, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'orderDate', child: Text('Order Date')),
                            DropdownMenuItem(value: 'totalPrice', child: Text('Total Price')),
                            DropdownMenuItem(value: 'orderStatus', child: Text('Status')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
                        onPressed: () {
                          setState(() {
                            _isDescending = !_isDescending;
                          });
                        },
                        tooltip: _isDescending ? 'Descending' : 'Ascending',
                      ),
                    ],
                  ),

                  // Clear Filter Button
                  if (_selectedOrderStatusFilter != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedOrderStatusFilter = null;
                            });
                            ErrorHandler.showInfoSnackBar(context, 'Status filter cleared');
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Status Filter'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Orders List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildOrderStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading orders...'),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading orders',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 8),
                      Text('${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {}); // Trigger rebuild
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(_appLocalizations.tryAgain),
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
                      Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _selectedOrderStatusFilter != null
                            ? 'No $_selectedOrderStatusFilter orders found'
                            : 'No orders found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedOrderStatusFilter != null
                            ? 'Try changing the filter or check back later'
                            : 'Orders will appear here when customers place them',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final orders = snapshot.data!.docs;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Trigger rebuild
                  ErrorHandler.showInfoSnackBar(context, 'Orders refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    final shippingAddress = orderData['shippingAddress'] as Map<String, dynamic>?;
                    final orderItems = orderData['items'] as List<dynamic>?;
                    final String currentOrderStatus = orderData['orderStatus'] ?? 'Pending';
                    final Color statusColor = _getStatusColor(currentOrderStatus);
                    final IconData statusIcon = _getStatusIcon(currentOrderStatus);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${orderDoc.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  currentOrderStatus,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${AppConfig.currency} ${(orderData['totalPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      (orderData['orderDate'] as Timestamp?)?.toDate().toLocal().toString().split('.')[0] ?? 'N/A',
                                      style: TextStyle(color: Colors.grey[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Shipping Address
                                  if (shippingAddress != null) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.local_shipping, color: Theme.of(context).primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          _appLocalizations.shippingAddress,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Area: ${shippingAddress['area'] ?? 'N/A'}'),
                                          Text('Building: ${shippingAddress['buildingNumber'] ?? 'N/A'}, Floor: ${shippingAddress['floorNumber'] ?? 'N/A'}, Apt: ${shippingAddress['apartmentNumber'] ?? 'N/A'}'),
                                          InkWell(
                                            onTap: () {
                                              if (shippingAddress['phoneNumber'] != null && shippingAddress['phoneNumber'].isNotEmpty) {
                                                _callPhoneNumber(shippingAddress['phoneNumber']);
                                              } else {
                                                ErrorHandler.showWarningSnackBar(
                                                  context,
                                                  _appLocalizations.phoneNumberNotAvailable,
                                                );
                                              }
                                            },
                                            child: Text(
                                              'Phone: ${shippingAddress['phoneNumber'] ?? 'N/A'}',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Order Items
                                  if (orderItems != null && orderItems.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.shopping_bag, color: Theme.of(context).primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          _appLocalizations.itemsOrdered,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: orderItems.length,
                                        itemBuilder: (context, itemIndex) {
                                          final item = orderItems[itemIndex];
                                          final List<dynamic>? imageUrls = item['imageUrls'] as List<dynamic>?;
                                          final String? firstImageUrl = (imageUrls != null && imageUrls.isNotEmpty)
                                              ? imageUrls[0] as String?
                                              : null;

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Row(
                                              children: [
                                                // Product Image
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey[300]!),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: firstImageUrl != null
                                                        ? Image.network(
                                                      firstImageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          color: Colors.grey[200],
                                                          child: Icon(
                                                            Icons.image_not_supported,
                                                            color: Colors.grey[400],
                                                            size: 20,
                                                          ),
                                                        );
                                                      },
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Container(
                                                          color: Colors.grey[100],
                                                          child: Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                value: loadingProgress.expectedTotalBytes != null
                                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                                    loadingProgress.expectedTotalBytes!
                                                                    : null,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                        : Container(
                                                      color: Colors.grey[200],
                                                      child: Icon(
                                                        Icons.image,
                                                        color: Colors.grey[400],
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Product Details
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item['name'] ?? 'Unknown Product',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'Qty: ${item['quantity'] ?? 1}',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Text(
                                                            '${AppConfig.currency} ${(item['price'] as num?)?.toStringAsFixed(2) ?? '0.00'} each',
                                                            style: TextStyle(
                                                              color: Colors.grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Action Button
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.edit, size: 20),
                                      label: Text(_appLocalizations.updateStatus),
                                      onPressed: () {
                                        _updateOrderStatus(orderDoc.id, currentOrderStatus);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}