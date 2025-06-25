import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

// Top-level utility function for comparing lists
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

class EditProductDialog extends StatefulWidget {
  final DocumentSnapshot productDoc;
  final AppLocalizations appLocalizations;
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;

  const EditProductDialog({
    super.key,
    required this.productDoc,
    required this.appLocalizations,
    required this.cloudinaryCloudName,
    required this.cloudinaryUploadPreset,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _editProductFormKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  bool _isOffer = false;
  String? _selectedCategory;
  List<String> _availableCategories = [];
  final List<File> _pickedNewImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _removedImageUrls = [];
  List<Product> _relatedProducts = [];
  bool _isSaving = false;

  final _imagePicker = ImagePicker();
  final TextEditingController _relatedProductSearchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearchingRelated = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchCategories();
  }

  void _initializeControllers() {
    final productData = widget.productDoc.data() as Map<String, dynamic>;

    debugPrint('EditProductDialog: Initializing with raw product data: $productData');

    final double initialPrice = _parseDouble(productData['price']);
    final int initialDiscount = _parseInt(productData['discount']);
    final int initialQuantity = _parseInt(productData['quantity']);

    _productNameController = TextEditingController(text: productData['name'] ?? '');
    _priceController = TextEditingController(text: initialPrice.toStringAsFixed(2));
    _discountController = TextEditingController(text: initialDiscount.toString());
    _quantityController = TextEditingController(text: initialQuantity.toString());
    _descriptionController = TextEditingController(text: productData['description'] ?? '');
    _tagsController = TextEditingController(text: (productData['tags'] as List<dynamic>?)?.map((e) => e.toString()).join(', ') ?? '');
    _isOffer = productData['isOffer'] ?? false;
    _selectedCategory = productData['category'] as String?;
    _existingImageUrls = (productData['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    _fetchRelatedProducts(productData['relatedProductIds']);
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    } else if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await _firestore.collection('categories').get();
      setState(() {
        _availableCategories = querySnapshot.docs.map((doc) => doc.id).toList();

        if (_selectedCategory != null && !_availableCategories.contains(_selectedCategory)) {
          debugPrint('EditProductDialog: Category "$_selectedCategory" not found in available categories. Resetting to null.');
          _selectedCategory = null;
        }
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        widget.appLocalizations.errorLoadingCategories(e.toString()),
      );
    }
  }

  Future<void> _fetchRelatedProducts(List<dynamic>? relatedProductIds) async {
    if (relatedProductIds == null || relatedProductIds.isEmpty) {
      setState(() {
        _relatedProducts = [];
      });
      return;
    }

    try {
      final productsQuery = await _firestore.collection('products')
          .where(FieldPath.documentId, whereIn: relatedProductIds)
          .get();
      setState(() {
        _relatedProducts = productsQuery.docs.map((doc) => Product.fromFirestore(doc)).toList();
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Error fetching related products: ${e.toString()}',
      );
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _relatedProductSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pickedNewImages.length + _existingImageUrls.length >= AppConfig.maxImagesPerProduct) {
      ErrorHandler.showWarningSnackBar(
        context,
        widget.appLocalizations.addMoreImages(_pickedNewImages.length + _existingImageUrls.length, AppConfig.maxImagesPerProduct),
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _pickedNewImages.add(File(pickedFile.path));
        });
        ErrorHandler.showSuccessSnackBar(context, 'Image added successfully');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error picking image: $e');
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    final url = 'https://api.cloudinary.com/v1_1/${widget.cloudinaryCloudName}/image/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['upload_preset'] = widget.cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseString);
        return jsonResponse['secure_url'];
      } else {
        debugPrint(widget.appLocalizations.cloudinaryUploadFailed(response.statusCode));
        return null;
      }
    } catch (e) {
      debugPrint(widget.appLocalizations.failedToUploadImage(e.toString()));
      return null;
    }
  }

  Future<void> _updateProduct() async {
    if (!_editProductFormKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(context, 'Please fill in all required fields correctly');
      return;
    }

    await ErrorHandler.handleAsyncError(
      context,
          () async {
        setState(() {
          _isSaving = true;
        });

        try {
          // Upload new images to Cloudinary
          List<String> uploadedImageUrls = [];
          if (_pickedNewImages.isNotEmpty) {
            ErrorHandler.showInfoSnackBar(context, 'Uploading new images...');
            for (var imageFile in _pickedNewImages) {
              final imageUrl = await _uploadImageToCloudinary(imageFile);
              if (imageUrl != null) {
                uploadedImageUrls.add(imageUrl);
              }
            }
          }

          // Combine existing images (not marked for removal) with newly uploaded images
          List<String> finalImageUrls = [];
          for (var url in _existingImageUrls) {
            if (!_removedImageUrls.contains(url)) {
              finalImageUrls.add(url);
            }
          }
          finalImageUrls.addAll(uploadedImageUrls);

          // Parse numeric fields safely
          final double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
          final int discount = int.tryParse(_discountController.text.trim()) ?? 0;
          final int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;

          if (price < 0 || quantity < 0) {
            throw Exception(widget.appLocalizations.priceAndQuantityCannotBeNegative);
          }

          final List<String> tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          final List<String> nameKeywords = _generateNameKeywords(_productNameController.text.trim());
          final List<String> relatedProductIds = _relatedProducts.map((p) => p.id).toList();

          await _firestore.collection('products').doc(widget.productDoc.id).update({
            'name': _productNameController.text.trim(),
            'price': price,
            'discount': discount,
            'quantity': quantity,
            'description': _descriptionController.text.trim(),
            'tags': tags,
            'nameKeywords': nameKeywords,
            'imageUrls': finalImageUrls,
            'category': _selectedCategory,
            'isOffer': _isOffer,
            'relatedProductIds': relatedProductIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            Navigator.of(context).pop();
          }
        } finally {
          setState(() {
            _isSaving = false;
          });
        }
      },
      successMessage: widget.appLocalizations.productUpdatedSuccessfully,
      errorPrefix: 'Failed to update product',
    );
  }

  Future<void> _searchRelatedProducts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingRelated = false;
      });
      return;
    }

    setState(() {
      _isSearchingRelated = true;
    });

    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('nameKeywords', arrayContainsAny: _generateNameKeywords(query.trim()).take(10).toList())
          .get();

      setState(() {
        _searchResults = querySnapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .where((product) => product.id != widget.productDoc.id)
            .where((product) => !_relatedProducts.any((rp) => rp.id == product.id))
            .toList();
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        widget.appLocalizations.failedToSearchProducts(e.toString()),
      );
    } finally {
      setState(() {
        _isSearchingRelated = false;
      });
    }
  }

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

  void _addRelatedProduct(Product product) {
    setState(() {
      if (!_relatedProducts.any((p) => p.id == product.id)) {
        _relatedProducts.add(product);
        _relatedProductSearchController.clear();
        _searchResults = [];
      }
    });
    ErrorHandler.showSuccessSnackBar(context, 'Related product added: ${product.name}');
  }

  void _removeRelatedProduct(String productId) {
    final product = _relatedProducts.firstWhere((p) => p.id == productId);
    setState(() {
      _relatedProducts.removeWhere((p) => p.id == productId);
    });
    ErrorHandler.showInfoSnackBar(context, 'Removed: ${product.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.appLocalizations.editProduct}: ${widget.productDoc['name']}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const Divider(),

            // Form content
            Expanded(
              child: Form(
                key: _editProductFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      TextFormField(
                        controller: _productNameController,
                        decoration: InputDecoration(
                          labelText: widget.appLocalizations.productName,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.shopping_bag),
                        ),
                        validator: (value) => value!.isEmpty
                            ? widget.appLocalizations.pleaseEnterFieldName(widget.appLocalizations.productName)
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Price and Discount Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              decoration: InputDecoration(
                                labelText: '${widget.appLocalizations.price} (${AppConfig.currency})',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.attach_money),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value!.isEmpty) return widget.appLocalizations.pleaseEnterFieldName(widget.appLocalizations.price);
                                if (double.tryParse(value) == null) return widget.appLocalizations.fieldNameMustBeNumber(widget.appLocalizations.price);
                                if (double.parse(value) < 0) return widget.appLocalizations.priceAndQuantityCannotBeNegative;
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              decoration: InputDecoration(
                                labelText: widget.appLocalizations.discount,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.percent),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) return widget.appLocalizations.pleaseEnterFieldName(widget.appLocalizations.discount);
                                final int? discount = int.tryParse(value);
                                if (discount == null || discount < 0 || discount > 100) return 'Discount must be between 0 and 100.';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: widget.appLocalizations.quantityInStock,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value!.isEmpty) return widget.appLocalizations.pleaseEnterFieldName(widget.appLocalizations.quantityInStock);
                          if (int.tryParse(value) == null) return widget.appLocalizations.fieldNameMustBeNumber(widget.appLocalizations.quantityInStock);
                          if (int.parse(value) < 0) return widget.appLocalizations.priceAndQuantityCannotBeNegative;
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: widget.appLocalizations.productDescription,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) => value!.isEmpty
                            ? widget.appLocalizations.pleaseEnterFieldName(widget.appLocalizations.productDescription)
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: InputDecoration(
                          labelText: widget.appLocalizations.tags,
                          hintText: 'e.g., electronic, mobile, smartphone',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Category Dropdown
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('categories').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          final List<Map<String, String>> currentAvailableCategories = snapshot.data!.docs
                              .map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return <String, String>{
                              'id': doc.id,
                              'name': data['name']?.toString() ?? doc.id,
                            };
                          })
                              .toList();

                          final List<String> categoryIds = currentAvailableCategories.map((cat) => cat['id']!).toList();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!listEquals(_availableCategories, categoryIds)) {
                              setState(() {
                                _availableCategories = categoryIds;
                                if (_selectedCategory != null && !_availableCategories.contains(_selectedCategory)) {
                                  _selectedCategory = null;
                                }
                              });
                            }
                          });

                          return DropdownButtonFormField<String?>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: widget.appLocalizations.selectCategory,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(widget.appLocalizations.selectCategory),
                              ),
                              ...currentAvailableCategories.map((category) {
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
                                _selectedCategory = value;
                              });
                            },
                            validator: (value) => value == null
                                ? widget.appLocalizations.pleaseSelectCategory
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 15),

                      // Image Management
                      Text(
                        widget.appLocalizations.addProductImages,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 120,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Existing Images
                              ..._existingImageUrls.map((url) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        url,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _removedImageUrls.add(url);
                                            _existingImageUrls.remove(url);
                                          });
                                          ErrorHandler.showInfoSnackBar(context, 'Image marked for removal');
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),

                              // Newly picked images
                              ..._pickedNewImages.map((file) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        file,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _pickedNewImages.remove(file);
                                          });
                                          ErrorHandler.showInfoSnackBar(context, 'New image removed');
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),

                              // Add Image Button
                              if (_pickedNewImages.length + _existingImageUrls.length < AppConfig.maxImagesPerProduct)
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[400]!),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo, color: Colors.grey[600]),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Add Image',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Is Offer Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _isOffer,
                            onChanged: (bool? newValue) {
                              setState(() {
                                _isOffer = newValue ?? false;
                              });
                            },
                          ),
                          Text(widget.appLocalizations.markAsOffer),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // Related Products Section
                      Text(
                        widget.appLocalizations.relatedProducts,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Search field
                      TextFormField(
                        controller: _relatedProductSearchController,
                        decoration: InputDecoration(
                          labelText: widget.appLocalizations.searchProductsToAdd,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                              : IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _searchRelatedProducts(_relatedProductSearchController.text),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_relatedProductSearchController.text == value) {
                                _searchRelatedProducts(value);
                              }
                            });
                          } else {
                            setState(() {
                              _searchResults = [];
                            });
                          }
                        },
                      ),

                      // Search Results
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final product = _searchResults[index];
                              return ListTile(
                                dense: true,
                                leading: product.imageUrls.isNotEmpty
                                    ? Image.network(product.imageUrls[0], width: 40, height: 40, fit: BoxFit.cover)
                                    : const Icon(Icons.image),
                                title: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text('${AppConfig.currency} ${product.price.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _addRelatedProduct(product),
                                ),
                              );
                            },
                          ),
                        ),

                      // Selected Related Products
                      if (_relatedProducts.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${widget.appLocalizations.selectedRelatedProducts} (${_relatedProducts.length})',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _relatedProducts.map((product) {
                            return Chip(
                              avatar: product.imageUrls.isNotEmpty
                                  ? CircleAvatar(
                                backgroundImage: NetworkImage(product.imageUrls[0]),
                              )
                                  : const CircleAvatar(child: Icon(Icons.image)),
                              label: Text(
                                product.name,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: () => _removeRelatedProduct(product.id),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text(widget.appLocalizations.cancel),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(widget.appLocalizations.saveChanges),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}