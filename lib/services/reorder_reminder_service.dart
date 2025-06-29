// File Location: lib/services/reorder_reminder_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';
import 'package:bubbles_ecommerce_app/services/customer_notification_service.dart';
import 'package:bubbles_ecommerce_app/models/reorder_prediction.dart';
import 'package:bubbles_ecommerce_app/models/user_pattern_settings.dart';

class ReorderReminderService {
  static final ReorderReminderService _instance = ReorderReminderService._internal();
  factory ReorderReminderService() => _instance;
  ReorderReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PatternService _patternService = PatternService();
  final CustomerNotificationService _notificationService = CustomerNotificationService();

  Timer? _reminderTimer;
  bool _isInitialized = false;

  // ==========================================
  // INITIALIZATION & SCHEDULING
  // ==========================================

  /// Initialize the reminder service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Initializing Reorder Reminder Service...');

      // Initialize notification service
      await _notificationService.initialize();

      // Start daily reminder checks (every 24 hours)
      _startDailyReminderChecks();

      _isInitialized = true;
      debugPrint('✅ Reorder Reminder Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Reorder Reminder Service: $e');
    }
  }

  /// Start daily checks for users who need reminders
  void _startDailyReminderChecks() {
    // Cancel existing timer
    _reminderTimer?.cancel();

    // Check every 24 hours (you can adjust this for testing - e.g., Duration(minutes: 1))
    _reminderTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _checkAndSendReminders();
    });

    // Also run initial check
    _checkAndSendReminders();

    debugPrint('⏰ Daily reminder checks started');
  }

  /// Stop the reminder service
  void dispose() {
    _reminderTimer?.cancel();
    _isInitialized = false;
    debugPrint('🛑 Reorder Reminder Service stopped');
  }

  // ==========================================
  // REMINDER CHECKING & SENDING
  // ==========================================

  /// Check all users and send reminders if needed
  Future<void> _checkAndSendReminders() async {
    try {
      debugPrint('🔍 === CHECKING FOR REORDER REMINDERS ===');

      // Get all users with reminders enabled
      final usersWithReminders = await _getUsersWithRemindersEnabled();
      debugPrint('👥 Found ${usersWithReminders.length} users with reminders enabled');

      int remindersSent = 0;

      for (final userSettings in usersWithReminders) {
        try {
          final userReminders = await _checkUserReminders(userSettings);
          remindersSent += userReminders;
        } catch (e) {
          debugPrint('❌ Error checking reminders for user ${userSettings.userId}: $e');
        }
      }

      debugPrint('📤 Sent $remindersSent reorder reminders total');
      debugPrint('🔍 === END REMINDER CHECK ===');

    } catch (e) {
      debugPrint('❌ Error in reminder check cycle: $e');
    }
  }

  /// Get all users who have reminders enabled
  Future<List<UserPatternSettings>> _getUsersWithRemindersEnabled() async {
    try {
      final snapshot = await _firestore
          .collection('user_pattern_settings')
          .where('enableReminders', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserPatternSettings.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting users with reminders: $e');
      return [];
    }
  }

  /// Check and send reminders for a specific user
  Future<int> _checkUserReminders(UserPatternSettings userSettings) async {
    try {
      debugPrint('🔍 Checking reminders for user: ${userSettings.userId}');

      // Get user's predictions
      final userPredictions = await _patternService.getUserPredictions(userSettings.userId);
      if (userPredictions == null || userPredictions.predictions.isEmpty) {
        debugPrint('📭 No predictions found for user ${userSettings.userId}');
        return 0;
      }

      // Find predictions that need reminders
      final remindersToSend = <ReorderPrediction>[];

      for (final prediction in userPredictions.predictions) {
        if (_shouldSendReminder(prediction, userSettings.reminderTiming)) {
          // Check if we haven't sent this reminder recently
          if (await _shouldSendReminderForProduct(userSettings.userId, prediction.productId)) {
            remindersToSend.add(prediction);
          }
        }
      }

      debugPrint('📨 Found ${remindersToSend.length} reminders to send for user ${userSettings.userId}');

      // Send reminders
      int sent = 0;
      for (final prediction in remindersToSend) {
        if (await _sendReorderReminder(userSettings, prediction)) {
          sent++;
        }
      }

      return sent;
    } catch (e) {
      debugPrint('❌ Error checking user reminders: $e');
      return 0;
    }
  }

  /// Check if reminder should be sent for a prediction
  bool _shouldSendReminder(ReorderPrediction prediction, String reminderTiming) {
    final daysUntil = prediction.daysUntilNextOrder;

    // Don't send if confidence is too low
    if (prediction.confidence < 0.3) return false;

    switch (reminderTiming) {
      case '1_day_before':
        return daysUntil <= 1 && daysUntil >= -1; // Allow 1 day after too
      case '2_days_before':
        return daysUntil <= 2 && daysUntil >= -1;
      case '3_days_before':
        return daysUntil <= 3 && daysUntil >= -1;
      case 'on_date':
        return daysUntil <= 0 && daysUntil >= -2;
      default:
        return daysUntil <= 2 && daysUntil >= -1;
    }
  }

  /// Check if we should send reminder for this product (avoid spam)
  Future<bool> _shouldSendReminderForProduct(String userId, String productId) async {
    try {
      // Check if we sent a reminder for this product in the last 7 days
      final recentReminders = await _firestore
          .collection('reminder_history')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('sentAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7))
      ))
          .get();

      return recentReminders.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking reminder history: $e');
      return true; // Default to sending if we can't check
    }
  }

  // ==========================================
  // REMINDER SENDING & TRACKING
  // ==========================================

  /// Send a reorder reminder notification
  Future<bool> _sendReorderReminder(UserPatternSettings userSettings, ReorderPrediction prediction) async {
    try {
      debugPrint('📨 Sending reorder reminder for ${prediction.productName}');

      // Generate personalized message
      final message = _generateReminderMessage(prediction, userSettings);

      // Send local notification
      await _notificationService.sendReorderReminder(
        userId: userSettings.userId,
        productName: prediction.productName,
        message: message,
        productId: prediction.productId,
      );

      // Track reminder sent
      await _trackReminderSent(userSettings.userId, prediction);

      debugPrint('✅ Reorder reminder sent for ${prediction.productName}');
      return true;

    } catch (e) {
      debugPrint('❌ Error sending reorder reminder: $e');
      return false;
    }
  }

  /// Generate personalized reminder message
  String _generateReminderMessage(ReorderPrediction prediction, UserPatternSettings userSettings) {
    final productName = prediction.productName;
    final daysUntil = prediction.daysUntilNextOrder;
    final confidence = (prediction.confidence * 100).round();

    // Personalized messages based on urgency and confidence
    if (daysUntil <= 0) {
      if (confidence >= 80) {
        return "🎯 Time to reorder $productName! Based on your pattern, you usually need this every ${prediction.avgDaysBetween.round()} days.";
      } else {
        return "⏰ Consider reordering $productName. You might be running low soon.";
      }
    } else if (daysUntil == 1) {
      return "📅 Tomorrow you'll likely need to reorder $productName. Want to add ${prediction.avgQuantity} to your basket?";
    } else {
      return "🔔 Reminder: You'll probably need $productName in $daysUntil days. Plan ahead and save time!";
    }
  }

  /// Track that reminder was sent
  Future<void> _trackReminderSent(String userId, ReorderPrediction prediction) async {
    try {
      await _firestore.collection('reminder_history').add({
        'userId': userId,
        'productId': prediction.productId,
        'productName': prediction.productName,
        'sentAt': FieldValue.serverTimestamp(),
        'daysUntilReorder': prediction.daysUntilNextOrder,
        'confidence': prediction.confidence,
        'predictedQuantity': prediction.avgQuantity,
      });
    } catch (e) {
      debugPrint('❌ Error tracking reminder: $e');
    }
  }

  // ==========================================
  // MANUAL ADMIN FUNCTIONS
  // ==========================================

  /// Manually trigger reminder check (for admin/testing)
  Future<Map<String, dynamic>> triggerReminderCheck() async {
    try {
      debugPrint('🔧 Manual reminder check triggered');

      final startTime = DateTime.now();

      // Get users with reminders
      final usersWithReminders = await _getUsersWithRemindersEnabled();

      int totalReminders = 0;
      int usersProcessed = 0;

      for (final userSettings in usersWithReminders) {
        try {
          final userReminders = await _checkUserReminders(userSettings);
          totalReminders += userReminders;
          usersProcessed++;
        } catch (e) {
          debugPrint('❌ Error processing user ${userSettings.userId}: $e');
        }
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      final result = {
        'success': true,
        'usersChecked': usersWithReminders.length,
        'usersProcessed': usersProcessed,
        'remindersSent': totalReminders,
        'duration': duration.inSeconds,
        'timestamp': endTime.toIso8601String(),
      };

      debugPrint('✅ Manual reminder check completed: $result');
      return result;

    } catch (e) {
      debugPrint('❌ Manual reminder check failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get reminder statistics for admin
  Future<Map<String, dynamic>> getReminderStats() async {
    try {
      // Get recent reminders (last 30 days)
      final recentReminders = await _firestore
          .collection('reminder_history')
          .where('sentAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 30))
      ))
          .get();

      // Get users with reminders enabled
      final usersWithReminders = await _firestore
          .collection('user_pattern_settings')
          .where('enableReminders', isEqualTo: true)
          .get();

      // Calculate stats
      final totalReminders = recentReminders.docs.length;
      final uniqueUsers = recentReminders.docs
          .map((doc) => doc.data()['userId'])
          .toSet()
          .length;

      final stats = {
        'totalRemindersSent30Days': totalReminders,
        'uniqueUsersReminded': uniqueUsers,
        'usersWithRemindersEnabled': usersWithReminders.docs.length,
        'avgRemindersPerUser': uniqueUsers > 0 ? (totalReminders / uniqueUsers).toStringAsFixed(1) : '0',
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting reminder stats: $e');
      return {
        'error': e.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  /// Test reminder for current user (for debugging)
  Future<bool> sendTestReminder() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Send test notification
      await _notificationService.sendReorderReminder(
        userId: currentUser.uid,
        productName: 'Test Product',
        message: '🧪 This is a test reorder reminder. Your ML system is working!',
        productId: 'test_product',
      );

      debugPrint('✅ Test reminder sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Test reminder failed: $e');
      return false;
    }
  }

  /// Check if service is running
  bool get isRunning => _isInitialized && _reminderTimer != null && _reminderTimer!.isActive;
}