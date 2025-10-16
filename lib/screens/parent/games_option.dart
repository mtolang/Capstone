import 'package:flutter/material.dart';
import '../admin/database_optimization_tool.dart';

class GamesOption extends StatelessWidget {
  const GamesOption({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B), // Kindora's primary theme color
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: size.height * 0.2),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
                    ),
                  ),
                  // Fallback for missing image
                  child: Image.asset(
                    'asset/images/WAVE.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(); // Return empty container if image fails
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ConstrainedBox(
                constraints: BoxConstraints.expand(height: size.height * 0.30),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xFF67AFA5), Colors.white],
                    ),
                  ),
                  // Fallback for missing image
                  child: Image.asset(
                    'asset/images/WAVE (1).png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(); // Return empty container if image fails
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(45.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo with fallback
                  SizedBox(
                    height: 100,
                    child: Image.asset(
                      'asset/logo1.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A5B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.games,
                            color: Colors.white,
                            size: 50,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Simple title
                  const Text(
                    'Choose a Game:',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30.0),

                  // Game Button 1 - Talk with Tiles
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.cyan.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      onPressed: () {
                        print('Talk with Tiles pressed');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loading Talk with Tiles...'),
                            backgroundColor: Color(0xFF006A5B),
                          ),
                        );
                      // Add navigation to talk with tiles game
                      Navigator.pushNamed(context, '/talkwithtiles');
                    },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 28),
                          SizedBox(width: 12),
                          Text(
                            '💬 Talk with Tiles',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Game Button 2 - Pattern Master
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.pink.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                    onPressed: () {
                      print('Pattern Master pressed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading Pattern Master...'),
                          backgroundColor: Color(0xFF006A5B),
                        ),
                      );
                      // Navigate to Pattern Master game
                      Navigator.pushNamed(context, '/cognitivepatternmaster');
                    },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.psychology, size: 28),
                          SizedBox(width: 12),
                          Text(
                            '🧠 Pattern Master',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Game Button 3 - Trace & Pop Pro (Motor Skills)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading Trace & Pop Pro...'),
                          backgroundColor: Color(0xFF006A5B),
                        ),
                      );
                      Navigator.pushNamed(context, '/traceandpoppro');
                    },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, size: 28),
                          SizedBox(width: 12),
                          Text(
                            '✨ Trace & Pop Pro',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30.0),

                  // Debug/Admin Section (Hidden by default)
                  GestureDetector(
                    onLongPress: () {
                      // Long press to access admin tools
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DatabaseOptimizationTool(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.settings,
                        color: Colors
                            .transparent, // Hidden unless you know to long press
                        size: 20,
                      ),
                    ),
                  ),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Interactive games designed to help with speech, coordination, cognitive skills, and communication development',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF006A5B),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
