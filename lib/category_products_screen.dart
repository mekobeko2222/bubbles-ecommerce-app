import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import ProductDetailScreen
import 'package:bubbles_ecommerce_app/home_screen.dart'; // To use ProductCard widget
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart'; // Import generated localizations
import 'package:bubbles_ecommerce_app/models/product.dart'; // Import Product model

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;

  const CategoryProductsScreen({super.key, required this.categoryName});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppLocalizations appLocalizations; // Declare AppLocalizations instance

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appLocalizations = AppLocalizations.of(context)!; // Initialize AppLocalizations
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${appLocalizations.productsIn} ${widget.categoryName}'), // Localized
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').where('category', isEqualTo: widget.categoryName).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(appLocalizations.loadingProducts), // Localized
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    appLocalizations.errorLoadingProducts, // Localized
                    textAlign: TextAlign.center,
                  ),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    appLocalizations.noProductsInCategory(widget.categoryName), // Corrected to positional argument
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    appLocalizations.checkBackLater, // Localized
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs.map((doc) {
            return Product.fromFirestore(doc); // Convert DocumentSnapshot to Product object
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7, // Adjusted to match ProductCard aspect ratio, assuming it now fits well
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard( // Pass the entire Product object
                product: product,
              );
            },
          );
        },
      ),
    );
  }
}
