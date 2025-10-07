import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedUserType = 0; // 0: Carer, 1: Clinic, 2: Therapist
  int _selectedTab = 0; // 0: Accounts, 1: Pending

  // Sample data for demonstration
  final List<Map<String, dynamic>> _acceptedUsers = [
    {
      'name': 'Taylor Swift',
      'type': 'Carer',
      'icon': Icons.visibility,
      'date': '2024-10-01',
    },
    {
      'name': 'Jeremy Adan',
      'type': 'Carer', 
      'icon': Icons.visibility,
      'date': '2024-10-02',
    },
    {
      'name': 'Dr. Smith',
      'type': 'Clinic',
      'icon': Icons.visibility,
      'date': '2024-10-03',
    },
    {
      'name': 'Sarah Johnson',
      'type': 'Therapist',
      'icon': Icons.visibility,
      'date': '2024-10-04',
    },
  ];

  final List<Map<String, dynamic>> _pendingUsers = [
    {
      'name': 'John Doe',
      'type': 'Carer',
      'icon': Icons.visibility,
      'date': '2024-10-06',
    },
    {
      'name': 'Jane Wilson',
      'type': 'Clinic',
      'icon': Icons.visibility,
      'date': '2024-10-06',
    },
    {
      'name': 'Mike Brown',
      'type': 'Therapist',
      'icon': Icons.visibility,
      'date': '2024-10-07',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredUsers(List<Map<String, dynamic>> users) {
    final userTypes = ['Carer', 'Clinic', 'Therapist'];
    final selectedType = userTypes[_selectedUserType];
    return users.where((user) => user['type'] == selectedType).toList();
  }

  void _acceptUser(Map<String, dynamic> user) {
    setState(() {
      _pendingUsers.remove(user);
      _acceptedUsers.add(user);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user['name']} has been accepted!'),
        backgroundColor: const Color(0xFF006A5B),
      ),
    );
  }

  void _rejectUser(Map<String, dynamic> user) {
    setState(() {
      _pendingUsers.remove(user);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user['name']} has been rejected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _removeUser(Map<String, dynamic> user) {
    setState(() {
      _acceptedUsers.remove(user);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${user['name']} has been removed!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewUserProfile(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${user['name']} Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${user['name']}'),
              const SizedBox(height: 8),
              Text('Type: ${user['type']}'),
              const SizedBox(height: 8),
              Text('Date Joined: ${user['date']}'),
              const SizedBox(height: 16),
              const Text('Additional details would be shown here when connected to backend.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF006A5B),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // User type selector (Carer, Clinic, Therapist)
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildUserTypeTab('Carer', 0),
                _buildUserTypeTab('Clinic', 1),
                _buildUserTypeTab('Therapist', 2),
              ],
            ),
          ),
          
          // Content area
          Expanded(
            child: Column(
              children: [
                // Tab bar for Accounts/Pending
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildBottomTab('Accounts', 0),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBottomTab('Pending', 1),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // User list
                Expanded(
                  child: _selectedTab == 0 
                    ? _buildUserList(_getFilteredUsers(_acceptedUsers), false)
                    : _buildUserList(_getFilteredUsers(_pendingUsers), true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeTab(String title, int index) {
    final isSelected = _selectedUserType == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedUserType = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF006A5B) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTab(String title, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _tabController.animateTo(index);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006A5B) : Colors.grey[300],
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, bool isPending) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No pending users' : 'No accepted users',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Eye icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User name
              Expanded(
                child: Text(
                  user['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              
              // Action buttons
              if (isPending) ...[
                // Accept button
                GestureDetector(
                  onTap: () => _acceptUser(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006A5B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Reject button
                GestureDetector(
                  onTap: () => _rejectUser(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Remove button for accepted users
                GestureDetector(
                  onTap: () => _removeUser(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(width: 8),
              
              // View button
              GestureDetector(
                onTap: () => _viewUserProfile(user),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A5B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}