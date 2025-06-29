import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:bubbles_ecommerce_app/basket_screen.dart';
import 'package:bubbles_ecommerce_app/admin_panel_screen.dart';
import 'package:bubbles_ecommerce_app/my_orders_screen.dart';
import 'package:bubbles_ecommerce_app/user_profile_screen.dart';
import "package:bubbles_ecommerce_app/contact_us_screen.dart";
// Import the new screens
import 'package:bubbles_ecommerce_app/nearby_shops_screen.dart';
import 'package:bubbles_ecommerce_app/support_small_business_screen.dart';
import 'package:bubbles_ecommerce_app/pet_adoption_screen.dart';
import 'package:bubbles_ecommerce_app/locale_provider.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/home_screen.dart';
import 'package:bubbles_ecommerce_app/customer_reorder_screen.dart';
import 'package:bubbles_ecommerce_app/wishlist_screen.dart';

class AppDrawer extends StatefulWidget {
  final String userEmail;

  const AppDrawer({
    super.key,
    required this.userEmail,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isAdmin = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
      debugPrint('AppDrawer: No current user logged in. _isAdmin set to false.');
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!mounted) return;
      setState(() {
        _isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] == true);
      });
      debugPrint('AppDrawer: Admin status for ${currentUser.email}: $_isAdmin');
      if (!userDoc.exists) {
        debugPrint('AppDrawer: User document for ${currentUser.uid} does not exist in Firestore.');
      } else {
        debugPrint('AppDrawer: User document data: ${userDoc.data()}');
      }
    } catch (e) {
      debugPrint('Error checking admin status in AppDrawer: $e');
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ?? appLocalizations.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              widget.userEmail,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null && FirebaseAuth.instance.currentUser!.photoURL!.isNotEmpty
                  ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                  : null,
              backgroundColor: Colors.white24,
              child: (FirebaseAuth.instance.currentUser?.photoURL == null || FirebaseAuth.instance.currentUser!.photoURL!.isEmpty)
                  ? const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              )
                  : null,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1549880338-65ddcdfd017b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=MnwxfDB8MXxyYW5kb218MHx8bW91bnRhaW5zLHdhbGxwYXBlcnx8fHx8fDE3MTc5NTI3MDc&ixlib=rb-4.0.3&q=80&w=1080',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black12,
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // HOME
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(appLocalizations.homeScreenTitle),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen(userEmail: widget.userEmail)),
                      (Route<dynamic> route) => false,
                );
              }
            },
          ),

          // PROFILE
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black),
            title: Text(appLocalizations.userProfileTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UserProfileScreen()),
              );
            },
          ),

          // BASKET
          ListTile(
            leading: const Icon(Icons.shopping_basket, color: Colors.orange),
            title: Text(appLocalizations.myBasketTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BasketScreen()),
              );
            },
          ),

          // WISHLIST
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(appLocalizations.wishlistTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WishlistScreen()),
              );
            },
          ),

          // MY ORDERS
          ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
            title: Text(appLocalizations.myOrdersTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
              );
            },
          ),

          // SMART REORDER - Fixed with proper title and icon
          ListTile(
            leading: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
            title: const Text('Smart Reorder'), // You may want to add this to your localizations
            subtitle: const Text('AI-powered suggestions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CustomerReorderScreen()),
              );
            },
          ),

          const Divider(),

          // NEARBY SHOPS (Always visible)
          ListTile(
            leading: const Icon(Icons.store_mall_directory, color: Colors.green),
            title: Text(appLocalizations.nearbyShopsTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NearbyShopsScreen()),
              );
            },
          ),

          // SUPPORT SMALL BUSINESSES (Toggleable from admin)
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('app_settings')
                .doc('features')
                .snapshots(),
            builder: (context, snapshot) {
              // Default to false if no data or error
              bool showSupportBusiness = false;
              String customTitle = appLocalizations.supportSmallBusinessTitle;
              String customIcon = 'business';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                showSupportBusiness = data?['support_small_business_enabled'] ?? false;
                customTitle = data?['support_small_business_title'] ?? appLocalizations.supportSmallBusinessTitle;
                customIcon = data?['support_small_business_icon'] ?? 'business';
              }

              // Only show if enabled by admin
              if (!showSupportBusiness) {
                return const SizedBox.shrink();
              }

              // Map icon name to IconData
              IconData iconData;
              switch (customIcon) {
                case 'favorite':
                  iconData = Icons.favorite;
                  break;
                case 'business':
                  iconData = Icons.business;
                  break;
                case 'handshake':
                  iconData = Icons.handshake;
                  break;
                case 'support':
                  iconData = Icons.support;
                  break;
                case 'local_offer':
                  iconData = Icons.local_offer;
                  break;
                case 'volunteer_activism':
                  iconData = Icons.volunteer_activism;
                  break;
                case 'group_work':
                  iconData = Icons.group_work;
                  break;
                case 'store':
                  iconData = Icons.store;
                  break;
                default:
                  iconData = Icons.business;
              }

              return ListTile(
                leading: Icon(iconData, color: Colors.purple),
                title: Text(customTitle),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SupportSmallBusinessScreen()),
                  );
                },
              );
            },
          ),

          // PET ADOPTION (Always visible)
          ListTile(
            leading: const Icon(Icons.pets, color: Colors.orange),
            title: Text(appLocalizations.petAdoptionTitle),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PetAdoptionScreen()),
              );
            },
          ),

          const Divider(),

          // CONTACT US
          ListTile(
            leading: const Icon(Icons.contact_mail, color: Colors.green),
            title: Text(appLocalizations.contactUs),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ContactUsScreen()),
              );
            },
          ),

          const Divider(),

          // ADMIN PANEL (Only for admins)
          if (_isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(appLocalizations.adminPanelTitle),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),

          // LANGUAGE TOGGLE
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(
              localeProvider.locale?.languageCode == 'en' ? 'اللغة العربية' : 'English Language',
            ),
            onTap: () {
              Navigator.pop(context);
              localeProvider.toggleLocale();
            },
          ),

          // LOGOUT
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(appLocalizations.logout),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}