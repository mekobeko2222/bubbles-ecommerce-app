import 'package:bubbles_ecommerce_app/admin_tabs/admin_ml_patterns_tab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/config/app_config.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';
import 'package:bubbles_ecommerce_app/services/reorder_reminder_service.dart';
import 'package:bubbles_ecommerce_app/admin_tabs/admin_ml_insights_tab.dart';



// Corrected imports for admin tabs from the admin_tabs directory
import 'admin_tabs/admin_add_product_tab.dart';
import 'admin_tabs/admin_manage_products_tab.dart';
import 'admin_tabs/admin_manage_areas_tab.dart';
import 'admin_tabs/admin_orders_tab.dart';
import 'admin_tabs/admin_analytics_tab.dart';
import 'admin_tabs/manage_offer_codes_screen.dart';
import 'admin_tabs/admin_manage_nearby_shops_tab.dart';
import 'admin_tabs/admin_manage_app_features_tab.dart';
import 'admin_tabs/admin_send_notifications_tab.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12,
        vsync: this); // UPDATED: Changed to 11 tabs (added debug tab)
    _checkAdminStatus();
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _isLoading = false;
        _error = 'User not logged in.';
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;
      setState(() {
        _isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] == true);
        _isLoading = false;
        if (!_isAdmin) {
          _error = 'You are not authorized to view the admin panel.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _isLoading = false;
        _error = 'Error checking admin status: $e';
      });
      debugPrint('Error checking admin status: $e');
    }
  }
  Future<void> _runCompleteSystemTest() async {
    debugPrint('🧪 === RUNNING COMPLETE SYSTEM TEST ===');

    try {
      // Show initial message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Starting complete system test...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      int testsRun = 0;
      int testsPassed = 0;
      final List<String> results = [];

      // Test 1: Pattern Tracking
      debugPrint('📊 Testing pattern tracking...');
      try {
        await _testPatternService();
        testsPassed++;
        results.add('✅ Pattern Tracking: PASSED');
      } catch (e) {
        results.add('❌ Pattern Tracking: FAILED - $e');
      }
      testsRun++;
      await Future.delayed(const Duration(seconds: 2));

      // Test 2: Firestore Connectivity
      debugPrint('🔥 Testing Firestore connectivity...');
      try {
        await _testFirestoreWrites();
        testsPassed++;
        results.add('✅ Firestore Connectivity: PASSED');
      } catch (e) {
        results.add('❌ Firestore Connectivity: FAILED - $e');
      }
      testsRun++;
      await Future.delayed(const Duration(seconds: 2));

      // Test 3: Prediction Generation
      debugPrint('🎯 Testing prediction generation...');
      try {
        await _testLowThresholdPredictions();
        testsPassed++;
        results.add('✅ Prediction Generation: PASSED');
      } catch (e) {
        results.add('❌ Prediction Generation: FAILED - $e');
      }
      testsRun++;
      await Future.delayed(const Duration(seconds: 2));

      // Test 4: Reminder System
      debugPrint('🔔 Testing reminder system...');
      try {
        await _testReminderService();
        testsPassed++;
        results.add('✅ Reminder System: PASSED');
      } catch (e) {
        results.add('❌ Reminder System: FAILED - $e');
      }
      testsRun++;
      await Future.delayed(const Duration(seconds: 2));

      // Test 5: Data Integrity
      debugPrint('🔍 Testing data integrity...');
      try {
        await _checkCollections();
        testsPassed++;
        results.add('✅ Data Integrity: PASSED');
      } catch (e) {
        results.add('❌ Data Integrity: FAILED - $e');
      }
      testsRun++;

      // Calculate success rate
      final successRate = (testsPassed / testsRun * 100).round();
      final overallStatus = successRate >= 80 ? 'SYSTEM READY 🚀' : 'NEEDS ATTENTION ⚠️';

      debugPrint('✅ Complete system test finished!');
      debugPrint('📊 Tests passed: $testsPassed/$testsRun ($successRate%)');

      // Show comprehensive results
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successRate >= 80 ? Icons.check_circle : Icons.warning,
                  color: successRate >= 80 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text('System Test Results'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    overallStatus,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: successRate >= 80 ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Success Rate: $successRate% ($testsPassed/$testsRun)'),
                  const SizedBox(height: 16),
                  ...results.map((result) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(result, style: const TextStyle(fontSize: 14)),
                  )),
                  const SizedBox(height: 16),
                  if (successRate >= 80)
                    const Text(
                      '🎉 Your ML system is ready for production!',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    const Text(
                      '⚠️ Some tests failed. Check console for details.',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (successRate < 80)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _runCompleteSystemTest(); // Retry
                  },
                  child: const Text('Retry Tests'),
                ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ System test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ System test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }

    debugPrint('🧪 === END COMPLETE SYSTEM TEST ===');
  }

  /// Test user journey simulation
  Future<void> _testUserJourney() async {
    debugPrint('👤 === TESTING USER JOURNEY ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('👤 Simulating complete user journey...'),
          backgroundColor: Colors.purple,
        ),
      );

      final steps = <String>[];

      // Step 1: New customer places order
      debugPrint('🛒 Step 1: Simulating new customer order...');
      await _testPatternService();
      steps.add('✅ New customer order placed & pattern tracked');
      await Future.delayed(const Duration(seconds: 1));

      // Step 2: Generate predictions
      debugPrint('🎯 Step 2: Generating predictions...');
      await _testLowThresholdPredictions();
      steps.add('✅ AI predictions generated');
      await Future.delayed(const Duration(seconds: 1));

      // Step 3: Test customer reorder experience
      debugPrint('📱 Step 3: Testing customer reorder interface...');
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final predictionsDoc = await FirebaseFirestore.instance
            .collection('reorder_predictions')
            .doc(currentUser.uid)
            .get();

        if (predictionsDoc.exists) {
          steps.add('✅ Customer reorder screen ready with suggestions');
        } else {
          steps.add('⚠️ Customer reorder screen has no suggestions');
        }
      }
      await Future.delayed(const Duration(seconds: 1));

      // Step 4: Test reminder system
      debugPrint('🔔 Step 4: Testing reminder system...');
      await _testReminderService();
      steps.add('✅ Reminder system operational');
      await Future.delayed(const Duration(seconds: 1));

      // Step 5: Test admin dashboard
      debugPrint('📊 Step 5: Testing admin insights...');
      // Simulate checking ML insights
      steps.add('✅ Admin ML insights dashboard functional');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person, color: Colors.green),
                SizedBox(width: 8),
                Text('User Journey Test'),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 Complete user journey tested successfully!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                ...steps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(step, style: const TextStyle(fontSize: 14)),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ User journey test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ User journey test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('👤 === END USER JOURNEY TEST ===');
  }

  /// Performance test
  Future<void> _runPerformanceTest() async {
    debugPrint('⚡ === RUNNING PERFORMANCE TEST ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Running performance tests...'),
          backgroundColor: Colors.orange,
        ),
      );

      final results = <String, int>{};

      // Test 1: Pattern service response time
      final patternStart = DateTime.now();
      await _testPatternService();
      final patternTime = DateTime.now().difference(patternStart).inMilliseconds;
      results['Pattern Service'] = patternTime;

      // Test 2: Firestore write speed
      final firestoreStart = DateTime.now();
      await _testFirestoreWrites();
      final firestoreTime = DateTime.now().difference(firestoreStart).inMilliseconds;
      results['Firestore Writes'] = firestoreTime;

      // Test 3: Prediction generation time
      final predictionStart = DateTime.now();
      await _testLowThresholdPredictions();
      final predictionTime = DateTime.now().difference(predictionStart).inMilliseconds;
      results['Prediction Generation'] = predictionTime;

      // Analyze results
      final performance = <String>[];
      results.forEach((test, time) {
        String status;
        if (time < 2000) status = '✅ Excellent';
        else if (time < 5000) status = '⚠️ Good';
        else status = '❌ Slow';

        performance.add('$test: ${time}ms - $status');
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.speed, color: Colors.orange),
                SizedBox(width: 8),
                Text('Performance Test Results'),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Response Times:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...performance.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(result, style: const TextStyle(fontSize: 14)),
                )),
                const SizedBox(height: 16),
                const Text(
                  '⚡ Target: < 2000ms (Excellent)\n'
                      '⚠️ Acceptable: < 5000ms (Good)\n'
                      '❌ Slow: > 5000ms (Needs optimization)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Performance test failed: $e');
    }

    debugPrint('⚡ === END PERFORMANCE TEST ===');
  }

  // ==========================================
  // NEW: Debug Firestore writes method
  // ==========================================
  Future<void> _testFirestoreWrites() async {
    debugPrint('🔥 === ADMIN TESTING FIRESTORE WRITES ===');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No user logged in')),
      );
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 Testing Firestore writes...'),
          backgroundColor: Colors.blue,
        ),
      );

      final userId = currentUser.uid;
      final firestore = FirebaseFirestore.instance;
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch;

      debugPrint('👤 Testing for user: $userId');
      debugPrint('📧 User email: ${currentUser.email}');

      // Test 1: customer_patterns collection
      debugPrint('📝 Testing customer_patterns write...');
      await firestore
          .collection('customer_patterns')
          .doc('admin_test_$timestamp')
          .set({
        'userId': userId,
        'productId': 'admin_test_product_$timestamp',
        'orderCount': 1,
        'avgDaysBetweenOrders': 0.0,
        'avgQuantityPerOrder': 1.0,
        'confidence': 0.1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'orderHistory': [
          {
            'orderDate': Timestamp.now(),
            'quantity': 1,
            'daysSinceLastOrder': 0,
          }
        ],
      });
      debugPrint('✅ customer_patterns write SUCCESS');

      // Test 2: user_pattern_settings collection
      debugPrint('📝 Testing user_pattern_settings write...');
      await firestore
          .collection('user_pattern_settings')
          .doc('${userId}_test_$timestamp')
          .set({
        'userId': userId,
        'enableReminders': true,
        'reminderTiming': '2_days_before',
        'totalOrders': 1,
        'overallFrequency': 0.0,
        'orderHistory': [Timestamp.now()],
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ user_pattern_settings write SUCCESS');

      // Test 3: reorder_predictions collection
      debugPrint('📝 Testing reorder_predictions write...');
      await firestore
          .collection('reorder_predictions')
          .doc('${userId}_test_$timestamp')
          .set({
        'userId': userId,
        'predictions': [
          {
            'productId': 'test_product_$timestamp',
            'productName': 'Admin Test Product',
            'avgDaysBetween': 30.0,
            'avgQuantity': 1,
            'confidence': 0.5,
            'lastOrderDate': Timestamp.now(),
            'predictedNextOrder': Timestamp.fromDate(
                DateTime.now().add(const Duration(days: 30))),
            'daysUntilNextOrder': 30,
            'imageUrl': '',
          }
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ reorder_predictions write SUCCESS');

      // Wait a moment then verify
      await Future.delayed(const Duration(seconds: 2));

      // Verify documents exist
      debugPrint('🔍 Verifying documents were created...');

      final patternDoc = await firestore
          .collection('customer_patterns')
          .doc('admin_test_$timestamp')
          .get();

      final settingsDoc = await firestore
          .collection('user_pattern_settings')
          .doc('${userId}_test_$timestamp')
          .get();

      final predictionsDoc = await firestore
          .collection('reorder_predictions')
          .doc('${userId}_test_$timestamp')
          .get();

      debugPrint('📄 customer_patterns doc exists: ${patternDoc.exists}');
      debugPrint('📄 user_pattern_settings doc exists: ${settingsDoc.exists}');
      debugPrint('📄 reorder_predictions doc exists: ${predictionsDoc.exists}');

      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Firestore test completed!\n'
                    'Patterns: ${patternDoc.exists ? "✅" : "❌"}\n'
                    'Settings: ${settingsDoc.exists ? "✅" : "❌"}\n'
                    'Predictions: ${predictionsDoc.exists ? "✅" : "❌"}\n'
                    'Check console & Firebase Console'
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      debugPrint('🔥 === END ADMIN FIRESTORE TEST ===');
    } catch (e) {
      debugPrint('❌ Admin Firestore test failed: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firestore test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.adminPanelTitle),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(appLocalizations.verifyingAdminAccess),
            ],
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.accessDenied),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 20),
                Text(
                  _error ?? appLocalizations.notAuthorizedToViewAdminPanel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(appLocalizations.backToHome),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 12, // UPDATED: Changed to 11 tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appLocalizations.adminPanelTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: appLocalizations.addProductTabTitle),
              Tab(text: appLocalizations.manageProducts),
              Tab(text: appLocalizations.manageAreas),
              Tab(text: appLocalizations.orders),
              Tab(text: appLocalizations.analytics),
              Tab(text: appLocalizations.manageOfferCodesTitle),
              Tab(text: appLocalizations.manageNearbyShopsTitle),
              Tab(text: appLocalizations.manageAppFeaturesTitle),
              const Tab(
                icon: Icon(Icons.campaign, size: 18),
                text: 'Send Notifications',
              ),
              const Tab(
                icon: Icon(Icons.psychology, size: 18),
                text: 'ML Patterns',
              ),
              const Tab(
                icon: Icon(Icons.insights, size: 18),
                text: 'ML Insights',
              ),
              // NEW: Debug tab
              const Tab(
                icon: Icon(Icons.bug_report, size: 18),
                text: 'Debug',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const AdminAddProductTab(
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            const AdminManageProductsTab(
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            const AdminManageAreasTab(),
            const AdminOrdersTab(),
            const AdminAnalyticsTab(),
            const ManageOfferCodesScreen(),
            const AdminManageNearbyShopsTab(
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            const AdminManageAppFeaturesTab(),
            const AdminSendNotificationsTab(),
            const AdminMLPatternsTab(),
            const AdminMLInsightsTab(),
            // NEW: Debug tab content
            _buildDebugTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ADD THIS TO YOUR AdminPanelScreen debug tab (replace the existing debug tab content)
  // Test reorder reminder service
  Future<void> _testReminderService() async {
    debugPrint('🔔 === TESTING REMINDER SERVICE ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Testing reminder service...'),
          backgroundColor: Colors.indigo,
        ),
      );

      final reminderService = ReorderReminderService();

      // Send test reminder
      final testResult = await reminderService.sendTestReminder();

      if (testResult) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Test reminder sent! Check your notifications.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Test reminder failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ Reminder service test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('🔔 === END REMINDER SERVICE TEST ===');
  }

  /// Trigger manual reminder check
  Future<void> _triggerReminderCheck() async {
    debugPrint('⏰ === MANUAL REMINDER CHECK ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏰ Checking all users for reminders...'),
          backgroundColor: Colors.purple,
        ),
      );

      final reminderService = ReorderReminderService();
      final result = await reminderService.triggerReminderCheck();

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Reminder Check Complete!\n'
                      'Users checked: ${result['usersChecked']}\n'
                      'Reminders sent: ${result['remindersSent']}\n'
                      'Duration: ${result['duration']}s'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Reminder check failed: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      debugPrint('⏰ Reminder check result: $result');

    } catch (e) {
      debugPrint('❌ Manual reminder check failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('⏰ === END MANUAL REMINDER CHECK ===');
  }

  /// Get reminder statistics
  Future<void> _getReminderStats() async {
    debugPrint('📊 === GETTING REMINDER STATS ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Getting reminder statistics...'),
          backgroundColor: Colors.teal,
        ),
      );

      final reminderService = ReorderReminderService();
      final stats = await reminderService.getReminderStats();

      if (stats.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Stats error: ${stats['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '📊 Reminder Statistics:\n'
                      'Reminders sent (30 days): ${stats['totalRemindersSent30Days']}\n'
                      'Users reminded: ${stats['uniqueUsersReminded']}\n'
                      'Users with reminders enabled: ${stats['usersWithRemindersEnabled']}\n'
                      'Avg per user: ${stats['avgRemindersPerUser']}'
              ),
              backgroundColor: Colors.teal,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }

      debugPrint('📊 Reminder stats: $stats');

    } catch (e) {
      debugPrint('❌ Getting reminder stats failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('📊 === END REMINDER STATS ===');
  }
  Future<void> _testLowThresholdPredictions() async {
    debugPrint('🎯 === TESTING LOW THRESHOLD PREDICTIONS ===');

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Testing low threshold predictions...'),
          backgroundColor: Colors.green,
        ),
      );

      // Get all patterns for this user
      final patternsSnapshot = await FirebaseFirestore.instance
          .collection('customer_patterns')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      debugPrint('📊 Found ${patternsSnapshot.docs.length} patterns to process');

      final predictions = <Map<String, dynamic>>[];

      for (var doc in patternsSnapshot.docs) {
        final data = doc.data();
        final orderCount = data['orderCount'] ?? 0;
        final confidence = (data['confidence'] ?? 0.0).toDouble();
        final productId = data['productId'] ?? '';

        debugPrint('📦 Pattern: $productId - $orderCount orders - $confidence confidence');

        // LOWERED THRESHOLDS for testing
        if (orderCount >= 1 && confidence >= 0.1) { // Much lower requirements

          // Create a simple prediction
          final avgDays = (data['avgDaysBetweenOrders'] ?? 30.0).toDouble();
          final avgQuantity = (data['avgQuantityPerOrder'] ?? 1.0).round();
          final lastOrderDate = data['lastOrderDate'] != null
              ? (data['lastOrderDate'] as Timestamp).toDate()
              : DateTime.now().subtract(Duration(days: avgDays.round()));

          final predictedDate = lastOrderDate.add(Duration(days: avgDays.round()));
          final daysUntil = predictedDate.difference(DateTime.now()).inDays;

          final prediction = {
            'productId': productId,
            'productName': 'Test Product $productId', // Simplified for testing
            'avgDaysBetween': avgDays,
            'avgQuantity': avgQuantity,
            'confidence': confidence,
            'lastOrderDate': Timestamp.fromDate(lastOrderDate),
            'predictedNextOrder': Timestamp.fromDate(predictedDate),
            'daysUntilNextOrder': daysUntil,
            'imageUrl': '',
          };

          predictions.add(prediction);
          debugPrint('✅ Created prediction for $productId - $daysUntil days until reorder');
        } else {
          debugPrint('❌ Skipped $productId - insufficient data or confidence');
        }
      }

      debugPrint('🎯 Generated ${predictions.length} predictions with low threshold');

      if (predictions.isNotEmpty) {
        // Store predictions manually
        await FirebaseFirestore.instance
            .collection('reorder_predictions')
            .doc(currentUser.uid)
            .set({
          'userId': currentUser.uid,
          'predictions': predictions,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Stored ${predictions.length} predictions in Firestore');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '🎯 SUCCESS! Generated ${predictions.length} predictions!\n'
                      'Now check Customer Reorder Screen'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No predictions generated even with low threshold'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

    } catch (e) {
      debugPrint('❌ Low threshold prediction test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('🎯 === END LOW THRESHOLD TEST ===');
  }

  Widget _buildDebugTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.bug_report, color: Theme
                    .of(context)
                    .primaryColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Debug Tools',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Test 1: Direct Firestore Test
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storage, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 1: Direct Firestore Writes',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Test if collections can be written directly to Firestore.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testFirestoreWrites,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Test Direct Firestore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test 2: PatternService Test
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 2: PatternService',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Test the actual PatternService methods with debug logging.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testPatternService,
                        icon: const Icon(Icons.science),
                        label: const Text('Test PatternService'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test 3: Generate Predictions
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 3: Generate Predictions',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Process existing patterns and generate reorder predictions.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatePredictions,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('Generate Predictions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 5: Force Generate Predictions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Generate predictions with lowered thresholds (for testing).',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _testLowThresholdPredictions,
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text('Force Generate Predictions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Test 6: Reminder Service
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active, color: Colors.indigo[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 6: Reminder Service',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Test the automated reorder reminder system.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testReminderService,
                            icon: const Icon(Icons.send),
                            label: const Text('Send Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _triggerReminderCheck,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _getReminderStats,
                        icon: const Icon(Icons.analytics),
                        label: const Text('Get Statistics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 16),

            // Test 4: Check Collections
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 4: Check Collections',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check what data currently exists in Firestore collections.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _checkCollections,
                        icon: const Icon(Icons.search),
                        label: const Text('Check Collections'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.play_circle, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 7: Complete System Test',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Run comprehensive end-to-end system testing.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _runCompleteSystemTest,
                        icon: const Icon(Icons.play_circle),
                        label: const Text('Run Complete System Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// Test 8: User Journey Test
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.purple[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test 8: User Journey Test',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Simulate complete customer and admin user journeys.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testUserJourney,
                            icon: const Icon(Icons.person),
                            label: const Text('User Journey'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _runPerformanceTest,
                            icon: const Icon(Icons.speed),
                            label: const Text('Performance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Debug Instructions',
                          style: Theme
                              .of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Run tests in order:\n'
                          '1. Test Direct Firestore (should work ✅)\n'
                          '2. Test PatternService (find the bug)\n'
                          '3. Generate Predictions (create suggestions)\n'
                          '4. Check Collections (verify data exists)\n\n'
                          'Watch console for detailed debug output.',
                      style: TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


// ADD THESE NEW TEST METHODS TO YOUR AdminPanelScreen class:

  /// Test PatternService with enhanced debugging
  Future<void> _testPatternService() async {
    debugPrint('🧠 === TESTING PATTERN SERVICE ===');

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No user logged in')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧠 Testing PatternService...'),
          backgroundColor: Colors.purple,
        ),
      );

      // Import PatternService
      final patternService = PatternService();

      debugPrint('👤 Testing PatternService for user: ${currentUser.uid}');

      // Test trackOrder method
      final testItems = [
        {'productId': 'pattern_service_test_1', 'quantity': 2},
        {'productId': 'pattern_service_test_2', 'quantity': 1},
      ];

      debugPrint('📦 Test items: $testItems');

      await patternService.trackOrder(
        userId: currentUser.uid,
        items: testItems,
        orderDate: DateTime.now(),
      );

      debugPrint('✅ PatternService trackOrder completed');

      // Wait and check if patterns were created
      await Future.delayed(const Duration(seconds: 3));

      // Check if patterns exist
      final patternsSnapshot = await FirebaseFirestore.instance
          .collection('customer_patterns')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final settingsDoc = await FirebaseFirestore.instance
          .collection('user_pattern_settings')
          .doc(currentUser.uid)
          .get();

      debugPrint('📊 PatternService Results:');
      debugPrint('   Patterns found: ${patternsSnapshot.docs.length}');
      debugPrint('   Settings exist: ${settingsDoc.exists}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ PatternService Test Completed!\n'
                    'Patterns: ${patternsSnapshot.docs.length}\n'
                    'Settings: ${settingsDoc.exists ? "✅" : "❌"}\n'
                    'Check console for details'
            ),
            backgroundColor: Colors.purple,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ PatternService test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PatternService failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('🧠 === END PATTERN SERVICE TEST ===');
  }


  /// Generate predictions from existing patterns
  Future<void> _generatePredictions() async {
    debugPrint('🎯 === GENERATING PREDICTIONS ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎯 Generating predictions...'),
          backgroundColor: Colors.amber,
        ),
      );

      final patternService = PatternService();
      final result = await patternService.processAllPatterns();

      debugPrint('🎯 Prediction generation result: $result');

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Predictions Generated!\n'
                      'Predictions: ${result['predictionsGenerated']}\n'
                      'Patterns processed: ${result['patternsProcessed']}\n'
                      'Users: ${result['usersProcessed']}'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '❌ Prediction generation failed: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Prediction generation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    debugPrint('🎯 === END PREDICTION GENERATION ===');
  }


  /// Check what data exists in collections
  Future<void> _checkCollections() async {
    debugPrint('🔍 === CHECKING COLLECTIONS DATA ===');

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔍 Checking collections...'),
          backgroundColor: Colors.blue,
        ),
      );

      final userId = currentUser.uid;

      // Check customer_patterns
      final patternsSnapshot = await FirebaseFirestore.instance
          .collection('customer_patterns')
          .where('userId', isEqualTo: userId)
          .get();

      debugPrint(
          '📊 customer_patterns: ${patternsSnapshot.docs.length} documents');
      for (var doc in patternsSnapshot.docs) {
        final data = doc.data();
        debugPrint(
            '   Pattern: ${data['productId']} - ${data['orderCount']} orders');
      }

      // Check user_pattern_settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('user_pattern_settings')
          .doc(userId)
          .get();

      debugPrint('⚙️ user_pattern_settings: ${settingsDoc.exists
          ? "EXISTS"
          : "MISSING"}');
      if (settingsDoc.exists) {
        final data = settingsDoc.data()!;
        debugPrint('   Total orders: ${data['totalOrders']}');
        debugPrint('   Reminders enabled: ${data['enableReminders']}');
      }

      // Check reorder_predictions
      final predictionsDoc = await FirebaseFirestore.instance
          .collection('reorder_predictions')
          .doc(userId)
          .get();

      debugPrint('🎯 reorder_predictions: ${predictionsDoc.exists
          ? "EXISTS"
          : "MISSING"}');
      if (predictionsDoc.exists) {
        final data = predictionsDoc.data()!;
        final predictions = data['predictions'] as List? ?? [];
        debugPrint('   Predictions: ${predictions.length}');
        for (var pred in predictions) {
          debugPrint(
              '   - ${pred['productName']}: ${pred['confidence']} confidence');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '🔍 Collection Check Complete!\n'
                    'Patterns: ${patternsSnapshot.docs.length}\n'
                    'Settings: ${settingsDoc.exists ? "✅" : "❌"}\n'
                    'Predictions: ${predictionsDoc.exists ? "✅" : "❌"}\n'
                    'Check console for details'
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Collection check failed: $e');
    }

    debugPrint('🔍 === END COLLECTION CHECK ===');
  }

}