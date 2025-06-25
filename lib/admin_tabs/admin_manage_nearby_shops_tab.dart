import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart';

// Enum for different shop collections
enum ShopCategory {
  nearbyShops('nearby_shops', 'Nearby Shops', Icons.store_mall_directory, Colors.green),
  supportSmallBusiness('support_small_business', 'Support Small Businesses', Icons.business, Colors.purple);

  const ShopCategory(this.collection, this.displayName, this.icon, this.color);
  final String collection;
  final String displayName;
  final IconData icon;
  final Color color;
}

class AdminManageNearbyShopsTab extends StatefulWidget {
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;

  const AdminManageNearbyShopsTab({
    super.key,
    required this.cloudinaryCloudName,
    required this.cloudinaryUploadPreset,
  });

  @override
  State<AdminManageNearbyShopsTab> createState() => _AdminManageNearbyShopsTabState();
}

class _AdminManageNearbyShopsTabState extends State<AdminManageNearbyShopsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Add Shop'),
              Tab(text: 'Manage Shops'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              AddShopTab(
                cloudinaryCloudName: widget.cloudinaryCloudName,
                cloudinaryUploadPreset: widget.cloudinaryUploadPreset,
              ),
              const ManageShopsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// Add Shop Tab
class AddShopTab extends StatefulWidget {
  final String cloudinaryCloudName;
  final String cloudinaryUploadPreset;

  const AddShopTab({
    super.key,
    required this.cloudinaryCloudName,
    required this.cloudinaryUploadPreset,
  });

  @override
  State<AddShopTab> createState() => _AddShopTabState();
}

class _AddShopTabState extends State<AddShopTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _floorController = TextEditingController();

  // NEW: Collection Selection
  ShopCategory _selectedShopCategory = ShopCategory.nearbyShops;
  String _selectedCategory = 'Grocery';
  bool _isLoading = false;
  List<File> _selectedImages = [];

  // Categories for Nearby Shops
  final List<String> _nearbyShopsCategories = [
    'Grocery',
    'Electronics',
    'Fashion',
    'Pharmacy',
    'Cafe',
    'Restaurant',
    'Pet Store',
    'Beauty',
    'Sports',
    'Books',
    'Other'
  ];

  // Categories for Support Small Business
  final List<String> _smallBusinessCategories = [
    'Handmade',
    'Art & Crafts',
    'Food & Beverage',
    'Services',
    'Technology',
    'Consulting',
    'Retail',
    'Fitness & Wellness',
    'Education',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  List<String> get _currentCategories {
    return _selectedShopCategory == ShopCategory.nearbyShops
        ? _nearbyShopsCategories
        : _smallBusinessCategories;
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    List<String> uploadedUrls = [];

    for (File image in _selectedImages) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/${widget.cloudinaryCloudName}/image/upload'),
        );

        request.fields['upload_preset'] = widget.cloudinaryUploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', image.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);

        if (response.statusCode == 200) {
          uploadedUrls.add(jsonData['secure_url']);
        }
      } catch (e) {
        debugPrint('Error uploading image: $e');
      }
    }

    return uploadedUrls;
  }

  Future<void> _addShop() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ErrorHandler.showWarningSnackBar(context, 'Please select at least one image for the shop');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _uploadImages();

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }

      final shopData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'imageUrls': imageUrls,
        'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'category': _selectedCategory,
        'floor': _floorController.text.trim().isEmpty ? null : _floorController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Remove null values
      shopData.removeWhere((key, value) => value == null);

      // Save to the selected collection
      await FirebaseFirestore.instance
          .collection(_selectedShopCategory.collection)
          .add(shopData);

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
            context,
            '${_selectedShopCategory.displayName.substring(0, _selectedShopCategory.displayName.length - 1)} added successfully!'
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error adding shop: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _phoneController.clear();
    _floorController.clear();
    setState(() {
      _selectedCategory = _currentCategories.first;
      _selectedImages.clear();
    });
  }

  void _onShopCategoryChanged(ShopCategory? newCategory) {
    if (newCategory != null && newCategory != _selectedShopCategory) {
      setState(() {
        _selectedShopCategory = newCategory;
        // Reset category to first option of new list
        _selectedCategory = _currentCategories.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Collection Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedShopCategory.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedShopCategory.icon,
                        color: _selectedShopCategory.color,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add New Shop',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _selectedShopCategory.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose destination and add shop details',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Collection Selector
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _selectedShopCategory.color.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Collection:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedShopCategory.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: ShopCategory.values.map((category) {
                            final isSelected = _selectedShopCategory == category;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => _onShopCategoryChanged(category),
                                child: Container(
                                  margin: EdgeInsets.only(
                                    right: category == ShopCategory.nearbyShops ? 8 : 0,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? category.color.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? category.color
                                          : Colors.grey.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: isSelected ? category.color : Colors.grey[600],
                                        size: 20,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        category.displayName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? category.color : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Shop Images Section (unchanged)
            Text(
              'Shop Images * (You can select multiple images)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Selected Images Grid
            if (_selectedImages.isNotEmpty) ...[
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 30, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text(
                                'Add More',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select shop images',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can select multiple images',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Shop Name (Required)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter shop name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category (Required) - Dynamic based on selected collection
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: const OutlineInputBorder(),
                helperText: _selectedShopCategory == ShopCategory.nearbyShops
                    ? 'Categories for nearby shops'
                    : 'Categories for small businesses',
              ),
              items: _currentCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Phone and Floor Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      hintText: '+20xxxxxxxxxx',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _floorController,
                    decoration: const InputDecoration(
                      labelText: 'Floor',
                      border: OutlineInputBorder(),
                      hintText: 'Ground Floor',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: const OutlineInputBorder(),
                hintText: _selectedShopCategory == ShopCategory.nearbyShops
                    ? 'Tell customers about this shop...'
                    : 'Tell customers about this business...',
              ),
            ),

            const SizedBox(height: 24),

            // Add Shop Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _addShop,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(_selectedShopCategory.icon),
                label: Text(_isLoading
                    ? 'Adding...'
                    : 'Add to ${_selectedShopCategory.displayName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedShopCategory.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Manage Shops Tab - Updated to support both collections
class ManageShopsTab extends StatefulWidget {
  const ManageShopsTab({super.key});

  @override
  State<ManageShopsTab> createState() => _ManageShopsTabState();
}

class _ManageShopsTabState extends State<ManageShopsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  ShopCategory _selectedCollection = ShopCategory.nearbyShops;

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      final bool launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Could not launch phone dialer');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error launching dialer: $e');
      }
    }
  }

  Future<void> _deleteShop(String shopId, String shopName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete "$shopName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection(_selectedCollection.collection).doc(shopId).delete();
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(context, 'Shop deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, 'Error deleting shop: $e');
        }
      }
    }
  }

  Future<void> _toggleShopStatus(String shopId, bool currentStatus) async {
    try {
      await _firestore.collection(_selectedCollection.collection).doc(shopId).update({
        'isActive': !currentStatus,
      });
      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
            context,
            !currentStatus ? 'Shop activated' : 'Shop deactivated'
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error updating shop: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Collection Selector Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.manage_accounts,
                    color: _selectedCollection.color,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Shops',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _selectedCollection.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Edit, activate, or remove shops from collections',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Collection Selector
              Row(
                children: ShopCategory.values.map((category) {
                  final isSelected = _selectedCollection == category;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCollection = category;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(
                          right: category == ShopCategory.nearbyShops ? 8 : 0,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? category.color
                                : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              category.icon,
                              color: isSelected ? category.color : Colors.grey[600],
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? category.color : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Shops List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection(_selectedCollection.collection)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading shops',
                        style: TextStyle(color: Colors.red[700], fontSize: 16),
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
                      Icon(_selectedCollection.icon, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No shops in ${_selectedCollection.displayName.toLowerCase()} yet',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first shop using the "Add Shop" tab!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final shops = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shopDoc = shops[index];
                  final shopData = shopDoc.data() as Map<String, dynamic>;
                  final shopId = shopDoc.id;

                  // Handle both old format (imageUrl) and new format (imageUrls)
                  List<String> imageUrls = [];
                  if (shopData['imageUrls'] != null && shopData['imageUrls'] is List) {
                    imageUrls = List<String>.from(shopData['imageUrls']);
                  } else if (shopData['imageUrl'] != null && shopData['imageUrl'].toString().isNotEmpty) {
                    imageUrls = [shopData['imageUrl']];
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrls.isNotEmpty
                            ? Image.network(
                          imageUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(_selectedCollection.icon, color: Colors.grey),
                          ),
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[200],
                          child: Icon(_selectedCollection.icon, color: Colors.grey),
                        ),
                      ),
                      title: Text(
                        shopData['name'] ?? 'Unknown Shop',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _selectedCollection.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  shopData['category'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _selectedCollection.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (imageUrls.length > 1)
                                Text('${imageUrls.length} images', style: TextStyle(fontSize: 12, color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Phone number (clickable if available)
                          if (shopData['phoneNumber'] != null && shopData['phoneNumber'].toString().isNotEmpty)
                            GestureDetector(
                              onTap: () => _makePhoneCall(shopData['phoneNumber']),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    shopData['phoneNumber'],
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Floor (if available)
                          if (shopData['floor'] != null && shopData['floor'].toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.business, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Floor: ${shopData['floor']}'),
                              ],
                            ),
                          ],

                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (shopData['isActive'] ?? true)
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (shopData['isActive'] ?? true) ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: (shopData['isActive'] ?? true)
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'toggle':
                              _toggleShopStatus(shopId, shopData['isActive'] ?? true);
                              break;
                            case 'delete':
                              _deleteShop(shopId, shopData['name'] ?? 'Unknown Shop');
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  (shopData['isActive'] ?? true) ? Icons.visibility_off : Icons.visibility,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text((shopData['isActive'] ?? true) ? 'Deactivate' : 'Activate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}