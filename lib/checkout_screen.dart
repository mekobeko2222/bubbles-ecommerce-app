import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/order_confirmation_screen.dart';
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import the new config

// Import notification service
import 'package:bubbles_ecommerce_app/services/api_notification_service.dart';

// Import checkout widgets
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/order_summary_card.dart';
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/offer_code_section.dart';
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/shipping_form.dart';
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/payment_method_selection.dart';
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/place_order_button.dart';
import 'package:bubbles_ecommerce_app/screens/checkout_widgets/empty_basket_view.dart';

// Payment method enum
enum PaymentMethod {
  cashOnDelivery,
  vodafoneCash,
  etisalatCash,
  weCash,
  instapay,
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String? _selectedArea;
  final _buildingNumberController = TextEditingController();
  final _floorNumberController = TextEditingController();
  final _apartmentNumberController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  double _currentShippingFee = 0.0;
  DateTime? _calculatedDeliveryDateTime;
  bool _isProcessingOrder = false;
  bool _isLoadingShippingFee = false;
  bool _isInitialized = false;

  late AppLocalizations _appLocalizations;

  PaymentMethod? _selectedPaymentMethod;

  final _buildingFocusNode = FocusNode();
  final _floorFocusNode = FocusNode();
  final _apartmentFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  final _offerCodeController = TextEditingController();
  bool _isApplyingOfferCode = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;

    if (!_isInitialized) {
      _loadShippingDetails();
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _buildingNumberController.dispose();
    _floorNumberController.dispose();
    _apartmentNumberController.dispose();
    _phoneNumberController.dispose();
    _buildingFocusNode.dispose();
    _floorFocusNode.dispose();
    _apartmentFocusNode.dispose();
    _phoneFocusNode.dispose();
    _offerCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadShippingDetails() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('DEBUG: _loadShippingDetails: User not logged in, cannot load shipping details.');
      return;
    }

    try {
      Map<String, dynamic>? shippingAddressData;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData['defaultAddress'] is Map) {
          shippingAddressData = userData['defaultAddress'] as Map<String, dynamic>;
        }
      }

      if (shippingAddressData == null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('orderDate', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final latestOrderData = querySnapshot.docs.first.data();
          if (latestOrderData['shippingAddress'] is Map) {
            shippingAddressData = latestOrderData['shippingAddress'] as Map<String, dynamic>;
          }
        }
      }

      if (shippingAddressData != null) {
        final String? loadedArea = shippingAddressData['area'] as String?;
        setState(() {
          _selectedArea = loadedArea;
          _buildingNumberController.text = shippingAddressData!['buildingNumber'] ?? '';
          _floorNumberController.text = shippingAddressData['floorNumber'] ?? '';
          _apartmentNumberController.text = shippingAddressData['apartmentNumber'] ?? '';
          _phoneNumberController.text = shippingAddressData['phoneNumber'] ?? '';

          String? savedPaymentMethodName = shippingAddressData['paymentMethod'] as String?;
          if (savedPaymentMethodName != null) {
            try {
              _selectedPaymentMethod = PaymentMethod.values.firstWhere((e) => e.name == savedPaymentMethodName);
            } catch (e) {
              debugPrint('DEBUG: No matching payment method enum found for $savedPaymentMethodName');
            }
          }
        });
        if (_selectedArea != null && _selectedArea!.isNotEmpty) {
          _fetchShippingFee(_selectedArea!);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_appLocalizations.failedToLoadPreviousAddressDetails);
      debugPrint('ERROR: _loadShippingDetails: Error loading shipping details: $e');
    }
  }

  Future<void> _fetchShippingFee(String areaName) async {
    setState(() {
      _isLoadingShippingFee = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('areas')
          .where('name', isEqualTo: areaName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final areaData = querySnapshot.docs.first.data();
        final fee = (areaData['shippingFee'] as num?)?.toDouble() ?? 0.0;

        final now = DateTime.now();
        DateTime calculatedDeliveryDate;

        // Use AppConfig for business hours
        if (now.hour >= AppConfig.businessStartHour && now.hour < AppConfig.businessEndHour) {
          calculatedDeliveryDate = DateTime(now.year, now.month, now.day);
        } else {
          calculatedDeliveryDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        }

        setState(() {
          _currentShippingFee = fee;
          _calculatedDeliveryDateTime = calculatedDeliveryDate;
          Provider.of<BasketManager>(context, listen: false).setShippingArea(areaName, fee);
        });
      } else {
        setState(() {
          _currentShippingFee = 0.0;
          _calculatedDeliveryDateTime = null;
          Provider.of<BasketManager>(context, listen: false).clearShipping();
        });
      }
    } catch (e) {
      setState(() {
        _currentShippingFee = 0.0;
        _calculatedDeliveryDateTime = null;
        Provider.of<BasketManager>(context, listen: false).clearShipping();
      });
      if (!mounted) return;
      _showErrorSnackBar(_appLocalizations.failedToLoadPreviousAddressDetails);
      debugPrint('ERROR: _fetchShippingFee: Error fetching shipping fee: $e');
    } finally {
      setState(() {
        _isLoadingShippingFee = false;
      });
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _appLocalizations.pleaseEnterPhoneNumber;
    }
    final phoneRegex = RegExp(r'^(010|011|012|015)[0-9]{8}$');
    final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneRegex.hasMatch(cleanNumber)) {
      return _appLocalizations.pleaseEnterValidEgyptianPhoneNumber;
    }
    return null;
  }

  String? _validateGenericField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return _appLocalizations.pleaseEnterFieldName(fieldName);
    }
    return null;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _getPaymentMethodDisplayName(PaymentMethod? method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery: return _appLocalizations.cashOnDelivery;
      case PaymentMethod.vodafoneCash: return _appLocalizations.vodafoneCash;
      case PaymentMethod.etisalatCash: return _appLocalizations.etisalatCash;
      case PaymentMethod.weCash: return _appLocalizations.weCash;
      case PaymentMethod.instapay: return _appLocalizations.instapay;
      default: return _appLocalizations.selectPaymentMethod;
    }
  }

  Future<void> _launchPaymentAction(double totalAmount, PaymentMethod method) async {
    final String amountString = totalAmount.toInt().toString();
    String url = '';
    String codeOrNumber = '';
    LaunchMode launchMode = LaunchMode.externalApplication;

    String encodeDialerCode(String code) {
      return Uri.encodeComponent(code).replaceAll('%23', '#');
    }

    switch (method) {
      case PaymentMethod.vodafoneCash:
        codeOrNumber = AppConfig.paymentMethodCodes['vodafoneCash']!.replaceAll('{amount}', amountString);
        url = 'tel:${encodeDialerCode(codeOrNumber)}';
        break;
      case PaymentMethod.etisalatCash:
        codeOrNumber = AppConfig.paymentMethodCodes['etisalatCash']!.replaceAll('{amount}', amountString);
        url = 'tel:${encodeDialerCode(codeOrNumber)}';
        break;
      case PaymentMethod.weCash:
        codeOrNumber = AppConfig.paymentMethodCodes['weCash']!.replaceAll('{amount}', amountString);
        url = 'tel:${encodeDialerCode(codeOrNumber)}';
        break;
      case PaymentMethod.instapay:
        url = AppConfig.instapayUrl;
        launchMode = LaunchMode.externalApplication;
        break;
      case PaymentMethod.cashOnDelivery:
        return;
    }

    if (url.isNotEmpty) {
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: launchMode);
          if (method == PaymentMethod.vodafoneCash || method == PaymentMethod.etisalatCash || method == PaymentMethod.weCash) {
            _showInfoDialog(_appLocalizations.paymentMethod, _appLocalizations.paymentDialerPrompt(codeOrNumber, amountString));
          }
        } else {
          _showErrorSnackBar(_appLocalizations.couldNotLaunchUrl(url));
        }
      } catch (e) {
        _showErrorSnackBar('Error launching payment: $e');
      }
    }
  }

  Future<void> _showInfoDialog(String title, String content) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_appLocalizations.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showOrderConfirmationDialog(BasketManager basket) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String formatDeliveryDateInDialog(DateTime dateTime) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
          final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

          if (dateOnly == today) {
            return _appLocalizations.today;
          } else if (dateOnly == tomorrow) {
            return _appLocalizations.tomorrow;
          } else {
            return DateFormat('dd MMM', _appLocalizations.localeName).format(dateTime);
          }
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.receipt_long, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(_appLocalizations.confirmOrder),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _appLocalizations.orderTotal(basket.grandTotal.toStringAsFixed(2)),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('${_appLocalizations.deliveryTo}: ${_selectedArea ?? 'N/A'}'),
                if (_calculatedDeliveryDateTime != null)
                  Text('${_appLocalizations.estimatedDelivery}: ${formatDeliveryDateInDialog(_calculatedDeliveryDateTime!)}'),
                const SizedBox(height: 16),
                Text('${_appLocalizations.paymentMethod}: ${_getPaymentMethodDisplayName(_selectedPaymentMethod)}'),
                if (basket.appliedOfferCode != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_appLocalizations.offerCode}: ${basket.appliedOfferCode} (-${basket.discountPercentage.toStringAsFixed(0)}%)',
                    style: const TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 16),
                Text(_appLocalizations.areYouSureWantToPlaceOrder),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_appLocalizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(_appLocalizations.confirm),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _processOrder(basket);
    }
  }

  Future<void> _processOrder(BasketManager basket) async {
    setState(() { _isProcessingOrder = true; });

    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() { _isProcessingOrder = false; });
      return;
    }
    if (_selectedArea == null || _selectedArea!.isEmpty) {
      _showErrorSnackBar(_appLocalizations.pleaseSelectShippingArea);
      setState(() { _isProcessingOrder = false; });
      return;
    }
    if (basket.items.isEmpty) {
      _showErrorSnackBar(_appLocalizations.basketEmptyCannotCheckout);
      setState(() { _isProcessingOrder = false; });
      return;
    }
    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar(_appLocalizations.selectPaymentMethod);
      setState(() { _isProcessingOrder = false; });
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userId == null) {
        _showErrorSnackBar(_appLocalizations.userNotLoggedInToPlaceOrder);
        setState(() { _isProcessingOrder = false; });
        return;
      }

      final List<Map<String, dynamic>> finalOrderedItems = [];

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // PHASE 1: Do ALL reads first
        Map<String, DocumentSnapshot> productSnapshots = {};
        Map<String, int> newQuantities = {};

        for (var cartItem in basket.items.values) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(cartItem.productId);
          final productSnapshot = await transaction.get(productRef);
          productSnapshots[cartItem.productId] = productSnapshot;
        }

        // PHASE 2: Validate and calculate new quantities
        for (var cartItem in basket.items.values) {
          final productSnapshot = productSnapshots[cartItem.productId]!;

          if (!productSnapshot.exists) {
            throw Exception(_appLocalizations.productDoesNotExistInInventory(cartItem.name));
          }

          final currentQuantity = (productSnapshot.data() as Map<String, dynamic>?)?['quantity'] as int? ?? 0;
          final orderedQuantity = cartItem.quantity;
          final newQuantity = currentQuantity - orderedQuantity;

          if (newQuantity < 0) {
            throw Exception(_appLocalizations.notEnoughStock(
              cartItem.name,
              currentQuantity,
              orderedQuantity,
            ));
          }

          newQuantities[cartItem.productId] = newQuantity;

          finalOrderedItems.add({
            'productId': cartItem.productId,
            'name': cartItem.name,
            'price': cartItem.price,
            'discountedPricePerItem': cartItem.discountedPricePerItem,
            'quantity': cartItem.quantity,
            'imageUrls': cartItem.product.imageUrls,
            'itemDiscount': cartItem.product.discount,
          });
        }

        // PHASE 3: Do ALL writes after all reads are complete
        for (var cartItem in basket.items.values) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(cartItem.productId);
          transaction.update(productRef, {'quantity': newQuantities[cartItem.productId]});
        }
      });

      final now = DateTime.now();
      DateTime finalCalculatedDeliveryDate;
      if (now.hour >= AppConfig.businessStartHour && now.hour < AppConfig.businessEndHour) {
        finalCalculatedDeliveryDate = DateTime(now.year, now.month, now.day);
      } else {
        finalCalculatedDeliveryDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      }

      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'userId': userId,
        'userEmail': userEmail,
        'orderDate': Timestamp.now(),
        'items': finalOrderedItems,
        'subtotalPrice': basket.subtotal,
        'shippingFee': basket.shippingFee,
        'discountedSubtotalPrice': basket.discountedSubtotal,
        'totalPrice': basket.grandTotal,
        'shippingAddress': {
          'area': _selectedArea,
          'buildingNumber': _buildingNumberController.text.trim(),
          'floorNumber': _floorNumberController.text.trim(),
          'apartmentNumber': _apartmentNumberController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'paymentMethod': _selectedPaymentMethod!.name,
        },
        'orderStatus': 'Pending',
        'estimatedDeliveryTimestamp': Timestamp.fromDate(finalCalculatedDeliveryDate),
        'appliedOfferCode': basket.appliedOfferCode,
        'appliedDiscountPercentage': basket.discountPercentage,
        'paymentMethod': _selectedPaymentMethod!.name,
      });

      // 🎯 NOTIFICATION CODE - RIGHT AFTER ORDER IS SAVED! 🎯
      try {
        debugPrint('🔔 Sending order notifications for order: ${orderRef.id}');

        // Create the order data in the exact format the API expects
        final orderDataForNotification = {
          'totalPrice': basket.grandTotal,
          'userEmail': userEmail ?? 'Unknown',
          'items': finalOrderedItems,
          'orderStatus': 'Pending',
          'userId': userId,
          'subtotalPrice': basket.subtotal,
          'shippingFee': basket.shippingFee,
          'discountedSubtotalPrice': basket.discountedSubtotal,
          'orderDate': DateTime.now().toIso8601String(),
          'shippingAddress': {
            'area': _selectedArea,
            'buildingNumber': _buildingNumberController.text.trim(),
            'floorNumber': _floorNumberController.text.trim(),
            'apartmentNumber': _apartmentNumberController.text.trim(),
            'phoneNumber': _phoneNumberController.text.trim(),
            'paymentMethod': _selectedPaymentMethod!.name,
          },
          'paymentMethod': _selectedPaymentMethod!.name,
        };

        // Use the direct method that sends the exact order data format
        await ApiNotificationService.notifyNewOrderDirect(
          orderId: orderRef.id,
          orderData: orderDataForNotification,
        );

        debugPrint('✅ Order notifications sent successfully');
      } catch (notificationError) {
        // Don't fail the order if notifications fail
        debugPrint('❌ Failed to send order notifications: $notificationError');
        // Optionally show a warning to the user, but don't break the order flow
      }

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'defaultAddress': {
          'area': _selectedArea,
          'buildingNumber': _buildingNumberController.text.trim(),
          'floorNumber': _floorNumberController.text.trim(),
          'apartmentNumber': _apartmentNumberController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'paymentMethod': _selectedPaymentMethod!.name,
        },
      }, SetOptions(merge: true));

      if (_selectedPaymentMethod != PaymentMethod.cashOnDelivery) {
        await _launchPaymentAction(basket.grandTotal, _selectedPaymentMethod!);
      }

      basket.clearBasket();
      _showSuccessSnackBar(_appLocalizations.orderPlacedSuccessfully);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: orderRef.id),
        ),
      );
    } catch (e) {
      _showErrorSnackBar(_appLocalizations.failedToPlaceOrder(e.toString()));
      debugPrint('Order processing error: $e');
    } finally {
      setState(() { _isProcessingOrder = false; });
    }
  }

  Future<void> _applyOfferCode() async {
    setState(() { _isApplyingOfferCode = true; });
    final basketManager = Provider.of<BasketManager>(context, listen: false);
    final String code = _offerCodeController.text.trim();

    bool success = await basketManager.applyOfferCode(code);

    if (!mounted) return;
    setState(() { _isApplyingOfferCode = false; });

    if (success) {
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_appLocalizations.itemRemoved('Offer Code'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_appLocalizations.offerCodeAddedSuccessfully(code))),
        );
      }
    } else {
      basketManager.clearOfferCode();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or inactive offer code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final basket = Provider.of<BasketManager>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _appLocalizations.checkoutTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: basket.items.isEmpty
          ? EmptyBasketView(appLocalizations: _appLocalizations)
          : SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                OrderSummaryCard(
                  basket: basket,
                  appLocalizations: _appLocalizations,
                  isLoadingShippingFee: _isLoadingShippingFee,
                  calculatedDeliveryDateTime: _calculatedDeliveryDateTime,
                ),
                const SizedBox(height: 20),
                OfferCodeSection(
                  offerCodeController: _offerCodeController,
                  isApplyingOfferCode: _isApplyingOfferCode,
                  onApplyOfferCode: _applyOfferCode,
                  basket: basket,
                  appLocalizations: _appLocalizations,
                ),
                const SizedBox(height: 20),
                ShippingForm(
                  formKey: _formKey,
                  selectedArea: _selectedArea,
                  onAreaChanged: (String? newValue) {
                    setState(() {
                      _selectedArea = newValue;
                      if (newValue != null) {
                        _fetchShippingFee(newValue);
                      } else {
                        _currentShippingFee = 0.0;
                        _calculatedDeliveryDateTime = null;
                        basket.clearShipping();
                      }
                    });
                  },
                  buildingNumberController: _buildingNumberController,
                  floorNumberController: _floorNumberController,
                  apartmentNumberController: _apartmentNumberController,
                  phoneNumberController: _phoneNumberController,
                  buildingFocusNode: _buildingFocusNode,
                  floorFocusNode: _floorFocusNode,
                  apartmentFocusNode: _apartmentFocusNode,
                  phoneFocusNode: _phoneFocusNode,
                  appLocalizations: _appLocalizations,
                  validateGenericField: _validateGenericField,
                  validatePhoneNumber: _validatePhoneNumber,
                ),
                const SizedBox(height: 20),
                PaymentMethodSelection(
                  selectedPaymentMethod: _selectedPaymentMethod,
                  onPaymentMethodChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                  appLocalizations: _appLocalizations,
                ),
                const SizedBox(height: 30),
                PlaceOrderButton(
                  basket: basket,
                  isProcessingOrder: _isProcessingOrder,
                  onPressed: () => _showOrderConfirmationDialog(basket),
                  appLocalizations: _appLocalizations,
                  isButtonEnabled: !_isProcessingOrder &&
                      basket.items.isNotEmpty &&
                      _selectedArea != null &&
                      _selectedPaymentMethod != null &&
                      (_formKey.currentState?.validate() ?? false) &&
                      _calculatedDeliveryDateTime != null,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}