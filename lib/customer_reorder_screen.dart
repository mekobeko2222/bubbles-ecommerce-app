// File Location: lib/customer_reorder_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart';
import 'package:bubbles_ecommerce_app/basket_manager.dart';
import 'package:bubbles_ecommerce_app/models/reorder_prediction.dart';
import 'package:bubbles_ecommerce_app/models/user_pattern_settings.dart';
import 'package:bubbles_ecommerce_app/models/product.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerReorderScreen extends StatefulWidget {
  const CustomerReorderScreen({super.key});

  @override
  State<CustomerReorderScreen> createState() => _CustomerReorderScreenState();
}

class _CustomerReorderScreenState extends State<CustomerReorderScreen> {
  final PatternService _patternService = PatternService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserReorderPredictions? _userPredictions;
  UserPatternSettings? _userSettings;
  bool _isLoading = true;
  late AppLocalizations _appLocalizations;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final predictions = await _patternService.getUserPredictions(user.uid);
      final settings = await _patternService.getUserSettings(user.uid);

      setState(() {
        _userPredictions = predictions;
        _userSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorHandler.showErrorSnackBar(context, 'Failed to load reorder data: $e');
    }
  }

  Future<void> _updateReminderSettings(bool enabled, String timing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final currentSettings = _userSettings ?? UserPatternSettings(userId: user.uid);
      final updatedSettings = currentSettings.copyWith(
        enableReminders: enabled,
        reminderTiming: timing,
      );

      final success = await _patternService.updateUserSettings(updatedSettings);

      if (success) {
        setState(() {
          _userSettings = updatedSettings;
        });
        ErrorHandler.showSuccessSnackBar(context, 'Settings updated successfully');
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Failed to update settings');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error updating settings: $e');
    }
  }

  Future<void> _addToBasket(ReorderPrediction prediction) async {
    try {
      // Get the actual product from Firestore
      final productDoc = await _firestore.collection('products').doc(prediction.productId).get();

      if (!productDoc.exists) {
        ErrorHandler.showErrorSnackBar(context, 'Product not found');
        return;
      }

      final product = Product.fromFirestore(productDoc);

      if (product.quantity <= 0) {
        ErrorHandler.showErrorSnackBar(context, 'Product is out of stock');
        return;
      }

      // Add to basket using BasketManager
      final basketManager = Provider.of<BasketManager>(context, listen: false);
      basketManager.addItem(product, prediction.avgQuantity);

      // Track user response
      await _patternService.trackReminderResponse(
        userId: FirebaseAuth.instance.currentUser!.uid,
        productId: prediction.productId,
        action: 'ordered',
        metadata: {
          'quantity': prediction.avgQuantity,
          'source': 'reorder_screen',
        },
      );

      ErrorHandler.showSuccessSnackBar(
        context,
        'Added ${prediction.avgQuantity} x ${prediction.productName} to basket',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to add to basket: $e');
    }
  }

  Future<void> _dismissPrediction(ReorderPrediction prediction) async {
    try {
      await _patternService.trackReminderResponse(
        userId: FirebaseAuth.instance.currentUser!.uid,
        productId: prediction.productId,
        action: 'dismissed',
        metadata: {
          'source': 'reorder_screen',
          'dismissedAt': DateTime.now().toIso8601String(),
        },
      );

      // Remove from local list
      if (_userPredictions != null) {
        final updatedPredictions = _userPredictions!.predictions
            .where((p) => p.productId != prediction.productId)
            .toList();

        setState(() {
          _userPredictions = _userPredictions!.copyWith(predictions: updatedPredictions);
        });
      }

      ErrorHandler.showInfoSnackBar(context, 'Reminder dismissed');
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to dismiss reminder: $e');
    }
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Reminder Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enable/Disable Reminders
            SwitchListTile(
              title: const Text('Enable Reorder Reminders'),
              subtitle: const Text('Get notified when it\'s time to reorder'),
              value: _userSettings?.enableReminders ?? true,
              onChanged: (value) {
                _updateReminderSettings(
                  value,
                  _userSettings?.reminderTiming ?? '2_days_before',
                );
              },
            ),

            const SizedBox(height: 12),

            // Reminder Timing
            if (_userSettings?.enableReminders == true) ...[
              const Text('Reminder Timing:'),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _userSettings?.reminderTiming ?? '2_days_before',
                isExpanded: true,
                items: UserPatternSettings.reminderTimingOptions.map((timing) {
                  return DropdownMenuItem(
                    value: timing,
                    child: Text(_getReminderTimingText(timing)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateReminderSettings(
                      _userSettings?.enableReminders ?? true,
                      value,
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getReminderTimingText(String timing) {
    switch (timing) {
      case '1_day_before':
        return 'One day before';
      case '2_days_before':
        return 'Two days before';
      case '3_days_before':
        return 'Three days before';
      case 'on_date':
        return 'On predicted date';
      default:
        return 'Two days before';
    }
  }

  Widget _buildPredictionCard(ReorderPrediction prediction) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: prediction.imageUrl.isNotEmpty
                      ? Image.network(
                    prediction.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  )
                      : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                ),

                const SizedBox(width: 16),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Usual quantity: ${prediction.avgQuantity}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            prediction.isOverdue
                                ? Icons.warning
                                : prediction.isUrgent
                                ? Icons.notification_important
                                : Icons.schedule,
                            size: 16,
                            color: prediction.isOverdue
                                ? Colors.red
                                : prediction.isUrgent
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            prediction.isOverdue
                                ? 'Overdue by ${-prediction.daysUntilNextOrder} days'
                                : prediction.daysUntilNextOrder == 0
                                ? 'Due today'
                                : 'Due in ${prediction.daysUntilNextOrder} days',
                            style: TextStyle(
                              fontSize: 12,
                              color: prediction.isOverdue
                                  ? Colors.red
                                  : prediction.isUrgent
                                  ? Colors.orange
                                  : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Confidence Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: prediction.confidence >= 0.8
                        ? Colors.green.withOpacity(0.2)
                        : prediction.confidence >= 0.6
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: prediction.confidence >= 0.8
                          ? Colors.green[700]
                          : prediction.confidence >= 0.6
                          ? Colors.orange[700]
                          : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _dismissPrediction(prediction),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Not Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToBasket(prediction),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: Text('Add ${prediction.avgQuantity} to Basket'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Reorder Suggestions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Place a few more orders and we\'ll start suggesting when to reorder your favorites!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Reorder'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
        ],

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Reorder Suggestions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI-powered recommendations based on your ordering patterns',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings Card
            _buildSettingsCard(),

            const SizedBox(height: 20),

            // Predictions Section
            if (_userPredictions == null || _userPredictions!.predictions.isEmpty)
              _buildEmptyState()
            else ...[
              // Urgent Section
              if (_userPredictions!.urgentPredictions.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.priority_high, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Urgent Reorders (${_userPredictions!.urgentPredictions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_userPredictions!.urgentPredictions
                    .map((prediction) => _buildPredictionCard(prediction))),
                const SizedBox(height: 20),
              ],

              // Upcoming Section
              if (_userPredictions!.upcomingPredictions.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Reorders (${_userPredictions!.upcomingPredictions.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_userPredictions!.upcomingPredictions
                    .map((prediction) => _buildPredictionCard(prediction))),
              ],
            ],
          ],
        ),
      ),
    );
  }
}