import 'package:flutter/material.dart';
import 'package:capstone_2/screens/parent/games_option.dart';
import 'package:capstone_2/screens/auth/login_as.dart';

class ParentNavbar extends StatelessWidget {
  const ParentNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'asset/logo1.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Container(
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
                          );
                        },
                      ),
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
              Navigator.pushNamed(context, '/thertherapistsideselect');
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
    );
  }
}

class TherapistNavbar extends StatelessWidget {
  const TherapistNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'asset/logo1.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF006A5B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
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
            leading: const Icon(Icons.people),
            iconColor: const Color(0xFF006A5B),
            title: const Text(
              'Patient List',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showPatientList(context);
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
              Navigator.pushNamed(context, '/patientselection');
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
    );
  }

  // Method to show patient list
  static void _showPatientList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF006A5B),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Patient List',
                      style: TextStyle(
                        color: Color(0xFF006A5B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF006A5B)),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Patient list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _getSamplePatients().length,
                    itemBuilder: (context, index) {
                      final patient = _getSamplePatients()[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF006A5B),
                            child: Text(
                              patient['name']![0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            patient['name']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Age: ${patient['age']} • ${patient['condition']}'),
                              Text(
                                'Next: ${patient['nextSession']}',
                                style: const TextStyle(
                                  color: Color(0xFF006A5B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF006A5B),
                            size: 16,
                          ),
                          onTap: () {
                            // Navigate to patient details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Viewing ${patient['name']} details'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Sample patient data
  static List<Map<String, String>> _getSamplePatients() {
    return [
      {
        'name': 'Emma Rodriguez',
        'age': '8',
        'condition': 'Speech Delay',
        'nextSession': 'Tomorrow 2:00 PM',
      },
      {
        'name': 'Liam Johnson',
        'age': '6',
        'condition': 'Articulation Disorder',
        'nextSession': 'Friday 10:00 AM',
      },
      {
        'name': 'Sophia Chen',
        'age': '7',
        'condition': 'Language Development',
        'nextSession': 'Monday 3:00 PM',
      },
      {
        'name': 'Noah Williams',
        'age': '5',
        'condition': 'Phonological Processing',
        'nextSession': 'Wednesday 11:00 AM',
      },
      {
        'name': 'Olivia Garcia',
        'age': '9',
        'condition': 'Fluency Disorder',
        'nextSession': 'Thursday 1:00 PM',
      },
      {
        'name': 'Ethan Brown',
        'age': '6',
        'condition': 'Social Communication',
        'nextSession': 'Friday 4:00 PM',
      },
      {
        'name': 'Ava Martinez',
        'age': '7',
        'condition': 'Voice Disorder',
        'nextSession': 'Next Tuesday 9:00 AM',
      },
      {
        'name': 'Mason Davis',
        'age': '8',
        'condition': 'Hearing Impairment',
        'nextSession': 'Next Wednesday 2:30 PM',
      },
    ];
  }
}
