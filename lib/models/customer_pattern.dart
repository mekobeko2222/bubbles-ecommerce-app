// File Location: lib/models/customer_pattern.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerPattern {
  final String userId;
  final String productId;
  final List<OrderEntry> orderHistory;
  final int orderCount;
  final double avgDaysBetweenOrders;
  final double avgQuantityPerOrder;
  final double confidence;
  final DateTime? firstOrderDate;
  final DateTime? lastOrderDate;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  CustomerPattern({
    required this.userId,
    required this.productId,
    required this.orderHistory,
    required this.orderCount,
    required this.avgDaysBetweenOrders,
    required this.avgQuantityPerOrder,
    required this.confidence,
    this.firstOrderDate,
    this.lastOrderDate,
    this.createdAt,
    this.lastUpdated,
  });

  // Generate pattern ID
  String get patternId => '${userId}_$productId';

  // Check if pattern is reliable
  bool get isReliable => confidence >= 0.5 && orderCount >= 3;

  // Check if pattern has enough data
  bool get hasEnoughData => orderCount >= 2;

  // Get next predicted order date
  DateTime? get predictedNextOrderDate {
    if (!hasEnoughData || avgDaysBetweenOrders <= 0 || lastOrderDate == null) {
      return null;
    }
    return lastOrderDate!.add(Duration(days: avgDaysBetweenOrders.round()));
  }

  // Get days until next predicted order
  int? get daysUntilNextOrder {
    final nextOrder = predictedNextOrderDate;
    if (nextOrder == null) return null;

    final now = DateTime.now();
    return nextOrder.difference(now).inDays;
  }

  // Check if reminder should be sent
  bool shouldSendReminder({String reminderTiming = '2_days_before'}) {
    final daysUntil = daysUntilNextOrder;
    if (daysUntil == null || !isReliable) return false;

    switch (reminderTiming) {
      case '1_day_before':
        return daysUntil <= 1 && daysUntil >= 0;
      case '2_days_before':
        return daysUntil <= 2 && daysUntil >= 0;
      case '3_days_before':
        return daysUntil <= 3 && daysUntil >= 0;
      case 'on_date':
        return daysUntil <= 0;
      default:
        return daysUntil <= 2 && daysUntil >= 0;
    }
  }

  // Create from Firestore document
  factory CustomerPattern.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse order history
    final orderHistoryData = data['orderHistory'] as List<dynamic>? ?? [];
    final orderHistory = orderHistoryData
        .map((item) => OrderEntry.fromMap(item as Map<String, dynamic>))
        .toList();

    return CustomerPattern(
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      orderHistory: orderHistory,
      orderCount: data['orderCount'] ?? 0,
      avgDaysBetweenOrders: (data['avgDaysBetweenOrders'] ?? 0.0).toDouble(),
      avgQuantityPerOrder: (data['avgQuantityPerOrder'] ?? 0.0).toDouble(),
      confidence: (data['confidence'] ?? 0.0).toDouble(),
      firstOrderDate: (data['firstOrderDate'] as Timestamp?)?.toDate(),
      lastOrderDate: (data['lastOrderDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'orderHistory': orderHistory.map((entry) => entry.toMap()).toList(),
      'orderCount': orderCount,
      'avgDaysBetweenOrders': avgDaysBetweenOrders,
      'avgQuantityPerOrder': avgQuantityPerOrder,
      'confidence': confidence,
      'firstOrderDate': firstOrderDate != null ? Timestamp.fromDate(firstOrderDate!) : null,
      'lastOrderDate': lastOrderDate != null ? Timestamp.fromDate(lastOrderDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Copy with new values
  CustomerPattern copyWith({
    String? userId,
    String? productId,
    List<OrderEntry>? orderHistory,
    int? orderCount,
    double? avgDaysBetweenOrders,
    double? avgQuantityPerOrder,
    double? confidence,
    DateTime? firstOrderDate,
    DateTime? lastOrderDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return CustomerPattern(
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      orderHistory: orderHistory ?? this.orderHistory,
      orderCount: orderCount ?? this.orderCount,
      avgDaysBetweenOrders: avgDaysBetweenOrders ?? this.avgDaysBetweenOrders,
      avgQuantityPerOrder: avgQuantityPerOrder ?? this.avgQuantityPerOrder,
      confidence: confidence ?? this.confidence,
      firstOrderDate: firstOrderDate ?? this.firstOrderDate,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'CustomerPattern(userId: $userId, productId: $productId, orderCount: $orderCount, confidence: $confidence)';
  }
}

// Individual order entry in the pattern
class OrderEntry {
  final DateTime orderDate;
  final int quantity;
  final int daysSinceLastOrder;

  OrderEntry({
    required this.orderDate,
    required this.quantity,
    required this.daysSinceLastOrder,
  });

  // Create from map
  factory OrderEntry.fromMap(Map<String, dynamic> map) {
    return OrderEntry(
      orderDate: (map['orderDate'] as Timestamp).toDate(),
      quantity: map['quantity'] ?? 0,
      daysSinceLastOrder: map['daysSinceLastOrder'] ?? 0,
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'orderDate': Timestamp.fromDate(orderDate),
      'quantity': quantity,
      'daysSinceLastOrder': daysSinceLastOrder,
    };
  }

  @override
  String toString() {
    return 'OrderEntry(date: $orderDate, quantity: $quantity, days: $daysSinceLastOrder)';
  }
}