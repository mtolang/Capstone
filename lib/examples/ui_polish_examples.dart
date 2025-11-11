import 'package:flutter/material.dart';
import 'package:kindora/theme/app_theme.dart';
import 'package:kindora/widgets/polished_widgets.dart';

/// EXAMPLE: How to migrate an existing screen to use polished UI components
/// 
/// This file demonstrates before/after comparisons for common UI patterns.
/// Use these examples as a reference when updating your screens.

// ===========================================================================
// EXAMPLE 1: Simple Screen with Card List
// ===========================================================================

/// BEFORE: Old style without theme
class OldPatientListScreen extends StatelessWidget {
  const OldPatientListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF006A5B),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                'Patient ${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Age: ${20 + index}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// AFTER: Polished style with theme
class PolishedPatientListScreen extends StatelessWidget {
  const PolishedPatientListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const PolishedAppBar(
        title: 'Patients',
        gradient: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
            child: PolishedCard(
              onTap: () => print('Patient ${index + 1} tapped'),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient ${index + 1}',
                          style: AppTheme.headingSmall,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'Age: ${20 + index}',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                    label: 'Active',
                    color: AppTheme.successGreen,
                    icon: Icons.check_circle,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===========================================================================
// EXAMPLE 2: Form Screen
// ===========================================================================

/// BEFORE: Old form style
class OldFormScreen extends StatefulWidget {
  const OldFormScreen({Key? key}) : super(key: key);

  @override
  State<OldFormScreen> createState() => _OldFormScreenState();
}

class _OldFormScreenState extends State<OldFormScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A5B),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AFTER: Polished form style
class PolishedFormScreen extends StatefulWidget {
  const PolishedFormScreen({Key? key}) : super(key: key);

  @override
  State<PolishedFormScreen> createState() => _PolishedFormScreenState();
}

class _PolishedFormScreenState extends State<PolishedFormScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const PolishedAppBar(
        title: 'Add Patient',
        gradient: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: PolishedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient Information', style: AppTheme.headingMedium),
              const SizedBox(height: AppTheme.spacingL),
              
              PolishedTextField(
                controller: nameController,
                hint: 'Enter full name',
                label: 'Name',
                prefixIcon: Icons.person,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              PolishedTextField(
                controller: emailController,
                hint: 'Enter email address',
                label: 'Email',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppTheme.spacingL),
              
              PolishedButton(
                text: 'Save Patient',
                icon: Icons.save,
                gradient: true,
                loading: isLoading,
                width: double.infinity,
                onPressed: () {
                  setState(() => isLoading = true);
                  // Simulate save
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      setState(() => isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppTheme.successSnackbar('Patient saved successfully!'),
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// EXAMPLE 3: Details Screen with Empty State
// ===========================================================================

/// BEFORE: Old details screen
class OldDetailsScreen extends StatelessWidget {
  final bool hasData;
  
  const OldDetailsScreen({Key? key, this.hasData = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: hasData
          ? const Center(child: Text('Has data'))
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No data available'),
                ],
              ),
            ),
    );
  }
}

/// AFTER: Polished details screen
class PolishedDetailsScreen extends StatelessWidget {
  final bool hasData;
  final bool isLoading;
  
  const PolishedDetailsScreen({
    Key? key,
    this.hasData = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const PolishedAppBar(
        title: 'Patient Details',
        gradient: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: null, // Add edit functionality
          ),
        ],
      ),
      body: isLoading
          ? const LoadingOverlay(message: 'Loading details...')
          : hasData
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      // Header Card
                      PolishedCard(
                        elevated: true,
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primaryTealLight,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text('John Doe', style: AppTheme.headingMedium),
                            const SizedBox(height: AppTheme.spacingXS),
                            StatusChip(
                              label: 'Active',
                              color: AppTheme.successGreen,
                              icon: Icons.check_circle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      // Information Card
                      PolishedCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Personal Information',
                              icon: Icons.info,
                            ),
                            const InfoRow(
                              icon: Icons.cake,
                              label: 'Age',
                              value: '5 years old',
                            ),
                            const InfoRow(
                              icon: Icons.phone,
                              label: 'Contact',
                              value: '+1 234 567 8900',
                            ),
                            const InfoRow(
                              icon: Icons.email,
                              label: 'Email',
                              value: 'parent@example.com',
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            PolishedButton(
                              text: 'View Progress',
                              icon: Icons.trending_up,
                              width: double.infinity,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : EmptyStateWidget(
                  icon: Icons.folder_open,
                  title: 'No Details Available',
                  message: 'Patient details have not been added yet. Add information to see it here.',
                  actionLabel: 'Add Details',
                  onAction: () => print('Add details'),
                ),
    );
  }
}

// ===========================================================================
// EXAMPLE 4: Dashboard with Action Cards
// ===========================================================================

/// AFTER: Polished dashboard (no "before" needed - this shows best practices)
class PolishedDashboard extends StatelessWidget {
  const PolishedDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const PolishedAppBar(
        title: 'Dashboard',
        gradient: true,
        showBackButton: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            PolishedCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTealLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.waving_hand,
                      size: 32,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back!', style: AppTheme.headingMedium),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          'You have 5 appointments today',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            
            // Quick Actions
            const SectionHeader(
              title: 'Quick Actions',
              icon: Icons.bolt,
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppTheme.spacingM,
              crossAxisSpacing: AppTheme.spacingM,
              children: [
                _buildActionCard(
                  icon: Icons.people,
                  title: 'Patients',
                  color: AppTheme.primaryTeal,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.calendar_today,
                  title: 'Schedule',
                  color: AppTheme.infoBlue,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.assessment,
                  title: 'Reports',
                  color: AppTheme.accentOrange,
                  onTap: () {},
                ),
                _buildActionCard(
                  icon: Icons.settings,
                  title: 'Settings',
                  color: AppTheme.textGrey,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PolishedCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            title,
            style: AppTheme.headingSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// HOW TO USE THESE EXAMPLES
// ===========================================================================
// 
// 1. Review the "BEFORE" examples to see old patterns
// 2. Study the "AFTER" examples to learn new patterns
// 3. Apply similar changes to your screens
// 4. Test the visual improvements
// 5. Refer to UI_POLISH_GUIDE.md for detailed documentation
//
// ===========================================================================
