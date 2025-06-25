import 'package:bubbles_ecommerce_app/models/product.dart'; // Ensure Product model is imported

/// Represents an item in the shopping basket.
/// It holds a reference to the actual Product and the quantity desired.
class CartItem {
  final Product product;
  final int quantity;

  // Constructor now takes Product and quantity directly.
  // All other properties are derived from the 'product' object via getters.
  CartItem({
    required this.product,
    required this.quantity,
  });

  // Getters to derive information from the associated Product object
  String get productId => product.id;
  String get name => product.name;
  double get price => product.price; // Original price of the product
  double get discountedPricePerItem => product.discountedPrice; // Discounted price of the product
  String get imageUrl => product.imageUrls.isNotEmpty ? product.imageUrls[0] : '';
}
