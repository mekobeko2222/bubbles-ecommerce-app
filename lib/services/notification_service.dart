import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
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

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Request permission
      await requestPermission();

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize with callback for when notification is tapped
    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    // Order notifications channel
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      'Order Notifications',
      description: 'Notifications for order updates and confirmations',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
      enableVibration: true,
    );

    // General notifications channel
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      _generalChannelId,
      'General Notifications',
      description: 'General app notifications and updates',
      importance: Importance.defaultImportance,
      showBadge: true,
    );

    // Admin notifications channel (high priority)
    const AndroidNotificationChannel adminChannel = AndroidNotificationChannel(
      _adminChannelId,
      'Admin Notifications',
      description: 'Important admin notifications for new orders and updates',
      importance: Importance.max,
      showBadge: true,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    // Create the channels
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(orderChannel);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(adminChannel);
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
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Foreground message received: ${message.messageId}');
    debugPrint('📱 Message data: ${message.data}');
    debugPrint('📱 Message notification: ${message.notification?.toMap()}');

    // Show local notification when app is in foreground
    await _showLocalNotification(message);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    // Determine channel based on message data
    String channelId = _generalChannelId;
    if (message.data['type'] == 'order') {
      channelId = _orderChannelId;
    } else if (message.data['type'] == 'admin') {
      channelId = _adminChannelId;
    }

    // Android notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == _orderChannelId ? 'Order Notifications' :
      channelId == _adminChannelId ? 'Admin Notifications' : 'General Notifications',
      channelDescription: channelId == _orderChannelId ? 'Order updates and confirmations' :
      channelId == _adminChannelId ? 'Admin notifications for new orders' : 'General app notifications',
      importance: channelId == _adminChannelId ? Importance.max : Importance.high,
      priority: channelId == _adminChannelId ? Priority.max : Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
        summaryText: 'Bubbles E-commerce',
      ),
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification
    await _localNotificationsPlugin.show(
      message.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');

    // Navigate based on notification type
    final String? type = message.data['type'];
    final String? orderId = message.data['orderId'];

    if (type == 'order' && orderId != null) {
      // Navigate to order details or orders list
      _navigateToOrders();
    } else if (type == 'admin') {
      // Navigate to admin panel
      _navigateToAdminPanel();
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    debugPrint('🔔 Local notification tapped: ${notificationResponse.payload}');

    if (notificationResponse.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(notificationResponse.payload!);

        final String? type = data['type'];
        final String? orderId = data['orderId'];

        if (type == 'order' && orderId != null) {
          _navigateToOrders();
        } else if (type == 'admin') {
          _navigateToAdminPanel();
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Navigate to orders screen (placeholder - implement with your navigation)
  void _navigateToOrders() {
    // TODO: Implement navigation to orders screen
    debugPrint('🚀 Navigating to orders...');
  }

  /// Navigate to admin panel (placeholder - implement with your navigation)
  void _navigateToAdminPanel() {
    // TODO: Implement navigation to admin panel
    debugPrint('🚀 Navigating to admin panel...');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      final NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Notification permission status: ${settings.authorizationStatus}');

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
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}