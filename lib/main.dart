import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bubbles_ecommerce_app/firebase_options.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/wishlist_manager.dart';
import 'package:bubbles_ecommerce_app/home_screen.dart';
import 'package:bubbles_ecommerce_app/auth_screen.dart';
import 'package:bubbles_ecommerce_app/locale_provider.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';

// Import notification services
import 'package:bubbles_ecommerce_app/services/notification_service.dart';
import 'package:bubbles_ecommerce_app/services/admin_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification services
  try {
    debugPrint('🔔 Initializing notification services...');

    // Initialize base notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    // Start listening for token refresh
    notificationService.listenForTokenRefresh();

    // Initialize admin notification service
    final adminNotificationService = AdminNotificationService();
    await adminNotificationService.initialize();

    debugPrint('✅ Notification services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing notification services: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => BasketManager()),
        ChangeNotifierProvider(create: (context) => WishlistManager()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        // Provide notification services
        Provider<NotificationService>(create: (context) => NotificationService()),
        Provider<AdminNotificationService>(create: (context) => AdminNotificationService()),
      ],
      child: const MyApp(),
    ),
  );
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
  }

  /// Setup notifications for the authenticated user
  Future<void> _setupNotificationsForUser() async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final adminNotificationService = Provider.of<AdminNotificationService>(context, listen: false);

      // Save user token
      await notificationService.saveUserToken();

      // If user is admin, setup admin-specific notifications
      await _setupAdminNotifications(adminNotificationService);

      debugPrint('✅ Notifications setup completed for user: ${widget.userEmail}');
    } catch (e) {
      debugPrint('❌ Error setting up notifications for user: $e');
    }
  }

  /// Setup admin-specific notifications if user is admin
  Future<void> _setupAdminNotifications(AdminNotificationService adminService) async {
    try {
      // Re-initialize admin service for the current user
      await adminService.initialize();

      // Setup order listener for admin notifications
      adminService.setupOrderListener();

      // Subscribe admin to order notifications topic
      await adminService.subscribeAdminToOrderNotifications();

      debugPrint('✅ Admin notifications setup completed');
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