// lib/services/customer_notification_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bubbles_ecommerce_app/main.dart' show navigatorKey;
import 'package:awesome_notifications/awesome_notifications.dart';

class CustomerNotificationService {
  static final CustomerNotificationService _instance = CustomerNotificationService._internal();
  factory CustomerNotificationService() => _instance;
  CustomerNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _lastNotificationTime;

  /// Initialize customer notification service
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing CustomerNotificationService...');

      // Start listening for promotional notifications
      _setupPromotionalNotificationListener();

      debugPrint('✅ CustomerNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing CustomerNotificationService: $e');
    }
  }

  /// Setup listener for promotional notifications
  void _setupPromotionalNotificationListener() {
    debugPrint('🔔 Setting up promotional notification listener...');

    // Get app start time to avoid showing old notifications
    final DateTime appStartTime = DateTime.now();

    // Listen to promotional_notifications collection for new documents
    _firestore
        .collection('promotional_notifications')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(appStartTime))
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (DocumentChange change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notificationData = change.doc.data() as Map<String, dynamic>;
          final notificationTime = (notificationData['createdAt'] as Timestamp?)?.toDate();

          debugPrint('📢 New promotional notification detected: ${change.doc.id}');

          // Check if this notification is truly new
          if (notificationTime != null && notificationTime.isAfter(appStartTime)) {
            // Check rate limiting (no more than 1 notification per minute)
            if (_shouldShowNotification()) {
              _showPromotionalNotification(change.doc.id, notificationData);
              _lastNotificationTime = DateTime.now();
            } else {
              debugPrint('⏳ Rate limited: Skipping notification to prevent spam');
            }
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ Error listening to promotional notifications: $error');
    });
  }

  /// Check if we should show notification (rate limiting)
  bool _shouldShowNotification() {
    if (_lastNotificationTime == null) return true;

    final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime!);
    return timeSinceLastNotification.inMinutes >= 1; // Max 1 notification per minute
  }

  /// Show promotional notification to customer
  Future<void> _showPromotionalNotification(String notificationId, Map<String, dynamic> data) async {
    try {
      final String title = data['title'] ?? 'Special Offer!';
      final String message = data['message'] ?? 'Check out our latest deals!';
      final String targetAudience = data['targetAudience'] ?? 'all_customers';

      debugPrint('📢 Showing promotional notification: $title');

      // Check if this customer should receive this notification
      if (await _shouldReceiveNotification(targetAudience)) {

        // Create notification using AwesomeNotifications
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            channelKey: 'general_notifications',
            title: title,
            body: message,
            wakeUpScreen: true,
            category: NotificationCategory.Promo,
            payload: {
              'type': 'promotional',
              'notificationId': notificationId,
              'action': 'open_app',
            },
            // Add some visual appeal
            largeIcon: null, // You can add your app icon here
            notificationLayout: NotificationLayout.BigText,
          ),
        );

        // Update delivery count
        await _updateDeliveryCount(notificationId);

        debugPrint('✅ Promotional notification shown to customer');
      } else {
        debugPrint('⚠️ Customer does not match target audience: $targetAudience');
      }
    } catch (e) {
      debugPrint('❌ Error showing promotional notification: $e');
    }
  }

  /// Check if customer should receive this notification based on target audience
  Future<bool> _shouldReceiveNotification(String targetAudience) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      switch (targetAudience) {
        case 'all_customers':
          return true;

        case 'recent_customers':
        // Check if user has placed an order in the last 30 days
          final DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

          final QuerySnapshot recentOrders = await _firestore
              .collection('orders')
              .where('userId', isEqualTo: user.uid)
              .where('orderDate', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
              .limit(1)
              .get();

          return recentOrders.docs.isNotEmpty;

        default:
          return true;
      }
    } catch (e) {
      debugPrint('❌ Error checking notification eligibility: $e');
      return false; // Default to not showing if there's an error
    }
  }

  /// Update delivery count for analytics
  Future<void> _updateDeliveryCount(String notificationId) async {
    try {
      await _firestore.collection('promotional_notifications').doc(notificationId).update({
        'deliveryCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Error updating delivery count: $e');
      // Don't fail the notification if analytics update fails
    }
  }
// ADD THIS METHOD to your CustomerNotificationService class
// (in lib/services/customer_notification_service.dart)

  /// Send reorder reminder notification
  Future<void> sendReorderReminder({
    required String userId,
    required String productName,
    required String message,
    required String productId,
  }) async {
    try {
      debugPrint('🔔 Sending reorder reminder: $productName');

      // Create local notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'general_notifications',
          title: '🛒 Time to Reorder!',
          body: message,
          bigPicture: 'asset://assets/notification_icon.png',
          notificationLayout: NotificationLayout.BigPicture,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          criticalAlert: false,
          payload: {
            'type': 'reorder_reminder',
            'productId': productId,
            'userId': userId,
            'productName': productName,
          },
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'add_to_basket',
            label: 'Add to Basket',
            actionType: ActionType.Default,
            icon: 'resource://drawable/ic_add_shopping_cart',
          ),
          NotificationActionButton(
            key: 'dismiss',
            label: 'Not Now',
            actionType: ActionType.Default,
            icon: 'resource://drawable/ic_close',
          ),
        ],
      );

      debugPrint('✅ Reorder reminder notification sent successfully');

    } catch (e) {
      debugPrint('❌ Error sending reorder reminder notification: $e');
      rethrow;
    }
  }

  /// Handle reorder reminder notification actions
  Future<void> handleReorderReminderAction(String action, Map<String, String?> payload) async {
    try {
      final productId = payload['productId'];
      final productName = payload['productName'];

      debugPrint('🔔 Handling reorder reminder action: $action for $productName');

      switch (action) {
        case 'add_to_basket':
        // Navigate to product or add to basket
        // You can implement this based on your basket manager
          debugPrint('🛒 User wants to add $productName to basket');

          // Example: Navigate to customer reorder screen
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pushNamed('/customer-reorder');
          }
          break;

        case 'dismiss':
          debugPrint('❌ User dismissed reorder reminder for $productName');
          // Track dismissal for analytics
          await _trackReminderResponse(payload['userId'] ?? '', productId ?? '', 'dismissed');
          break;

        default:
        // Default action - navigate to customer reorder screen
          if (navigatorKey.currentContext != null) {
            Navigator.of(navigatorKey.currentContext!).pushNamed('/customer-reorder');
          }
          break;
      }

    } catch (e) {
      debugPrint('❌ Error handling reorder reminder action: $e');
    }
  }

  /// Track reminder response for analytics
  Future<void> _trackReminderResponse(String userId, String productId, String action) async {
    try {
      await FirebaseFirestore.instance.collection('reminder_responses').add({
        'userId': userId,
        'productId': productId,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Tracked reminder response: $action');
    } catch (e) {
      debugPrint('❌ Error tracking reminder response: $e');
    }
  }
  /// Test promotional notification (for debugging)
  Future<void> testPromotionalNotification() async {
    try {
      debugPrint('🧪 Testing promotional notification...');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'general_notifications',
          title: '🧪 Test Promotion',
          body: 'This is a test promotional notification!',
          wakeUpScreen: true,
          category: NotificationCategory.Promo,
          payload: {
            'type': 'promotional',
            'action': 'test',
          },
        ),
      );

      debugPrint('✅ Test promotional notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test promotional notification: $e');
    }
  }
}