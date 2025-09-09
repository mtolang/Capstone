import 'package:flutter/material.dart';

class ClinicNavBar extends StatelessWidget {
  const ClinicNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      size: 24,
                      color: Color(0xFF006A5B),
                    ),
                  ),

                  // Add spacing between logo and text
                  const SizedBox(width: 8.0),

                  // app name
                  const Text(
                    "TherapEase",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation items
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
            leading: const Icon(Icons.edit_calendar_rounded),
            iconColor: const Color(0xFF006A5B),
            title: const Text(
              'Booking',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/clinicbooking');
              print('Booking tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking selected')),
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
            leading: const Icon(Icons.edit_note_rounded),
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
              print('Patient List tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Patient List selected')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups_2),
            iconColor: const Color(0xFF006A5B),
            title: const Text(
              'Clinic Staff',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              print('Clinic Staff tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clinic Staff selected')),
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
              Navigator.pushNamed(context, '/patientselection');
              print('Chat tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat selected')),
              );
            },
          ),

          // Add a divider for visual separation for logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              print('Logout tapped');
              // Show logout confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Logout'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
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
