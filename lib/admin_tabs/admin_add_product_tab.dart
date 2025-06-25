import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

class AdminAddProductTab extends StatefulWidget {
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;

  const AdminAddProductTab({
    super.key,
    required this.cloudinaryCloudName,
    required this.cloudinaryUploadPreset,
  });

  @override
  State<AdminAddProductTab> createState() => _AdminAddProductTabState();
}

class _AdminAddProductTabState extends State<AdminAddProductTab> {
  final _productNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _isOffer = false;
  bool _isAddingProduct = false;

  String? _selectedCategory;
  List<File> _pickedImages = [];

  final _addProductFormKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for 'Add New Category' Dialog
  final _newCategoryNameController = TextEditingController();
  final _newCategoryIconController = TextEditingController();

  // Related Products fields
  final _relatedProductSearchController = TextEditingController();
  final List<Product> _selectedRelatedProducts = [];
  List<Product> _relatedProductSuggestions = [];
  bool _isSearchingRelated = false;

  late AppLocalizations _appLocalizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _newCategoryNameController.dispose();
    _newCategoryIconController.dispose();
    _relatedProductSearchController.dispose();
    super.dispose();
  }

  // Generates keywords for search
  List<String> _generateNameKeywords(String name) {
    List<String> keywords = [];
    final words = name.toLowerCase().split(' ').where((w) => w.isNotEmpty);
    for (var word in words) {
      for (int i = 1; i <= word.length; i++) {
        keywords.add(word.substring(0, i));
      }
    }
    return keywords.toSet().toList();
  }

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images.map((xfile) => File(xfile.path)));
          // Limit to max images per product
          if (_pickedImages.length > AppConfig.maxImagesPerProduct) {
            _pickedImages = _pickedImages.sublist(
                _pickedImages.length - AppConfig.maxImagesPerProduct);
          }
        });

        ErrorHandler.showSuccessSnackBar(
          context,
          'Added ${images.length} image(s). Total: ${_pickedImages
              .length}/${AppConfig.maxImagesPerProduct}',
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error picking images: $e',
      );
    }
  }

  // Remove a picked image
  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
    ErrorHandler.showInfoSnackBar(context, 'Image removed');
  }

  // Search for related products by name using keywords
  Future<void> _searchRelatedProducts(String query) async {
    if (query
        .trim()
        .isEmpty) {
      setState(() {
        _relatedProductSuggestions = [];
        _isSearchingRelated = false;
      });
      return;
    }

    setState(() {
      _isSearchingRelated = true;
    });

    final searchKeywords = _generateNameKeywords(query.trim());

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where(
          'nameKeywords', arrayContainsAny: searchKeywords.take(10).toList())
          .get();

      setState(() {
        _relatedProductSuggestions = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) =>
        !_selectedRelatedProducts.any((selectedProduct) =>
        selectedProduct.id == product.id))
            .toList();
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        _appLocalizations.failedToSearchProducts(e.toString()),
      );
    } finally {
      setState(() {
        _isSearchingRelated = false;
      });
    }
  }

  // Add a related product to the selected list
  void _addRelatedProduct(Product product) {
    setState(() {
      if (!_selectedRelatedProducts.any((p) => p.id == product.id)) {
        _selectedRelatedProducts.add(product);
        _relatedProductSearchController.clear();
        _relatedProductSuggestions.clear();
      }
    });
    ErrorHandler.showSuccessSnackBar(
        context, 'Related product added: ${product.name}');
  }

  // Remove a related product from the selected list
  void _removeSelectedRelatedProduct(String productId) {
    final product = _selectedRelatedProducts.firstWhere((p) =>
    p.id == productId);
    setState(() {
      _selectedRelatedProducts.removeWhere((p) => p.id == productId);
    });
    ErrorHandler.showInfoSnackBar(context, 'Removed: ${product.name}');
  }

  // Upload images to Cloudinary
  Future<List<String>> _uploadImagesToCloudinary(List<File> images) async {
    List<String> imageUrls = [];
    final url = 'https://api.cloudinary.com/v1_1/${widget
        .cloudinaryCloudName}/image/upload';

    for (var imageFile in images) {
      try {
        final request = http.MultipartRequest('POST', Uri.parse(url))
          ..fields['upload_preset'] = widget.cloudinaryUploadPreset
          ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);

        if (response.statusCode == 200) {
          imageUrls.add(data['secure_url']);
        } else {
          debugPrint(
              _appLocalizations.cloudinaryUploadFailed(response.statusCode));
          throw Exception(_appLocalizations.failedToUploadImage(
              'Cloudinary responded with status code ${response.statusCode}'));
        }
      } catch (e) {
        debugPrint(_appLocalizations.failedToUploadImage(e.toString()));
        throw Exception(_appLocalizations.failedToUploadImage(e.toString()));
      }
    }
    return imageUrls;
  }

  // Add new product to Firestore
  Future<void> _addNewProduct() async {
    if (!_addProductFormKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(
          context, 'Please fill in all required fields correctly');
      return;
    }

    if (_pickedImages.isEmpty) {
      ErrorHandler.showWarningSnackBar(
          context, _appLocalizations.addProductImages);
      return;
    }

    await ErrorHandler.handleAsyncError(
      context,
          () async {
        setState(() {
          _isAddingProduct = true;
        });

        try {
          final String productName = _productNameController.text.trim();
          final double price = double.tryParse(_priceController.text.trim()) ??
              0.0;
          final int discount = int.tryParse(_discountController.text.trim()) ??
              0;
          final int quantity = int.tryParse(_quantityController.text.trim()) ??
              0;
          final String description = _descriptionController.text.trim();
          final List<String> tags = _tagsController.text.split(',')
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toList();
          final List<String> relatedProductIds = _selectedRelatedProducts.map((
              p) => p.id).toList();

          if (price <= 0 || quantity < 0 || discount < 0 || discount > 100) {
            throw Exception(_appLocalizations.enterValidNumbers);
          }

          // Show upload progress
          ErrorHandler.showInfoSnackBar(context, 'Uploading images...');
          final List<String> imageUrls = await _uploadImagesToCloudinary(
              _pickedImages);

          await _firestore.collection('products').add({
            'name': productName,
            'price': price,
            'discount': discount,
            'quantity': quantity,
            'description': description,
            'imageUrls': imageUrls,
            'category': _selectedCategory,
            'isOffer': _isOffer,
            'tags': tags,
            'nameKeywords': _generateNameKeywords(productName),
            'relatedProductIds': relatedProductIds,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          _clearForm();
        } finally {
          setState(() {
            _isAddingProduct = false;
          });
        }
      },
      successMessage: _appLocalizations.productAddedSuccessfully,
      errorPrefix: 'Failed to add product',
    );
  }

  // Clear all form fields and states
  void _clearForm() {
    _productNameController.clear();
    _priceController.clear();
    _discountController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    _relatedProductSearchController.clear();
    setState(() {
      _isOffer = false;
      _selectedCategory = null;
      _pickedImages.clear();
      _selectedRelatedProducts.clear();
      _relatedProductSuggestions.clear();
    });
  }

  // Show dialog to add a new category
  Future<void> _showAddCategoryDialog() async {
    _newCategoryNameController.clear();
    _newCategoryIconController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Theme
                  .of(context)
                  .primaryColor),
              const SizedBox(width: 8),
              Text(_appLocalizations.addCategory),
            ],
          ),
          content: Form(
            key: GlobalKey<FormState>(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _newCategoryNameController,
                  decoration: InputDecoration(
                    labelText: _appLocalizations.categoryName,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
                      return _appLocalizations.categoryNameCannotBeEmpty;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _newCategoryIconController,
                  decoration: InputDecoration(
                    labelText: _appLocalizations.categoryIcon,
                    hintText: 'e.g., 📱, 👗, 🏠',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.emoji_emotions),
                  ),
                  validator: (value) {
                    if (value == null || value
                        .trim()
                        .isEmpty) {
                      return _appLocalizations.categoryIconCannotBeEmpty;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_appLocalizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(Form.of(context).validate() ?? false)) {
                  return;
                }

                await ErrorHandler.handleAsyncError(
                  context,
                      () async {
                    await _firestore.collection('categories').doc(
                        _newCategoryNameController.text.trim()).set({
                      'name': _newCategoryNameController.text.trim(),
                      'icon': _newCategoryIconController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  },
                  successMessage: _appLocalizations.categoryAdded(
                      _newCategoryNameController.text.trim()),
                  errorPrefix: 'Failed to add category',
                );

                if (context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(_appLocalizations.addCategory),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Category was added successfully
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _addProductFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.add_box, color: Theme
                        .of(context)
                        .primaryColor, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appLocalizations.addProduct,
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: '${_appLocalizations.productName} *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.shopping_bag),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return _appLocalizations.pleaseEnterFieldName(
                      _appLocalizations.productName);
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Price and Discount Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${_appLocalizations.price} (${AppConfig
                          .currency}) *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.attach_money),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return _appLocalizations.fieldNameMustBeNumber(
                            _appLocalizations.price);
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${_appLocalizations.discount} (0-100)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.percent),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final int? discount = int.tryParse(value);
                        if (discount == null || discount < 0 ||
                            discount > 100) {
                          return 'Must be 0-100';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Quantity in Stock
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '${_appLocalizations.quantityInStock} *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.numbers),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || int.tryParse(value) == null ||
                    int.parse(value) < 0) {
                  return _appLocalizations.fieldNameMustBeNumber(
                      _appLocalizations.quantityInStock);
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Product Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: '${_appLocalizations.productDescription} *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value
                    .trim()
                    .isEmpty) {
                  return _appLocalizations.pleaseEnterFieldName(
                      _appLocalizations.productDescription);
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Tags
            TextFormField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: _appLocalizations.tags,
                hintText: 'e.g., electronics, mobile, smartphone',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.tag),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 20),

            // Category Selection
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(_appLocalizations.errorLoadingCategories(
                      snapshot.error.toString()));
                }

                List<DropdownMenuItem<String>> categoryItems = [];
                if (snapshot.hasData) {
                  categoryItems = snapshot.data!.docs.map((doc) {
                    final categoryData = doc.data() as Map<String, dynamic>;
                    final categoryName = categoryData['name'] as String;
                    final categoryIcon = categoryData['icon'] as String? ?? '📦';
                    return DropdownMenuItem<String>(
                      value: categoryName,
                      child: Row(
                        children: [
                          Text(categoryIcon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(categoryName),
                        ],
                      ),
                    );
                  }).toList();
                }

                if (_selectedCategory != null && !categoryItems.any((item) =>
                item.value == _selectedCategory)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  });
                }

                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      hint: Text(_appLocalizations.selectCategory),
                      decoration: InputDecoration(
                        labelText: '${_appLocalizations.selectCategory} *',
                        border: OutlineInputBorder(borderRadius: BorderRadius
                            .circular(10)),
                        prefixIcon: const Icon(Icons.category),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: categoryItems,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _appLocalizations.pleaseEnterFieldName(
                              _appLocalizations.selectCategory);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _showAddCategoryDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(_appLocalizations.addCategory),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Image Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, color: Theme
                            .of(context)
                            .primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _appLocalizations.addProductImages,
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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickedImages.length <
                          AppConfig.maxImagesPerProduct ? _pickImages : null,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        _pickedImages.isEmpty
                            ? _appLocalizations.addProductImages
                            : _appLocalizations.addMoreImages(
                            _pickedImages.length,
                            AppConfig.maxImagesPerProduct),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                    if (_pickedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _pickedImages[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                              12),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Related Products Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.link, color: Theme
                            .of(context)
                            .primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          _appLocalizations.relatedProducts,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _relatedProductSearchController,
                      decoration: InputDecoration(
                        labelText: _appLocalizations.searchProductsToAdd,
                        hintText: 'Type product name...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _isSearchingRelated
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                            : (_relatedProductSearchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _relatedProductSearchController.clear();
                              _relatedProductSuggestions.clear();
                            });
                          },
                        )
                            : null),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 700), () {
                            if (_relatedProductSearchController.text == value) {
                              _searchRelatedProducts(value);
                            }
                          });
                        } else {
                          setState(() {
                            _relatedProductSuggestions = [];
                          });
                        }
                      },
                    ),

                    // Search Results
                    if (_relatedProductSuggestions.isNotEmpty &&
                        _relatedProductSearchController.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _relatedProductSuggestions.length,
                          itemBuilder: (context, index) {
                            final product = _relatedProductSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: product.imageUrls.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.imageUrls[0],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image),
                                ),
                              )
                                  : const Icon(Icons.image),
                              title: Text(product.name),
                              subtitle: Text(
                                  '${AppConfig.currency} ${product.price
                                      .toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(
                                    Icons.add_circle, color: Colors.green),
                                onPressed: () => _addRelatedProduct(product),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Selected Related Products
                    if (_selectedRelatedProducts.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${_appLocalizations
                            .selectedRelatedProducts} (${_selectedRelatedProducts
                            .length})',
                        style: Theme
                            .of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _selectedRelatedProducts.map((product) {
                          return Chip(
                            avatar: product.imageUrls.isNotEmpty
                                ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                  product.imageUrls[0]),
                            )
                                : const CircleAvatar(child: Icon(Icons.image)),
                            label: Text(product.name),
                            onDeleted: () =>
                                _removeSelectedRelatedProduct(product.id),
                            deleteIcon: const Icon(Icons.cancel),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Is Offer Checkbox
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isOffer,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _isOffer = newValue ?? false;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.local_offer, color: Theme
                        .of(context)
                        .primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appLocalizations.markAsOffer,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Products marked as offers will appear on the home screen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Add Product Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isAddingProduct ? null : _addNewProduct,
                icon: _isAddingProduct
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.add_shopping_cart),
                label: Text(
                  _isAddingProduct ? 'Adding Product...' : _appLocalizations
                      .addProduct,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme
                      .of(context)
                      .colorScheme
                      .primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: _isAddingProduct ? 0 : 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}