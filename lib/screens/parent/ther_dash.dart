import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/dashboard_tabbar.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'package:kindora/screens/parent/parent_therapist_profile.dart';
import 'package:kindora/widgets/map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TherapistsDashboard extends StatefulWidget {
  const TherapistsDashboard({super.key});

  @override
  State<TherapistsDashboard> createState() => _TherapistsDashboardState();
}

class _TherapistsDashboardState extends State<TherapistsDashboard> {
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
      ),

      // drawer or sidebar of hamburger menu
      drawer: const ParentNavbar(),

      //body
      body: Stack(
        children: [
          // Background images with fallback gradients
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
                const SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned:
                      false, // Set to false so it doesn't stay on top when scrolling
                  expandedHeight: 100.0,
                  toolbarHeight: 100.0, // Set the toolbar height
                  backgroundColor:
                      Colors.transparent, // Make the background transparent
                  flexibleSpace: FlexibleSpaceBar(
                    title: DashTab(
                        initialSelectedIndex:
                            1), // Set to therapists tab (index 1)
                    centerTitle: true, // Center the title
                  ),
                ),

                // top height of the therapy clinic finder and/or spacing of therapy clinic finder and custom tab bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // Search Therapists header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Search Therapists',
                      style: TextStyle(
                        color: Color(0xFF006A5B),
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),

                // top height of the map
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),

                // code for map (OpenStreetMap implementation)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: SizedBox(
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: const Maps(title: "Find Therapists"),
                        ),
                      ),
                    ),
                  ),
                ),

                // top height of the searchbar and/or spacing of search bar and map
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),

                // code for the search bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterTherapists,
                      decoration: InputDecoration(
                        hintText: 'Search therapists by name, location...',
                        hintStyle: const TextStyle(fontFamily: 'Poppins'),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF67AFA5),
                          ),
                          onPressed: () {
                            // Search is already triggered by onChanged
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // top height of the grid and/or spacing of grid and search bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),

                // Loading indicator or therapists grid
                SliverToBoxAdapter(
                  child: isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(50.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF006A5B),
                            ),
                          ),
                        )
                      : filteredTherapists.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(50.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      therapists.isEmpty
                                          ? Icons.person_off
                                          : Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      therapists.isEmpty
                                          ? 'No therapists available'
                                          : 'No therapists found',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    if (therapists.isNotEmpty)
                                      const Text(
                                        'Try adjusting your search criteria',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                ),

                // Therapists grid
                if (!isLoading && filteredTherapists.isNotEmpty)
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final therapist = filteredTherapists[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                _showTherapistDetails(context, therapist);
                              },
                              borderRadius: BorderRadius.circular(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Therapist image placeholder
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006A5B)
                                          .withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Color(0xFF006A5B),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),

                                  // Therapist name
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      therapist['name'],
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Rating stars (placeholder)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          Icons.star,
                                          color: starIndex < 4
                                              ? Colors.yellow[700]
                                              : Colors.grey[300],
                                          size: 12,
                                        );
                                      }),
                                    ),
                                  ),

                                  // Location
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        therapist['address'],
                                        style: const TextStyle(
                                          fontSize: 10.0,
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),

                                  // Status indicator
                                  Container(
                                    margin: const EdgeInsets.all(8.0),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      'Available',
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredTherapists.length,
                    ),
                  ),
              ],
            ),
          ),
          // Floating Action Button (FAB)
          Positioned(
            bottom: 35, // distance from the bottom
            right: 30, // distance from the right
            child: ClipOval(
              child: Material(
                color: const Color(0xFF006A5B), // FAB background color
                child: InkWell(
                  onTap: () {
                    print('FAB tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Floating Action Button tapped')),
                    );
                  },
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                backgroundColor: const Color(0xFF006A5B).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF006A5B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  therapist['name'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Verified Therapist',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
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
                  color: Color(0xFF006A5B),
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
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                color: Colors.black87,
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
}

// Content-only version (no AppBar, Drawer, or TabBar)
class TherapistsDashboardContent extends StatefulWidget {
  const TherapistsDashboardContent({super.key});

  @override
  State<TherapistsDashboardContent> createState() =>
      _TherapistsDashboardContentState();
}

class _TherapistsDashboardContentState
    extends State<TherapistsDashboardContent> {
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
                  return Container();
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
                  return Container();
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Search Therapists',
                    style: TextStyle(
                      color: Color(0xFF006A5B),
                      fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: const Maps(title: "Find Therapists"),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterTherapists,
                    decoration: InputDecoration(
                      hintText: 'Search therapists...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF67AFA5),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 15),
              ),
              SliverToBoxAdapter(
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF006A5B),
                          ),
                        ),
                      )
                    : filteredTherapists.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_search,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    therapists.isEmpty
                                        ? 'No Therapists Available'
                                        : 'No Therapists Found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  if (therapists.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
              if (!isLoading && filteredTherapists.isNotEmpty)
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final therapist = filteredTherapists[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () =>
                              _showTherapistDetails(context, therapist),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10.0),
                                      topRight: Radius.circular(10.0),
                                    ),
                                    color: const Color(0xFF67AFA5),
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
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    therapist['name'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (starIndex) {
                                      return Icon(
                                        starIndex < 4
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      therapist['address'].isEmpty
                                          ? 'Location not provided'
                                          : therapist['address'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontFamily: 'Poppins',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF006A5B),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(10.0),
                                      bottomRight: Radius.circular(10.0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Available',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filteredTherapists.length,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 35,
          right: 30,
          child: ClipOval(
            child: Material(
              color: const Color(0xFF006A5B),
              child: InkWell(
                onTap: () {
                  print('FAB tapped');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAB Tapped!')),
                  );
                },
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
                backgroundColor: const Color(0xFF006A5B).withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF006A5B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  therapist['name'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Verified Therapist',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
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
                  color: Color(0xFF006A5B),
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
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(BuildContext context, Map<String, dynamic> therapist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentTherapistProfilePage(
          therapistId: therapist['id'],
        ),
      ),
    );
  }
}
