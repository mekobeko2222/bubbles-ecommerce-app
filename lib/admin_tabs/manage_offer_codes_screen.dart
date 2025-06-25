import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart'; // Import error handler
// Import config

class ManageOfferCodesScreen extends StatefulWidget {
  const ManageOfferCodesScreen({super.key});

  @override
  State<ManageOfferCodesScreen> createState() => _ManageOfferCodesScreenState();
}

class _ManageOfferCodesScreenState extends State<ManageOfferCodesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AppLocalizations _appLocalizations;
  bool _isAddingCode = false;
  String _filterStatus = 'All'; // All, Active, Inactive

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _addOfferCode() async {
    if (!_formKey.currentState!.validate()) {
      ErrorHandler.showWarningSnackBar(context, 'Please fill in all required fields correctly');
      return;
    }

    final String code = _codeController.text.trim().toUpperCase();
    final double discount = double.parse(_discountController.text.trim());

    if (discount <= 0 || discount > 100) {
      ErrorHandler.showWarningSnackBar(context, 'Discount percentage must be between 1 and 100.');
      return;
    }

    await ErrorHandler.handleAsyncError(
      context,
          () async {
        setState(() {
          _isAddingCode = true;
        });

        try {
          // Check if code already exists
          final existingCode = await _firestore.collection('offer_codes').doc(code).get();
          if (existingCode.exists) {
            throw Exception('Offer code "$code" already exists. Please choose a unique code.');
          }

          await _firestore.collection('offer_codes').doc(code).set({
            'code': code,
            'discountPercentage': discount,
            'isActive': true,
            'createdAt': Timestamp.now(),
            'usageCount': 0, // Track how many times it's been used
            'createdBy': 'admin', // Could be dynamic based on current user
          });

          _codeController.clear();
          _discountController.clear();
          _formKey.currentState?.reset();
        } finally {
          setState(() {
            _isAddingCode = false;
          });
        }
      },
      successMessage: _appLocalizations.offerCodeAddedSuccessfully(code),
      errorPrefix: 'Failed to add offer code',
    );
  }

  Future<void> _toggleOfferCodeStatus(String code, bool currentStatus) async {
    await ErrorHandler.handleAsyncError(
      context,
          () async {
        await _firestore.collection('offer_codes').doc(code).update({
          'isActive': !currentStatus,
          'updatedAt': Timestamp.now(),
        });
      },
      successMessage: !currentStatus
          ? 'Offer code "$code" activated'
          : 'Offer code "$code" deactivated',
      errorPrefix: 'Failed to update offer code status',
    );
  }

  Future<void> _removeOfferCode(String code) async {
    final bool confirmed = await ErrorHandler.showConfirmationDialog(
      context,
      title: _appLocalizations.confirmDeletion,
      content: _appLocalizations.areYouSureDeleteProduct(code),
      confirmText: _appLocalizations.delete,
      cancelText: _appLocalizations.cancel,
      isDestructive: true,
    );

    if (confirmed) {
      await ErrorHandler.handleAsyncError(
        context,
            () async {
          await _firestore.collection('offer_codes').doc(code).delete();
        },
        successMessage: _appLocalizations.offerCodeRemoved(code),
        errorPrefix: 'Failed to remove offer code',
      );
    }
  }

  Stream<QuerySnapshot> _getFilteredOfferCodes() {
    Query query = _firestore.collection('offer_codes').orderBy('createdAt', descending: true);

    if (_filterStatus == 'Active') {
      query = query.where('isActive', isEqualTo: true);
    } else if (_filterStatus == 'Inactive') {
      query = query.where('isActive', isEqualTo: false);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact Add Offer Code Form
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _appLocalizations.addOfferCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact form fields in a row
                    Row(
                      children: [
                        // Offer Code Input
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Code',
                              hintText: 'SAVE20',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 3) {
                                return 'Min 3 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Discount Percentage Input
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              labelText: 'Discount %',
                              hintText: '20',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                              LengthLimitingTextInputFormatter(5),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final discount = double.tryParse(value);
                              if (discount == null || discount <= 0 || discount > 100) {
                                return '1-100';
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
                            onPressed: _isAddingCode ? null : _addOfferCode,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _isAddingCode
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

        // Compact Filter Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              const Text(
                'Filter:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'All',
                      label: Text('All', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment<String>(
                      value: 'Active',
                      label: Text('Active', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment<String>(
                      value: 'Inactive',
                      label: Text('Inactive', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {_filterStatus},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _filterStatus = newSelection.first;
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Offer Codes List - Now takes most of the screen space
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getFilteredOfferCodes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading offer codes...'),
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
                      Text('Error: ${snapshot.error}'),
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
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _filterStatus == 'All'
                            ? _appLocalizations.noOfferCodesFound
                            : 'No ${_filterStatus.toLowerCase()} offer codes found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _filterStatus == 'All'
                            ? 'Add your first offer code above'
                            : 'Try changing the filter or add new codes',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final codes = snapshot.data!.docs;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {}); // Trigger rebuild
                  ErrorHandler.showInfoSnackBar(context, 'Offer codes refreshed');
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: codes.length,
                  itemBuilder: (context, index) {
                    final codeDoc = codes[index];
                    final codeData = codeDoc.data() as Map<String, dynamic>;
                    final code = codeData['code'] as String;
                    final discount = codeData['discountPercentage'] as double;
                    final isActive = codeData['isActive'] as bool? ?? true;
                    final usageCount = codeData['usageCount'] as int? ?? 0;
                    final createdAt = codeData['createdAt'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: isActive
                              ? Border.all(color: Colors.green.withOpacity(0.3))
                              : Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              color: isActive ? Colors.green : Colors.grey,
                              size: 16,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? 'ACTIVE' : 'INACTIVE',
                                  style: const TextStyle(
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
                                    '${discount.toStringAsFixed(0)}% off',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Used: $usageCount',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        createdAt.toDate().toLocal().toString().split(' ')[0],
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
                              // Toggle Active/Inactive
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.toggle_on : Icons.toggle_off,
                                  color: isActive ? Colors.green : Colors.grey,
                                  size: 24,
                                ),
                                onPressed: () => _toggleOfferCodeStatus(code, isActive),
                                tooltip: isActive ? 'Deactivate' : 'Activate',
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                onPressed: () => _removeOfferCode(code),
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