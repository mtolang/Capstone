import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kindora/screens/parent/parent_booking.dart';

class ParentTherapistProfilePage extends StatefulWidget {
  final String? therapistId; // Therapist document ID

  const ParentTherapistProfilePage({Key? key, this.therapistId})
      : super(key: key);

  @override
  State<ParentTherapistProfilePage> createState() =>
      _ParentTherapistProfilePageState();
}

class _ParentTherapistProfilePageState
    extends State<ParentTherapistProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample review data
  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Parent Sarah',
      'time': '2 days ago',
      'rating': 5,
      'comment':
          'Excellent therapist! Very patient and caring with my child. Highly recommended.',
      'avatar': 'asset/icons/user (1).png',
    },
    {
      'name': 'Parent Michael',
      'time': '1 week ago',
      'rating': 5,
      'comment':
          'Great experience! The therapist is very professional and knowledgeable.',
      'avatar': 'asset/icons/user (2).png',
    },
  ];

  // Therapist data variables
  Map<String, dynamic>? therapistData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTherapistData();
  }

  // Method to load therapist data from Firebase
  Future<void> _loadTherapistData() async {
    try {
      String therapistIdToUse = widget.therapistId ?? '';

      if (therapistIdToUse.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('TherapistAcc')
          .doc(therapistIdToUse)
          .get();

      if (doc.exists) {
        setState(() {
          therapistData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Therapist not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading therapist data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading therapist data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to load therapist reviews from Firebase
  Future<List<Map<String, dynamic>>> _loadTherapistReviews() async {
    try {
      String therapistIdToUse = widget.therapistId ?? '';

      final snapshot = await FirebaseFirestore.instance
          .collection('TherapistReviews')
          .where('therapistId', isEqualTo: therapistIdToUse)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['reviewerName'] ?? 'Anonymous',
          'time': _formatTimestamp(data['createdAt']),
          'rating': data['rating'] ?? 5,
          'comment': data['comment'] ?? '',
          'avatar': data['reviewerAvatar'] ?? 'asset/icons/user (1).png',
        };
      }).toList();
    } catch (e) {
      print('Error loading reviews: $e');
      return _reviews; // Fallback to sample data
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Recently';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // Show loading screen while fetching data
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF006A5B),
          title: const Text(
            'Therapist Profile',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF006A5B),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top wave background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.4),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF006A5B),
                      Color(0xFF67AFA5),
                    ],
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

          // Bottom wave background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: size.height * 0.25),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF67AFA5),
                      Colors.white,
                    ],
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

          // Main content
          Column(
            children: [
              // Custom AppBar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  bottom: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Therapist Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),

              // Profile section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile image
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFF006A5B),
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Therapist name
                    Text(
                      therapistData?['Full_Name'] ?? 'Therapist Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            color: index < 4
                                ? Colors.yellow[700]
                                : Colors.grey[300],
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
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
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Gallery'),
                    Tab(text: 'Reviews'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildGalleryTab(),
                      _buildReviewsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Button - Book Appointment
          Positioned(
            bottom: 30,
            right: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  // Navigate to booking page with therapist ID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentBookingPage(
                        therapistId: widget.therapistId,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  therapistData?['Full_Name'] ?? 'Therapist Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Experienced and dedicated therapist specializing in pediatric occupational therapy. Passionate about helping children reach their full potential.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Color(0xFF006A5B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        therapistData?['Address'] ?? 'Not provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone,
                        color: Color(0xFF006A5B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      therapistData?['Contact_Number'] ?? 'Not provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email,
                        color: Color(0xFF006A5B), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        therapistData?['Email'] ?? 'Not provided',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadTherapistReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reviews',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data ?? _reviews;

        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No Reviews Yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Be the first to leave a review!',
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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(review);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF006A5B),
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              // Review content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          color: index < review['rating']
                              ? Colors.yellow[700]
                              : Colors.grey[300],
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review['comment'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
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
