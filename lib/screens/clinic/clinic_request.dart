import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicRequestScreen extends StatefulWidget {
  const ClinicRequestScreen({Key? key}) : super(key: key);

  @override
  State<ClinicRequestScreen> createState() => _ClinicRequestScreenState();
}

class _ClinicRequestScreenState extends State<ClinicRequestScreen> {
  DateTime currentWeek = DateTime.now();
  String? selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Booking Requests',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildWeekNavigator(),
          _buildWeekTable(),
          const SizedBox(height: 16),
          if (selectedDay != null) _buildDayRequestsList(),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final weekStart = _getWeekStart(currentWeek);
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF006A5B),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                currentWeek = currentWeek.subtract(const Duration(days: 7));
                selectedDay = null;
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.white),
          ),
          Text(
            '${DateFormat('MMM dd').format(weekStart)} - ${DateFormat('MMM dd, yyyy').format(weekEnd)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                currentWeek = currentWeek.add(const Duration(days: 7));
                selectedDay = null;
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTable() {
    final weekStart = _getWeekStart(currentWeek);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF006A5B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: days
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Data rows
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Request')
                .where('appointmentDetails.requestedDate',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
                .where('appointmentDetails.requestedDate',
                    isLessThan: Timestamp.fromDate(
                        weekStart.add(const Duration(days: 7))))
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006A5B),
                    ),
                  ),
                );
              }

              final requests = snapshot.data?.docs ?? [];

              // Group requests by day
              final Map<String, List<QueryDocumentSnapshot>> requestsByDay = {};
              for (final request in requests) {
                final data = request.data() as Map<String, dynamic>;
                final appointmentDetails =
                    data['appointmentDetails'] as Map<String, dynamic>? ?? {};
                final appointmentTimestamp =
                    appointmentDetails['requestedDate'] as Timestamp?;

                if (appointmentTimestamp != null) {
                  final appointmentDate = appointmentTimestamp.toDate();
                  final dayKey =
                      DateFormat('yyyy-MM-dd').format(appointmentDate);

                  if (!requestsByDay.containsKey(dayKey)) {
                    requestsByDay[dayKey] = [];
                  }
                  requestsByDay[dayKey]!.add(request);
                }
              }

              return Container(
                height: 120,
                child: Row(
                  children: List.generate(7, (index) {
                    final date = weekStart.add(Duration(days: index));
                    final dayKey = DateFormat('yyyy-MM-dd').format(date);
                    final dayRequests = requestsByDay[dayKey] ?? [];
                    final isSelected = selectedDay == dayKey;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = selectedDay == dayKey ? null : dayKey;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF006A5B).withOpacity(0.1)
                                : dayRequests.isNotEmpty
                                    ? Colors.blue.withOpacity(0.05)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF006A5B)
                                  : dayRequests.isNotEmpty
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? const Color(0xFF006A5B)
                                        : Colors.black87,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: dayRequests.isNotEmpty
                                        ? const Color(0xFF006A5B)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${dayRequests.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dayRequests.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                                if (dayRequests.isNotEmpty)
                                  const SizedBox(height: 4),
                                if (dayRequests.isNotEmpty)
                                  const Text(
                                    'requests',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayRequestsList() {
    final selectedDate = DateTime.parse(selectedDay!);
    final dayName = DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF006A5B),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        selectedDay = null;
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Request')
                    .where('appointmentDetails.requestedDate',
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(selectedDate))
                    .where('appointmentDetails.requestedDate',
                        isLessThan: Timestamp.fromDate(
                            selectedDate.add(const Duration(days: 1))))
                    .orderBy('appointmentDetails.requestedTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006A5B),
                      ),
                    );
                  }

                  final requests = snapshot.data?.docs ?? [];

                  if (requests.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No requests for this day',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final data = request.data() as Map<String, dynamic>;
                      return _buildDayRequestCard(request.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRequestCard(String requestId, Map<String, dynamic> data) {
    final parentInfo = data['parentInfo'] as Map<String, dynamic>? ?? {};
    final childInfo = data['childInfo'] as Map<String, dynamic>? ?? {};
    final appointmentDetails =
        data['appointmentDetails'] as Map<String, dynamic>? ?? {};

    final parentName = parentInfo['parentName'] ?? 'Unknown Parent';
    final childName = childInfo['childName'] ?? 'Unknown Child';
    final appointmentTime = appointmentDetails['requestedTime'] ?? 'TBD';
    final appointmentType = appointmentDetails['appointmentType'] ?? 'Therapy';
    final status = data['status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'pending'
              ? Colors.orange.withOpacity(0.3)
              : status == 'approved'
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                appointmentTime.split(' ')[0], // Show just the time part
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'for $childName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF67AFA5),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  appointmentType,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'pending'
                  ? Colors.orange.withOpacity(0.1)
                  : status == 'approved'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: status == 'pending'
                    ? Colors.orange
                    : status == 'approved'
                        ? Colors.green
                        : Colors.red,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
