import 'package:flutter/material.dart';

class GamesOption extends StatelessWidget {
  const GamesOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'Games',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
                  Container(
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

                  // Title
                  const Text(
                    'Choose a Game',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40.0),

                  // Game Button 1 - Talk with Tiles
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 8,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Talk with Tiles',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Game Button 2 - Shape Shifters
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 8,
                    ),
                    onPressed: () {
                      print('Shape Shifters pressed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loading Shape Shifters...'),
                          backgroundColor: Color(0xFF006A5B),
                        ),
                      );
                      // Navigate to Shape Shifters game
                      Navigator.pushNamed(context, '/shapeshifters');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Shape Shifters',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Game Button 3 - Coming Soon
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),
                      elevation: 4,
                    ),
                    onPressed: null, // Disabled for now
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          'Coming Soon',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30.0),

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
                      'Interactive games designed to help with speech and communication development',
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
