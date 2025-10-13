import 'package:flutter/material.dart';
import 'package:kindora/screens/auth/login_as.dart';
import 'package:kindora/helper/therapist_auth.dart';

class TherapistNavbar extends StatelessWidget {
  final String currentPage;

  const TherapistNavbar({
    Key? key,
    required this.currentPage,
  }) : super(key: key);

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
                  Image.asset("asset/logo1.png",
                      width: 40.0, height: 40.0), // logo

                  // Add spacing between logo and text
                  const SizedBox(width: 8.0),

                  // app name
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

          // Profile
          _buildNavItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            routeName: '/therapistprofile',
            isSelected: currentPage == 'profile',
          ),

          // Booking
          _buildNavItem(
            context,
            icon: Icons.edit_calendar_rounded,
            title: 'Booking',
            routeName: '/therapistbookingmain',
            isSelected: currentPage == 'booking',
          ),

          // Materials
          _buildNavItem(
            context,
            icon: Icons.sticky_note_2_rounded,
            title: 'Materials',
            routeName: '/therapistmaterials',
            isSelected: currentPage == 'materials',
          ),

          // Patient List
          _buildNavItem(
            context,
            icon: Icons.edit_note_rounded,
            title: 'Patient List',
            routeName: '/therapistpatients',
            isSelected: currentPage == 'patients',
          ),

          // Clinic Staff
          _buildNavItem(
            context,
            icon: Icons.groups_2,
            title: 'Clinic Staff',
            routeName: '/therapiststaff',
            isSelected: currentPage == 'staff',
          ),

          // Chat
          _buildNavItem(
            context,
            icon: Icons.message,
            title: 'Chat',
            routeName: '/therapistpatientselection',
            isSelected: currentPage == 'chat',
          ),

          // Add a divider for visual separation for logout
          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Color(0xFF006A5B),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            onTap: () async {
              await _handleLogout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String routeName,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF006A5B).withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF006A5B) : const Color(0xFF006A5B),
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFF006A5B) : const Color(0xFF006A5B),
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF006A5B),
                size: 16,
              )
            : null,
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          if (!isSelected) {
            _navigateToPage(context, routeName, title);
          }
        },
      ),
    );
  }

  void _navigateToPage(
      BuildContext context, String routeName, String pageName) {
    try {
      Navigator.pushNamed(context, routeName);
    } catch (e) {
      // If route doesn't exist, show a placeholder or error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$pageName page is coming soon!'),
          backgroundColor: const Color(0xFF006A5B),
        ),
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Show confirmation dialog
      bool? confirmLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirmLogout == true) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006A5B)),
              ),
            );
          },
        );

        // Sign out
        await TherapistAuthService.signOut();

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();

          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginAs()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (context.mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
