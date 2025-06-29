// File Location: lib/services/pattern_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/models/customer_pattern.dart';
import 'package:bubbles_ecommerce_app/models/reorder_prediction.dart';
import 'package:bubbles_ecommerce_app/models/user_pattern_settings.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';

class PatternService {
  static final PatternService _instance = PatternService._internal();
  factory PatternService() => _instance;
  PatternService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // PATTERN TRACKING (Called from orders)
  // ==========================================

  /// Track a new order for pattern analysis
  Future<void> trackOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required DateTime orderDate,
  }) async {
    try {
      debugPrint('🧠 Tracking order patterns for user: $userId');

      // Process each item in the order
      for (final item in items) {
        final String? productId = item['productId'];
        final int? quantity = item['quantity'];

        if (productId != null && quantity != null) {
          await _updateProductPattern(userId, productId, orderDate, quantity);
        }
      }

      // Update user's overall ordering pattern
      await _updateUserOverallPattern(userId, orderDate);

      debugPrint('✅ Pattern tracking completed for user: $userId');
    } catch (e) {
      debugPrint('❌ Error tracking order patterns: $e');
    }
  }

  /// Update pattern for a specific product
  Future<void> _updateProductPattern(
      String userId,
      String productId,
      DateTime orderDate,
      int quantity,
      ) async {
    try {
      final patternId = '${userId}_$productId';
      final patternRef = _firestore.collection('customer_patterns').doc(patternId);
      final patternDoc = await patternRef.get();

      if (patternDoc.exists) {
        // Update existing pattern
        final existingPattern = CustomerPattern.fromFirestore(patternDoc);
        final updatedPattern = _addOrderToPattern(existingPattern, orderDate, quantity);

        await patternRef.set(updatedPattern.toFirestore());
        debugPrint('✅ Updated pattern for product: $productId');
      } else {
        // Create new pattern
        final newPattern = _createNewPattern(userId, productId, orderDate, quantity);
        await patternRef.set(newPattern.toFirestore());
        debugPrint('✅ Created new pattern for product: $productId');
      }
    } catch (e) {
      debugPrint('❌ Error updating product pattern: $e');
    }
  }

  /// Add new order to existing pattern
  CustomerPattern _addOrderToPattern(
      CustomerPattern existingPattern,
      DateTime orderDate,
      int quantity,
      ) {
    // Calculate days since last order
    final lastOrder = existingPattern.orderHistory.isNotEmpty
        ? existingPattern.orderHistory.last
        : null;

    final daysSinceLastOrder = lastOrder != null
        ? orderDate.difference(lastOrder.orderDate).inDays
        : 0;

    // Add new order to history
    final newOrderEntry = OrderEntry(
      orderDate: orderDate,
      quantity: quantity,
      daysSinceLastOrder: daysSinceLastOrder,
    );

    final updatedHistory = List<OrderEntry>.from(existingPattern.orderHistory)
      ..add(newOrderEntry);

    // Keep only last 10 orders for performance
    if (updatedHistory.length > 10) {
      updatedHistory.removeRange(0, updatedHistory.length - 10);
    }

    // Recalculate averages
    final avgDaysBetween = _calculateAverageFrequency(updatedHistory);
    final avgQuantity = _calculateAverageQuantity(updatedHistory);
    final confidence = _calculateConfidence(updatedHistory);

    return existingPattern.copyWith(
      orderHistory: updatedHistory,
      orderCount: existingPattern.orderCount + 1,
      avgDaysBetweenOrders: avgDaysBetween,
      avgQuantityPerOrder: avgQuantity,
      confidence: confidence,
      lastOrderDate: orderDate,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create new pattern for first-time product order
  CustomerPattern _createNewPattern(
      String userId,
      String productId,
      DateTime orderDate,
      int quantity,
      ) {
    final orderEntry = OrderEntry(
      orderDate: orderDate,
      quantity: quantity,
      daysSinceLastOrder: 0,
    );

    return CustomerPattern(
      userId: userId,
      productId: productId,
      orderHistory: [orderEntry],
      orderCount: 1,
      avgDaysBetweenOrders: 0.0,
      avgQuantityPerOrder: quantity.toDouble(),
      confidence: 0.1, // Very low confidence with only 1 order
      firstOrderDate: orderDate,
      lastOrderDate: orderDate,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Update user's overall ordering pattern
  Future<void> _updateUserOverallPattern(String userId, DateTime orderDate) async {
    try {
      final userSettingsRef = _firestore.collection('user_pattern_settings').doc(userId);
      final userSettingsDoc = await userSettingsRef.get();

      if (userSettingsDoc.exists) {
        final existingSettings = UserPatternSettings.fromFirestore(userSettingsDoc);
        final updatedHistory = List<DateTime>.from(existingSettings.orderHistory)
          ..add(orderDate);

        // Keep only last 10 orders
        if (updatedHistory.length > 10) {
          updatedHistory.removeRange(0, updatedHistory.length - 10);
        }

        final overallFrequency = _calculateOverallFrequency(updatedHistory);

        final updatedSettings = existingSettings.copyWith(
          orderHistory: updatedHistory,
          totalOrders: existingSettings.totalOrders + 1,
          overallFrequency: overallFrequency,
          lastOrderDate: orderDate,
          lastUpdated: DateTime.now(),
        );

        await userSettingsRef.set(updatedSettings.toFirestore());
      } else {
        // Create new user settings
        final newSettings = UserPatternSettings(
          userId: userId,
          enableReminders: true, // Default enabled
          reminderTiming: '2_days_before',
          orderHistory: [orderDate],
          totalOrders: 1,
          overallFrequency: 0.0,
          firstOrderDate: orderDate,
          lastOrderDate: orderDate,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        await userSettingsRef.set(newSettings.toFirestore());
      }

      debugPrint('✅ Updated user overall pattern: $userId');
    } catch (e) {
      debugPrint('❌ Error updating user overall pattern: $e');
    }
  }

  // ==========================================
  // MANUAL PATTERN PROCESSING
  // ==========================================

  /// Process all patterns for all users (Admin function)
  Future<Map<String, dynamic>> processAllPatterns() async {
    try {
      debugPrint('🔄 Processing all customer patterns...');

      int patternsProcessed = 0;
      int predictionsGenerated = 0;

      // Get all customer patterns
      final patternsSnapshot = await _firestore.collection('customer_patterns').get();

      // Group patterns by user
      final Map<String, List<CustomerPattern>> userPatterns = {};

      for (final doc in patternsSnapshot.docs) {
        final pattern = CustomerPattern.fromFirestore(doc);
        if (!userPatterns.containsKey(pattern.userId)) {
          userPatterns[pattern.userId] = [];
        }
        userPatterns[pattern.userId]!.add(pattern);
        patternsProcessed++;
      }

      // Generate predictions for each user
      for (final userId in userPatterns.keys) {
        final patterns = userPatterns[userId]!;
        final predictions = await _generatePredictionsForUser(userId, patterns);

        if (predictions.isNotEmpty) {
          await _storePredictions(userId, predictions);
          predictionsGenerated += predictions.length;
        }
      }

      debugPrint('✅ Pattern processing completed');

      return {
        'success': true,
        'patternsProcessed': patternsProcessed,
        'predictionsGenerated': predictionsGenerated,
        'usersProcessed': userPatterns.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error processing patterns: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Generate predictions for a specific user
  Future<List<ReorderPrediction>> _generatePredictionsForUser(
      String userId,
      List<CustomerPattern> patterns,
      ) async {
    final predictions = <ReorderPrediction>[];

    try {
      for (final pattern in patterns) {
        // Only generate predictions for patterns with enough data
        if (pattern.hasEnoughData && pattern.confidence >= 0.3) {
          // Get product details
          final productDoc = await _firestore.collection('products').doc(pattern.productId).get();

          if (productDoc.exists) {
            final product = Product.fromFirestore(productDoc);
            final prediction = _calculatePrediction(pattern, product);
            predictions.add(prediction);
          }
        }
      }

      // Sort predictions by urgency (soonest first)
      predictions.sort((a, b) => a.daysUntilNextOrder.compareTo(b.daysUntilNextOrder));

    } catch (e) {
      debugPrint('❌ Error generating predictions for user $userId: $e');
    }

    return predictions;
  }

  /// Calculate prediction from pattern
  ReorderPrediction _calculatePrediction(CustomerPattern pattern, Product product) {
    final avgDays = pattern.avgDaysBetweenOrders;
    final lastOrderDate = pattern.lastOrderDate!;

    // Predict next order date
    final predictedDate = lastOrderDate.add(Duration(days: avgDays.round()));
    final daysUntil = predictedDate.difference(DateTime.now()).inDays;

    return ReorderPrediction(
      productId: pattern.productId,
      productName: product.name,
      avgDaysBetween: avgDays,
      avgQuantity: pattern.avgQuantityPerOrder.round(),
      confidence: pattern.confidence,
      lastOrderDate: lastOrderDate,
      predictedNextOrder: predictedDate,
      daysUntilNextOrder: daysUntil,
      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
    );
  }

  /// Store predictions for a user
  Future<void> _storePredictions(String userId, List<ReorderPrediction> predictions) async {
    try {
      final userPredictions = UserReorderPredictions(
        userId: userId,
        predictions: predictions,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection('reorder_predictions')
          .doc(userId)
          .set(userPredictions.toFirestore());

      debugPrint('✅ Stored ${predictions.length} predictions for user: $userId');
    } catch (e) {
      debugPrint('❌ Error storing predictions: $e');
    }
  }

  // ==========================================
  // REMINDER MANAGEMENT
  // ==========================================

  /// Find all users who need reorder reminders
  Future<List<Map<String, dynamic>>> findUsersNeedingReminders() async {
    try {
      debugPrint('🔍 Finding users who need reorder reminders...');

      final remindersNeeded = <Map<String, dynamic>>[];

      // Get users with reminders enabled
      final userSettingsSnapshot = await _firestore
          .collection('user_pattern_settings')
          .where('enableReminders', isEqualTo: true)
          .get();

      for (final userDoc in userSettingsSnapshot.docs) {
        final userSettings = UserPatternSettings.fromFirestore(userDoc);

        // Get user's predictions
        final predictionsDoc = await _firestore
            .collection('reorder_predictions')
            .doc(userSettings.userId)
            .get();

        if (predictionsDoc.exists) {
          final userPredictions = UserReorderPredictions.fromFirestore(predictionsDoc);

          // Find predictions that need reminders
          for (final prediction in userPredictions.predictions) {
            if (_shouldSendReminder(prediction, userSettings.reminderTiming)) {
              remindersNeeded.add({
                'userId': userSettings.userId,
                'prediction': prediction,
                'userSettings': userSettings,
              });
            }
          }
        }
      }

      debugPrint('✅ Found ${remindersNeeded.length} reminders needed');
      return remindersNeeded;
    } catch (e) {
      debugPrint('❌ Error finding users needing reminders: $e');
      return [];
    }
  }

  /// Check if reminder should be sent for a prediction
  bool _shouldSendReminder(ReorderPrediction prediction, String reminderTiming) {
    final daysUntil = prediction.daysUntilNextOrder;

    // Don't send if confidence is too low
    if (prediction.confidence < 0.5) return false;

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

  /// Queue reminders for sending (adds to reminder_queue collection)
  Future<int> queueReminders(List<Map<String, dynamic>> remindersToSend) async {
    try {
      debugPrint('📤 Queueing ${remindersToSend.length} reminders...');

      int queuedCount = 0;

      for (final reminderData in remindersToSend) {
        final prediction = reminderData['prediction'] as ReorderPrediction;
        final userId = reminderData['userId'] as String;

        await _firestore.collection('reminder_queue').add({
          'userId': userId,
          'productId': prediction.productId,
          'productName': prediction.productName,
          'predictedQuantity': prediction.avgQuantity,
          'confidence': prediction.confidence,
          'daysUntilNextOrder': prediction.daysUntilNextOrder,
          'reminderType': 'reorder',
          'scheduledDate': FieldValue.serverTimestamp(),
          'processed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        queuedCount++;
      }

      debugPrint('✅ Queued $queuedCount reminders');
      return queuedCount;
    } catch (e) {
      debugPrint('❌ Error queueing reminders: $e');
      return 0;
    }
  }

  // ==========================================
  // DATA RETRIEVAL
  // ==========================================

  /// Get patterns for a specific user
  Future<List<CustomerPattern>> getUserPatterns(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('customer_patterns')
          .where('userId', isEqualTo: userId)
          .orderBy('lastOrderDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerPattern.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user patterns: $e');
      return [];
    }
  }

  /// Get predictions for a specific user
  Future<UserReorderPredictions?> getUserPredictions(String userId) async {
    try {
      final doc = await _firestore
          .collection('reorder_predictions')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserReorderPredictions.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user predictions: $e');
      return null;
    }
  }

  /// Get user pattern settings
  Future<UserPatternSettings?> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('user_pattern_settings')
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserPatternSettings.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user settings: $e');
      return null;
    }
  }

  /// Update user pattern settings
  Future<bool> updateUserSettings(UserPatternSettings settings) async {
    try {
      await _firestore
          .collection('user_pattern_settings')
          .doc(settings.userId)
          .set(settings.toFirestore());

      debugPrint('✅ Updated user settings for: ${settings.userId}');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating user settings: $e');
      return false;
    }
  }

  // ==========================================
  // ANALYTICS
  // ==========================================

  /// Get pattern analytics for admin dashboard
  Future<Map<String, dynamic>> getPatternAnalytics() async {
    try {
      // Get all patterns
      final patternsSnapshot = await _firestore.collection('customer_patterns').get();
      final patterns = patternsSnapshot.docs
          .map((doc) => CustomerPattern.fromFirestore(doc))
          .toList();

      // Get all predictions
      final predictionsSnapshot = await _firestore.collection('reorder_predictions').get();
      int totalPredictions = 0;
      int highConfidencePredictions = 0;

      for (final doc in predictionsSnapshot.docs) {
        final userPredictions = UserReorderPredictions.fromFirestore(doc);
        totalPredictions += userPredictions.predictions.length;
        highConfidencePredictions += userPredictions.predictions
            .where((p) => p.confidence >= 0.8)
            .length;
      }

      // Calculate statistics
      final totalPatterns = patterns.length;
      final reliablePatterns = patterns.where((p) => p.isReliable).length;
      final avgConfidence = patterns.isNotEmpty
          ? patterns.map((p) => p.confidence).reduce((a, b) => a + b) / patterns.length
          : 0.0;

      // Get unique users with patterns
      final uniqueUsers = patterns.map((p) => p.userId).toSet().length;

      return {
        'totalPatterns': totalPatterns,
        'reliablePatterns': reliablePatterns,
        'totalPredictions': totalPredictions,
        'highConfidencePredictions': highConfidencePredictions,
        'uniqueUsers': uniqueUsers,
        'avgConfidence': avgConfidence,
        'reliabilityRate': totalPatterns > 0 ? (reliablePatterns / totalPatterns) * 100 : 0,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting pattern analytics: $e');
      return {
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // ==========================================
  // CALCULATION HELPERS
  // ==========================================

  /// Calculate average frequency between orders
  double _calculateAverageFrequency(List<OrderEntry> orderHistory) {
    if (orderHistory.length < 2) return 0.0;

    final intervals = orderHistory
        .skip(1) // Skip first order (daysSinceLastOrder = 0)
        .map((order) => order.daysSinceLastOrder)
        .where((days) => days > 0)
        .toList();

    if (intervals.isEmpty) return 0.0;

    return intervals.reduce((a, b) => a + b) / intervals.length;
  }

  /// Calculate average quantity per order
  double _calculateAverageQuantity(List<OrderEntry> orderHistory) {
    if (orderHistory.isEmpty) return 0.0;

    final totalQuantity = orderHistory
        .map((order) => order.quantity)
        .reduce((a, b) => a + b);

    return totalQuantity / orderHistory.length;
  }

  /// Calculate confidence score based on order count and consistency
  double _calculateConfidence(List<OrderEntry> orderHistory) {
    final orderCount = orderHistory.length;

    if (orderCount < 2) return 0.1;
    if (orderCount < 3) return 0.4;
    if (orderCount < 5) return 0.6;
    if (orderCount < 8) return 0.8;

    return 0.9;
  }

  /// Calculate overall ordering frequency for user
  double _calculateOverallFrequency(List<DateTime> orderHistory) {
    if (orderHistory.length < 2) return 0.0;

    final intervals = <int>[];
    for (int i = 1; i < orderHistory.length; i++) {
      final days = orderHistory[i].difference(orderHistory[i - 1]).inDays;
      if (days > 0) intervals.add(days);
    }

    if (intervals.isEmpty) return 0.0;

    return intervals.reduce((a, b) => a + b) / intervals.length;
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Track reminder response
  Future<void> trackReminderResponse({
    required String userId,
    required String productId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = ReminderResponse(
        userId: userId,
        productId: productId,
        reminderSentDate: DateTime.now(),
        action: action,
        responseDate: DateTime.now(),
        metadata: metadata,
      );

      await _firestore
          .collection('reminder_responses')
          .add(response.toFirestore());

      debugPrint('✅ Tracked reminder response: $action for $productId');
    } catch (e) {
      debugPrint('❌ Error tracking reminder response: $e');
    }
  }

  /// Clear old data (cleanup function)
  Future<void> cleanupOldData({int retentionDays = 365}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));

      // Clean up old patterns
      final oldPatterns = await _firestore
          .collection('customer_patterns')
          .where('lastOrderDate', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in oldPatterns.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Cleaned up ${oldPatterns.docs.length} old patterns');
    } catch (e) {
      debugPrint('❌ Error cleaning up old data: $e');
    }
  }
  Future<Map<String, dynamic>> getCustomerBehaviorAnalytics() async {
    try {
      debugPrint('📊 Getting customer behavior analytics...');

      // Get all patterns
      final patternsSnapshot = await _firestore.collection('customer_patterns').get();
      final patterns = patternsSnapshot.docs
          .map((doc) => CustomerPattern.fromFirestore(doc))
          .toList();

      // Get all user settings
      final settingsSnapshot = await _firestore.collection('user_pattern_settings').get();
      final userSettings = settingsSnapshot.docs
          .map((doc) => UserPatternSettings.fromFirestore(doc))
          .toList();

      // Calculate customer segments
      final customerSegments = _analyzeCustomerSegments(patterns, userSettings);

      // Calculate product popularity
      final productAnalytics = _analyzeProductPatterns(patterns);

      // Calculate retention metrics
      final retentionMetrics = _calculateRetentionMetrics(patterns);

      return {
        'customerSegments': customerSegments,
        'productAnalytics': productAnalytics,
        'retentionMetrics': retentionMetrics,
        'totalCustomers': userSettings.length,
        'activePatterns': patterns.where((p) => p.confidence >= 0.3).length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting customer behavior analytics: $e');
      return {'error': e.toString()};
    }
  }

  /// Analyze customer segments based on behavior patterns
  Map<String, dynamic> _analyzeCustomerSegments(
      List<CustomerPattern> patterns,
      List<UserPatternSettings> userSettings) {

    final userPatternCounts = <String, int>{};
    final userConfidenceScores = <String, List<double>>{};
    final userFrequencies = <String, List<double>>{};

    // Group patterns by user
    for (final pattern in patterns) {
      final userId = pattern.userId;
      userPatternCounts[userId] = (userPatternCounts[userId] ?? 0) + 1;
      userConfidenceScores[userId] = (userConfidenceScores[userId] ?? [])
        ..add(pattern.confidence);
      userFrequencies[userId] = (userFrequencies[userId] ?? [])
        ..add(pattern.avgDaysBetweenOrders);
    }

    // Categorize customers
    int highValueCustomers = 0;
    int regularCustomers = 0;
    int occasionalCustomers = 0;
    int newCustomers = 0;

    for (final userId in userPatternCounts.keys) {
      final patternCount = userPatternCounts[userId] ?? 0;
      final avgConfidence = userConfidenceScores[userId]?.isNotEmpty == true
          ? userConfidenceScores[userId]!.reduce((a, b) => a + b) / userConfidenceScores[userId]!.length
          : 0.0;
      final avgFrequency = userFrequencies[userId]?.isNotEmpty == true
          ? userFrequencies[userId]!.reduce((a, b) => a + b) / userFrequencies[userId]!.length
          : 0.0;

      if (patternCount >= 5 && avgConfidence >= 0.7) {
        highValueCustomers++;
      } else if (patternCount >= 3 && avgConfidence >= 0.5) {
        regularCustomers++;
      } else if (patternCount >= 2) {
        occasionalCustomers++;
      } else {
        newCustomers++;
      }
    }

    return {
      'highValue': highValueCustomers,
      'regular': regularCustomers,
      'occasional': occasionalCustomers,
      'new': newCustomers,
      'segments': [
        {'name': 'High Value', 'count': highValueCustomers, 'color': 'green'},
        {'name': 'Regular', 'count': regularCustomers, 'color': 'blue'},
        {'name': 'Occasional', 'count': occasionalCustomers, 'color': 'orange'},
        {'name': 'New', 'count': newCustomers, 'color': 'grey'},
      ],
    };
  }

  /// Analyze product pattern performance
  Map<String, dynamic> _analyzeProductPatterns(List<CustomerPattern> patterns) {
    final productStats = <String, Map<String, dynamic>>{};

    for (final pattern in patterns) {
      final productId = pattern.productId;

      if (!productStats.containsKey(productId)) {
        productStats[productId] = {
          'totalPatterns': 0,
          'avgConfidence': 0.0,
          'avgFrequency': 0.0,
          'totalOrders': 0,
          'confidenceScores': <double>[],
          'frequencies': <double>[],
        };
      }

      productStats[productId]!['totalPatterns'] =
          (productStats[productId]!['totalPatterns'] as int) + 1;
      productStats[productId]!['totalOrders'] =
          (productStats[productId]!['totalOrders'] as int) + pattern.orderCount;

      (productStats[productId]!['confidenceScores'] as List<double>).add(pattern.confidence);
      (productStats[productId]!['frequencies'] as List<double>).add(pattern.avgDaysBetweenOrders);
    }

    // Calculate averages and sort by performance
    final productPerformance = <Map<String, dynamic>>[];

    for (final entry in productStats.entries) {
      final productId = entry.key;
      final stats = entry.value;

      final confidenceScores = stats['confidenceScores'] as List<double>;
      final frequencies = stats['frequencies'] as List<double>;

      final avgConfidence = confidenceScores.isNotEmpty
          ? confidenceScores.reduce((a, b) => a + b) / confidenceScores.length
          : 0.0;

      final avgFrequency = frequencies.isNotEmpty
          ? frequencies.reduce((a, b) => a + b) / frequencies.length
          : 0.0;

      productPerformance.add({
        'productId': productId,
        'totalPatterns': stats['totalPatterns'],
        'avgConfidence': avgConfidence,
        'avgFrequency': avgFrequency,
        'totalOrders': stats['totalOrders'],
        'score': avgConfidence * (stats['totalPatterns'] as int), // Performance score
      });
    }

    // Sort by performance score
    productPerformance.sort((a, b) =>
        (b['score'] as double).compareTo(a['score'] as double));

    return {
      'topProducts': productPerformance.take(10).toList(),
      'totalProducts': productPerformance.length,
      'avgProductConfidence': productPerformance.isNotEmpty
          ? productPerformance.map((p) => p['avgConfidence'] as double).reduce((a, b) => a + b) / productPerformance.length
          : 0.0,
    };
  }

  /// Calculate customer retention metrics
  Map<String, dynamic> _calculateRetentionMetrics(List<CustomerPattern> patterns) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));

    int activeLastMonth = 0;
    int activeLastTwoMonths = 0;
    int totalWithRecentActivity = 0;

    final userLastActivity = <String, DateTime>{};

    // Find last activity for each user
    for (final pattern in patterns) {
      final userId = pattern.userId;
      final lastOrder = pattern.lastOrderDate;

      if (lastOrder != null) {
        if (!userLastActivity.containsKey(userId) ||
            lastOrder.isAfter(userLastActivity[userId]!)) {
          userLastActivity[userId] = lastOrder;
        }
      }
    }

    // Calculate retention metrics
    for (final lastActivity in userLastActivity.values) {
      totalWithRecentActivity++;

      if (lastActivity.isAfter(thirtyDaysAgo)) {
        activeLastMonth++;
      }

      if (lastActivity.isAfter(sixtyDaysAgo)) {
        activeLastTwoMonths++;
      }
    }

    final monthlyRetention = totalWithRecentActivity > 0
        ? (activeLastMonth / totalWithRecentActivity) * 100
        : 0.0;

    final twoMonthRetention = totalWithRecentActivity > 0
        ? (activeLastTwoMonths / totalWithRecentActivity) * 100
        : 0.0;

    return {
      'activeLastMonth': activeLastMonth,
      'activeLastTwoMonths': activeLastTwoMonths,
      'totalTrackedUsers': totalWithRecentActivity,
      'monthlyRetentionRate': monthlyRetention,
      'twoMonthRetentionRate': twoMonthRetention,
      'churnRate': 100 - monthlyRetention,
    };
  }

  /// Get prediction accuracy metrics
  Future<Map<String, dynamic>> getPredictionAccuracyMetrics() async {
    try {
      // Get all predictions
      final predictionsSnapshot = await _firestore.collection('reorder_predictions').get();

      // Get reminder responses for accuracy calculation
      final responsesSnapshot = await _firestore.collection('reminder_responses').get();

      int totalPredictions = 0;
      int accuratePredictions = 0;

      for (final doc in predictionsSnapshot.docs) {
        final data = doc.data();
        final predictions = data['predictions'] as List<dynamic>? ?? [];
        totalPredictions += predictions.length;

        // This is a simplified accuracy calculation
        // In a real system, you'd track actual vs predicted reorder dates
        for (final prediction in predictions) {
          final confidence = (prediction['confidence'] ?? 0.0) as double;
          if (confidence >= 0.7) {
            accuratePredictions++;
          }
        }
      }

      final accuracy = totalPredictions > 0
          ? (accuratePredictions / totalPredictions) * 100
          : 0.0;

      return {
        'totalPredictions': totalPredictions,
        'accuratePredictions': accuratePredictions,
        'accuracyPercentage': accuracy,
        'totalResponses': responsesSnapshot.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error calculating prediction accuracy: $e');
      return {'error': e.toString()};
    }
  }

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealthMetrics() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));

      // Check recent pattern updates
      final recentPatterns = await _firestore
          .collection('customer_patterns')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      // Check recent predictions
      final recentPredictions = await _firestore
          .collection('reorder_predictions')
          .where('lastUpdated', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      // Check system errors (if you have an errors collection)
      final recentErrors = await _firestore
          .collection('system_errors')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      // Calculate health score
      int healthScore = 100;

      if (recentPatterns.docs.isEmpty) healthScore -= 20;
      if (recentPredictions.docs.isEmpty) healthScore -= 15;
      if (recentErrors.docs.length > 5) healthScore -= 30;

      String healthStatus = 'Excellent';
      if (healthScore < 70) healthStatus = 'Poor';
      else if (healthScore < 85) healthStatus = 'Good';

      return {
        'healthScore': healthScore,
        'healthStatus': healthStatus,
        'recentPatternUpdates': recentPatterns.docs.length,
        'recentPredictions': recentPredictions.docs.length,
        'recentErrors': recentErrors.docs.length,
        'lastChecked': now.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting system health metrics: $e');
      return {
        'healthScore': 0,
        'healthStatus': 'Error',
        'error': e.toString(),
      };
    }
  }
}