import 'package:flutter/material.dart';

class DashTab extends StatefulWidget {
  const DashTab({Key? key}) : super(key: key);

  @override
  State<DashTab> createState() => _DashTabState();
}

class _DashTabState extends State<DashTab> {
  int _selectedTabIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Handle different actions based on tab index
    switch (index) {
      case 0:
        _onClinicsPressed();
        break;
      case 1:
        _onTherapistsPressed();
        break;
      case 2:
        _onMaterialsPressed();
        break;
    }
  }

  // OnPressed methods for each tab
  void _onClinicsPressed() {
    print('Clinics tab pressed');
    Navigator.pushNamed(context, '/parentdashboard');
    // Add your clinics navigation or logic here
    // Example: Navigator.pushNamed(context, '/clinics');
  }

  void _onTherapistsPressed() {
    print('Therapists tab pressed');
    Navigator.pushNamed(context, 'therdashboard');
    // Add your therapists navigation or logic here
    // Example: Navigator.pushNamed(context, '/therapists');
  }

  void _onMaterialsPressed() {
    print('Materials tab pressed');
    // Add your materials navigation or logic here
    // Example: Navigator.pushNamed(context, '/materials');
  }

  Widget buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _onTabTapped(index);
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color.fromARGB(255, 3, 62, 54)
                  : Colors.white,
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
      width: 350,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          buildTab('Clinics', 0),
          buildTab('Therapists', 1),
          buildTab('Materials', 2),
        ],
      ),
    );
  }
}
