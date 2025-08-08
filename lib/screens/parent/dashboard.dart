import 'package:capstone_2/screens/auth/login_as.dart';
import 'package:flutter/material.dart';
import 'package:capstone_2/screens/parent/dashboard_tabbar.dart';
import 'package:capstone_2/screens/parent/games_option.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

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
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 90,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.child_care,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      "Kindora",
                      style: TextStyle(
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Dashboard',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Dashboard tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dashboard selected')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Profile tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile selected')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sticky_note_2_rounded),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Materials',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Materials tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Materials selected')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.games),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Games',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Games tapped');
                // Direct navigation instead of named route
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GamesOption()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_rounded),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Schedule',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Schedule tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedule selected')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_alt),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Journal',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Journal tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Journal selected')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              iconColor: const Color(0xFF006A5B),
              title: const Text(
                'Chat',
                style: TextStyle(
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                print('Chat tapped');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat selected')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                // Show logout confirmation
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginAs()));
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'asset/images/map.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text(
                                  'Map Placeholder\n(Replace with your map)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            },
                          ),
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
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.search,
                            color: Color(0xFF67AFA5),
                          ),
                          onPressed: () {
                            print('Search pressed');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Search functionality')),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.45,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
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
                          child: Column(
                            children: [
                              Container(
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                child: Image.asset(
                                  'asset/images/tiny.png',
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.business,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('The Tiny House Clinic',
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star,
                                      color: starIndex < 5
                                          ? Colors.yellow
                                          : Colors.grey,
                                      size: 15,
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 5.0),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                    'A center with all your needed services',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12.0)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: 8,
                  ),
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
