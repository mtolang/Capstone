import 'package:flutter/material.dart';
import 'package:kindora/services/call_history_service.dart';
import 'package:kindora/services/dynamic_user_service.dart';
import 'package:intl/intl.dart';

/// Call History Screen
///
/// PURPOSE: Display user's call history from Firebase
/// FEATURES:
/// - Shows all calls (completed, declined, cancelled, missed)
/// - Displays call duration for completed calls
/// - Shows caller/recipient information
/// - Color-coded by call status
/// - Sortable by date/time

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  List<Map<String, dynamic>> _callHistory = [];
  Map<String, int> _callStats = {};
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      setState(() => _isLoading = true);

      // Get current user ID
      _currentUserId = await DynamicUserService.getCurrentUserId();
      if (_currentUserId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load call history and statistics
      final history =
          await CallHistoryService().getUserCallHistory(_currentUserId!);
      final stats =
          await CallHistoryService().getCallStatistics(_currentUserId!);

      setState(() {
        _callHistory = history;
        _callStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading call history: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      case 'missed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.call_end;
      case 'declined':
        return Icons.call_end;
      case 'cancelled':
        return Icons.cancel;
      case 'missed':
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'No duration';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${remainingSeconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  String _formatDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is DateTime) {
        date = timestamp;
      } else {
        date = timestamp.toDate();
      }
      return DateFormat('MMM dd, yyyy - HH:mm').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCallHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Card
                if (_callStats.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Call Statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                                'Total', _callStats['total'] ?? 0, Colors.blue),
                            _buildStatItem('Completed',
                                _callStats['completed'] ?? 0, Colors.green),
                            _buildStatItem('Missed', _callStats['missed'] ?? 0,
                                Colors.grey),
                            _buildStatItem('Declined',
                                _callStats['declined'] ?? 0, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Call History List
                Expanded(
                  child: _callHistory.isEmpty
                      ? const Center(
                          child: Text(
                            'No call history found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _callHistory.length,
                          itemBuilder: (context, index) {
                            final call = _callHistory[index];
                            return _buildCallHistoryItem(call);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCallHistoryItem(Map<String, dynamic> call) {
    final status = call['status'] as String? ?? 'unknown';
    final role = call['role'] as String? ?? 'unknown';
    final isOutgoing = role == 'caller';

    // Determine display name based on role
    final displayName = isOutgoing
        ? (call['recipientName'] as String? ?? 'Unknown')
        : (call['callerName'] as String? ?? 'Unknown');

    final duration = call['duration'] as int? ?? 0;
    final startTime = call['startTime'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.2),
          child: Icon(
            isOutgoing ? Icons.call_made : Icons.call_received,
            color: _getStatusColor(status),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isOutgoing ? "Outgoing" : "Incoming"} • ${status.toUpperCase()}',
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (duration > 0) ...[
              Text('Duration: ${_formatDuration(duration)}'),
            ],
            Text(_formatDate(startTime)),
          ],
        ),
        trailing: Icon(
          _getStatusIcon(status),
          color: _getStatusColor(status),
        ),
        isThreeLine: true,
      ),
    );
  }
}
