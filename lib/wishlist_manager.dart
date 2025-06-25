import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';

class WishlistManager extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _wishlistProductIds = [];
  Map<String, Product> _wishlistProducts = {};
  bool _isLoading = false;

  List<String> get wishlistProductIds => _wishlistProductIds;
  List<Product> get wishlistProducts => _wishlistProducts.values.toList();
  bool get isLoading => _isLoading;
  int get wishlistCount => _wishlistProductIds.length;

  WishlistManager() {
    _loadWishlist();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _clearWishlist();
      } else {
        _loadWishlist();
      }
    });
  }

  Future<void> _loadWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load wishlist product IDs from user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final List<dynamic> wishlistIds = userData['wishlist'] ?? [];
        _wishlistProductIds = wishlistIds.cast<String>();
      } else {
        _wishlistProductIds = [];
      }

      // Load actual product data for wishlist items
      await _loadProductDetails();

    } catch (e) {
      debugPrint('Error loading wishlist: $e');
      _wishlistProductIds = [];
      _wishlistProducts = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProductDetails() async {
    if (_wishlistProductIds.isEmpty) {
      _wishlistProducts = {};
      return;
    }

    try {
      // Split into chunks of 10 (Firestore limit for 'in' queries)
      Map<String, Product> products = {};

      for (int i = 0; i < _wishlistProductIds.length; i += 10) {
        final chunk = _wishlistProductIds.skip(i).take(10).toList();

        final querySnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in querySnapshot.docs) {
          products[doc.id] = Product.fromFirestore(doc);
        }
      }

      _wishlistProducts = products;

      // Remove any product IDs that no longer exist
      _wishlistProductIds.removeWhere((id) => !products.containsKey(id));

    } catch (e) {
      debugPrint('Error loading product details: $e');
    }
  }

  bool isInWishlist(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  Future<bool> toggleWishlist(Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to manage wishlist');
    }

    try {
      if (isInWishlist(product.id)) {
        return await _removeFromWishlist(product.id);
      } else {
        return await _addToWishlist(product);
      }
    } catch (e) {
      debugPrint('Error toggling wishlist: $e');
      return false;
    }
  }

  Future<bool> _addToWishlist(Product product) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _wishlistProductIds.add(product.id);
      _wishlistProducts[product.id] = product;
      notifyListeners();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'wishlist': FieldValue.arrayUnion([product.id]),
      });

      return true;
    } catch (e) {
      // Revert local changes if Firestore update fails
      _wishlistProductIds.remove(product.id);
      _wishlistProducts.remove(product.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> _removeFromWishlist(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Store the product before removing it for potential revert
    final Product? removedProduct = _wishlistProducts[productId];

    try {
      _wishlistProductIds.remove(productId);
      _wishlistProducts.remove(productId);
      notifyListeners();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'wishlist': FieldValue.arrayRemove([productId]),
      });

      return true;
    } catch (e) {
      // Revert local changes if Firestore update fails
      if (!_wishlistProductIds.contains(productId)) {
        _wishlistProductIds.add(productId);
        if (removedProduct != null) {
          _wishlistProducts[productId] = removedProduct;
        }
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> clearWishlist() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Store old data for potential revert
      final List<String> oldWishlistIds = List<String>.from(_wishlistProductIds);
      final Map<String, Product> oldWishlistProducts = Map<String, Product>.from(_wishlistProducts);

      _wishlistProductIds.clear();
      _wishlistProducts.clear();
      notifyListeners();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'wishlist': [],
      });

    } catch (e) {
      // Revert local changes if Firestore update fails
      _wishlistProductIds = List<String>.from(_wishlistProductIds);
      _wishlistProducts = Map<String, Product>.from(_wishlistProducts);
      notifyListeners();
      rethrow;
    }
  }

  void _clearWishlist() {
    _wishlistProductIds.clear();
    _wishlistProducts.clear();
    notifyListeners();
  }

  // Method to refresh wishlist data
  Future<void> refreshWishlist() async {
    await _loadWishlist();
  }

  // Method to remove product if it's no longer available
  Future<void> removeUnavailableProduct(String productId) async {
    if (isInWishlist(productId)) {
      await _removeFromWishlist(productId);
    }
  }
}