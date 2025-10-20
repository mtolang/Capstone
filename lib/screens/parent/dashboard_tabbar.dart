import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/dashboard.dart';
import 'package:kindora/screens/parent/ther_dash.dart';
import 'package:kindora/screens/parent/materials.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';

class DashTab extends StatefulWidget {
  final int initialSelectedIndex; // Which tab to show initially

  const DashTab({
    super.key,
    this.initialSelectedIndex = 0, // Default to Clinics tab
  });

  @override
  State<DashTab> createState() => _DashTabState();
}

class _DashTabState extends State<DashTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialSelectedIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const ParentNavbar(),
      body: Stack(
        children: [
          // Top ellipse background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),
          // Bottom ellipse background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
                ),
              ),
            ),
          ),
          // Main content with TabBar
          Column(
            children: [
              // TabBar - Beautiful rounded design
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
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
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Clinics'),
                    Tab(text: 'Therapists'),
                    Tab(text: 'Materials'),
                  ],
                ),
              ),
              // TabBarView with content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    DashboardContent(), // Clinics page content
                    TherapistsDashboardContent(), // Therapists page content
                    MaterialsPageContent(), // Materials page content
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
