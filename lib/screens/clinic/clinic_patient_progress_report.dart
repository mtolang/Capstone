import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicPatientProgressReport extends StatefulWidget {
  final String? patientName;
  final Map<String, dynamic> progressData;

  const ClinicPatientProgressReport({
    Key? key,
    required this.patientName,
    required this.progressData,
  }) : super(key: key);

  @override
  State<ClinicPatientProgressReport> createState() =>
      _ClinicPatientProgressReportState();
}

class _ClinicPatientProgressReportState
    extends State<ClinicPatientProgressReport> {
  bool isEditing = false;
  late Map<String, dynamic> editableData;

  @override
  void initState() {
    super.initState();
    editableData = Map<String, dynamic>.from(widget.progressData);
  }

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
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress Report',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              widget.patientName ?? 'Unknown Patient',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (isEditing) {
                              _saveChanges();
                            }
                            isEditing = !isEditing;
                          });
                        },
                        icon: Icon(
                          isEditing ? Icons.save : Icons.edit,
                          color: Colors.white,
                        ),
                      ),
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
                          // Patient Information Section
                          _buildSection(
                            title: 'Patient Information',
                            icon: Icons.person,
                            children: [
                              _buildInfoRow('Child Name',
                                  editableData['childName'] ?? 'N/A'),
                              _buildInfoRow('Parent Name',
                                  editableData['parentName'] ?? 'N/A'),
                              _buildInfoRow('Age',
                                  editableData['patientInfo']?['age'] ?? 'N/A'),
                              _buildInfoRow(
                                  'Gender',
                                  editableData['patientInfo']?['gender'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Diagnosis',
                                  editableData['patientInfo']?['diagnosis'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Therapist Information Section
                          _buildSection(
                            title: 'Therapist Information',
                            icon: Icons.medical_services,
                            children: [
                              _buildInfoRow(
                                  'Therapist Name',
                                  editableData['therapistInfo']?['name'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Specialization',
                                  editableData['therapistInfo']
                                          ?['specialization'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Session Number',
                                  editableData['therapistInfo']
                                          ?['sessionNumber'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Session Duration',
                                  editableData['therapistInfo']
                                          ?['sessionDuration'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Attendance Summary Section
                          _buildSection(
                            title: 'Attendance Summary',
                            icon: Icons.calendar_today,
                            children: [
                              _buildInfoRow(
                                  'Total Sessions',
                                  editableData['attendance']
                                          ?['totalSessions'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Missed Sessions',
                                  editableData['attendance']
                                          ?['missedSessions'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Attendance Remarks',
                                  editableData['attendance']
                                          ?['attendanceRemarks'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Therapy Goals Section
                          _buildSection(
                            title: 'Therapy Goals',
                            icon: Icons.track_changes,
                            children: [
                              _buildInfoRow('Short-term Goals',
                                  editableData['goals']?['shortTerm'] ?? 'N/A'),
                              _buildInfoRow('Long-term Goals',
                                  editableData['goals']?['longTerm'] ?? 'N/A'),
                              _buildInfoRow(
                                  'Progress Notes',
                                  editableData['goals']?['progressNotes'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Developmental Domains Section
                          _buildDevelopmentalDomainsSection(),
                          const SizedBox(height: 20),

                          // Therapist Observations Section
                          _buildSection(
                            title: 'Therapist Observations',
                            icon: Icons.visibility,
                            children: [
                              _buildInfoRow(
                                  'Behavior During Session',
                                  editableData['observations']?['behavior'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Therapy Response',
                                  editableData['observations']?['response'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Family Involvement',
                                  editableData['observations']
                                          ?['familyInvolvement'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Tools Used',
                                  editableData['observations']?['toolsUsed'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Recommendations Section
                          _buildSection(
                            title: 'Recommendations',
                            icon: Icons.recommend,
                            children: [
                              _buildInfoRow(
                                  'Next Session Plan',
                                  editableData['recommendations']
                                          ?['nextSessionPlan'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Frequency',
                                  editableData['recommendations']
                                          ?['frequency'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Home Exercises',
                                  editableData['recommendations']
                                          ?['homeExercises'] ??
                                      'N/A'),
                              _buildInfoRow(
                                  'Referrals',
                                  editableData['recommendations']
                                          ?['referrals'] ??
                                      'N/A'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Report Metadata
                          _buildSection(
                            title: 'Report Information',
                            icon: Icons.info,
                            children: [
                              _buildInfoRow('Report Date',
                                  _formatDate(editableData['date'])),
                              _buildInfoRow('Session Date',
                                  _formatDate(editableData['sessionDate'])),
                              _buildInfoRow('Report Generated',
                                  _formatDate(editableData['reportDate'])),
                            ],
                          ),
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF006A5B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
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
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentalDomainsSection() {
    final domains =
        editableData['developmentalDomains'] as Map<String, dynamic>? ?? {};

    final domainNames = {
      'gross_motor': 'Gross Motor Skills',
      'fine_motor': 'Fine Motor Skills',
      'speech_language': 'Speech & Language',
      'cognitive': 'Cognitive Skills',
      'social_emotional': 'Social & Emotional',
      'self_help': 'Self-Help / Adaptive',
    };

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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Color(0xFF006A5B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Developmental Domains',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...domains.entries.map((entry) {
            final domainName = domainNames[entry.key] ?? entry.key;
            final domainData = entry.value as Map<String, dynamic>? ?? {};

            return _buildDomainCard(
              domainName,
              domainData['baseline'] ?? 'N/A',
              domainData['progress'] ?? 'N/A',
              domainData['remarks'] ?? 'N/A',
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDomainCard(
      String domainName, String baseline, String progress, String remarks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            domainName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _buildDomainRow('Baseline', baseline),
          _buildDomainRow('Current Progress', progress),
          _buildDomainRow('Remarks', remarks),
        ],
      ),
    );
  }

  Widget _buildDomainRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7F8C8D),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance
          .collection('ClinicProgress')
          .doc(widget.progressData['id'])
          .update(editableData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Progress report updated successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF006A5B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating report: $e',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
