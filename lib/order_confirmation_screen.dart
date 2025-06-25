import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
// Required for date formatting

// CORRECTED: Renamed the class from OrderConfirmedScreen to OrderConfirmationScreen
class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String? _error;

  late AppLocalizations _appLocalizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
    _fetchOrderDetails();
  }

  // Fetches the complete order details from Firestore
  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      if (docSnapshot.exists) {
        setState(() {
          _orderDetails = docSnapshot.data();
        });
      } else {
        setState(() {
          _error = 'Order not found.';
        });
      }
    } catch (e) {
      setState(() {
        _error = _appLocalizations.errorLoadingData(e.toString());
      });
      debugPrint('Error fetching order details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_appLocalizations.orderConfirmedTitle)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_appLocalizations.loadingData),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_appLocalizations.orderConfirmedTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700], fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchOrderDetails,
                  icon: const Icon(Icons.refresh),
                  label: Text(_appLocalizations.tryAgain), // Localized
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_orderDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_appLocalizations.orderConfirmedTitle)),
        body: Center(
          child: Text(_appLocalizations.noDataFound),
        ),
      );
    }

    // Safely extract order details
    final totalPrice = (_orderDetails!['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final subtotalPrice = (_orderDetails!['subtotalPrice'] as num?)?.toDouble() ?? 0.0;
    final discountedSubtotalPrice = (_orderDetails!['discountedSubtotalPrice'] as num?)?.toDouble() ?? subtotalPrice;
    final shippingFee = (_orderDetails!['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final orderDate = (_orderDetails!['orderDate'] as Timestamp?)?.toDate();
    final items = _orderDetails!['items'] as List<dynamic>? ?? [];
    final shippingAddress = _orderDetails!['shippingAddress'] as Map<String, dynamic>?;
    final paymentMethod = _orderDetails!['paymentMethod'] as String? ?? 'N/A';
    final appliedOfferCode = _orderDetails!['appliedOfferCode'] as String?;
    final appliedDiscountPercentage = (_orderDetails!['appliedDiscountPercentage'] as num?)?.toDouble() ?? 0.0;


    return Scaffold(
      appBar: AppBar(
        title: Text(_appLocalizations.orderConfirmedTitle),
        automaticallyImplyLeading: false, // Prevent going back with back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _appLocalizations.thankYouForYourOrder,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _appLocalizations.orderPlacedSuccessfully,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_appLocalizations.orderId}: ${widget.orderId}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    Text(
                      _appLocalizations.orderDetails,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_appLocalizations.subtotal),
                        Text('EGP ${subtotalPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (appliedOfferCode != null && appliedDiscountPercentage > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_appLocalizations.discount} ($appliedDiscountPercentage%)',
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text(
                            '-EGP ${(subtotalPrice - discountedSubtotalPrice).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_appLocalizations.shippingFee),
                        Text(
                          shippingFee == 0.0
                              ? _appLocalizations.freeShipping
                              : 'EGP ${shippingFee.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _appLocalizations.grandTotal,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          'EGP ${totalPrice.toStringAsFixed(2)}', // This is the final total
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (appliedOfferCode != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${_appLocalizations.offerCode}: $appliedOfferCode',
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.green),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '${_appLocalizations.paymentMethod}: $paymentMethod',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _appLocalizations.itemsOrdered,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ...items.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['imageUrls'] != null && item['imageUrls'].isNotEmpty
                                  ? Image.network(
                                item['imageUrls'][0],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(_appLocalizations.imageLoadingError(item['name'], item['imageUrls'][0], error.toString()));
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 24),
                                  );
                                },
                              )
                                  : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 24),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'N/A',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    // Use 'discountedPricePerItem' if available, fallback to 'price'
                                    '${item['quantity']} x EGP ${((item['discountedPricePerItem'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)} = EGP ${((item['discountedPricePerItem'] as num? ?? (item['price'] as num? ?? 0.0)) * (item['quantity'] as num? ?? 0)).toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    Text(
                      _appLocalizations.shippingAddress,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (shippingAddress != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // CORRECTED: Use 'area' key to retrieve the area name
                          Text('Area: ${shippingAddress['area'] ?? 'N/A'}'),
                          Text('Bldg: ${shippingAddress['buildingNumber'] ?? 'N/A'}'),
                          Text('Floor: ${shippingAddress['floorNumber'] ?? 'N/A'}'),
                          Text('Apt: ${shippingAddress['apartmentNumber'] ?? 'N/A'}'),
                          Text('Phone: ${shippingAddress['phoneNumber'] ?? 'N/A'}'),
                        ],
                      )
                    else
                      Text(_appLocalizations.noShippingAreasFound),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to the home screen and clear all routes in between
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home),
                    label: Text(_appLocalizations.backToHome),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
