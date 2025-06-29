import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'notification_service.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Initialize admin notification service
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing AdminNotificationService...');

      // Note: We're using local notifications only, no FCM tokens needed
      debugPrint('📱 Using local notifications (no Firebase FCM)');

      debugPrint('✅ AdminNotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AdminNotificationService: $e');
    }
  }

  /// Check if user is admin and save token
  Future<void> _checkAndSaveAdminToken() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      if (isAdmin) {
        await _notificationService.saveAdminToken();
        debugPrint('✅ Admin token saved for user: ${user.email}');
      }
    } catch (e) {
      debugPrint('❌ Error checking admin status: $e');
    }
  }

  /// Setup listener for new orders (triggers notifications)
  void setupOrderListener() {
    debugPrint('🔔 Setting up order listener for admin notifications...');

    // Only listen for orders created AFTER the app starts (to avoid old orders)
    final DateTime appStartTime = DateTime.now();
    debugPrint('📅 App start time: $appStartTime - Only orders after this will trigger notifications');

    // Listen to orders collection for new documents
    _firestore
        .collection('orders')
        .where('orderDate', isGreaterThan: Timestamp.fromDate(appStartTime))
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (DocumentChange change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final orderData = change.doc.data() as Map<String, dynamic>;
          final orderDate = (orderData['orderDate'] as Timestamp?)?.toDate();

          debugPrint('📦 New order detected: ${change.doc.id}');
          debugPrint('📅 Order date: $orderDate');

          // Double-check that this order was created after app start
          if (orderDate != null && orderDate.isAfter(appStartTime)) {
            debugPrint('✅ Order is truly new, showing notification');

            // Show LOCAL notification immediately (no FCM needed!)
            try {
              _showLocalAdminNotification(change.doc.id);
            } catch (e) {
              debugPrint('❌ Error showing local notification: $e');
            }

            // Optional: Still send via Vercel API for logging/webhooks
            try {
              handleNewOrderNotification(change.doc.id, orderData);
            } catch (e) {
              debugPrint('❌ Error sending API notification: $e');
            }
          } else {
            debugPrint('⏳ Order is from before app start, skipping notification');
          }
        }
      }
    }, onError: (error) {
      debugPrint('❌ Error listening to orders: $error');
    });
  }

  /// Show local admin notification using AwesomeNotifications
  Future<void> _showLocalAdminNotification(String orderId) async {
    try {
      debugPrint('🔔 Showing LOCAL admin notification for order: $orderId');

      // Check if user is admin first
      final User? user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      if (!isAdmin) {
        debugPrint('⚠️ User is not admin, skipping notification');
        return;
      }

      // Create notification using AwesomeNotifications
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'admin_notifications',
          title: '🛒 New Order!',
          body: 'You have received a new order. Check your admin panel for details.',
          wakeUpScreen: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          payload: {
            'type': 'admin',
            'action': 'new_order',
            'orderId': orderId,
          },
        ),
      );

      debugPrint('✅ LOCAL admin notification created successfully');
    } catch (e) {
      debugPrint('❌ Error creating local admin notification: $e');
    }
  }

  /// Get all admin tokens (for testing purposes)
  Future<List<String>> getAllAdminTokens() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('admin_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      final List<String> tokens = [];
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String? token = data['token'];
        if (token != null) {
          tokens.add(token);
        }
      }

      debugPrint('📋 Found ${tokens.length} active admin tokens');
      return tokens;
    } catch (e) {
      debugPrint('❌ Error getting admin tokens: $e');
      return [];
    }
  }

  /// Manually trigger admin notification (for testing)
  Future<void> testAdminNotification(String orderId, Map<String, dynamic> orderData) async {
    try {
      debugPrint('🧪 Testing admin notification for order: $orderId');

      // Create a test notification document that the Cloud Function can pick up
      await _firestore.collection('admin_notifications').add({
        'type': 'new_order',
        'orderId': orderId,
        'orderData': orderData,
        'timestamp': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('✅ Test admin notification document created');
    } catch (e) {
      debugPrint('❌ Error creating test admin notification: $e');
    }
  }

  /// Send notification to specific admin
  Future<void> notifySpecificAdmin(String adminUserId, String title, String body, Map<String, dynamic> data) async {
    try {
      // Get admin token
      final adminTokenDoc = await _firestore.collection('admin_tokens').doc(adminUserId).get();

      if (!adminTokenDoc.exists) {
        debugPrint('⚠️ Admin token not found for user: $adminUserId');
        return;
      }

      final adminData = adminTokenDoc.data() as Map<String, dynamic>;
      final String? token = adminData['token'];

      if (token == null) {
        debugPrint('⚠️ No token found for admin: $adminUserId');
        return;
      }

      // Create notification payload
      final notificationData = {
        'token': token,
        'title': title,
        'body': body,
        'data': data,
        'type': 'admin',
      };

      // Add to notification queue for Cloud Function to process
      await _firestore.collection('notification_queue').add({
        'payload': notificationData,
        'targetType': 'individual',
        'processed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Admin notification queued for: $adminUserId');
    } catch (e) {
      debugPrint('❌ Error sending notification to admin: $e');
    }
  }

  /// Broadcast notification to all admins
  Future<void> broadcastToAllAdmins(String title, String body, Map<String, dynamic> data) async {
    try {
      // Create broadcast notification payload
      final notificationData = {
        'title': title,
        'body': body,
        'data': data,
        'type': 'admin',
      };

      // Add to notification queue for Cloud Function to process
      await _firestore.collection('notification_queue').add({
        'payload': notificationData,
        'targetType': 'all_admins',
        'processed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Broadcast notification queued for all admins');
    } catch (e) {
      debugPrint('❌ Error broadcasting to all admins: $e');
    }
  }

  /// Format order notification data
  Map<String, dynamic> _formatOrderNotificationData(String orderId, Map<String, dynamic> orderData) {
    return {
      'type': 'order',
      'orderId': orderId,
      'action': 'view_order',
      'customerEmail': orderData['userEmail'] ?? 'Unknown',
      'totalPrice': orderData['totalPrice']?.toString() ?? '0',
      'itemCount': (orderData['items'] as List?)?.length?.toString() ?? '0',
      'orderStatus': orderData['orderStatus'] ?? 'Pending',
    };
  }

  /// Handle new order notification
  Future<void> handleNewOrderNotification(String orderId, Map<String, dynamic> orderData) async {
    try {
      final double totalPrice = (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final int itemCount = (orderData['items'] as List?)?.length ?? 0;
      final String customerEmail = orderData['userEmail'] ?? 'Unknown Customer';

      final String title = '🛒 New Order Received!';
      final String body = 'Order #${orderId.substring(0, 8).toUpperCase()}\n'
          'Customer: $customerEmail\n'
          'Total: EGP ${totalPrice.toStringAsFixed(2)}\n'
          'Items: $itemCount';

      final Map<String, dynamic> notificationData = _formatOrderNotificationData(orderId, orderData);

      await broadcastToAllAdmins(title, body, notificationData);

      debugPrint('✅ New order notification sent for order: $orderId');
    } catch (e) {
      debugPrint('❌ Error handling new order notification: $e');
    }
  }

  /// Handle order status update notification (for customers)
  Future<void> handleOrderStatusUpdateNotification(String orderId, String newStatus, String userId) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('⚠️ User document not found: $userId');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final String? userToken = userData['fcmToken'];

      if (userToken == null) {
        debugPrint('⚠️ No FCM token found for user: $userId');
        return;
      }

      String title = '📦 Order Update';
      String body = 'Your order #${orderId.substring(0, 8).toUpperCase()} is now $newStatus';

      // Customize message based on status
      switch (newStatus.toLowerCase()) {
        case 'processing':
          body = '⚙️ Your order is being prepared!';
          break;
        case 'shipped':
          body = '🚚 Your order has been shipped and is on its way!';
          break;
        case 'delivered':
          title = '✅ Order Delivered';
          body = '🎉 Your order has been delivered successfully!';
          break;
        case 'cancelled':
          title = '❌ Order Cancelled';
          body = '😔 Your order has been cancelled.';
          break;
      }

      final Map<String, dynamic> notificationData = {
        'type': 'order',
        'orderId': orderId,
        'action': 'view_order',
        'newStatus': newStatus,
      };

      // Create notification payload
      final payload = {
        'token': userToken,
        'title': title,
        'body': body,
        'data': notificationData,
        'type': 'order',
      };

      // Add to notification queue
      await _firestore.collection('notification_queue').add({
        'payload': payload,
        'targetType': 'individual',
        'processed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Order status update notification queued for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending order status update notification: $e');
    }
  }

  /// Clean up old admin tokens
  Future<void> cleanupOldTokens() async {
    try {
      final DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final QuerySnapshot oldTokens = await _firestore
          .collection('admin_tokens')
          .where('updatedAt', isLessThan: Timestamp.fromDate(oneWeekAgo))
          .get();

      for (QueryDocumentSnapshot doc in oldTokens.docs) {
        await doc.reference.delete();
        debugPrint('🗑️ Deleted old admin token: ${doc.id}');
      }

      debugPrint('✅ Cleanup completed. Removed ${oldTokens.docs.length} old tokens');
    } catch (e) {
      debugPrint('❌ Error cleaning up old tokens: $e');
    }
  }

  /// Get admin notification statistics
  Future<Map<String, dynamic>> getAdminNotificationStats() async {
    try {
      // Count active admin tokens
      final QuerySnapshot adminTokens = await _firestore
          .collection('admin_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      // Count pending notifications
      final QuerySnapshot pendingNotifications = await _firestore
          .collection('notification_queue')
          .where('processed', isEqualTo: false)
          .get();

      // Count processed notifications from last 24 hours
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      final QuerySnapshot recentNotifications = await _firestore
          .collection('notification_queue')
          .where('processed', isEqualTo: true)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      return {
        'activeAdminTokens': adminTokens.docs.length,
        'pendingNotifications': pendingNotifications.docs.length,
        'recentNotifications': recentNotifications.docs.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting admin notification stats: $e');
      return {
        'activeAdminTokens': 0,
        'pendingNotifications': 0,
        'recentNotifications': 0,
        'error': e.toString(),
      };
    }
  }

  /// Test notification system
  Future<void> testNotificationSystem() async {
    try {
      debugPrint('🧪 Testing notification system...');

      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No user logged in for testing');
        return;
      }

      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      if (!isAdmin) {
        debugPrint('❌ User is not admin, cannot test admin notifications');
        return;
      }

      // Show test local notification
      await _showLocalAdminNotification('TEST_ORDER_ID');

      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error testing notification system: $e');
    }
  }

  /// Subscribe admin to order notifications topic
  Future<void> subscribeAdminToOrderNotifications() async {
    try {
      await _notificationService.subscribeToTopic('admin_orders');
      debugPrint('✅ Subscribed admin to order notifications topic');
    } catch (e) {
      debugPrint('❌ Error subscribing admin to order notifications: $e');
    }
  }

  /// Unsubscribe admin from order notifications topic
  Future<void> unsubscribeAdminFromOrderNotifications() async {
    try {
      await _notificationService.unsubscribeFromTopic('admin_orders');
      debugPrint('✅ Unsubscribed admin from order notifications topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing admin from order notifications: $e');
    }
  }
}