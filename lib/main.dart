import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bubbles_ecommerce_app/firebase_options.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/wishlist_manager.dart';
import 'package:bubbles_ecommerce_app/home_screen.dart';
import 'package:bubbles_ecommerce_app/auth_screen.dart';
import 'package:bubbles_ecommerce_app/locale_provider.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/reorder_reminder_service.dart';


// Import notification services
import 'package:bubbles_ecommerce_app/services/notification_service.dart';
import 'package:bubbles_ecommerce_app/services/admin_notification_service.dart';
import 'package:bubbles_ecommerce_app/services/customer_notification_service.dart';

// Import ML Pattern Service
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';

// Import admin panel and orders screens
import 'package:bubbles_ecommerce_app/admin_panel_screen.dart';
import 'admin_orders_screen.dart';

// Import Customer Reorder Screen
import 'package:bubbles_ecommerce_app/customer_reorder_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification services (using local notifications only)
  try {
    debugPrint('🔔 Initializing notification services...');

    // Initialize base notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Initialize admin notification service
    final adminNotificationService = AdminNotificationService();
    await adminNotificationService.initialize();

    // Initialize customer notification service
    final customerNotificationService = CustomerNotificationService();
    await customerNotificationService.initialize();

    // NEW: Initialize reorder reminder service
    final reorderReminderService = ReorderReminderService();
    await reorderReminderService.initialize();

    debugPrint('✅ All notification services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing notification services: $e');
  }

  // Test pattern tracking on startup
  await _testPatternTrackingOnStartup();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BasketManager()),
        ChangeNotifierProvider(create: (context) => WishlistManager()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        // Provide notification services
        Provider<NotificationService>(create: (context) => NotificationService()),
        Provider<AdminNotificationService>(create: (context) => AdminNotificationService()),
        Provider<CustomerNotificationService>(create: (context) => CustomerNotificationService()),
        // Provide ML services
        Provider<PatternService>(create: (context) => PatternService()),
        // NEW: Provide reorder reminder service
        Provider<ReorderReminderService>(create: (context) => ReorderReminderService()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Test pattern tracking functionality on app startup
Future<void> _testPatternTrackingOnStartup() async {
  try {
    debugPrint('🧪 === TESTING PATTERN TRACKING ON STARTUP ===');

    final patternService = PatternService();

    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      debugPrint('👤 User is logged in: ${currentUser.uid}');

      // Test pattern tracking with sample data
      await patternService.trackOrder(
        userId: currentUser.uid,
        items: [
          {'productId': 'startup_test_product_1', 'quantity': 2},
          {'productId': 'startup_test_product_2', 'quantity': 1},
        ],
        orderDate: DateTime.now(),
      );

      debugPrint('✅ Startup pattern tracking test completed');

      // Check if patterns were actually created
      await _checkFirestorePatterns(currentUser.uid);

    } else {
      debugPrint('❌ No user logged in - pattern tracking test skipped');
    }

    debugPrint('🧪 === END STARTUP PATTERN TEST ===');
  } catch (e) {
    debugPrint('❌ Startup pattern tracking test failed: $e');
    debugPrint('❌ Error details: ${e.toString()}');
  }
}

/// Check if patterns were created in Firestore
Future<void> _checkFirestorePatterns(String userId) async {
  try {
    debugPrint('🔍 Checking Firestore for created patterns...');

    // Wait a moment for Firestore to process
    await Future.delayed(const Duration(seconds: 2));

    // Check customer_patterns collection
    final patternsSnapshot = await FirebaseFirestore.instance
        .collection('customer_patterns')
        .where('userId', isEqualTo: userId)
        .get();

    debugPrint('📊 Found ${patternsSnapshot.docs.length} patterns in customer_patterns collection');

    for (var doc in patternsSnapshot.docs) {
      final data = doc.data();
      debugPrint('   Pattern: ${data['productId']} - ${data['orderCount']} orders - confidence: ${data['confidence']}');
    }

    // Check user_pattern_settings collection
    final settingsDoc = await FirebaseFirestore.instance
        .collection('user_pattern_settings')
        .doc(userId)
        .get();

    if (settingsDoc.exists) {
      final settings = settingsDoc.data();
      debugPrint('⚙️ User settings found - ${settings?['totalOrders']} total orders recorded');
    } else {
      debugPrint('❌ No user pattern settings found');
    }

    // Check all collections existence
    await _checkFirestoreCollections();

  } catch (e) {
    debugPrint('❌ Error checking Firestore patterns: $e');
  }
}

/// Check if required Firestore collections exist
Future<void> _checkFirestoreCollections() async {
  try {
    debugPrint('🔍 === CHECKING FIRESTORE COLLECTIONS ===');

    final collections = [
      'customer_patterns',
      'user_pattern_settings',
      'reorder_predictions',
      'orders',
      'products',
      'users'
    ];

    for (String collectionName in collections) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .limit(1)
            .get();

        final status = snapshot.docs.isNotEmpty ? 'HAS DATA' : 'EMPTY';
        debugPrint('📁 $collectionName: $status (${snapshot.docs.length} docs checked)');
      } catch (e) {
        debugPrint('📁 $collectionName: ERROR - $e');
      }
    }

    debugPrint('🔍 === END FIRESTORE COLLECTIONS CHECK ===');
  } catch (e) {
    debugPrint('❌ Error checking Firestore collections: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bubbles E-commerce App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6200EE)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6200EE),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF03DAC5),
          foregroundColor: Colors.white,
        ),
      ),
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // Add the global navigator key for navigation from notifications
      navigatorKey: navigatorKey,
      // Add routes for notification navigation and ML features
      routes: {
        '/admin': (context) => const AdminPanelScreen(),
        '/admin-orders': (context) => const AdminOrdersScreen(),
        '/customer-reorder': (context) => const CustomerReorderScreen(),
      },
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // User is logged in
            return AuthenticatedApp(userEmail: snapshot.data!.email ?? 'N/A');
          }
          // User is not logged in
          return const AuthScreen();
        },
      ),
    );
  }
}

/// Wrapper widget for authenticated users to handle notification setup
class AuthenticatedApp extends StatefulWidget {
  final String userEmail;

  const AuthenticatedApp({super.key, required this.userEmail});

  @override
  State<AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends State<AuthenticatedApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationsForUser();
    // Test pattern tracking after user authentication
    _testPatternTrackingForUser();
  }

  /// Setup notifications for the authenticated user
  Future<void> _setupNotificationsForUser() async {
    try {
      final adminNotificationService = Provider.of<AdminNotificationService>(context, listen: false);

      // If user is admin, setup admin-specific notifications
      await _setupAdminNotifications(adminNotificationService);

      debugPrint('✅ Notifications setup completed for user: ${widget.userEmail}');
    } catch (e) {
      debugPrint('❌ Error setting up notifications for user: $e');
    }
  }

  /// Test pattern tracking for authenticated user
  Future<void> _testPatternTrackingForUser() async {
    try {
      debugPrint('🧪 === TESTING PATTERN TRACKING FOR AUTHENTICATED USER ===');

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No current user found');
        return;
      }

      // Get BasketManager and test pattern tracking
      final basketManager = Provider.of<BasketManager>(context, listen: false);
      await basketManager.testPatternTracking();

      // Check if patterns were created
      await Future.delayed(const Duration(seconds: 3));
      await _checkFirestorePatterns(currentUser.uid);

      debugPrint('🧪 === END AUTHENTICATED USER PATTERN TEST ===');
    } catch (e) {
      debugPrint('❌ Authenticated user pattern test failed: $e');
    }
  }

  /// Setup admin-specific notifications if user is admin
  Future<void> _setupAdminNotifications(AdminNotificationService adminService) async {
    try {
      // Re-initialize admin service for the current user
      await adminService.initialize();

      // Setup order listener for admin notifications (LOCAL NOTIFICATIONS)
      adminService.setupOrderListener();

      debugPrint('✅ Admin LOCAL notifications setup completed');
    } catch (e) {
      debugPrint('❌ Error setting up admin notifications: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return HomeScreen(userEmail: widget.userEmail);
  }
}



/// Global navigator key for navigation from notification handlers
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();