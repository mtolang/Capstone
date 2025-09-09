import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClinicBookingPage extends StatefulWidget {
  const ClinicBookingPage({Key? key}) : super(key: key);

  @override
  State<ClinicBookingPage> createState() => _ClinicBookingPageState();
}

class _ClinicBookingPageState extends State<ClinicBookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> bookings = [
    {
      'name': 'Joe Alwyn',
      'time': '02:00 - 03:00 PM',
      'color': Colors.teal,
    },
    {
      'name': 'Selena Gomez',
      'time': '03:00 - 04:00 PM',
      'color': Colors.lightGreen,
    },
    {
      'name': 'Lana Del Ray',
      'time': '04:00 - 05:00 PM',
      'color': Colors.blue,
    },
    {
      'name': 'Ed Sheeran',
      'time': '05:00 - 06:00 PM',
      'color': Colors.indigo,
    },
    {
      'name': 'Avril Lavigne',
      'time': '06:00 - 07:00 PM',
      'color': Colors.blueAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final today = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Booking Schedule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      body: Stack(
        children: [
          // Top wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.2),
              child: Image.asset(
                'asset/images/WAVE.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Bottom wave background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Image.asset(
                'asset/images/WAVE (1).png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF67AFA5), Colors.transparent],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              // Tab bar section
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF006A5B),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF006A5B),
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Today'),
                    Tab(text: 'Schedule'),
                    Tab(text: 'Request'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(today),
                    _buildScheduleTab(),
                    _buildRequestTab(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(Icons.calendar_today, color: Colors.white),
        onPressed: () {
          // TODO: Add booking setup logic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add new booking')),
          );
        },
      ),
    );
  }

  Widget _buildTodayTab(String today) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            today,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "That's it for today!",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF67AFA5),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 100), // Extra space for bottom wave
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 64,
            color: Color(0xFF67AFA5),
          ),
          SizedBox(height: 16),
          Text(
            'Schedule',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View all upcoming appointments',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF67AFA5),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pending_actions,
            size: 64,
            color: Color(0xFF67AFA5),
          ),
          SizedBox(height: 16),
          Text(
            'Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF006A5B),
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Manage booking requests',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF67AFA5),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: booking['color'],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF67AFA5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        booking['time'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF67AFA5),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A5B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.link,
                              size: 14,
                              color: Color(0xFF006A5B),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Meet Link',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
