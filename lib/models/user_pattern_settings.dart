// File Location: lib/models/user_pattern_settings.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserPatternSettings {
  final String userId;
  final bool enableReminders;
  final String reminderTiming;
  final List<DateTime> orderHistory;
  final int totalOrders;
  final double overallFrequency;
  final DateTime? firstOrderDate;
  final DateTime? lastOrderDate;
  final DateTime? createdAt;
  final DateTime? lastUpdated;

  UserPatternSettings({
    required this.userId,
    this.enableReminders = true,
    this.reminderTiming = '2_days_before',
    this.orderHistory = const [],
    this.totalOrders = 0,
    this.overallFrequency = 0.0,
    this.firstOrderDate,
    this.lastOrderDate,
    this.createdAt,
    this.lastUpdated,
  });

  // Available reminder timing options
  static const List<String> reminderTimingOptions = [
    '1_day_before',
    '2_days_before',
    '3_days_before',
    'on_date',
  ];

  // Get reminder timing display text
  String get reminderTimingText {
    switch (reminderTiming) {
      case '1_day_before':
        return 'One day before';
      case '2_days_before':
        return 'Two days before';
      case '3_days_before':
        return 'Three days before';
      case 'on_date':
        return 'On predicted date';
      default:
        return 'Two days before';
    }
  }

  // Calculate user's ordering frequency category
  String get frequencyCategory {
    if (overallFrequency <= 0) return 'Unknown';
    if (overallFrequency <= 7) return 'Weekly Shopper';
    if (overallFrequency <= 14) return 'Bi-weekly Shopper';
    if (overallFrequency <= 30) return 'Monthly Shopper';
    if (overallFrequency <= 90) return 'Seasonal Shopper';
    return 'Occasional Shopper';
  }

  // Check if user has enough data for patterns
  bool get hasEnoughOrderHistory => totalOrders >= 3;

  // Get days since last order
  int? get daysSinceLastOrder {
    if (lastOrderDate == null) return null;
    return DateTime.now().difference(lastOrderDate!).inDays;
  }

  // Create from Firestore document
  factory UserPatternSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse order history timestamps
    final orderHistoryData = data['orderHistory'] as List<dynamic>? ?? [];
    final orderHistory = orderHistoryData
        .map((timestamp) => (timestamp as Timestamp).toDate())
        .toList();

    return UserPatternSettings(
      userId: data['userId'] ?? '',
      enableReminders: data['enableReminders'] ?? true,
      reminderTiming: data['reminderTiming'] ?? '2_days_before',
      orderHistory: orderHistory,
      totalOrders: data['totalOrders'] ?? 0,
      overallFrequency: (data['overallFrequency'] ?? 0.0).toDouble(),
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
      'enableReminders': enableReminders,
      'reminderTiming': reminderTiming,
      'orderHistory': orderHistory.map((date) => Timestamp.fromDate(date)).toList(),
      'totalOrders': totalOrders,
      'overallFrequency': overallFrequency,
      'firstOrderDate': firstOrderDate != null ? Timestamp.fromDate(firstOrderDate!) : null,
      'lastOrderDate': lastOrderDate != null ? Timestamp.fromDate(lastOrderDate!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Copy with new values
  UserPatternSettings copyWith({
    String? userId,
    bool? enableReminders,
    String? reminderTiming,
    List<DateTime>? orderHistory,
    int? totalOrders,
    double? overallFrequency,
    DateTime? firstOrderDate,
    DateTime? lastOrderDate,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserPatternSettings(
      userId: userId ?? this.userId,
      enableReminders: enableReminders ?? this.enableReminders,
      reminderTiming: reminderTiming ?? this.reminderTiming,
      orderHistory: orderHistory ?? this.orderHistory,
      totalOrders: totalOrders ?? this.totalOrders,
      overallFrequency: overallFrequency ?? this.overallFrequency,
      firstOrderDate: firstOrderDate ?? this.firstOrderDate,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'UserPatternSettings(userId: $userId, enableReminders: $enableReminders, frequency: $overallFrequency)';
  }
}

// Reminder response tracking
class ReminderResponse {
  final String userId;
  final String productId;
  final DateTime reminderSentDate;
  final String action; // 'ordered', 'dismissed', 'snoozed', 'ignored'
  final DateTime? responseDate;
  final Map<String, dynamic>? metadata;

  ReminderResponse({
    required this.userId,
    required this.productId,
    required this.reminderSentDate,
    required this.action,
    this.responseDate,
    this.metadata,
  });

  // Create from Firestore document
  factory ReminderResponse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReminderResponse(
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      reminderSentDate: (data['reminderSentDate'] as Timestamp).toDate(),
      action: data['action'] ?? 'ignored',
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'reminderSentDate': Timestamp.fromDate(reminderSentDate),
      'action': action,
      'responseDate': responseDate != null ? Timestamp.fromDate(responseDate!) : null,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() {
    return 'ReminderResponse(userId: $userId, productId: $productId, action: $action)';
  }
}