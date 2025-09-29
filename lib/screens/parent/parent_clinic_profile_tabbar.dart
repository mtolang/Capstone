import 'package:flutter/material.dart';

class ParentClinicProfileTabBar extends StatefulWidget {
  const ParentClinicProfileTabBar({Key? key}) : super(key: key);

  @override
  State<ParentClinicProfileTabBar> createState() =>
      _ParentClinicProfileTabBarState();
}

class _ParentClinicProfileTabBarState extends State<ParentClinicProfileTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF006A5B),
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF006A5B),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            indicatorPadding: const EdgeInsets.all(4),
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Gallery'),
              Tab(text: 'Reviews'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileTab(),
              _buildGalleryTab(),
              _buildReviewsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Text(
        'Profile Tab Content',
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          color: Color(0xFF006A5B),
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Gallery Coming Soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Photos and videos will be available here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return const Center(
      child: Text(
        'Reviews Tab Content',
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Poppins',
          color: Color(0xFF006A5B),
        ),
      ),
    );
  }
}
