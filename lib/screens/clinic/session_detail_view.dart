import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SessionDetailView extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  final int sessionNumber;

  const SessionDetailView({
    Key? key,
    required this.sessionData,
    required this.sessionNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Session $sessionNumber Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card with Session Info
            _buildHeaderCard(),
            const SizedBox(height: 20),

            // Session Details
            if (sessionData['sessionDate'] != null ||
                sessionData['duration'] != null ||
                sessionData['therapistName'] != null)
              _buildSectionCard(
                'Session Information',
                Icons.info,
                [
                  if (sessionData['sessionDate'] != null)
                    _buildInfoRow('Date', _formatDate(sessionData['sessionDate'])),
                  if (sessionData['duration'] != null)
                    _buildInfoRow('Duration', '${sessionData['duration']} minutes'),
                  if (sessionData['therapistName'] != null)
                    _buildInfoRow('Therapist', sessionData['therapistName']),
                  if (sessionData['sessionType'] != null)
                    _buildInfoRow('Session Type', sessionData['sessionType']),
                ],
              ),

            const SizedBox(height: 20),

            // Skill Ratings
            if (sessionData['skillsRating'] != null)
              _buildSkillsSection(),

            const SizedBox(height: 20),

            // Activities
            if (sessionData['activities'] != null &&
                sessionData['activities'].toString().isNotEmpty)
              _buildSectionCard(
                'Activities Performed',
                Icons.extension,
                [
                  _buildTextContent(sessionData['activities']),
                ],
              ),

            const SizedBox(height: 20),

            // Progress Notes
            if (sessionData['progressNotes'] != null &&
                sessionData['progressNotes'].toString().isNotEmpty)
              _buildSectionCard(
                'Progress Notes',
                Icons.note_alt,
                [
                  _buildTextContent(sessionData['progressNotes']),
                ],
              ),

            const SizedBox(height: 20),

            // Goals
            if (sessionData['goals'] != null &&
                sessionData['goals'].toString().isNotEmpty)
              _buildSectionCard(
                'Session Goals',
                Icons.flag,
                [
                  _buildTextContent(sessionData['goals']),
                ],
              ),

            const SizedBox(height: 20),

            // Home Exercises
            if (sessionData['homeExercises'] != null &&
                sessionData['homeExercises'].toString().isNotEmpty)
              _buildSectionCard(
                'Home Exercise Recommendations',
                Icons.home,
                [
                  _buildTextContent(sessionData['homeExercises']),
                ],
              ),

            const SizedBox(height: 20),

            // Next Session Plan
            if (sessionData['nextSessionPlan'] != null &&
                sessionData['nextSessionPlan'].toString().isNotEmpty)
              _buildSectionCard(
                'Next Session Plan',
                Icons.arrow_forward,
                [
                  _buildTextContent(sessionData['nextSessionPlan']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    String dateStr = 'Unknown date';
    try {
      final timestamp = sessionData['createdAt'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        dateStr = DateFormat('MMMM dd, yyyy').format(date);
      }
    } catch (e) {
      // Use default
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A5B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session $sessionNumber',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sessionData['childName'] != null) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  sessionData['childName'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Icon(icon, color: const Color(0xFF006A5B), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(dynamic content) {
    return Text(
      content?.toString() ?? 'No information provided',
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF2C3E50),
        height: 1.5,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = sessionData['skillsRating'] as Map<String, dynamic>?;
    if (skills == null || skills.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      'Skills Assessment',
      Icons.stars,
      [
        ...skills.entries.map((entry) {
          return _buildSkillRating(
            _formatSkillName(entry.key),
            entry.value ?? 0,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSkillRating(String skillName, dynamic rating) {
    int ratingValue = 0;
    if (rating is int) {
      ratingValue = rating;
    } else if (rating is double) {
      ratingValue = rating.round();
    } else if (rating is String) {
      ratingValue = int.tryParse(rating) ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            skillName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...List.generate(5, (index) {
                final isActive = index < ratingValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.star,
                    size: 20,
                    color: isActive ? const Color(0xFFFFB800) : Colors.grey[300],
                  ),
                );
              }),
              const SizedBox(width: 8),
              Text(
                '$ratingValue/5',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSkillName(String key) {
    // Convert camelCase to Title Case
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return result.substring(0, 1).toUpperCase() + result.substring(1);
  }

  String _formatDate(dynamic date) {
    try {
      if (date is Timestamp) {
        return DateFormat('MMMM dd, yyyy').format(date.toDate());
      } else if (date is String) {
        return date;
      }
    } catch (e) {
      // Return as is
    }
    return 'Unknown date';
  }
}
