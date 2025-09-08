import 'package:flutter/material.dart';

class TherDashTab extends StatefulWidget {
  final int initialTabIndex;
  const TherDashTab({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<TherDashTab> createState() => _TherDashTabState();
}

class _TherDashTabState extends State<TherDashTab> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Navigate to different screens based on tab selection
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/therapistprofile');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/therapistgallery');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/therapistreview');
        break;
    }
  }

  Widget buildTab(String label, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _navigateToTab(index),
        child: Container(
          height: 40,
          decoration: _selectedTabIndex == index
              ? ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(255, 3, 62, 54),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350, // Adjust the width as needed
      height: 40,
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildTab('Profile', 0),
          buildTab('Gallery', 1),
          buildTab('Reviews', 2),
        ],
      ),
    );
  }
}
