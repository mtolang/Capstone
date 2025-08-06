import 'package:flutter/material.dart';

class DashTab extends StatefulWidget {
  final Function(int)? onTabChanged; // Add callback for parent widget

  const DashTab({Key? key, this.onTabChanged}) : super(key: key);

  @override
  State<DashTab> createState() => _DashTabState();
}

class _DashTabState extends State<DashTab> {
  int _selectedTabIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Notify parent widget about tab change
    widget.onTabChanged?.call(index);

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
    // Add your clinics navigation or logic here
    // Navigator.pushNamed(context, '/clinics');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clinics tab selected')),
    );
  }

  void _onTherapistsPressed() {
    print('Therapists tab pressed');

    Navigator.pushNamed(context, '/therdashboard');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Therapists tab selected')),
    );
  }

  void _onMaterialsPressed() {
    print('Materials tab pressed');
    // Add your materials navigation or logic here
    // Navigator.pushNamed(context, '/materials');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Materials tab selected')),
    );
  }

  Widget buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
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
