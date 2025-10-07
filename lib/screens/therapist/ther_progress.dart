import 'package:flutter/material.dart';
import 'package:capstone_2/screens/therapist/ther_tab.dart';

class TherProgress extends StatelessWidget {
  const TherProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF006A5B),
                  Color(0xFF004D42),
                ],
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Header with Tab Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Therapist Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Snapshot of patient activity, progress trends, and upcoming workflow.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const TherDashTab(initialTabIndex: 3), // Progress tab active
                    ],
                  ),
                ),
                // Content Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats Cards Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Active Patients',
                                  value: '3',
                                  subtitle: 'Currently under your care',
                                  icon: Icons.people,
                                  color: const Color(0xFF006A5B),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Pending Reports',
                                  value: '3',
                                  subtitle: 'Reports due this week',
                                  icon: Icons.assignment,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Upcoming Sessions',
                                  value: '3',
                                  subtitle: 'Next 3 days',
                                  icon: Icons.schedule,
                                  color: const Color(0xFF388E3C),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildStatCard(
                                  title: 'Avg Weekly Change',
                                  value: '+2.3%',
                                  subtitle: 'Across all domains',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          // Progress Charts Section
                          const Text(
                            'Progress Tracking',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          // Progress Charts Grid
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 1.1,
                            children: [
                              _buildProgressChart(
                                title: 'Motor',
                                status: 'On Track',
                                percentage: 75,
                                change: '+11% over last 7 days',
                                statusColor: const Color(0xFF4CAF50),
                              ),
                              _buildProgressChart(
                                title: 'Speech',
                                status: 'Watch',
                                percentage: 60,
                                change: '+8% over last 7 days',
                                statusColor: const Color(0xFFFF9800),
                              ),
                              _buildProgressChart(
                                title: 'Cognitive',
                                status: 'Needs Attention',
                                percentage: 40,
                                change: '+1% over last 7 days',
                                statusColor: const Color(0xFFFF5722),
                              ),
                              _buildProgressChart(
                                title: 'Socio-emotional',
                                status: 'On Track',
                                percentage: 80,
                                change: '+7% over last 7 days',
                                statusColor: const Color(0xFF4CAF50),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          // Upcoming Sessions Section
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildUpcomingSessions(),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                flex: 2,
                                child: _buildEngagementHeatmap(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          
                          // Active Patients Table
                          _buildActivePatients(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart({
    required String title,
    required String status,
    required int percentage,
    required String change,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            change,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF95A5A6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Upcoming Sessions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_today,
                color: const Color(0xFF006A5B),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          _buildSessionItem('Ava Santos', 'Teletherapy • 2025-09-27 at 10:00', 'Teletherapy'),
          _buildSessionItem('Mia Garcia', 'In-person • 2025-09-28 at 14:30', 'In-person'),
          _buildSessionItem('Liam Cruz', 'Teletherapy • 2025-09-29 at 09:15', 'Teletherapy'),
        ],
      ),
    );
  }

  Widget _buildSessionItem(String name, String details, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              type == 'Teletherapy' ? Icons.video_call : Icons.person,
              color: const Color(0xFF006A5B),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF95A5A6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: type == 'Teletherapy' 
                  ? const Color(0xFF2196F3).withOpacity(0.1)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                color: type == 'Teletherapy' 
                    ? const Color(0xFF2196F3)
                    : const Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementHeatmap() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engagement Heatmap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 15),
          
          // Heatmap Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              // Random engagement levels for demo
              final engagement = (index % 4) + 1;
              return Container(
                decoration: BoxDecoration(
                  color: Color.lerp(
                    const Color(0xFFE8F5E8),
                    const Color(0xFF006A5B),
                    engagement / 4,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          
          const Row(
            children: [
              Text(
                'Green = frequent activity, light = skipped',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF95A5A6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivePatients() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Patients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 15),
          
          // Table Header
          const Row(
            children: [
              Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(child: Text('Age', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(flex: 2, child: Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(child: Text('Overall', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
              Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7F8C8D)))),
            ],
          ),
          const SizedBox(height: 10),
          
          _buildPatientRow('Ava Santos', '7', 'ASD Level 1', 70, 'On Track', const Color(0xFF4CAF50)),
          _buildPatientRow('Liam Cruz', '6', 'ADHD Combined', 55, 'Watch', const Color(0xFFFF9800)),
          _buildPatientRow('Mia Garcia', '8', 'Developmental Delay', 46, 'Needs Attention', const Color(0xFFFF5722)),
        ],
      ),
    );
  }

  Widget _buildPatientRow(String name, String age, String diagnosis, int progress, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              age,
              style: const TextStyle(color: Color(0xFF7F8C8D)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              diagnosis,
              style: const TextStyle(color: Color(0xFF7F8C8D)),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$progress%',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}