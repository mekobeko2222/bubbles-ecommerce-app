import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart'; // Import localizations

class EditProductDialog extends StatefulWidget {
  final DocumentSnapshot productDoc;
  final AppLocalizations appLocalizations; // NEW: Add appLocalizations parameter

  const EditProductDialog({
    super.key,
    required this.productDoc,
    required this.appLocalizations, // NEW: Require appLocalizations
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late AppLocalizations _appLocalizations; // Localizations instance

  String? _selectedCategory;
  final List<File> _newlyPickedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _initialRelatedProductIds = [];
  List<String> _selectedRelatedProductIds = []; // To store IDs of selected related products

  bool _isSaving = false;
  bool _isOffer = false;

  final _editProductFormKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _appLocalizations = widget.appLocalizations; // Initialize localizations

    final productData = widget.productDoc.data() as Map<String, dynamic>;

    _productNameController = TextEditingController(text: productData['name'] ?? '');
    _priceController = TextEditingController(text: (productData['price'] as num?)?.toStringAsFixed(2) ?? '0.00');
    _discountController = TextEditingController(text: (productData['discount'] as num?)?.toString() ?? '0');
    _quantityController = TextEditingController(text: (productData['quantity'] as num?)?.toString() ?? '0');
    _descriptionController = TextEditingController(text: productData['description'] ?? '');
    _tagsController = TextEditingController(text: (productData['tags'] as List?)?.join(', ') ?? '');
    _selectedCategory = productData['category'];
    _existingImageUrls = (productData['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    _isOffer = productData['isOffer'] ?? false;

    // Load existing related product IDs
    _initialRelatedProductIds = (productData['relatedProducts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    _selectedRelatedProductIds = List.from(_initialRelatedProductIds); // Initialize with existing
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Helper for SnackBar messages
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Image Picking
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _newlyPickedImages.add(File(pickedFile.path));
      });
    }
  }

  // Image Upload to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
    const cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

    if (cloudinaryCloudName.isEmpty || cloudinaryUploadPreset.isEmpty) {
      _showSnackBar('Cloudinary credentials not set. Image upload skipped.', isError: true);
      return null;
    }

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(utf8.decode(responseData));
        return result['secure_url'];
      } else {
        _showSnackBar(
          _appLocalizations.cloudinaryUploadFailed(response.statusCode),
          isError: true,
        );
        return null;
      }
    } catch (e) {
      _showSnackBar(
        _appLocalizations.failedToUploadImage(e.toString()),
        isError: true,
      );
      return null;
    }
  }

  // Fetch Categories for Dropdown
  Stream<List<String>> _fetchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Update Product
  Future<void> _updateProduct() async {
    if (!_editProductFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload new images
      List<String> uploadedImageUrls = [];
      for (var imageFile in _newlyPickedImages) {
        final url = await _uploadImageToCloudinary(imageFile);
        if (url != null) {
          uploadedImageUrls.add(url);
        }
      }

      // Combine existing and newly uploaded images
      final allImageUrls = [..._existingImageUrls, ...uploadedImageUrls];

      // Prepare product data
      final productData = {
        'name': _productNameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'discount': int.parse(_discountController.text.trim()),
        'quantity': int.parse(_quantityController.text.trim()),
        'description': _descriptionController.text.trim(),
        'tags': _tagsController.text.trim().split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList(),
        'category': _selectedCategory,
        'imageUrls': allImageUrls,
        'isOffer': _isOffer,
        'relatedProducts': _selectedRelatedProductIds, // Save selected related product IDs
      };

      await _firestore.collection('products').doc(widget.productDoc.id).update(productData);

      if (mounted) {
        _showSnackBar(_appLocalizations.productAddedSuccessfully); // Re-using for update success
        Navigator.of(context).pop(); // Close dialog on success
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          _appLocalizations.failedToAddProduct(e.toString()), // Re-using for update failure
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showRelatedProductsSelectionDialog() async {
    final List<String> tempSelectedRelatedProductIds = List.from(_selectedRelatedProductIds);
    final searchController = TextEditingController();
    String currentSearchQuery = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: Text(_appLocalizations.searchProductsToAdd),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: _appLocalizations.searchProductByName,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            setStateInDialog(() {
                              currentSearchQuery = '';
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        setStateInDialog(() {
                          currentSearchQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('products').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: Text(_appLocalizations.loadingData));
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text(_appLocalizations.errorLoadingData(snapshot.error.toString())));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(child: Text(_appLocalizations.noDataFound));
                          }

                          final allProducts = snapshot.data!.docs;
                          final filteredProducts = allProducts.where((doc) {
                            final productName = (doc.data() as Map<String, dynamic>)['name']?.toLowerCase() ?? '';
                            // Exclude the current product from related products
                            return doc.id != widget.productDoc.id && productName.contains(currentSearchQuery);
                          }).toList();

                          if (filteredProducts.isEmpty) {
                            return Center(child: Text(_appLocalizations.noProductsFoundMatchingFilters));
                          }

                          return ListView.builder(
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final productDoc = filteredProducts[index];
                              final productData = productDoc.data() as Map<String, dynamic>;
                              final productName = productData['name'] ?? _appLocalizations.unnamedProduct;
                              final isSelected = tempSelectedRelatedProductIds.contains(productDoc.id);

                              return CheckboxListTile(
                                title: Text(productName),
                                value: isSelected,
                                onChanged: (bool? newValue) {
                                  setStateInDialog(() {
                                    if (newValue == true) {
                                      tempSelectedRelatedProductIds.add(productDoc.id);
                                    } else {
                                      tempSelectedRelatedProductIds.remove(productDoc.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(_appLocalizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRelatedProductIds = List.from(tempSelectedRelatedProductIds);
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: Text(_appLocalizations.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${_appLocalizations.editProfile}: ${widget.productDoc['name']}'), // Re-using editProfile string
      content: Form(
        key: _editProductFormKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: InputDecoration(labelText: _appLocalizations.productName),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _appLocalizations.pleaseEnterFieldName(_appLocalizations.productName);
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: _appLocalizations.price),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return _appLocalizations.fieldNameMustBeNumber(_appLocalizations.price);
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(labelText: _appLocalizations.discount),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return _appLocalizations.fieldNameMustBeNumber(_appLocalizations.discount);
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: _appLocalizations.quantityInStock),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return _appLocalizations.fieldNameMustBeNumber(_appLocalizations.quantityInStock);
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: _appLocalizations.productDescription),
                maxLines: 3,
              ),
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: _appLocalizations.tags,
                  hintText: _appLocalizations.tags,
                ),
              ),
              const SizedBox(height: 15),
              StreamBuilder<List<String>>(
                stream: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Text(_appLocalizations.loadingData));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(_appLocalizations.errorLoadingCategories(snapshot.error.toString())));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(_appLocalizations.noCategoriesAvailable));
                  }
                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: _appLocalizations.selectCategory),
                    items: snapshot.data!.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _appLocalizations.pleaseEnterFieldName(_appLocalizations.category);
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 15),
              // Display existing images
              if (_existingImageUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_appLocalizations.addProductImages, style: const TextStyle(fontWeight: FontWeight.bold)), // Re-using addProductImages
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100, // Fixed height for image list
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _existingImageUrls.length,
                        itemBuilder: (context, index) {
                          final imageUrl = _existingImageUrls[index];
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Icon(Icons.broken_image));
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _existingImageUrls.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.remove_circle, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              // Display newly picked images
              if (_newlyPickedImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('New Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _newlyPickedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _newlyPickedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _newlyPickedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.remove_circle, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _newlyPickedImages.length + _existingImageUrls.length < 5 ? _pickImage : null,
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(_appLocalizations.addMoreImages(_newlyPickedImages.length + _existingImageUrls.length, 5)),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
                  Text(_appLocalizations.markAsOffer),
                ],
              ),
              const SizedBox(height: 15),
              // Related Products Selection
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showRelatedProductsSelectionDialog,
                  icon: const Icon(Icons.link),
                  label: Text(
                    '${_appLocalizations.selectedRelatedProducts}: ${_selectedRelatedProductIds.length} ${_appLocalizations.items(_selectedRelatedProductIds.length)}',
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Center(
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                  onPressed: _updateProduct,
                  icon: const Icon(Icons.save),
                  label: Text(_appLocalizations.saveChanges, style: const TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
