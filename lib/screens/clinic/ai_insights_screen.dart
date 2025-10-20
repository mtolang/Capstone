import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/therapy_ai_service.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TherapyProgressAIService _aiService;
  late TabController _tabController;

  String? clinicId;
  bool isLoading = false;
  Map<String, dynamic>? dashboardData;
  String? errorMessage;

  final List<String> categories = [
    'Fine Motor',
    'Gross Motor',
    'Sensory Processing',
    'Cognitive',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize AI service with your API key
    _aiService =
        TherapyProgressAIService('AIzaSyC2yYSFl7NSxVyicp3oKPqUbpMkkYPit98');
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getClinicId();
    if (clinicId != null) {
      await _loadDashboard();
    }
  }

  Future<void> _getClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('clinic_id');

    if (id == null) {
      final possibleKeys = ['user_id', 'clinicId', 'userId', 'id'];
      for (final key in possibleKeys) {
        id = prefs.getString(key);
        if (id != null) break;
      }
    }

    setState(() {
      clinicId = id;
    });
  }

  Future<void> _loadDashboard() async {
    if (clinicId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final analytics = await _aiService.generateDashboardAnalytics(clinicId!);

      setState(() {
        dashboardData = analytics;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'AI Insights',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
          ],
        ),
      ),
      body: clinicId == null
          ? _buildNoClinicIdView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCategoriesTab(),
              ],
            ),
    );
  }

  Widget _buildNoClinicIdView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Clinic ID Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in again to access AI insights.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF006A5B),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, size: 64, color: Colors.orange[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A5B),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF006A5B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallStatistics(),
            const SizedBox(height: 24),
            _buildCategoryPerformanceCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF006A5B),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Center Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF006A5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Overall Average',
                  '${dashboardData!['overallAverage'].toStringAsFixed(1)}%',
                  Icons.trending_up,
                  const Color(0xFF006A5B),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Total Assessments',
                  '${dashboardData!['totalAssessments']}',
                  Icons.assignment,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Active Clients',
                  '${dashboardData!['uniqueClients']}',
                  Icons.people,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryPerformanceCards() {
    final categoryAnalytics = dashboardData!['categoryAnalytics']
        as Map<String, CategoryPerformanceAnalytics>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ...categoryAnalytics.entries
            .map((entry) => _buildCategoryCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF006A5B),
        ),
      );
    }

    if (dashboardData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final categoryAnalytics = dashboardData!['categoryAnalytics']
        as Map<String, CategoryPerformanceAnalytics>;

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: const Color(0xFF006A5B),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categoryAnalytics.length,
        itemBuilder: (context, index) {
          final entry = categoryAnalytics.entries.elementAt(index);
          return _buildDetailedCategoryCard(entry.key, entry.value);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
      String category, CategoryPerformanceAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _getScoreColor(analytics.averageScore),
          child: Text(
            '${analytics.averageScore.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${analytics.totalAssessments} assessments',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
            if (analytics.improvementRate != 0)
              Text(
                '${analytics.improvementRate > 0 ? '+' : ''}${analytics.improvementRate.toStringAsFixed(1)}% trend',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      analytics.improvementRate > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.insights, color: Color(0xFF006A5B)),
          onPressed: () => _showCategoryInsights(category, analytics),
        ),
      ),
    );
  }

  Widget _buildDetailedCategoryCard(
      String category, CategoryPerformanceAnalytics analytics) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: _getScoreColor(analytics.averageScore),
          child: Text(
            '${analytics.averageScore.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          'Average: ${analytics.averageScore.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
        children: [
          _buildInfoRow('Total Assessments', '${analytics.totalAssessments}'),
          _buildInfoRow('Improvement Rate',
              '${analytics.improvementRate.toStringAsFixed(1)}%'),
          if (analytics.topPerformers.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Top Performers:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              analytics.topPerformers.join(', '),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ],
          if (analytics.needsAttention.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Needs Attention:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              analytics.needsAttention.join(', '),
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCategoryInsights(category, analytics),
              icon: const Icon(Icons.psychology, size: 20),
              label: const Text(
                'View AI Insights',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> _showCategoryInsights(
    String category,
    CategoryPerformanceAnalytics analytics,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF006A5B),
              strokeWidth: 3,
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Generating AI Insights...',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please wait while our AI analyzes the data.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
    );

    try {
      final insights = await _aiService.generateCategoryInsights(analytics);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF006A5B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$category Insights',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                insights,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFF006A5B),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
