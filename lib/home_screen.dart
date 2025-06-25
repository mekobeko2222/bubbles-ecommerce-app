import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import 'package:bubbles_ecommerce_app/app_drawer.dart';
import 'package:bubbles_ecommerce_app/basket_screen.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/wishlist_manager.dart';
import 'package:bubbles_ecommerce_app/product_detail_screen.dart';
import 'package:bubbles_ecommerce_app/category_products_screen.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';

class HomeScreen extends StatefulWidget {
  final String userEmail;
  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isAdmin = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  // PAGINATION VARIABLES
  static const int _productsPerPage = 20;
  int _currentProductsLimit = _productsPerPage;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;
  List<DocumentSnapshot> _allProducts = [];
  DocumentSnapshot? _lastDocument;

  // PERFORMANCE TRACKING
  DateTime? _loadStartTime;
  int _productsLoadedCount = 0;
  bool _isLoadingProducts = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_onSearchChanged);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_slideController);

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
      });
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!mounted) return;
      if (userDoc.exists) {
        setState(() {
          _isAdmin = userDoc.data()?['isAdmin'] ?? false;
        });
      } else {
        setState(() {
          _isAdmin = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking admin status: $e')),
        );
      }
      setState(() {
        _isAdmin = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
      // Reset pagination when search changes
      _resetPagination();
    });
  }

  void _resetPagination() {
    _currentProductsLimit = _productsPerPage;
    _hasMoreProducts = true;
    _allProducts.clear();
    _lastDocument = null;
    _isLoadingMore = false;
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      Query query;
      if (_searchQuery.isEmpty) {
        query = _firestore
            .collection('products')
            .where('isOffer', isEqualTo: true)
            .limit(_productsPerPage);
      } else {
        query = _firestore
            .collection('products')
            .where('nameKeywords', arrayContainsAny: _searchQuery.split(' ').where((w) => w.isNotEmpty).toList())
            .limit(_productsPerPage);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;

        // Add new products to the list
        for (var doc in querySnapshot.docs) {
          if (_searchQuery.isEmpty) {
            _allProducts.add(doc);
          } else {
            // Filter products client-side for search
            final product = Product.fromFirestore(doc);
            if (product.name.toLowerCase().contains(_searchQuery)) {
              _allProducts.add(doc);
            }
          }
        }

        // Check if we have more products to load
        if (querySnapshot.docs.length < _productsPerPage) {
          _hasMoreProducts = false;
        }
      } else {
        _hasMoreProducts = false;
      }

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      developer.log('Error loading more products: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: appLocalizations.searchProducts,
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        )
            : Text(appLocalizations.homeScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                  _resetPagination();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          // In your AppBar actions, replace the existing basket icon with:
          Consumer<BasketManager>(
            builder: (context, basket, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_basket),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BasketScreen()),
                      );
                    },
                  ),
                  if (basket.totalQuantity > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${basket.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: AppDrawer(userEmail: widget.userEmail),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    appLocalizations.shopByCategory,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('categories').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text(appLocalizations.noCategoriesAvailable));
                      }

                      final categories = snapshot.data!.docs;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final categoryDoc = categories[index];
                          final categoryData = categoryDoc.data() as Map<String, dynamic>;
                          final categoryName = categoryData['name'] ?? 'Category';
                          final categoryIcon = categoryData['icon'] ?? '🛒';
                          final categoryImageUrl = categoryData['imageUrl'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductsScreen(categoryName: categoryName),
                                ),
                              );
                            },
                            child: Container(
                              width: 110,
                              margin: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child: categoryImageUrl.isNotEmpty
                                              ? Image.network(
                                            categoryImageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            cacheWidth: 120, // Optimize image loading
                                            cacheHeight: 120,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 60,
                                                height: 60,
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                child: Center(
                                                  child: Text(
                                                    categoryIcon,
                                                    style: const TextStyle(fontSize: 30),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                              : Container(
                                            width: 60,
                                            height: 60,
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                            child: Center(
                                              child: Text(
                                                categoryIcon,
                                                style: const TextStyle(fontSize: 30),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Products Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _isSearching ? appLocalizations.searchResults : appLocalizations.productsOnOffer,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                // Products Grid with Pagination
                StreamBuilder<QuerySnapshot>(
                  stream: _searchQuery.isEmpty
                      ? _firestore.collection('products').where('isOffer', isEqualTo: true).limit(_productsPerPage).snapshots()
                      : _firestore.collection('products')
                      .where('nameKeywords', arrayContainsAny: _searchQuery.split(' ').where((w) => w.isNotEmpty).toList())
                      .limit(_productsPerPage)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Performance tracking
                    if (snapshot.connectionState == ConnectionState.waiting && _loadStartTime == null) {
                      _loadStartTime = DateTime.now();
                      _isLoadingProducts = true;
                      developer.log('Started loading products at: ${_loadStartTime}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Loading products..."),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    // Performance tracking when data arrives
                    if (snapshot.hasData && _loadStartTime != null && _isLoadingProducts) {
                      final loadEndTime = DateTime.now();
                      final loadDuration = loadEndTime.difference(_loadStartTime!);
                      _productsLoadedCount = snapshot.data!.docs.length;
                      _isLoadingProducts = false;

                      developer.log('Products loaded successfully!');
                      developer.log('Load duration: ${loadDuration.inMilliseconds}ms');
                      developer.log('Products count: $_productsLoadedCount');

                      // Show performance info in debug mode only
                      if (kDebugMode) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Loaded $_productsLoadedCount products in ${loadDuration.inMilliseconds}ms'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                      }

                      // Reset timer for next load
                      _loadStartTime = null;
                    }

                    // Combine initial load with loaded products
                    List<DocumentSnapshot> displayProducts = [];
                    if (snapshot.hasData) {
                      displayProducts.addAll(snapshot.data!.docs);
                    }
                    displayProducts.addAll(_allProducts);

                    // Remove duplicates based on product ID
                    final uniqueProducts = <String, DocumentSnapshot>{};
                    for (var product in displayProducts) {
                      uniqueProducts[product.id] = product;
                    }
                    final productsList = uniqueProducts.values.toList();

                    // Filter for search
                    List<DocumentSnapshot> filteredProducts;
                    if (_searchQuery.isEmpty) {
                      filteredProducts = productsList;
                    } else {
                      filteredProducts = productsList.where((doc) {
                        final product = Product.fromFirestore(doc);
                        return product.name.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                _isSearching ? appLocalizations.noProductsFoundMatchingFilters : appLocalizations.noOffersFound,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              if (_isSearching) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Try searching with different keywords',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Products count indicator
                        if (filteredProducts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                if (_hasMoreProducts) ...[
                                  const Spacer(),
                                  Text(
                                    'Load more to see all products',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                        // Products Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.65,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = Product.fromFirestore(filteredProducts[index]);
                            return ProductCard(product: product);
                          },
                        ),

                        // Load More Button
                        if (_hasMoreProducts && !_isSearching) // Don't show for search results
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoadingMore ? null : _loadMoreProducts,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: _isLoadingMore
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Icon(Icons.add_shopping_cart),
                                label: Text(_isLoadingMore ? 'Loading more products...' : 'Load More Products'),
                              ),
                            ),
                          ),

                        // End of products indicator
                        if (!_hasMoreProducts && filteredProducts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'You\'ve seen all available products!',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ProductCard Widget with optimized rebuilds to prevent screen refresh
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    final double discountedPrice = product.price * (1 - (product.discount / 100));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with wishlist button
            Expanded(
              flex: 3,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    // Product Image with optimized loading
                    product.imageUrls.isNotEmpty
                        ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.imageUrls[0],
                        key: ValueKey(product.imageUrls[0]),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        // Removed cacheWidth for faster loading
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('ProductCard Image.network error for URL: ${product.imageUrls[0]} - Error: $error');
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      ),
                    ),

                    // Wishlist Heart Button - Only listen to WishlistManager changes
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<WishlistManager>(
                        builder: (context, wishlistManager, child) {
                          final isInWishlist = wishlistManager.isInWishlist(product.id);

                          return GestureDetector(
                            onTap: () async {
                              try {
                                final success = await wishlistManager.toggleWishlist(product);
                                if (context.mounted && success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isInWishlist ? 'Removed from wishlist' : 'Added to wishlist',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                color: isInWishlist ? Colors.red : Colors.grey[600],
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Discount Badge
                    if (product.discount > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.discount}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Content Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Expanded(
                      flex: 2,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Price Section
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'EGP ${discountedPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.discount > 0) ...[
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'EGP ${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Stock Status
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Icon(
                            product.quantity > 0 ? Icons.check_circle_outline : Icons.cancel_outlined,
                            color: product.quantity > 0 ? Colors.green : Theme.of(context).colorScheme.error,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.quantity > 0
                                  ? appLocalizations.inStock(product.quantity)
                                  : appLocalizations.outOfStock,
                              style: TextStyle(
                                color: product.quantity > 0 ? Colors.green : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Add to Basket Button - Use Consumer to avoid rebuilding entire card
                    Consumer<BasketManager>(
                      builder: (context, basket, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(
                            onPressed: product.quantity > 0
                                ? () {
                              // Use listen: false to prevent rebuilds
                              context.read<BasketManager>().addItem(product, 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(appLocalizations.uniqueItemsAddedToBasket(1))),
                              );
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                product.quantity > 0 ? appLocalizations.addToBasket : appLocalizations.outOfStock,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        );
                      },
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
}