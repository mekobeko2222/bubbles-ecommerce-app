import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/config/app_config.dart';

// Corrected imports for admin tabs from the admin_tabs directory
import 'admin_tabs/admin_add_product_tab.dart';
import 'admin_tabs/admin_manage_products_tab.dart';
import 'admin_tabs/admin_manage_areas_tab.dart';
import 'admin_tabs/admin_orders_tab.dart';
import 'admin_tabs/admin_analytics_tab.dart';
import 'admin_tabs/manage_offer_codes_screen.dart';
import 'admin_tabs/admin_manage_nearby_shops_tab.dart';
import 'admin_tabs/admin_manage_app_features_tab.dart'; // NEW TAB

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
    _tabController = TabController(length: 8, vsync: this); // Updated to 8 tabs
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

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalizations.adminPanelTitle),
          backgroundColor: Theme.of(context).colorScheme.primary,
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
          backgroundColor: Theme.of(context).colorScheme.primary,
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 8, // Updated to 8 tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appLocalizations.adminPanelTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.7),
            indicatorColor: Colors.white,
            tabAlignment: TabAlignment.start, // Align tabs to start for better scrolling
            tabs: [
              Tab(text: appLocalizations.addProductTabTitle),
              Tab(text: appLocalizations.manageProducts),
              Tab(text: appLocalizations.manageAreas),
              Tab(text: appLocalizations.orders),
              Tab(text: appLocalizations.analytics),
              Tab(text: appLocalizations.manageOfferCodesTitle),
              Tab(text: appLocalizations.manageNearbyShopsTitle), // Use localized text
              Tab(text: appLocalizations.manageAppFeaturesTitle), // NEW TAB with localization
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            AdminAddProductTab(
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            AdminManageProductsTab(
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            AdminManageAreasTab(),
            AdminOrdersTab(),
            AdminAnalyticsTab(),
            ManageOfferCodesScreen(),
            AdminManageNearbyShopsTab( // Updated to support both collections
              cloudinaryCloudName: AppConfig.cloudinaryCloudName,
              cloudinaryUploadPreset: AppConfig.cloudinaryUploadPreset,
            ),
            AdminManageAppFeaturesTab(), // NEW TAB
          ],
        ),
      ),
    );
  }
}