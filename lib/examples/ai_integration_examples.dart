import 'package:flutter/material.dart';
import 'package:capstone_2/widgets/ai_insights_widgets.dart';

/// Example 1: Add AI Insights Button to AppBar
/// Use this in any screen's AppBar actions
class ExampleScreenWithAppBarButton extends StatelessWidget {
  const ExampleScreenWithAppBarButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Screen'),
        backgroundColor: const Color(0xFF006A5B),
        actions: const [
          // Simply add an IconButton
          AIInsightsButton(icon: Icons.psychology),
          SizedBox(width: 8),
        ],
      ),
      body: const Center(
        child: Text('Your content here'),
      ),
    );
  }
}

/// Example 2: Add AI Insights Card to Dashboard
/// Perfect for the clinic home/dashboard screen
class ExampleDashboardWithAICard extends StatelessWidget {
  const ExampleDashboardWithAICard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your existing dashboard widgets
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text('Welcome to Dashboard'),
            ),

            // Add the AI Insights Card
            const AIInsightsCard(),

            // More dashboard widgets...
          ],
        ),
      ),
    );
  }
}

/// Example 3: Add Floating Action Button
/// Use this for quick access from any screen
class ExampleScreenWithFAB extends StatelessWidget {
  const ExampleScreenWithFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Reports'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: const Center(
        child: Text('Your content here'),
      ),
      floatingActionButton: const AIInsightsButton(
        isFloating: true,
        label: 'AI Insights',
      ),
    );
  }
}

/// Example 4: Add to Grid of Quick Actions
/// Perfect for a home screen with multiple action tiles
class ExampleGridWithQuickActions extends StatelessWidget {
  const ExampleGridWithQuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Actions'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            // Your existing quick action tiles
            _buildQuickActionTile(
              context,
              'Patients',
              Icons.people,
              Colors.blue,
              () {},
            ),
            _buildQuickActionTile(
              context,
              'Calendar',
              Icons.calendar_today,
              Colors.orange,
              () {},
            ),

            // Add the AI Insights quick action tile
            const AIQuickActionTile(),

            _buildQuickActionTile(
              context,
              'Reports',
              Icons.bar_chart,
              Colors.green,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example 5: Programmatic Usage of AI Service
/// Use this when you want to get AI insights programmatically
class ExampleProgrammaticAIUsage extends StatefulWidget {
  const ExampleProgrammaticAIUsage({Key? key}) : super(key: key);

  @override
  State<ExampleProgrammaticAIUsage> createState() =>
      _ExampleProgrammaticAIUsageState();
}

class _ExampleProgrammaticAIUsageState
    extends State<ExampleProgrammaticAIUsage> {
  String? insights;
  bool isLoading = false;

  Future<void> _generateInsights() async {
    setState(() => isLoading = true);

    try {
      // Import the AI service
      // import 'package:capstone_2/services/therapy_ai_service.dart';

      // Initialize the service
      // final aiService = TherapyProgressAIService('AIzaSyC2yYSFl7NSxVyicp3oKPqUbpMkkYPit98');

      // Get dashboard analytics
      // final analytics = await aiService.generateDashboardAnalytics('your_clinic_id');

      // Or get category insights
      // final categoryAnalytics = analytics['categoryAnalytics']['Fine Motor'];
      // final categoryInsights = await aiService.generateCategoryInsights(categoryAnalytics);

      // Or get client report
      // final clientReport = await aiService.generateClientReport(
      //   'client_id',
      //   'Client Name',
      //   'Fine Motor',
      // );

      setState(() {
        insights = 'AI insights would appear here';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        insights = 'Error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom AI Integration'),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isLoading ? null : _generateInsights,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Generate Insights'),
            ),
            const SizedBox(height: 20),
            if (insights != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      insights!,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Example 6: Simple Button Integration
/// Minimal code to add AI insights button anywhere
void exampleAddButtonAnywhere(BuildContext context) {
  // Just add this button widget anywhere:
  const AIInsightsButton();

  // Or with custom label:
  const AIInsightsButton(label: 'View AI Analysis');

  // Or with custom icon:
  const AIInsightsButton(icon: Icons.analytics);
}

/// Example 7: Add to Existing Clinic Progress Screen
/// This shows how to integrate into your clinic_progress.dart
/*
In your clinic_progress.dart file:

1. Add the import at the top:
   import 'ai_insights_screen.dart';

2. Add a FloatingActionButton in your Scaffold:
   
   return Scaffold(
     body: Stack(
       children: [
         // Your existing ellipse backgrounds and content
         ...
       ],
     ),
     floatingActionButton: FloatingActionButton.extended(
       onPressed: () {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (context) => const AIInsightsScreen(),
           ),
         );
       },
       backgroundColor: const Color(0xFF006A5B),
       icon: const Icon(Icons.psychology),
       label: const Text(
         'AI Insights',
         style: TextStyle(fontFamily: 'Poppins'),
       ),
     ),
   );

OR add it as a button in your content:

   // Inside your SingleChildScrollView or Column:
   Padding(
     padding: const EdgeInsets.all(16),
     child: const AIInsightsButton(),
   ),

OR add it as a card:

   // Inside your content area:
   const AIInsightsCard(),
*/
