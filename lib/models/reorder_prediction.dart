// File Location: lib/models/reorder_prediction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReorderPrediction {
  final String productId;
  final String productName;
  final double avgDaysBetween;
  final int avgQuantity;
  final double confidence;
  final DateTime lastOrderDate;
  final DateTime predictedNextOrder;
  final int daysUntilNextOrder;
  final String imageUrl;

  ReorderPrediction({
    required this.productId,
    required this.productName,
    required this.avgDaysBetween,
    required this.avgQuantity,
    required this.confidence,
    required this.lastOrderDate,
    required this.predictedNextOrder,
    required this.daysUntilNextOrder,
    this.imageUrl = '',
  });

  // Confidence level as string
  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }

  // Urgency level for reminder
  String get urgencyLevel {
    if (daysUntilNextOrder <= 0) return 'Overdue';
    if (daysUntilNextOrder <= 1) return 'Urgent';
    if (daysUntilNextOrder <= 3) return 'Soon';
    if (daysUntilNextOrder <= 7) return 'Upcoming';
    return 'Future';
  }

  // Should this prediction show a reminder?
  bool get shouldShowReminder {
    return confidence >= 0.5 && daysUntilNextOrder <= 3;
  }

  // Is this prediction urgent?
  bool get isUrgent {
    return daysUntilNextOrder <= 1 && confidence >= 0.5;
  }

  // Is this prediction overdue?
  bool get isOverdue {
    return daysUntilNextOrder <= 0 && confidence >= 0.5;
  }

  // Create from map (for Firestore)
  factory ReorderPrediction.fromMap(Map<String, dynamic> map) {
    return ReorderPrediction(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      avgDaysBetween: (map['avgDaysBetween'] ?? 0.0).toDouble(),
      avgQuantity: map['avgQuantity'] ?? 1,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      lastOrderDate: (map['lastOrderDate'] as Timestamp).toDate(),
      predictedNextOrder: (map['predictedNextOrder'] as Timestamp).toDate(),
      daysUntilNextOrder: map['daysUntilNextOrder'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // Convert to map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'avgDaysBetween': avgDaysBetween,
      'avgQuantity': avgQuantity,
      'confidence': confidence,
      'lastOrderDate': Timestamp.fromDate(lastOrderDate),
      'predictedNextOrder': Timestamp.fromDate(predictedNextOrder),
      'daysUntilNextOrder': daysUntilNextOrder,
      'imageUrl': imageUrl,
    };
  }

  // Copy with new values
  ReorderPrediction copyWith({
    String? productId,
    String? productName,
    double? avgDaysBetween,
    int? avgQuantity,
    double? confidence,
    DateTime? lastOrderDate,
    DateTime? predictedNextOrder,
    int? daysUntilNextOrder,
    String? imageUrl,
  }) {
    return ReorderPrediction(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      avgDaysBetween: avgDaysBetween ?? this.avgDaysBetween,
      avgQuantity: avgQuantity ?? this.avgQuantity,
      confidence: confidence ?? this.confidence,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      predictedNextOrder: predictedNextOrder ?? this.predictedNextOrder,
      daysUntilNextOrder: daysUntilNextOrder ?? this.daysUntilNextOrder,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'ReorderPrediction(productName: $productName, daysUntil: $daysUntilNextOrder, confidence: $confidence)';
  }
}

// Container for user's reorder predictions
class UserReorderPredictions {
  final String userId;
  final List<ReorderPrediction> predictions;
  final DateTime lastUpdated;

  UserReorderPredictions({
    required this.userId,
    required this.predictions,
    required this.lastUpdated,
  });

  // Get urgent predictions (need reorder soon)
  List<ReorderPrediction> get urgentPredictions {
    return predictions.where((p) => p.shouldShowReminder).toList()
      ..sort((a, b) => a.daysUntilNextOrder.compareTo(b.daysUntilNextOrder));
  }

  // Get overdue predictions
  List<ReorderPrediction> get overduePredictions {
    return predictions.where((p) => p.isOverdue).toList();
  }

  // Get upcoming predictions (1-7 days)
  List<ReorderPrediction> get upcomingPredictions {
    return predictions
        .where((p) => p.daysUntilNextOrder > 3 && p.daysUntilNextOrder <= 7)
        .toList()
      ..sort((a, b) => a.daysUntilNextOrder.compareTo(b.daysUntilNextOrder));
  }

  // Get high confidence predictions
  List<ReorderPrediction> get highConfidencePredictions {
    return predictions.where((p) => p.confidence >= 0.8).toList();
  }

  // Create from Firestore document
  factory UserReorderPredictions.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final predictionsData = data['predictions'] as List<dynamic>? ?? [];
    final predictions = predictionsData
        .map((item) => ReorderPrediction.fromMap(item as Map<String, dynamic>))
        .toList();

    return UserReorderPredictions(
      userId: data['userId'] ?? '',
      predictions: predictions,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'predictions': predictions.map((p) => p.toMap()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // FIXED: Added missing copyWith method
  UserReorderPredictions copyWith({
    String? userId,
    List<ReorderPrediction>? predictions,
    DateTime? lastUpdated,
  }) {
    return UserReorderPredictions(
      userId: userId ?? this.userId,
      predictions: predictions ?? this.predictions,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'UserReorderPredictions(userId: $userId, predictions: ${predictions.length})';
  }
}