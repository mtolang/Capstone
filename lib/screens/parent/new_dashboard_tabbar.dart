import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'package:kindora/screens/parent/parent_therapist_profile.dart';
import 'package:kindora/screens/parent/parent_clinic_profile.dart';
import 'package:kindora/widgets/map.dart';

class NewDashboardTabBar extends StatefulWidget {
  final int initialSelectedIndex; // Which tab to show initially

  const NewDashboardTabBar({
    super.key,
    this.initialSelectedIndex = 0, // Default to Clinics tab
  });

  @override
  State<NewDashboardTabBar> createState() => _NewDashboardTabBarState();
}

class _NewDashboardTabBarState extends State<NewDashboardTabBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialSelectedIndex;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _currentIndex,
    );

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Clinics', icon: Icon(Icons.local_hospital)),
            Tab(text: 'Therapists', icon: Icon(Icons.person)),
          ],
        ),
      ),
      drawer: const ParentNavbar(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ClinicTabContent(),
          TherapistTabContent(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI Assistant feature coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(
          Icons.smart_toy,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// Clinic Tab Content
class ClinicTabContent extends StatefulWidget {
  const ClinicTabContent({super.key});

  @override
  State<ClinicTabContent> createState() => _ClinicTabContentState();
}

class _ClinicTabContentState extends State<ClinicTabContent> {
  List<Map<String, dynamic>> clinics = [];
  List<Map<String, dynamic>> filteredClinics = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('ClinicAcc').get();

      final loadedClinics = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['Clinic_Name'] ?? 'Unknown Clinic',
          'userName': data['User_name'] ?? '',
          'email': data['Email'] ?? '',
          'address': data['Address'] ?? '',
          'contactNumber': data['Contact_Number'] ?? '',
          'services': data['Services'] ?? [],
        };
      }).toList();

      setState(() {
        clinics = loadedClinics;
        filteredClinics = loadedClinics;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading clinics: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterClinics(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredClinics = clinics;
      } else {
        filteredClinics = clinics.where((clinic) {
          final name = clinic['name'].toLowerCase();
          final address = clinic['address'].toLowerCase();
          final userName = clinic['userName'].toLowerCase();
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              address.contains(searchQuery) ||
              userName.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background images with ellipse design like materials page
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.30),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 255, 255, 255)
                  ],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(); // Gradient fallback
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.3),
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
                  return Container(); // Gradient fallback
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: <Widget>[
              // Map section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Stack(
                      children: [
                        // Real map widget
                        const Maps(title: 'Nearby Clinics'),
                        // Interactive overlay
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _openFullMap(context, 'clinics');
                              },
                              child: Container(),
                            ),
                          ),
                        ),
                        // Map controls
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006A5B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Full Map',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterClinics,
                      decoration: const InputDecoration(
                        hintText: 'Search clinics...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF67AFA5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              // Clinics grid
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006A5B),
                    ),
                  ),
                )
              else if (filteredClinics.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No clinics found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final clinic = filteredClinics[index];
                      return _buildClinicCard(clinic);
                    },
                    childCount: filteredClinics.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 35,
          right: 30,
          child: ClipOval(
            child: Material(
              color: const Color(0xFF006A5B),
              child: InkWell(
                splashColor: Colors.white.withOpacity(0.3),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Assistant feature coming soon!'),
                      backgroundColor: Color(0xFF006A5B),
                    ),
                  );
                },
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic) {
    return GestureDetector(
      onTap: () => _showClinicDetails(context, clinic),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic header
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF006A5B), Color(0xFF00A693)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_hospital,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            // Clinic name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                clinic['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            // Star rating
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: starIndex < 4 ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ),
            // Address
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  clinic['address'].isEmpty
                      ? 'Address not provided'
                      : clinic['address'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            // View details button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF006A5B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                ),
              ),
              child: const Text(
                'View Details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClinicDetails(BuildContext context, Map<String, dynamic> clinic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF006A5B),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  clinic['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Username', clinic['userName']),
              _buildDetailRow('Email', clinic['email']),
              _buildDetailRow('Contact', clinic['contactNumber']),
              _buildDetailRow('Address', clinic['address']),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '4.0 Rating • Professional Clinic',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bookAppointment(context, clinic);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(BuildContext context, Map<String, dynamic> clinic) {
    // Navigate to ParentClinicProfilePage with the selected clinic's ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentClinicProfilePage(
          clinicId: clinic['id'], // Pass the clinic's document ID
        ),
      ),
    );
  }

  void _openFullMap(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              type == 'clinics'
                  ? 'Nearby Clinics Map'
                  : 'Nearby Therapists Map',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF006A5B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Maps(
              title:
                  type == 'clinics' ? 'Nearby Clinics' : 'Nearby Therapists'),
        ),
      ),
    );
  }
}

// Therapist Tab Content
class TherapistTabContent extends StatefulWidget {
  const TherapistTabContent({super.key});

  @override
  State<TherapistTabContent> createState() => _TherapistTabContentState();
}

class _TherapistTabContentState extends State<TherapistTabContent> {
  List<Map<String, dynamic>> therapists = [];
  List<Map<String, dynamic>> filteredTherapists = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('TherapistAcc')
          .where('acceptedBy', isEqualTo: 'Admin')
          .get();

      final loadedTherapists = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['Full_Name'] ?? 'Unknown Therapist',
          'userName': data['User_Name'] ?? '',
          'email': data['Email'] ?? '',
          'address': data['Address'] ?? '',
          'contactNumber': data['Contact_Number'] ?? '',
          'acceptedAt': data['acceptedAt'],
        };
      }).toList();

      setState(() {
        therapists = loadedTherapists;
        filteredTherapists = loadedTherapists;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading therapists: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterTherapists(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTherapists = therapists;
      } else {
        filteredTherapists = therapists.where((therapist) {
          final name = therapist['name'].toLowerCase();
          final address = therapist['address'].toLowerCase();
          final userName = therapist['userName'].toLowerCase();
          final searchQuery = query.toLowerCase();

          return name.contains(searchQuery) ||
              address.contains(searchQuery) ||
              userName.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Background images with ellipse design like materials page
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.30),
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
                  return Container(); // Gradient fallback
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.3),
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
                  return Container(); // Gradient fallback
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: <Widget>[
              // Map section
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Stack(
                      children: [
                        // Real map widget
                        const Maps(title: 'Nearby Therapists'),
                        // Interactive overlay
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _openFullMap(context, 'therapists');
                              },
                              child: Container(),
                            ),
                          ),
                        ),
                        // Map controls
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF006A5B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Full Map',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterTherapists,
                      decoration: const InputDecoration(
                        hintText: 'Search therapists...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        suffixIcon: Icon(
                          Icons.search,
                          color: Color(0xFF67AFA5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              // Therapists grid
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF006A5B),
                    ),
                  ),
                )
              else if (filteredTherapists.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No therapists found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final therapist = filteredTherapists[index];
                      return _buildTherapistCard(therapist);
                    },
                    childCount: filteredTherapists.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 35,
          right: 30,
          child: ClipOval(
            child: Material(
              color: const Color(0xFF006A5B),
              child: InkWell(
                splashColor: Colors.white.withOpacity(0.3),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Assistant feature coming soon!'),
                      backgroundColor: Color(0xFF006A5B),
                    ),
                  );
                },
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTherapistCard(Map<String, dynamic> therapist) {
    return GestureDetector(
      onTap: () => _showTherapistDetails(context, therapist),
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Therapist header
            Container(
              height: 120,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF006A5B),
                    Color.fromARGB(255, 255, 255, 255)
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            // Therapist name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                therapist['name'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            // Star rating
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    Icons.star,
                    size: 16,
                    color: starIndex < 4 ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
            ),
            // Address
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  therapist['address'].isEmpty
                      ? 'Address not provided'
                      : therapist['address'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            // View details button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF006A5B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15.0),
                  bottomRight: Radius.circular(15.0),
                ),
              ),
              child: const Text(
                'View Details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTherapistDetails(
      BuildContext context, Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF006A5B),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  therapist['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Username', therapist['userName']),
              _buildDetailRow('Email', therapist['email']),
              _buildDetailRow('Contact', therapist['contactNumber']),
              _buildDetailRow('Address', therapist['address']),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '4.0 Rating • Professional Therapist',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bookAppointment(context, therapist);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Book Appointment',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(BuildContext context, Map<String, dynamic> therapist) {
    // Navigate to ParentTherapistProfilePage with the selected therapist's ID
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentTherapistProfilePage(
          therapistId: therapist['id'], // Pass the therapist's document ID
        ),
      ),
    );
  }

  void _openFullMap(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              type == 'clinics'
                  ? 'Nearby Clinics Map'
                  : 'Nearby Therapists Map',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF006A5B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Maps(
              title:
                  type == 'clinics' ? 'Nearby Clinics' : 'Nearby Therapists'),
        ),
      ),
    );
  }
}
