import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppLocalizations _appLocalizations;
  final bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  Widget _buildAnalyticCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14), // Reduced from 20 to 14
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Added to prevent overflow
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8), // Reduced from 12 to 8
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: color, size: 18), // Reduced from 22 to 18
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14), // Reduced from 16 to 14
                ],
              ),
              const SizedBox(height: 12), // Reduced from 16 to 12
              Text(
                title,
                style: TextStyle(
                  fontSize: 12, // Reduced from 14 to 12
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1, // Reduced from 2 to 1
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // Reduced from 8 to 6
              Flexible( // Added Flexible to prevent overflow
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20, // Reduced from 24 to 20
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4), // Reduced from 6 to 4
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10, // Reduced from 12 to 10
                    color: Colors.grey[500],
                  ),
                  maxLines: 1, // Reduced from 2 to 1
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String status,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14), // Reduced from 16 to 14
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: color, size: 18), // Reduced from 20 to 18
            ),
            const SizedBox(width: 10), // Reduced from 12 to 10
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 13, // Reduced from 14 to 13
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 16, // Reduced from 18 to 16
                      fontWeight: FontWeight.bold,
                      color: color,
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

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _appLocalizations.noOrderDataAvailable,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start taking orders to see analytics here',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        ErrorHandler.showInfoSnackBar(context, 'Analytics refreshed');
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _appLocalizations.dashboardAnalytics,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Real-time business insights',
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Analytics Data
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('orders').snapshots(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }
                if (orderSnapshot.hasError) {
                  return _buildErrorState(orderSnapshot.error.toString());
                }
                if (!orderSnapshot.hasData || orderSnapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final orders = orderSnapshot.data!.docs;
                double totalSales = 0.0;
                double totalShipping = 0.0;
                Map<String, int> statusCounts = {
                  'Pending': 0,
                  'Processing': 0,
                  'Shipped': 0,
                  'Delivered': 0,
                  'Cancelled': 0,
                };

                // Calculate analytics
                for (var orderDoc in orders) {
                  final orderData = orderDoc.data() as Map<String, dynamic>?;
                  if (orderData != null) {
                    final orderTotal = (orderData['totalPrice'] is num
                        ? (orderData['totalPrice'] as num).toDouble()
                        : 0.0);
                    final shippingFee = (orderData['shippingFee'] is num
                        ? (orderData['shippingFee'] as num).toDouble()
                        : 0.0);

                    totalSales += orderTotal;
                    totalShipping += shippingFee;

                    String status = orderData['orderStatus'] as String? ?? 'Pending';
                    if (statusCounts.containsKey(status)) {
                      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
                    }
                  }
                }

                final completedOrders = statusCounts['Delivered'] ?? 0;
                final pendingOrders = statusCounts['Pending'] ?? 0;
                final cancelledOrders = statusCounts['Cancelled'] ?? 0;
                final averageOrderValue = orders.isNotEmpty ? totalSales / orders.length : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Key Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95, // Increased from 0.85 to 0.95 for shorter cards
                      children: [
                        _buildAnalyticCard(
                          title: 'Total Orders',
                          value: '${orders.length}',
                          icon: Icons.shopping_bag,
                          color: Colors.blue,
                          subtitle: '$pendingOrders pending',
                        ),
                        _buildAnalyticCard(
                          title: 'Total Sales',
                          value: '${AppConfig.currency} ${totalSales.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                          subtitle: 'Revenue',
                        ),
                        _buildAnalyticCard(
                          title: 'Completed',
                          value: '$completedOrders',
                          icon: Icons.check_circle,
                          color: Colors.orange,
                          subtitle: '${((completedOrders / orders.length) * 100).toStringAsFixed(1)}% rate',
                        ),
                        _buildAnalyticCard(
                          title: 'Avg Order',
                          value: '${AppConfig.currency} ${averageOrderValue.toStringAsFixed(0)}',
                          icon: Icons.trending_up,
                          color: Colors.purple,
                          subtitle: 'Per order',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Additional Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildAnalyticCard(
                            title: 'Total Shipping',
                            value: '${AppConfig.currency} ${totalShipping.toStringAsFixed(0)}',
                            icon: Icons.local_shipping,
                            color: Colors.indigo,
                            subtitle: 'Shipping revenue',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAnalyticCard(
                            title: 'Cancelled',
                            value: '$cancelledOrders',
                            icon: Icons.cancel,
                            color: Colors.red,
                            subtitle: '${((cancelledOrders / orders.length) * 100).toStringAsFixed(1)}% rate',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Orders by Status Section
                    Text(
                      _appLocalizations.ordersByStatus,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Status Cards
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (context, index) => const SizedBox(height: 10), // Reduced from 12 to 10
                      itemCount: statusCounts.entries.length,
                      itemBuilder: (context, index) {
                        final entry = statusCounts.entries.elementAt(index);
                        IconData icon;
                        Color color;

                        switch (entry.key) {
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

                        return _buildStatusCard(
                          status: entry.key,
                          count: entry.value,
                          icon: icon,
                          color: color,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Additional Insights Section
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('products').snapshots(),
                      builder: (context, productSnapshot) {
                        if (!productSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final products = productSnapshot.data!.docs;
                        final totalProducts = products.length;
                        final outOfStockProducts = products.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return ((data['quantity'] as num?)?.toInt() ?? 0) == 0;
                        }).length;
                        final lowStockProducts = products.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
                          return quantity > 0 && quantity < 5;
                        }).length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Insights',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildAnalyticCard(
                                    title: 'Products',
                                    value: '$totalProducts',
                                    icon: Icons.inventory,
                                    color: Colors.teal,
                                    subtitle: 'In catalog',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildAnalyticCard(
                                    title: 'Out of Stock',
                                    value: '$outOfStockProducts',
                                    icon: Icons.warning,
                                    color: Colors.red,
                                    subtitle: 'Need restock',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _buildAnalyticCard(
                              title: 'Low Stock Alert',
                              value: '$lowStockProducts',
                              icon: Icons.inventory_2_outlined,
                              color: Colors.orange,
                              subtitle: 'Less than 5 items',
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}