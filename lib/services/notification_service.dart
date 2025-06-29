import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // Import to access navigatorKey
import 'package:firebase_auth/firebase_auth.dart';

/// Global function to handle background messages
/// This must be a top-level function or static method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  debugPrint('Background message data: ${message.data}');

  // You can process the background message here
  // For example, update local database, show notification, etc.
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification channel IDs
  static const String _orderChannelId = 'order_notifications';
  static const String _generalChannelId = 'general_notifications';
  static const String _adminChannelId = 'admin_notifications';

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing NotificationService...');

      // Initialize awesome notifications
      await _initializeAwesomeNotifications();

      // Initialize Firebase Messaging (optional, for future use)
      await _initializeFirebaseMessaging();

      // Request permission
      await requestPermission();

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Initialize awesome notifications
  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null, // Use default app icon
      [
        // Order notifications channel
        NotificationChannel(
          channelKey: _orderChannelId,
          channelName: 'Order Notifications',
          channelDescription: 'Notifications for order updates and confirmations',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
        ),
        // General notifications channel
        NotificationChannel(
          channelKey: _generalChannelId,
          channelName: 'General Notifications',
          channelDescription: 'General app notifications and updates',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          channelShowBadge: true,
        ),
        // Admin notifications channel (high priority)
        NotificationChannel(
          channelKey: _adminChannelId,
          channelName: 'Admin Notifications',
          channelDescription: 'Important admin notifications for new orders and updates',
          defaultColor: Colors.red,
          ledColor: Colors.red,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );

    // Set up notification action stream
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationTapped,
      onNotificationCreatedMethod: _onNotificationCreated,
      onNotificationDisplayedMethod: _onNotificationDisplayed,
      onDismissActionReceivedMethod: _onDismissActionReceived,
    );
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Add debug logging for FCM token
    final String? token = await _firebaseMessaging.getToken();
    debugPrint('🔑 Current FCM Token: ${token?.substring(0, 50)}...');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('📱 Message data: ${message.data}');
    debugPrint('📱 Message notification: ${message.notification?.toMap()}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Show local notification using AwesomeNotifications
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final RemoteNotification? notification = message.notification;

      // If no notification payload, create one from data
      String title = notification?.title ?? 'New Notification';
      String body = notification?.body ?? 'You have a new notification';

      // Handle cases where title/body might be in data
      if (message.data.containsKey('title')) {
        title = message.data['title'] ?? title;
      }
      if (message.data.containsKey('body')) {
        body = message.data['body'] ?? body;
      }

      debugPrint('📱 Showing local notification: $title - $body');

      // Determine channel based on message data
      String channelId = _generalChannelId;
      if (message.data['type'] == 'order' || message.data['action'] == 'new_order') {
        channelId = _orderChannelId;
      } else if (message.data['type'] == 'admin') {
        channelId = _adminChannelId;
      }

      // Show the notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
          channelKey: channelId,
          title: title,
          body: body,
          bigPicture: null,
          largeIcon: null,
          notificationLayout: NotificationLayout.BigText,
          payload: message.data.map((key, value) => MapEntry(key, value?.toString())),
          category: channelId == _orderChannelId ? NotificationCategory.Status :
          channelId == _adminChannelId ? NotificationCategory.Message :
          NotificationCategory.Social,
          wakeUpScreen: true,
          criticalAlert: channelId == _adminChannelId, // Critical for admin notifications
        ),
      );

      debugPrint('✅ Local notification created successfully');
    } catch (e) {
      debugPrint('❌ Error creating local notification: $e');
    }
  }

  /// Handle notification tap from Firebase
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Firebase notification tapped: ${message.data}');
    _processNotificationAction(message.data.map((key, value) => MapEntry(key, value?.toString())));
  }

  /// Handle awesome notification events
  @pragma("vm:entry-point")
  static Future<void> _onNotificationTapped(ReceivedAction receivedAction) async {
    debugPrint('🔔 Awesome notification tapped: ${receivedAction.payload}');
    final instance = NotificationService();
    instance._processNotificationAction(receivedAction.payload ?? {});
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationCreated(ReceivedNotification receivedNotification) async {
    debugPrint('🔔 Notification created: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDisplayed(ReceivedNotification receivedNotification) async {
    debugPrint('🔔 Notification displayed: ${receivedNotification.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismissActionReceived(ReceivedAction receivedAction) async {
    debugPrint('🔔 Notification dismissed: ${receivedAction.id}');
  }

  /// Process notification action
  void _processNotificationAction(Map<String, String?> data) {
    final String? type = data['type'];
    final String? action = data['action'];

    debugPrint('🔔 Processing notification action: type=$type, action=$action');

    if (type == 'admin' && action == 'new_order') {
      // Navigate to admin orders screen
      _navigateToAdminOrders();
    } else {
      // Fallback: just bring app to foreground
      debugPrint('🚀 Bringing app to foreground');
    }
  }

  /// Navigate to admin orders screen
  void _navigateToAdminOrders() {
    try {
      debugPrint('🚀 Navigating to admin orders screen...');
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Navigate to admin panel with orders tab selected
        Navigator.of(context).pushNamed('/admin-orders');
      } else {
        debugPrint('⚠️ No context available for navigation');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to admin orders: $e');
    }
  }

  /// Navigate to orders screen (placeholder - implement with your navigation)
  void _navigateToOrders() {
    // Not needed for admin notifications
    debugPrint('🚀 Navigating to orders...');
  }

  /// Navigate to admin panel (placeholder - implement with your navigation)
  void _navigateToAdminPanel() {
    try {
      debugPrint('🚀 Navigating to admin panel...');
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamed('/admin');
      } else {
        debugPrint('⚠️ No context available for navigation');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to admin panel: $e');
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      // Request Firebase permission
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Request AwesomeNotifications permission
      final bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      debugPrint('🔔 Firebase permission status: ${settings.authorizationStatus}');
      debugPrint('🔔 AwesomeNotifications allowed: ${await AwesomeNotifications().isNotificationAllowed()}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permission granted');
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Provisional notification permission granted');
        return true;
      } else {
        debugPrint('❌ Notification permission denied');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save user token to Firestore
  Future<void> saveUserToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot save token');
        return;
      }

      final String? token = await getToken();
      if (token == null) {
        debugPrint('⚠️ No FCM token available');
        return;
      }

      // Save token to user's document
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'android', // or detect platform
      }, SetOptions(merge: true));

      debugPrint('✅ User FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving user token: $e');
    }
  }

  /// Save admin token to Firestore
  Future<void> saveAdminToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, cannot save admin token');
        return;
      }

      final String? token = await getToken();
      if (token == null) {
        debugPrint('⚠️ No FCM token available');
        return;
      }

      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;

      if (!isAdmin) {
        debugPrint('⚠️ User is not admin, cannot save admin token');
        return;
      }

      // Save token to admin_tokens collection
      await _firestore.collection('admin_tokens').doc(user.uid).set({
        'token': token,
        'userId': user.uid,
        'userEmail': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'android', // or detect platform
        'isActive': true,
      });

      debugPrint('✅ Admin FCM token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving admin token: $e');
    }
  }

  /// Remove user token from Firestore (on logout)
  Future<void> removeUserToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      // Remove from users collection
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'tokenUpdatedAt': FieldValue.delete(),
      });

      // Remove from admin_tokens collection if exists
      await _firestore.collection('admin_tokens').doc(user.uid).delete();

      debugPrint('✅ User tokens removed from Firestore');
    } catch (e) {
      debugPrint('❌ Error removing user token: $e');
    }
  }

  /// Listen for token refresh
  void listenForTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String token) async {
      debugPrint('🔄 FCM Token refreshed: $token');

      // Update token in Firestore
      await saveUserToken();

      // If user is admin, also update admin token
      final User? user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final bool isAdmin = userDoc.data()?['isAdmin'] ?? false;
        if (isAdmin) {
          await saveAdminToken();
        }
      }
    });
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    final awesomeAllowed = await AwesomeNotifications().isNotificationAllowed();

    return (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) &&
        awesomeAllowed;
  }

  /// Force show a test admin notification (for debugging)
  Future<void> forceShowAdminNotification() async {
    debugPrint('🔔 Force showing admin notification...');
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: _adminChannelId,
          title: '🛒 New Order!',
          body: 'You have received a new order. Check your admin panel for details.',
          wakeUpScreen: true,
          criticalAlert: true,
          category: NotificationCategory.Message,
          payload: {
            'type': 'admin',
            'action': 'new_order',
            'source': 'force_test'
          },
        ),
      );
      debugPrint('✅ Force admin notification created');
    } catch (e) {
      debugPrint('❌ Error creating force admin notification: $e');
    }
  }
}