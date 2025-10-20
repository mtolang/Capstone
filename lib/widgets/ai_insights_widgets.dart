import 'package:flutter/material.dart';
import '../screens/clinic/ai_insights_screen.dart';

/// Quick access button to AI Insights
/// Add this to any screen where you want quick access to AI analysis
class AIInsightsButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final bool isFloating;

  const AIInsightsButton({
    Key? key,
    this.label,
    this.icon,
    this.isFloating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isFloating) {
      return FloatingActionButton.extended(
        onPressed: () => _navigateToAIInsights(context),
        backgroundColor: const Color(0xFF006A5B),
        icon: Icon(icon ?? Icons.psychology),
        label: Text(
          label ?? 'AI Insights',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _navigateToAIInsights(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon ?? Icons.psychology),
      label: Text(
        label ?? 'AI Insights',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _navigateToAIInsights(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIInsightsScreen(),
      ),
    );
  }
}

/// AI Insights Card Widget
/// Shows a preview card with quick stats and a button to view full insights
class AIInsightsCard extends StatelessWidget {
  const AIInsightsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A5B).withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      'Get intelligent insights',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Discover patterns, track progress, and receive AI-generated recommendations for your therapy programs.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIInsightsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF006A5B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.insights),
              label: const Text(
                'View Insights',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini AI Stats Widget
/// Shows compact stats that can be embedded in dashboards
class AIStatsWidget extends StatefulWidget {
  final String clinicId;

  const AIStatsWidget({
    Key? key,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<AIStatsWidget> createState() => _AIStatsWidgetState();
}

class _AIStatsWidgetState extends State<AIStatsWidget> {
  // This is a simplified version - you can expand it to fetch real data

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                'Ready',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIInsightsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF006A5B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Action Tile for AI Insights
/// Use in a grid of quick actions
class AIQuickActionTile extends StatelessWidget {
  const AIQuickActionTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AIInsightsScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF006A5B).withOpacity(0.2),
          ),
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
                color: const Color(0xFF006A5B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                color: Color(0xFF006A5B),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'AI Insights',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: Color(0xFF006A5B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Get smart analysis',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
