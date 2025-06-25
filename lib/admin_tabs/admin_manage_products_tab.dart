import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/admin_tabs/edit_product_dialog.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

class AdminManageProductsTab extends StatefulWidget {
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;

  const AdminManageProductsTab({
    super.key,
    required this.cloudinaryCloudName,
    required this.cloudinaryUploadPreset,
  });

  @override
  State<AdminManageProductsTab> createState() => _AdminManageProductsTabState();
}

class _AdminManageProductsTabState extends State<AdminManageProductsTab> {
  final _productSearchController = TextEditingController();
  String? _productFilterCategory;
  bool _isProductFiltering = false;
  String _sortBy = 'name'; // Default sort
  bool _isAscending = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  late AppLocalizations _appLocalizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    super.dispose();
  }

  void _clearProductFilters() {
    setState(() {
      _productSearchController.clear();
      _productFilterCategory = null;
      _isProductFiltering = false;
    });
    ErrorHandler.showInfoSnackBar(context, 'Filters cleared');
  }

  void _showEditProductDialog(DocumentSnapshot productDoc) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EditProductDialog(
        productDoc: productDoc,
        appLocalizations: _appLocalizations,
        cloudinaryCloudName: widget.cloudinaryCloudName,
        cloudinaryUploadPreset: widget.cloudinaryUploadPreset,
      ),
    );
  }

  Future<void> _deleteProduct(String productId, String productName) async {
    final bool confirmed = await ErrorHandler.showConfirmationDialog(
      context,
      title: _appLocalizations.confirmDeletion,
      content: _appLocalizations.areYouSureDeleteProductAdmin(productName),
      confirmText: _appLocalizations.delete,
      cancelText: _appLocalizations.cancel,
      isDestructive: true,
    );

    if (confirmed) {
      await ErrorHandler.handleAsyncError(
        context,
            () async {
          // Fetch product document to get image URLs
          final productRef = _firestore.collection('products').doc(productId);
          final productDoc = await productRef.get();

          if (productDoc.exists) {
            final data = productDoc.data() as Map<String, dynamic>;
            final List<dynamic> imageUrls = data['imageUrls'] ?? [];

            // Delete images from Firebase Storage (if they are Firebase Storage URLs)
            for (var url in imageUrls) {
              try {
                if (url.toString().contains('firebasestorage.googleapis.com')) {
                  final ref = _firebaseStorage.refFromURL(url as String);
                  await ref.delete();
                }
              } catch (e) {
                // Handle cases where image might not exist or other storage errors
                debugPrint('Error deleting image from storage: $e');
              }
            }
          }

          // Delete product document from Firestore
          await productRef.delete();
        },
        successMessage: _appLocalizations.productDeletedSuccessfully(productName),
        errorPrefix: 'Failed to delete product',
      );
    }
  }

  Stream<List<Map<String, String>>> _fetchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'id': doc.id,
          'name': data['name']?.toString() ?? doc.id, // Convert to String and use name field or fallback to ID
        };
      }).toList();
    });
  }

  Query<Map<String, dynamic>> _buildProductQuery() {
    Query<Map<String, dynamic>> query = _firestore.collection('products');

    // Apply category filter
    if (_productFilterCategory != null && _productFilterCategory != 'All') {
      query = query.where('category', isEqualTo: _productFilterCategory);
    }

    // Apply sorting
    query = query.orderBy(_sortBy, descending: !_isAscending);

    return query;
  }

  List<DocumentSnapshot> _filterProducts(List<DocumentSnapshot> products) {
    if (_productSearchController.text.isEmpty) {
      return products;
    }

    final searchQuery = _productSearchController.text.toLowerCase();
    return products.where((doc) {
      final productData = doc.data() as Map<String, dynamic>;
      final productName = productData['name']?.toLowerCase() ?? '';
      return productName.contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with statistics
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final totalProducts = snapshot.data!.docs.length;
              final inStockProducts = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ((data['quantity'] as num?)?.toInt() ?? 0) > 0;
              }).length;
              final offersCount = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isOffer'] == true;
              }).length;

              return Row(
                children: [
                  Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Overview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: $totalProducts • In Stock: $inStockProducts • Offers: $offersCount',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Search and Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _productSearchController,
                decoration: InputDecoration(
                  labelText: 'Search products...',
                  hintText: 'Enter product name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _productSearchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _productSearchController.clear();
                      setState(() {
                        _isProductFiltering = _productFilterCategory != null;
                      });
                    },
                  )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _isProductFiltering = value.isNotEmpty || _productFilterCategory != null;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Filters Row
              Row(
                children: [
                  // Category Filter
                  Expanded(
                    flex: 3,
                    child: StreamBuilder<List<Map<String, String>>>(
                      stream: _fetchCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(
                            height: 48,
                            child: Text(
                              'Error loading categories',
                              style: TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox(
                            height: 48,
                            child: Text(
                              'No categories',
                              style: TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }

                        return DropdownButtonFormField<String?>(
                          value: _productFilterCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Categories'),
                            ),
                            ...snapshot.data!.map((category) {
                              return DropdownMenuItem(
                                value: category['id'],
                                child: Text(
                                  category['name']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _productFilterCategory = value;
                              _isProductFiltering = value != null || _productSearchController.text.isNotEmpty;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sort Options
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _sortBy,
                      decoration: InputDecoration(
                        labelText: 'Sort',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'price', child: Text('Price')),
                        DropdownMenuItem(value: 'quantity', child: Text('Stock')),
                        DropdownMenuItem(value: 'createdAt', child: Text('Date')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Sort Direction
                  IconButton(
                    icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      setState(() {
                        _isAscending = !_isAscending;
                      });
                    },
                    tooltip: _isAscending ? 'Ascending' : 'Descending',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),

              // Clear Filters Button
              if (_isProductFiltering)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _clearProductFilters,
                    icon: const Icon(Icons.clear),
                    label: Text(_appLocalizations.clearFilters),
                  ),
                ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildProductQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_appLocalizations.loadingProducts),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        _appLocalizations.errorLoadingProducts,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString()),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {}); // Trigger rebuild
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(_appLocalizations.tryAgain),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No products found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      if (_isProductFiltering) ...[
                        const SizedBox(height: 8),
                        Text(
                          _appLocalizations.noProductsFoundMatchingFilters,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearProductFilters,
                          icon: const Icon(Icons.clear),
                          label: Text(_appLocalizations.clearFilters),
                        ),
                      ],
                    ],
                  ),
                );
              }

              final filteredProducts = _filterProducts(snapshot.data!.docs);

              if (filteredProducts.isEmpty && _isProductFiltering) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_appLocalizations.noProductsFoundMatchingFilters),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _clearProductFilters,
                        icon: const Icon(Icons.clear),
                        label: Text(_appLocalizations.clearFilters),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Trigger rebuild
                  ErrorHandler.showInfoSnackBar(context, 'Products refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final productDoc = filteredProducts[index];
                    final productData = productDoc.data() as Map<String, dynamic>;
                    final List<String> imageUrls = (productData['imageUrls'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ?? [];

                    final bool isLowStock = ((productData['quantity'] as num?)?.toInt() ?? 0) < 5;
                    final bool isOutOfStock = ((productData['quantity'] as num?)?.toInt() ?? 0) == 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: isOutOfStock
                              ? Border.all(color: Colors.red, width: 2)
                              : isLowStock
                              ? Border.all(color: Colors.orange, width: 1)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(12, 12, 50, 12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrls.isNotEmpty
                                    ? Image.network(
                                  imageUrls[0],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                    );
                                  },
                                )
                                    : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      productData['name'] ?? _appLocalizations.unnamedProduct,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (productData['isOffer'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'OFFER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('${AppConfig.currency} ${(productData['price'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                                      if (((productData['discount'] as num?)?.toInt() ?? 0) > 0) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '${(productData['discount'] as num?)?.toInt() ?? 0}% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        isOutOfStock
                                            ? Icons.error
                                            : isLowStock
                                            ? Icons.warning
                                            : Icons.check_circle,
                                        size: 14,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : isLowStock
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_appLocalizations.quantity}: ${(productData['quantity'] as num?)?.toInt() ?? 0}',
                                        style: TextStyle(
                                          color: isOutOfStock
                                              ? Colors.red
                                              : isLowStock
                                              ? Colors.orange
                                              : Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.category, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: StreamBuilder<DocumentSnapshot>(
                                          stream: productData['category'] != null
                                              ? _firestore.collection('categories').doc(productData['category']).snapshots()
                                              : null,
                                          builder: (context, categorySnapshot) {
                                            String categoryDisplayName = _appLocalizations.notAvailableAbbreviation;

                                            if (categorySnapshot.hasData && categorySnapshot.data!.exists) {
                                              final categoryData = categorySnapshot.data!.data() as Map<String, dynamic>?;
                                              categoryDisplayName = categoryData?['name'] ?? productData['category'] ?? _appLocalizations.notAvailableAbbreviation;
                                            } else if (productData['category'] != null) {
                                              categoryDisplayName = productData['category'];
                                            }

                                            return Text(
                                              categoryDisplayName,
                                              style: TextStyle(color: Colors.grey[600]),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Edit button at top right
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _showEditProductDialog(productDoc);
                                },
                                tooltip: _appLocalizations.editProfile,
                              ),
                            ),
                            // Delete button at bottom right
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteProduct(
                                    productDoc.id,
                                    productData['name'] ?? _appLocalizations.unnamedProduct,
                                  );
                                },
                                tooltip: _appLocalizations.delete,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}