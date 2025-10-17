import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Debug widget to inspect AcceptedBooking database structure
/// Add this temporarily to your app to see the exact data structure
class DebugDatabaseViewer extends StatelessWidget {
  final String clinicId;

  const DebugDatabaseViewer({Key? key, required this.clinicId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug Viewer'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('clinicId', isEqualTo: clinicId)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // Extract nested data
              final originalRequestData = data['originalRequestData'];
              final additionalInfo = originalRequestData?['additionalInfo'];
              final contractInfo = originalRequestData?['contractInfo'];
              final bookingType = additionalInfo?['bookingType'];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text('Document: ${doc.id}'),
                  subtitle: Text('Type: ${bookingType ?? 'N/A'}'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Clinic ID', data['clinicId']),
                          _buildInfoRow('Status', data['status']),
                          const Divider(height: 24),
                          const Text('📋 Additional Info:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          _buildInfoRow('Booking Type', bookingType),
                          const SizedBox(height: 12),
                          if (bookingType == 'contract') ...[
                            const Text('🔶 Contract Info:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange)),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                                'Day of Week', contractInfo?['dayOfWeek']),
                            _buildInfoRow('Appointment Time',
                                contractInfo?['appointmentTime']),
                            const SizedBox(height: 12),
                          ],
                          const Text('📦 Full Data Structure:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[100],
                            child: SelectableText(
                              _formatJson(data),
                              style: const TextStyle(
                                  fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'null',
              style: TextStyle(
                color: value == null ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}: ${_formatValue(e.value)}')
        .join('\n');
  }

  String _formatValue(dynamic value) {
    if (value is Map) {
      return '\n  ' +
          value.entries
              .map((e) => '  ${e.key}: ${_formatValue(e.value)}')
              .join('\n  ');
    }
    return value.toString();
  }
}
