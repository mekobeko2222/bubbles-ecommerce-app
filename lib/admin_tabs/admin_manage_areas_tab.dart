import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
import 'package:bubbles_ecommerce_app/config/app_config.dart'; // Import config

class AdminManageAreasTab extends StatefulWidget {
  const AdminManageAreasTab({super.key});

  @override
  State<AdminManageAreasTab> createState() => _AdminManageAreasTabState();
}

class _AdminManageAreasTabState extends State<AdminManageAreasTab> {
  final _newAreaNameController = TextEditingController();
  final _newAreaShippingFeeController = TextEditingController();
  final _addAreaFormKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppLocalizations _appLocalizations;
  bool _isAddingArea = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _newAreaNameController.dispose();
    _newAreaShippingFeeController.dispose();
    super.dispose();
  }

  Future<void> _addNewArea() async {
    if (!_addAreaFormKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(context, 'Please fill in all required fields correctly');
      return;
    }

    final areaName = _newAreaNameController.text.trim();
    final shippingFee = double.tryParse(_newAreaShippingFeeController.text.trim());

    if (areaName.isEmpty) {
      ErrorHandler.showWarningSnackBar(context, 'Area name cannot be empty.');
      return;
    }
    if (shippingFee == null || shippingFee < 0) {
      ErrorHandler.showWarningSnackBar(context, 'Please enter a valid shipping fee (0 or more).');
      return;
    }

    await ErrorHandler.handleAsyncError(
      context,
          () async {
        setState(() {
          _isAddingArea = true;
        });

        try {
          // Check if area already exists
          final existingAreas = await _firestore.collection('areas')
              .where('name', isEqualTo: areaName)
              .get();

          if (existingAreas.docs.isNotEmpty) {
            throw Exception('Area "$areaName" already exists. Please choose a different name.');
          }

          await _firestore.collection('areas').add({
            'name': areaName,
            'shippingFee': shippingFee,
            'createdAt': Timestamp.now(),
            'isActive': true, // Track if area is active
            'orderCount': 0, // Track number of orders to this area
          });

          _newAreaNameController.clear();
          _newAreaShippingFeeController.clear();
          _addAreaFormKey.currentState?.reset();
        } finally {
          setState(() {
            _isAddingArea = false;
          });
        }
      },
      successMessage: _appLocalizations.areaAddedSuccessfully(areaName),
      errorPrefix: 'Failed to add area',
    );
  }

  Future<void> _deleteArea(String areaId, String areaName) async {
    final bool confirmed = await ErrorHandler.showConfirmationDialog(
      context,
      title: _appLocalizations.confirmDeletion,
      content: 'Are you sure you want to delete area "$areaName"? This cannot be undone and may affect existing orders.',
      confirmText: _appLocalizations.delete,
      cancelText: _appLocalizations.cancel,
      isDestructive: true,
    );

    if (confirmed) {
      await ErrorHandler.handleAsyncError(
        context,
            () async {
          await _firestore.collection('areas').doc(areaId).delete();
        },
        successMessage: _appLocalizations.areaDeleted(areaName),
        errorPrefix: 'Failed to delete area',
      );
    }
  }

  Future<void> _editArea(String areaId, String currentName, double currentFee) async {
    final nameController = TextEditingController(text: currentName);
    final feeController = TextEditingController(text: currentFee.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Area: $currentName',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: _appLocalizations.areaName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an area name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: feeController,
                decoration: InputDecoration(
                  labelText: 'Shipping Fee (${AppConfig.currency})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.local_shipping),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                validator: (value) {
                  if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Please enter a valid shipping fee (0 or more).';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_appLocalizations.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop({
                  'name': nameController.text.trim(),
                  'fee': double.parse(feeController.text.trim()),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(_appLocalizations.saveChanges),
          ),
        ],
      ),
    );

    if (result != null) {
      await ErrorHandler.handleAsyncError(
        context,
            () async {
          await _firestore.collection('areas').doc(areaId).update({
            'name': result['name'],
            'shippingFee': result['fee'],
            'updatedAt': Timestamp.now(),
          });
        },
        successMessage: 'Area "${result['name']}" updated successfully',
        errorPrefix: 'Failed to update area',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact Add New Area Form
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _addAreaFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _appLocalizations.addNewShippingArea,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact form fields in a row
                    Row(
                      children: [
                        // Area Name Input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _newAreaNameController,
                            decoration: InputDecoration(
                              labelText: 'Area Name',
                              hintText: 'New Cairo',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 2) {
                                return 'Min 2 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Shipping Fee Input
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _newAreaShippingFeeController,
                            decoration: InputDecoration(
                              labelText: 'Fee (${AppConfig.currency})',
                              hintText: '25',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                            ],
                            validator: (value) {
                              if (value == null || double.tryParse(value) == null || double.parse(value) < 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Add Button
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            onPressed: _isAddingArea ? null : _addNewArea,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isAddingArea
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text('Add', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Areas List - Now takes most of the screen space
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('areas').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading shipping areas...'),
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
                      Text('Error loading areas: ${snapshot.error}'),
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
                      Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _appLocalizations.noShippingAreasFound,
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first shipping area above',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final areas = snapshot.data!.docs;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Trigger rebuild
                  ErrorHandler.showInfoSnackBar(context, 'Areas refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final areaDoc = areas[index];
                    final areaData = areaDoc.data() as Map<String, dynamic>;
                    final areaName = areaData['name'] ?? 'Unnamed Area';
                    final shippingFee = (areaData['shippingFee'] as num?)?.toDouble() ?? 0.0;
                    final isFreeShipping = shippingFee == 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isFreeShipping
                              ? Border.all(color: Colors.green.withOpacity(0.3))
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isFreeShipping
                                  ? Colors.green.withOpacity(0.1)
                                  : Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isFreeShipping ? Icons.local_shipping : Icons.location_on,
                              color: isFreeShipping
                                  ? Colors.green
                                  : Theme.of(context).primaryColor,
                              size: 16,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  areaName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFreeShipping)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'FREE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    'Shipping: ${AppConfig.currency} ${shippingFee.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isFreeShipping ? Colors.green : Colors.grey[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (areaData['createdAt'] != null) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Added: ${(areaData['createdAt'] as Timestamp).toDate().toLocal().toString().split(' ')[0]}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                onPressed: () => _editArea(areaDoc.id, areaName, shippingFee),
                                tooltip: 'Edit area',
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _deleteArea(areaDoc.id, areaName),
                                tooltip: _appLocalizations.delete,
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                            ],
                          ),
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