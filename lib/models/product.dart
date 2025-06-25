import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int discount;
  final int quantity;
  final String description;
  final List<String> imageUrls;
  final String? category;
  final bool isOffer;
  final List<String> tags;
  final List<String> relatedProductIds;
  final Timestamp? createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.discount = 0,
    this.quantity = 0,
    this.description = '',
    this.imageUrls = const [],
    this.category,
    this.isOffer = false,
    this.tags = const [],
    this.relatedProductIds = const [],
    this.createdAt,
  });

  // Calculate discounted price
  double get discountedPrice {
    return price * (1 - (discount / 100));
  }

  // Helper for robust numeric parsing
  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Factory constructor to create a Product from a Firestore DocumentSnapshot
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Defensive parsing for numeric values using helper functions
    final double parsedPrice = _parseDouble(data['price']);
    final int parsedDiscount = _parseInt(data['discount']);
    final int parsedQuantity = _parseInt(data['quantity']);

    // Debugging for parsing
    // debugPrint('Product.fromFirestore - Raw Data: $data');
    // debugPrint('Product.fromFirestore - Parsed Price: $parsedPrice (was ${data['price']?.runtimeType})');
    // debugPrint('Product.fromFirestore - Parsed Discount: $parsedDiscount (was ${data['discount']?.runtimeType})');
    // debugPrint('Product.fromFirestore - Parsed Quantity: $parsedQuantity (was ${data['quantity']?.runtimeType})');


    return Product(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Product',
      price: parsedPrice,
      discount: parsedDiscount,
      quantity: parsedQuantity,
      description: data['description'] ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: data['category'] as String?,
      isOffer: data['isOffer'] ?? false,
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      relatedProductIds: (data['relatedProductIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  // Convert Product object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'discount': discount,
      'quantity': quantity,
      'description': description,
      'imageUrls': imageUrls,
      'category': category,
      'isOffer': isOffer,
      'tags': tags,
      'relatedProductIds': relatedProductIds,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
