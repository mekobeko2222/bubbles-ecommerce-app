import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';

class AdminManageAppFeaturesTab extends StatefulWidget {
  const AdminManageAppFeaturesTab({super.key});

  @override
  State<AdminManageAppFeaturesTab> createState() => _AdminManageAppFeaturesTabState();
}

class _AdminManageAppFeaturesTabState extends State<AdminManageAppFeaturesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Support Small Business Feature
  bool _supportSmallBusinessEnabled = false;
  String _supportSmallBusinessTitle = 'Support Small Businesses';
  String _supportSmallBusinessIcon = 'business';

  // Controllers for editing
  final _titleController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  final List<String> _iconOptions = [
    'business',
    'favorite',
    'handshake',
    'support',
    'local_offer',
    'volunteer_activism',
    'group_work',
    'store',
  ];

  @override
  void initState() {
    super.initState();
    _loadFeatureSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadFeatureSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore.collection('app_settings').doc('features').get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _supportSmallBusinessEnabled = data['support_small_business_enabled'] ?? false;
          _supportSmallBusinessTitle = data['support_small_business_title'] ?? 'Support Small Businesses';
          _supportSmallBusinessIcon = data['support_small_business_icon'] ?? 'business';
          _titleController.text = _supportSmallBusinessTitle;
        });
      } else {
        // Create default settings if document doesn't exist
        await _createDefaultSettings();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error loading settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createDefaultSettings() async {
    try {
      await _firestore.collection('app_settings').doc('features').set({
        'support_small_business_enabled': false,
        'support_small_business_title': 'Support Small Businesses',
        'support_small_business_icon': 'business',
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _supportSmallBusinessEnabled = false;
        _supportSmallBusinessTitle = 'Support Small Businesses';
        _supportSmallBusinessIcon = 'business';
        _titleController.text = _supportSmallBusinessTitle;
      });
    } catch (e) {
      debugPrint('Error creating default settings: $e');
    }
  }

  Future<void> _saveFeatureSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedTitle = _titleController.text.trim().isEmpty
          ? 'Support Small Businesses'
          : _titleController.text.trim();

      await _firestore.collection('app_settings').doc('features').set({
        'support_small_business_enabled': _supportSmallBusinessEnabled,
        'support_small_business_title': updatedTitle,
        'support_small_business_icon': _supportSmallBusinessIcon,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _supportSmallBusinessTitle = updatedTitle;
      });

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
            context,
            'Feature settings saved successfully!'
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, 'Error saving settings: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'business':
        return Icons.business;
      case 'favorite':
        return Icons.favorite;
      case 'handshake':
        return Icons.handshake;
      case 'support':
        return Icons.support;
      case 'local_offer':
        return Icons.local_offer;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'group_work':
        return Icons.group_work;
      case 'store':
        return Icons.store;
      default:
        return Icons.business;
    }
  }

  String _getIconDisplayName(BuildContext context, String iconName) {
    final appLocalizations = AppLocalizations.of(context)!;

    switch (iconName) {
      case 'business':
        return appLocalizations.business;
      case 'favorite':
        return appLocalizations.heart;
      case 'handshake':
        return appLocalizations.handshake;
      case 'support':
        return appLocalizations.support;
      case 'local_offer':
        return appLocalizations.offer;
      case 'volunteer_activism':
        return appLocalizations.volunteer;
      case 'group_work':
        return appLocalizations.group;
      case 'store':
        return appLocalizations.store;
      default:
        return appLocalizations.business;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(appLocalizations.loadingFeatureSettings),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations.appFeaturesManagement,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appLocalizations.controlWhichFeaturesVisible,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Support Small Business Feature
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Feature Header
                  Row(
                    children: [
                      Icon(
                        _getIconData(_supportSmallBusinessIcon),
                        color: Colors.purple,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        appLocalizations.supportSmallBusinessScreen,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    appLocalizations.toggleVisibilityDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Enable/Disable Toggle
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _supportSmallBusinessEnabled
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _supportSmallBusinessEnabled
                            ? Colors.green.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _supportSmallBusinessEnabled
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _supportSmallBusinessEnabled
                              ? Colors.green[700]
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _supportSmallBusinessEnabled
                                    ? appLocalizations.featureIsEnabled
                                    : appLocalizations.featureIsDisabled,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _supportSmallBusinessEnabled
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                ),
                              ),
                              Text(
                                _supportSmallBusinessEnabled
                                    ? appLocalizations.customersCanSeeThisScreen
                                    : appLocalizations.thisScreenIsHidden,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _supportSmallBusinessEnabled,
                          onChanged: (value) {
                            setState(() {
                              _supportSmallBusinessEnabled = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  if (_supportSmallBusinessEnabled) ...[
                    const SizedBox(height: 20),

                    // Customization Section
                    Text(
                      appLocalizations.customizationOptions,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title Customization
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: appLocalizations.menuTitle,
                        border: const OutlineInputBorder(),
                        hintText: appLocalizations.supportSmallBusinessTitle,
                      ),
                      onChanged: (value) {
                        // Auto-save functionality could be added here
                      },
                    ),

                    const SizedBox(height: 16),

                    // Icon Selection
                    Text(
                      appLocalizations.menuIcon,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _iconOptions.map((iconName) {
                        final isSelected = _supportSmallBusinessIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _supportSmallBusinessIcon = iconName;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconData(iconName),
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getIconDisplayName(context, iconName),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[600],
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Preview Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                appLocalizations.previewInAppDrawer,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getIconData(_supportSmallBusinessIcon),
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _titleController.text.isEmpty
                                      ? appLocalizations.supportSmallBusinessTitle
                                      : _titleController.text,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveFeatureSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? appLocalizations.saving : appLocalizations.saveFeatureSettings),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Information Card
          Card(
            color: Colors.blue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        appLocalizations.howItWorks,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appLocalizations.howItWorksDescription,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}