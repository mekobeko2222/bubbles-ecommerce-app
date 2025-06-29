// File Location: lib/admin_tabs/admin_ml_patterns_tab.dart

import 'package:flutter/material.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';
import 'package:bubbles_ecommerce_app/services/error_handler.dart';
import 'package:bubbles_ecommerce_app/generated/app_localizations.dart';
import 'package:bubbles_ecommerce_app/models/customer_pattern.dart';
import 'package:bubbles_ecommerce_app/models/reorder_prediction.dart';

class AdminMLPatternsTab extends StatefulWidget {
  const AdminMLPatternsTab({super.key});

  @override
  State<AdminMLPatternsTab> createState() => _AdminMLPatternsTabState();
}

class _AdminMLPatternsTabState extends State<AdminMLPatternsTab> {
  final PatternService _patternService = PatternService();
  late AppLocalizations _appLocalizations;

  bool _isProcessingPatterns = false;
  bool _isFindingReminders = false;
  bool _isQueuingReminders = false;

  Map<String, dynamic>? _lastProcessingResult;
  List<Map<String, dynamic>> _remindersFound = [];
  Map<String, dynamic>? _analyticsData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appLocalizations = AppLocalizations.of(context)!;
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await _patternService.getPatternAnalytics();
      setState(() {
        _analyticsData = analytics;
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Failed to load analytics: $e');
    }
  }

  Future<void> _processAllPatterns() async {
    setState(() {
      _isProcessingPatterns = true;
    });

    try {
      final result = await _patternService.processAllPatterns();
      setState(() {
        _lastProcessingResult = result;
      });

      if (result['success'] == true) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Processed ${result['patternsProcessed']} patterns, generated ${result['predictionsGenerated']} predictions',
        );
        _loadAnalytics(); // Refresh analytics
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Processing failed: ${result['error']}');
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error processing patterns: $e');
    } finally {
      setState(() {
        _isProcessingPatterns = false;
      });
    }
  }

  Future<void> _findUsersNeedingReminders() async {
    setState(() {
      _isFindingReminders = true;
      _remindersFound.clear();
    });

    try {
      final reminders = await _patternService.findUsersNeedingReminders();
      setState(() {
        _remindersFound = reminders;
      });

      ErrorHandler.showSuccessSnackBar(
        context,
        'Found ${reminders.length} users who need reminders',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error finding reminders: $e');
    } finally {
      setState(() {
        _isFindingReminders = false;
      });
    }
  }

  Future<void> _queueSelectedReminders() async {
    if (_remindersFound.isEmpty) {
      ErrorHandler.showWarningSnackBar(context, 'No reminders to queue');
      return;
    }

    setState(() {
      _isQueuingReminders = true;
    });

    try {
      final queuedCount = await _patternService.queueReminders(_remindersFound);

      ErrorHandler.showSuccessSnackBar(
        context,
        'Queued $queuedCount reminders for sending',
      );

      setState(() {
        _remindersFound.clear(); // Clear after queuing
      });
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, 'Error queuing reminders: $e');
    } finally {
      setState(() {
        _isQueuingReminders = false;
      });
    }
  }

  Widget _buildAnalyticsCard() {
    if (_analyticsData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_analyticsData!.containsKey('error')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading analytics: ${_analyticsData!['error']}'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'ML System Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  'Total Patterns',
                  '${_analyticsData!['totalPatterns'] ?? 0}',
                  Icons.pattern,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Reliable Patterns',
                  '${_analyticsData!['reliablePatterns'] ?? 0}',
                  Icons.verified,
                  Colors.green,
                ),
                _buildStatCard(
                  'Total Predictions',
                  '${_analyticsData!['totalPredictions'] ?? 0}',
                  Icons.lightbulb,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Users with Patterns',
                  '${_analyticsData!['uniqueUsers'] ?? 0}',
                  Icons.people,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Avg Confidence',
                    '${((_analyticsData!['avgConfidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.teal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Reliability Rate',
                    '${(_analyticsData!['reliabilityRate'] ?? 0.0).toStringAsFixed(1)}%',
                    Icons.thumb_up,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Card(
      elevation: 4,
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
                  'ML System Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Process Patterns Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessingPatterns ? null : _processAllPatterns,
                icon: _isProcessingPatterns
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_isProcessingPatterns ? 'Processing...' : 'Process All Patterns'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Find Reminders Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isFindingReminders ? null : _findUsersNeedingReminders,
                icon: _isFindingReminders
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.notifications),
                label: Text(_isFindingReminders ? 'Finding...' : 'Find Users Needing Reminders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Queue Reminders Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isQueuingReminders || _remindersFound.isEmpty)
                    ? null
                    : _queueSelectedReminders,
                icon: _isQueuingReminders
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.send),
                label: Text(_isQueuingReminders
                    ? 'Queueing...'
                    : 'Queue ${_remindersFound.length} Reminders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _remindersFound.isEmpty ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Refresh Analytics Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastProcessingResult() {
    if (_lastProcessingResult == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _lastProcessingResult!['success'] == true
                      ? Icons.check_circle
                      : Icons.error,
                  color: _lastProcessingResult!['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last Processing Result',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_lastProcessingResult!['success'] == true) ...[
              Text('✅ Patterns Processed: ${_lastProcessingResult!['patternsProcessed']}'),
              Text('✅ Predictions Generated: ${_lastProcessingResult!['predictionsGenerated']}'),
              Text('✅ Users Processed: ${_lastProcessingResult!['usersProcessed']}'),
            ] else ...[
              Text('❌ Error: ${_lastProcessingResult!['error']}'),
            ],
            Text('🕒 ${_lastProcessingResult!['timestamp']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersFound() {
    if (_remindersFound.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notification_important, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Reminders Found (${_remindersFound.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _remindersFound.length,
                itemBuilder: (context, index) {
                  final reminderData = _remindersFound[index];
                  final prediction = reminderData['prediction'] as ReorderPrediction;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: prediction.isOverdue
                            ? Colors.red
                            : prediction.isUrgent
                            ? Colors.orange
                            : Colors.blue,
                        child: Text(
                          '${prediction.daysUntilNextOrder}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(
                        prediction.productName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User: ${reminderData['userId']}'),
                          Text('Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%'),
                          Text('Quantity: ${prediction.avgQuantity}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          prediction.urgencyLevel,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: prediction.isOverdue
                            ? Colors.red.withOpacity(0.2)
                            : prediction.isUrgent
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.psychology, color: Theme.of(context).primaryColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ML Pattern Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Analyze customer patterns and manage reorder reminders',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Analytics Card
          _buildAnalyticsCard(),

          const SizedBox(height: 16),

          // Control Panel
          _buildControlPanel(),

          const SizedBox(height: 16),

          // Last Processing Result
          _buildLastProcessingResult(),

          const SizedBox(height: 16),

          // Reminders Found
          _buildRemindersFound(),

          const SizedBox(height: 24),

          // Help Section
          Card(
            color: Colors.blue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'How to Use ML System',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Click "Process All Patterns" to analyze customer ordering habits\n'
                        '2. Click "Find Users Needing Reminders" to identify customers ready for reorders\n'
                        '3. Review the reminder list and click "Queue Reminders" to schedule notifications\n'
                        '4. Check your notification system to send the queued reminders\n'
                        '5. Use "Refresh Analytics" to see updated statistics',
                    style: TextStyle(height: 1.5),
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