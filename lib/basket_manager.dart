import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bubbles_ecommerce_app/models/product.dart';
import 'package:bubbles_ecommerce_app/models/cart_item.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';

class BasketManager with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  double _shippingFee = 0.0;
  String? _shippingArea;
  double _discountPercentage = 0.0;
  String? _appliedOfferCode;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PatternService _patternService = PatternService();

  // Keys for SharedPreferences
  static const String _basketItemsKey = 'basket_items';
  static const String _shippingFeeKey = 'shipping_fee';
  static const String _shippingAreaKey = 'shipping_area';
  static const String _discountPercentageKey = 'discount_percentage';
  static const String _appliedOfferCodeKey = 'applied_offer_code';

  BasketManager() {
    _loadBasketFromStorage();
  }

  Map<String, CartItem> get items => {..._items};
  List<CartItem> get basketItems => _items.values.toList();
  double get shippingFee => _shippingFee;
  String? get shippingArea => _shippingArea;
  double get discountPercentage => _discountPercentage;
  String? get appliedOfferCode => _appliedOfferCode;

  // Total count of unique products in the basket
  int get itemCount {
    return _items.length;
  }

  // Total quantity of all items (sum of quantities of each product)
  int get totalQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  double get subtotal {
    double total = 0.0;
    _items.forEach((productId, item) {
      total += item.product.discountedPrice * item.quantity;
    });
    return total;
  }

  double get discountedSubtotal {
    return subtotal * (1 - (_discountPercentage / 100));
  }

  double get totalPrice => discountedSubtotal;

  double get grandTotal {
    return discountedSubtotal + _shippingFee;
  }

  // Load basket data from SharedPreferences
  Future<void> _loadBasketFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load basket items
      final String? basketItemsJson = prefs.getString(_basketItemsKey);
      if (basketItemsJson != null) {
        final Map<String, dynamic> basketData = json.decode(basketItemsJson);

        for (String productId in basketData.keys) {
          final itemData = basketData[productId] as Map<String, dynamic>;

          // Reconstruct Product from saved data
          final productData = itemData['product'] as Map<String, dynamic>;
          final product = Product(
            id: productData['id'] ?? '',
            name: productData['name'] ?? '',
            price: (productData['price'] as num?)?.toDouble() ?? 0.0,
            discount: (productData['discount'] as num?)?.toInt() ?? 0,
            quantity: (productData['quantity'] as num?)?.toInt() ?? 0,
            description: productData['description'] ?? '',
            imageUrls: List<String>.from(productData['imageUrls'] ?? []),
            category: productData['category'],
            isOffer: productData['isOffer'] ?? false,
            tags: List<String>.from(productData['tags'] ?? []),
            relatedProductIds: List<String>.from(productData['relatedProductIds'] ?? []),
            createdAt: productData['createdAt'] != null
                ? Timestamp.fromMillisecondsSinceEpoch(productData['createdAt'])
                : null,
          );

          final cartItem = CartItem(
            product: product,
            quantity: (itemData['quantity'] as num?)?.toInt() ?? 1,
          );

          _items[productId] = cartItem;
        }
      }

      // Load other data
      _shippingFee = prefs.getDouble(_shippingFeeKey) ?? 0.0;
      _shippingArea = prefs.getString(_shippingAreaKey);
      _discountPercentage = prefs.getDouble(_discountPercentageKey) ?? 0.0;
      _appliedOfferCode = prefs.getString(_appliedOfferCodeKey);

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading basket from storage: $e');
      // If there's an error, start with empty basket
      _clearBasketData();
    }
  }

  // Save basket data to SharedPreferences
  Future<void> _saveBasketToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert basket items to JSON
      final Map<String, dynamic> basketData = {};
      _items.forEach((productId, cartItem) {
        basketData[productId] = {
          'product': {
            'id': cartItem.product.id,
            'name': cartItem.product.name,
            'price': cartItem.product.price,
            'discount': cartItem.product.discount,
            'quantity': cartItem.product.quantity,
            'description': cartItem.product.description,
            'imageUrls': cartItem.product.imageUrls,
            'category': cartItem.product.category,
            'isOffer': cartItem.product.isOffer,
            'tags': cartItem.product.tags,
            'relatedProductIds': cartItem.product.relatedProductIds,
            'createdAt': cartItem.product.createdAt?.millisecondsSinceEpoch,
          },
          'quantity': cartItem.quantity,
        };
      });

      await prefs.setString(_basketItemsKey, json.encode(basketData));
      await prefs.setDouble(_shippingFeeKey, _shippingFee);

      if (_shippingArea != null) {
        await prefs.setString(_shippingAreaKey, _shippingArea!);
      } else {
        await prefs.remove(_shippingAreaKey);
      }

      await prefs.setDouble(_discountPercentageKey, _discountPercentage);

      if (_appliedOfferCode != null) {
        await prefs.setString(_appliedOfferCodeKey, _appliedOfferCode!);
      } else {
        await prefs.remove(_appliedOfferCodeKey);
      }

    } catch (e) {
      debugPrint('Error saving basket to storage: $e');
    }
  }

  // Clear all basket data from memory and storage
  void _clearBasketData() {
    _items.clear();
    _shippingFee = 0.0;
    _shippingArea = null;
    _discountPercentage = 0.0;
    _appliedOfferCode = null;
  }

  void addItem(Product product, int quantity) {
    if (_items.containsKey(product.id)) {
      _items.update(product.id, (existingItem) {
        final newQuantity = existingItem.quantity + quantity;
        return CartItem(
          product: existingItem.product,
          quantity: newQuantity,
        );
      });
    } else {
      _items.putIfAbsent(product.id, () {
        return CartItem(
          product: product,
          quantity: quantity,
        );
      });
    }
    _saveBasketToStorage();
    notifyListeners();
  }

  // ==========================================
  // NEW: Add to basket by product ID (for CustomerReorderScreen)
  // ==========================================
  Future<void> addToBasket(String productId, int quantity) async {
    try {
      debugPrint('🛒 Adding to basket: $productId x $quantity');

      // Get product from Firestore
      final productDoc = await _firestore.collection('products').doc(productId).get();

      if (!productDoc.exists) {
        debugPrint('❌ Product not found: $productId');
        throw Exception('Product not found');
      }

      final product = Product.fromFirestore(productDoc);

      // Check if product has enough stock
      if (product.quantity < quantity) {
        debugPrint('❌ Insufficient stock for $productId. Available: ${product.quantity}, Requested: $quantity');
        throw Exception('Insufficient stock. Only ${product.quantity} available.');
      }

      // Add to basket using existing method
      addItem(product, quantity);

      debugPrint('✅ Added $quantity x ${product.name} to basket');
    } catch (e) {
      debugPrint('❌ Error adding to basket: $e');
      rethrow;
    }
  }

  void updateItemQuantity(String productId, int newQuantity) {
    if (_items.containsKey(productId)) {
      if (newQuantity <= 0) {
        _items.remove(productId);
      } else {
        _items.update(productId, (existingItem) {
          return CartItem(
            product: existingItem.product,
            quantity: newQuantity,
          );
        });
      }
      _saveBasketToStorage();
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveBasketToStorage();
    notifyListeners();
  }

  Future<void> clearBasket() async {
    _clearBasketData();

    // Clear from storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_basketItemsKey);
      await prefs.remove(_shippingFeeKey);
      await prefs.remove(_shippingAreaKey);
      await prefs.remove(_discountPercentageKey);
      await prefs.remove(_appliedOfferCodeKey);
    } catch (e) {
      debugPrint('Error clearing basket from storage: $e');
    }

    notifyListeners();
  }

  void setShippingArea(String area, double fee) {
    _shippingArea = area;
    _shippingFee = fee;
    _saveBasketToStorage();
    notifyListeners();
  }

  void clearShipping() {
    _shippingFee = 0.0;
    _shippingArea = null;
    _saveBasketToStorage();
    notifyListeners();
  }

  Future<bool> applyOfferCode(String code) async {
    if (code.isEmpty) {
      _discountPercentage = 0.0;
      _appliedOfferCode = null;
      _saveBasketToStorage();
      notifyListeners();
      return true;
    }

    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('offer_codes').doc(code).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final double discount = (data?['discountPercentage'] as num?)?.toDouble() ?? 0.0;
        final bool isActive = data?['isActive'] ?? false;

        if (isActive) {
          _discountPercentage = discount;
          _appliedOfferCode = code;
          _saveBasketToStorage();
          notifyListeners();
          return true;
        }
      }
      _discountPercentage = 0.0;
      _appliedOfferCode = null;
      _saveBasketToStorage();
      notifyListeners();
      return false; // Code not found or not active
    } catch (e) {
      debugPrint('Error applying offer code: $e');
      _discountPercentage = 0.0;
      _appliedOfferCode = null;
      _saveBasketToStorage();
      notifyListeners();
      return false;
    }
  }

  void clearOfferCode() {
    _discountPercentage = 0.0;
    _appliedOfferCode = null;
    _saveBasketToStorage();
    notifyListeners();
  }

  // Method to refresh product data in basket (useful if product prices/stock change)
  Future<void> refreshBasketProducts() async {
    if (_items.isEmpty) return;

    try {
      final List<String> productIds = _items.keys.toList();
      final Map<String, CartItem> updatedItems = {};

      // Fetch fresh product data from Firestore
      for (String productId in productIds) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final freshProduct = Product.fromFirestore(productDoc);
          final currentQuantity = _items[productId]!.quantity;

          updatedItems[productId] = CartItem(
            product: freshProduct,
            quantity: currentQuantity,
          );
        }
        // If product doesn't exist anymore, we don't add it to updatedItems
      }

      _items.clear();
      _items.addAll(updatedItems);

      _saveBasketToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing basket products: $e');
    }
  }

  // ==========================================
  // ENHANCED: ML PATTERN TRACKING INTEGRATION
  // ==========================================

  /// Place order and track patterns for ML system
  Future<String?> placeOrder({
    required String userEmail,
    required Map<String, String> shippingAddress,
    required double shippingFee,
    String? offerCode,
    double discountAmount = 0.0,
  }) async {
    if (_items.isEmpty) {
      throw Exception('Basket is empty');
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🛒 Starting order placement for user: ${currentUser.uid}');
      debugPrint('🛒 Items in basket: ${_items.length}');

      // Prepare order data
      final orderData = {
        'userId': currentUser.uid,
        'userEmail': userEmail,
        'items': _items.values.map((item) => {
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
          'discountedPrice': item.product.discountedPrice,
          'imageUrl': item.imageUrl,
        }).toList(),
        'totalPrice': totalPrice,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discountAmount': discountAmount,
        'offerCode': offerCode,
        'shippingAddress': shippingAddress,
        'orderStatus': 'Pending',
        'orderDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Place the order in Firestore
      final orderRef = await _firestore.collection('orders').add(orderData);
      final orderId = orderRef.id;

      debugPrint('✅ Order placed successfully: $orderId');

      // Update product quantities
      await _updateProductQuantities();

      // ==========================================
      // ENHANCED PATTERN TRACKING WITH DEBUGGING
      // ==========================================
      debugPrint('🧠 Starting pattern tracking...');

      try {
        // Prepare items for pattern tracking
        final trackingItems = _items.values.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
        }).toList();

        debugPrint('🧠 Tracking items: $trackingItems');

        await _patternService.trackOrder(
          userId: currentUser.uid,
          items: trackingItems,
          orderDate: DateTime.now(),
        );

        debugPrint('✅ Pattern tracking completed successfully');
      } catch (patternError) {
        debugPrint('⚠️ Pattern tracking failed: $patternError');
        debugPrint('⚠️ Pattern tracking stack trace: ${patternError.toString()}');
        // Don't fail the order if pattern tracking fails
      }
      // ==========================================

      // Clear the basket after successful order
      await clearBasket();
      debugPrint('✅ Basket cleared after successful order');

      return orderId;
    } catch (e) {
      debugPrint('❌ Error placing order: $e');
      rethrow;
    }
  }

  /// Update product quantities in Firestore after order
  Future<void> _updateProductQuantities() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (CartItem item in _items.values) {
        DocumentReference productRef = _firestore.collection('products').doc(item.product.id);

        // Decrease quantity by the amount ordered
        batch.update(productRef, {
          'quantity': FieldValue.increment(-item.quantity),
        });
      }

      await batch.commit();
      debugPrint('✅ Product quantities updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating product quantities: $e');
      // Don't throw error as order is already placed
    }
  }

  // ==========================================
  // DEBUGGING METHODS
  // ==========================================

  /// Test pattern tracking without placing an order (for debugging)
  Future<void> testPatternTracking() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in for pattern testing');
      return;
    }

    try {
      debugPrint('🧪 Testing pattern tracking...');

      // Test with sample data
      await _patternService.trackOrder(
        userId: currentUser.uid,
        items: [
          {'productId': 'test_product_1', 'quantity': 2},
          {'productId': 'test_product_2', 'quantity': 1},
        ],
        orderDate: DateTime.now(),
      );

      debugPrint('✅ Pattern tracking test completed');
    } catch (e) {
      debugPrint('❌ Pattern tracking test failed: $e');
    }
  }

  /// Place order without pattern tracking (for debugging)
  Future<String?> placeOrderWithoutPatterns({
    required String userEmail,
    required Map<String, String> shippingAddress,
    required double shippingFee,
    String? offerCode,
    double discountAmount = 0.0,
  }) async {
    if (_items.isEmpty) {
      throw Exception('Basket is empty');
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🛒 Placing order WITHOUT pattern tracking...');

      // Prepare order data
      final orderData = {
        'userId': currentUser.uid,
        'userEmail': userEmail,
        'items': _items.values.map((item) => {
          'productId': item.product.id,
          'productName': item.product.name,
          'quantity': item.quantity,
          'price': item.product.price,
          'discountedPrice': item.product.discountedPrice,
          'imageUrl': item.imageUrl,
        }).toList(),
        'totalPrice': totalPrice,
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'discountAmount': discountAmount,
        'offerCode': offerCode,
        'shippingAddress': shippingAddress,
        'orderStatus': 'Pending',
        'orderDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Place the order in Firestore
      final orderRef = await _firestore.collection('orders').add(orderData);
      final orderId = orderRef.id;

      debugPrint('✅ Order placed successfully WITHOUT patterns: $orderId');

      // Update product quantities
      await _updateProductQuantities();

      // Clear the basket
      await clearBasket();

      return orderId;
    } catch (e) {
      debugPrint('❌ Error placing order without patterns: $e');
      rethrow;
    }
  }

  /// Check current basket status for debugging
  void debugBasketStatus() {
    debugPrint('🛒 === BASKET DEBUG STATUS ===');
    debugPrint('🛒 Items count: ${_items.length}');
    debugPrint('🛒 Total quantity: $totalQuantity');
    debugPrint('🛒 Subtotal: \$${subtotal.toStringAsFixed(2)}');
    debugPrint('🛒 Items:');

    _items.forEach((productId, item) {
      debugPrint('   - ${item.product.name}: ${item.quantity} x \$${item.product.discountedPrice}');
    });

    debugPrint('🛒 === END BASKET DEBUG ===');
  }
}