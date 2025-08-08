import 'package:flutter/material.dart';
import 'package:capstone_2/screens/parent/dashboard_tabbar.dart';

class TherapistsDashboard extends StatelessWidget {
  const TherapistsDashboard({Key? key}) : super(key: key);

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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          color: Colors.white,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),

      // drawer or sidebar of hamburger menu
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 90,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.white, // background color of the head title
                ),
                child: Row(
                  children: [
                    // Use placeholder if image doesn't exist
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    // Add spacing between logo and text
                    const SizedBox(width: 8.0),

                    // app name
                    const Text(
                      "TherapEase",
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

            // Add your other side bar items
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
            // Add more items as needed

            // Add a divider for visual separation for logout
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout), // Icon for logout
              title: const Text('Logout'), // Text for logout
              onTap: () {
                Navigator.pop(context);
                print('Logout tapped');
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Logged out successfully')),
                          );
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

      //body
      body: Stack(
        children: [
          // top background
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
              ),
            ),
          ),

          // bottom background
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
                      true, // Set to true if you want it pinned, false for floating
                  expandedHeight: 100.0,
                  toolbarHeight: 100.0, // Set the toolbar height
                  backgroundColor:
                      Color(0xFF006A5B), // Make the background transparent
                  flexibleSpace: FlexibleSpaceBar(
                    title:
                        DashTab(), // Make DashTab the content of the flexibleSpace
                    centerTitle: true, // Center the title
                  ),
                ),

                // top height of the therapy clinic finder and/or spacing of therapy clinic finder and custom tab bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                // Therapy clinic finder
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Therapists Finder',
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

                // top height of the map
                const SliverToBoxAdapter(
                  child: SizedBox(height: 1),
                ),

                // code for map (placeholder)
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
                          child: const Center(
                            child: Text(
                              'Map Placeholder\n(Replace with your map)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
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

                // top height of the grid and/or spacing of grid and search bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),

                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200.0,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 12.0,
                    childAspectRatio: 0.7,
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
                              // Placeholder for therapist image
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10),
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),
                              const Text('Therapist Name',
                                  style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    color: starIndex < 5
                                        ? Colors.yellow
                                        : Colors.grey,
                                    // Adjust star color based on the rating
                                    size: 15,
                                  );
                                }),
                              ),
                              const SizedBox(height: 5.0),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('Occupational and Speech Therapist',
                                    style: TextStyle(fontSize: 12.0),
                                    textAlign: TextAlign.center),
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
}
