// File Location: lib/admin_tabs/admin_ml_insights_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bubbles_ecommerce_app/services/pattern_service.dart';
import 'package:bubbles_ecommerce_app/services/reorder_reminder_service.dart';
import 'package:bubbles_ecommerce_app/models/customer_pattern.dart';
import 'package:bubbles_ecommerce_app/models/reorder_prediction.dart';

class AdminMLInsightsTab extends StatefulWidget {
  const AdminMLInsightsTab({super.key});

  @override
  State<AdminMLInsightsTab> createState() => _AdminMLInsightsTabState();
}

class _AdminMLInsightsTabState extends State<AdminMLInsightsTab> {
  final PatternService _patternService = PatternService();
  final ReorderReminderService _reminderService = ReorderReminderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _reminderStats;
  List<CustomerPattern> _topPatterns = [];
  List<Map<String, dynamic>> _customerInsights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Load all analytics data in parallel
      final results = await Future.wait([
        _patternService.getPatternAnalytics(),
        _reminderService.getReminderStats(),
        _getTopPatterns(),
        _getCustomerInsights(),
      ]);

      setState(() {
        _analyticsData = results[0] as Map<String, dynamic>;
        _reminderStats = results[1] as Map<String, dynamic>;
        _topPatterns = results[2] as List<CustomerPattern>;
        _customerInsights = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading analytics data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<CustomerPattern>> _getTopPatterns() async {
    try {
      final snapshot = await _firestore
          .collection('customer_patterns')
          .where('confidence', isGreaterThan: 0.5)
          .orderBy('confidence', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => CustomerPattern.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting top patterns: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getCustomerInsights() async {
    try {
      // Get customer behavior insights
      final insights = <Map<String, dynamic>>[];

      // Get users with most patterns
      final patternsSnapshot = await _firestore
          .collection('customer_patterns')
          .get();

      final userPatternCounts = <String, int>{};
      final userConfidenceScores = <String, List<double>>{};

      for (var doc in patternsSnapshot.docs) {
        final userId = doc.data()['userId'] as String;
        final confidence = (doc.data()['confidence'] ?? 0.0) as double;

        userPatternCounts[userId] = (userPatternCounts[userId] ?? 0) + 1;
        userConfidenceScores[userId] = (userConfidenceScores[userId] ?? [])..add(confidence);
      }

      // Create insights
      for (var userId in userPatternCounts.keys) {
        final patternCount = userPatternCounts[userId] ?? 0;
        final confidences = userConfidenceScores[userId] ?? [];
        final avgConfidence = confidences.isNotEmpty
            ? confidences.reduce((a, b) => a + b) / confidences.length
            : 0.0;

        insights.add({
          'userId': userId,
          'patternCount': patternCount,
          'avgConfidence': avgConfidence,
          'behavior': _getBehaviorType(patternCount, avgConfidence),
        });
      }

      insights.sort((a, b) => (b['patternCount'] as int).compareTo(a['patternCount'] as int));
      return insights.take(5).toList();
    } catch (e) {
      debugPrint('❌ Error getting customer insights: $e');
      return [];
    }
  }

  String _getBehaviorType(int patternCount, double avgConfidence) {
    if (patternCount >= 5 && avgConfidence >= 0.7) return 'Highly Predictable';
    if (patternCount >= 3 && avgConfidence >= 0.5) return 'Regular Customer';
    if (patternCount >= 2) return 'Developing Patterns';
    return 'New Customer';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading ML insights...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),

            // ML System Overview
            _buildMLOverview(),
            const SizedBox(height: 24),

            // Reminder Statistics
            _buildReminderStats(),
            const SizedBox(height: 24),

            // Top Performing Patterns
            _buildTopPatterns(),
            const SizedBox(height: 24),

            // Customer Behavior Insights
            _buildCustomerInsights(),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ML System Insights',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Artificial Intelligence Dashboard',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMLOverview() {
    if (_analyticsData == null) return const SizedBox.shrink();

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
                  'ML System Performance',
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
              childAspectRatio: 1.8,
              children: [
                _buildStatCard(
                  'Active Patterns',
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
                  'Predictions Generated',
                  '${_analyticsData!['totalPredictions'] ?? 0}',
                  Icons.lightbulb,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Users Tracked',
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
                    'System Accuracy',
                    '${(_analyticsData!['avgConfidence'] ?? 0.0 * 100).toStringAsFixed(1)}%',
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

  Widget _buildReminderStats() {
    if (_reminderStats == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Reminder System Performance',
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
              childAspectRatio: 1.8,
              children: [
                _buildStatCard(
                  'Reminders Sent (30d)',
                  '${_reminderStats!['totalRemindersSent30Days'] ?? 0}',
                  Icons.send,
                  Colors.green,
                ),
                _buildStatCard(
                  'Users Reminded',
                  '${_reminderStats!['uniqueUsersReminded'] ?? 0}',
                  Icons.person_pin,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Users Subscribed',
                  '${_reminderStats!['usersWithRemindersEnabled'] ?? 0}',
                  Icons.notifications_on,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Avg per User',
                  '${_reminderStats!['avgRemindersPerUser'] ?? '0'}',
                  Icons.repeat,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPatterns() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Top Performing Patterns',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_topPatterns.isEmpty)
              const Center(
                child: Text('No high-confidence patterns yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _topPatterns.length,
                itemBuilder: (context, index) {
                  final pattern = _topPatterns[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      child: Text(
                        '${(pattern.confidence * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(pattern.productId),
                    subtitle: Text(
                      '${pattern.orderCount} orders • Every ${pattern.avgDaysBetweenOrders.toInt()} days',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Reliable',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInsights() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_alt, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                Text(
                  'Customer Behavior Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_customerInsights.isEmpty)
              const Center(
                child: Text('No customer insights available yet'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _customerInsights.length,
                itemBuilder: (context, index) {
                  final insight = _customerInsights[index];
                  final behaviorColor = _getBehaviorColor(insight['behavior']);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: behaviorColor.withOpacity(0.2),
                      child: Text(
                        '${insight['patternCount']}',
                        style: TextStyle(
                          color: behaviorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('User ${insight['userId'].toString().substring(0, 8)}...'),
                    subtitle: Text(
                      '${insight['patternCount']} patterns • ${(insight['avgConfidence'] * 100).toInt()}% avg confidence',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: behaviorColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        insight['behavior'],
                        style: TextStyle(
                          color: behaviorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.amber[700]),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
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
              childAspectRatio: 2.5,
              children: [
                _buildActionButton(
                  'Process Patterns',
                  Icons.refresh,
                  Colors.blue,
                      () => _processAllPatterns(),
                ),
                _buildActionButton(
                  'Send Reminders',
                  Icons.send,
                  Colors.green,
                      () => _triggerReminders(),
                ),
                _buildActionButton(
                  'Export Data',
                  Icons.download,
                  Colors.purple,
                      () => _exportData(),
                ),
                _buildActionButton(
                  'System Health',
                  Icons.health_and_safety,
                  Colors.orange,
                      () => _checkSystemHealth(),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBehaviorColor(String behavior) {
    switch (behavior) {
      case 'Highly Predictable': return Colors.green;
      case 'Regular Customer': return Colors.blue;
      case 'Developing Patterns': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // Quick Action Methods
  Future<void> _processAllPatterns() async {
    // Implementation for processing patterns
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing all patterns...')),
    );
  }

  Future<void> _triggerReminders() async {
    // Implementation for triggering reminders
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Triggering reminder check...')),
    );
  }

  Future<void> _exportData() async {
    // Implementation for exporting data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting ML data...')),
    );
  }

  Future<void> _checkSystemHealth() async {
    // Implementation for system health check
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking system health...')),
    );
  }
}