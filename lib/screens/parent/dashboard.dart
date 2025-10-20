import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/dashboard_tabbar.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'package:kindora/widgets/map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kindora/screens/parent/parent_clinic_profile.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
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
      drawer: const ParentNavbar(),
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
                  pinned: true,
                  expandedHeight: 70.0,
                  toolbarHeight: 70.0,
                  backgroundColor: Color(0xFF006A5B),
                  flexibleSpace: FlexibleSpaceBar(
                    title:
                        DashTab(initialSelectedIndex: 0), // Set to clinics tab
                    centerTitle: true,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 50),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Therapy Clinic Finder',
                      style: TextStyle(
                        color: Color(0xFF67AFA5),
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 1),
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search clinics...',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF67AFA5),
                          ),
                          onPressed: () {
                            // Optional: trigger search on button press
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
                // Firebase clinic grid
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ClinicAcc')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF006A5B),
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Error loading clinics: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No clinics available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final clinics = snapshot.data!.docs;

                    // Filter clinics based on search query
                    final filteredClinics = clinics.where((clinic) {
                      if (_searchQuery.isEmpty) return true;

                      final clinicData = clinic.data() as Map<String, dynamic>;
                      final clinicName = (clinicData['Clinic_Name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final clinicAddress = (clinicData['Address'] ?? '')
                          .toString()
                          .toLowerCase();
                      final userName = (clinicData['User_name'] ?? '')
                          .toString()
                          .toLowerCase();

                      return clinicName.contains(_searchQuery) ||
                          clinicAddress.contains(_searchQuery) ||
                          userName.contains(_searchQuery);
                    }).toList();
                    if (filteredClinics.isEmpty && _searchQuery.isNotEmpty) {
                      return const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              'No clinics found matching your search',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200.0,
                        mainAxisSpacing: 12.0,
                        crossAxisSpacing: 12.0,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final clinic = filteredClinics[index];
                          final clinicData =
                              clinic.data() as Map<String, dynamic>;

                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ParentClinicProfilePage(
                                      clinicId: clinic.id,
                                    ),
                                  ),
                                );
                              },
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
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: clinicData['Clinic_Image'] !=
                                                  null &&
                                              clinicData['Clinic_Image']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                              clinicData['Clinic_Image'],
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF006A5B)
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(10),
                                                      topRight:
                                                          Radius.circular(10),
                                                    ),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.local_hospital,
                                                      size: 40,
                                                      color: Color(0xFF006A5B),
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF006A5B)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.local_hospital,
                                                  size: 40,
                                                  color: Color(0xFF006A5B),
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        clinicData['Clinic_Name'] ??
                                            'Unknown Clinic',
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
                                    // Rating stars
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
                                          clinicData['Address'] ??
                                              'Address not available',
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
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: Text(
                                        'Open',
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
                        childCount: filteredClinics.length,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 35,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {
                print('FAB tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add new functionality')),
                );
              },
              backgroundColor: const Color(0xFF006A5B),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Content-only version (no AppBar, Drawer, or TabBar)
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
                    'Therapy Clinic Finder',
                    style: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 1),
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
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search clinics...',
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
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ClinicAcc')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF006A5B),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Error loading clinics: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No clinics available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final clinics = snapshot.data!.docs;

                  final filteredClinics = clinics.where((clinic) {
                    if (_searchQuery.isEmpty) return true;

                    final clinicData = clinic.data() as Map<String, dynamic>;
                    final clinicName = (clinicData['Clinic_Name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final clinicAddress =
                        (clinicData['Address'] ?? '').toString().toLowerCase();
                    final userName = (clinicData['User_name'] ?? '')
                        .toString()
                        .toLowerCase();

                    return clinicName.contains(_searchQuery) ||
                        clinicAddress.contains(_searchQuery) ||
                        userName.contains(_searchQuery);
                  }).toList();

                  if (filteredClinics.isEmpty && _searchQuery.isNotEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            'No clinics found matching your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200.0,
                      mainAxisSpacing: 12.0,
                      crossAxisSpacing: 12.0,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final clinic = filteredClinics[index];
                        final clinicData =
                            clinic.data() as Map<String, dynamic>;

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ParentClinicProfilePage(
                                    clinicId: clinic.id,
                                  ),
                                ),
                              );
                            },
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
                                        Icons.local_hospital,
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
                                      clinicData['Clinic_Name'] ??
                                          'Clinic Name',
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                        clinicData['Address'] ?? 'Location',
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
                      childCount: filteredClinics.length,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 35,
          right: 30,
          child: FloatingActionButton(
            onPressed: () {
              print('FAB tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add new functionality')),
              );
            },
            backgroundColor: const Color(0xFF006A5B),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}
