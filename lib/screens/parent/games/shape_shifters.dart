import 'package:flutter/material.dart';
import 'dart:math';
import '../../../services/game_data_service.dart';

class ShapeShiftersGame extends StatelessWidget {
  const ShapeShiftersGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pattern Matcher Game',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const PatternMatcherGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PatternElement {
  final String id;
  final String type;
  final Color color;
  final double size;
  Offset position;
  final bool isTarget;
  bool isMatched;

  PatternElement({
    required this.id,
    required this.type,
    required this.color,
    required this.size,
    required this.position,
    this.isTarget = false,
    this.isMatched = false,
  });
}

class PatternSlot {
  final String id;
  final Offset position;
  final double size;
  final String expectedType;
  final Color expectedColor;
  bool hasElement;
  PatternElement? element;

  PatternSlot({
    required this.id,
    required this.position,
    required this.size,
    required this.expectedType,
    required this.expectedColor,
    this.hasElement = false,
    this.element,
  });
}

class PatternMatcherGame extends StatefulWidget {
  const PatternMatcherGame({super.key});

  @override
  _PatternMatcherGameState createState() => _PatternMatcherGameState();
}

class _PatternMatcherGameState extends State<PatternMatcherGame>
    with SingleTickerProviderStateMixin {
  int currentLevel = 0; // Start from 0 for Level 1 (0-3 for 4 levels)
  bool showSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<PatternSlot> patternSlots = [];
  List<PatternElement> draggableElements = [];

  // Firebase tracking variables
  DateTime _sessionStart = DateTime.now();
  int _shapesPlaced = 0;
  int _levelsCompleted = 0;
  int _totalAttempts = 0;
  int _correctPlacements = 0;
  Map<String, int> _shapeTypeUsage = {};

  @override
  void initState() {
    super.initState();
    _newSession();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _initializeGame();
  }

  /// Initialize game by loading saved progress
  Future<void> _initializeGame() async {
    try {
      // Load saved progress from unified user progress
      final userProgress = await GameDataService.getUserGameProgress();
      final savedLevel = userProgress.getCurrentLevel('pattern_matcher');
      setState(() {
        currentLevel = savedLevel - 1; // Convert from 1-based to 0-based
      });
      print('Pattern Matcher: Starting at level $savedLevel');
    } catch (e) {
      print('Error loading saved level: $e');
      setState(() {
        currentLevel = 0; // Default to level 1 (0-based)
      });
    }
    _loadLevel();
  }

  void _newSession() {
    _sessionStart = DateTime.now();
    _shapesPlaced = 0;
    _levelsCompleted = 0;
    _totalAttempts = 0;
    _correctPlacements = 0;
    _shapeTypeUsage.clear();
  }

  @override
  void dispose() {
    // Save session data when exiting
    if (DateTime.now().difference(_sessionStart).inSeconds > 10) {
      _saveGameSession();
    }
    _animationController.dispose();
    super.dispose();
  }

  /// Save current game session to Firebase
  Future<void> _saveGameSession() async {
    try {
      // Save using the new unified progress system
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_matcher',
        level: currentLevel + 1, // currentLevel is 0-based, save as 1-based
        score: _correctPlacements * 10 + _levelsCompleted * 50,
        completed: currentLevel >= 3, // All 4 levels completed
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'shapesPlaced': _shapesPlaced,
          'levelsCompleted': _levelsCompleted,
          'totalAttempts': _totalAttempts,
          'correctPlacements': _correctPlacements,
          'accuracy':
              _totalAttempts > 0 ? _correctPlacements / _totalAttempts : 0.0,
          'shapeTypeUsage': _shapeTypeUsage,
          'finalLevel': currentLevel + 1,
          'sessionStart': _sessionStart.toIso8601String(),
        },
      );

      print('Pattern Matcher session saved successfully');
    } catch (e) {
      print('Error saving Pattern Matcher session: $e');
    }
  }

  void _loadLevel() {
    setState(() {
      patternSlots.clear();
      draggableElements.clear();
      showSuccess = false;
    });

    switch (currentLevel) {
      case 0: // Level 1: Simple Shape Pattern (Red Circle, Blue Square)
        patternSlots.addAll([
          PatternSlot(
            id: 'slot1',
            position: const Offset(150, 200),
            size: 80,
            expectedType: 'circle',
            expectedColor: Colors.red,
          ),
          PatternSlot(
            id: 'slot2',
            position: const Offset(250, 200),
            size: 80,
            expectedType: 'square',
            expectedColor: Colors.blue,
          ),
        ]);
        draggableElements.addAll([
          PatternElement(
            id: 'red_circle',
            type: 'circle',
            color: Colors.red,
            size: 60,
            position: const Offset(120, 350),
          ),
          PatternElement(
            id: 'blue_square',
            type: 'square',
            color: Colors.blue,
            size: 60,
            position: const Offset(280, 350),
          ),
        ]);
        break;

      case 1: // Level 2: Color Pattern (Red, Green, Blue sequence)
        patternSlots.addAll([
          PatternSlot(
            id: 'slot1',
            position: const Offset(120, 200),
            size: 70,
            expectedType: 'circle',
            expectedColor: Colors.red,
          ),
          PatternSlot(
            id: 'slot2',
            position: const Offset(200, 200),
            size: 70,
            expectedType: 'circle',
            expectedColor: Colors.green,
          ),
          PatternSlot(
            id: 'slot3',
            position: const Offset(280, 200),
            size: 70,
            expectedType: 'circle',
            expectedColor: Colors.blue,
          ),
        ]);
        draggableElements.addAll([
          PatternElement(
            id: 'blue_circle',
            type: 'circle',
            color: Colors.blue,
            size: 50,
            position: const Offset(100, 350),
          ),
          PatternElement(
            id: 'red_circle',
            type: 'circle',
            color: Colors.red,
            size: 50,
            position: const Offset(180, 350),
          ),
          PatternElement(
            id: 'green_circle',
            type: 'circle',
            color: Colors.green,
            size: 50,
            position: const Offset(260, 350),
          ),
          PatternElement(
            id: 'yellow_circle',
            type: 'circle',
            color: Colors.yellow,
            size: 50,
            position: const Offset(340, 350),
          ),
        ]);
        break;

      case 2: // Level 3: Shape and Color Pattern (Triangle-Red, Star-Yellow, Square-Green)
        patternSlots.addAll([
          PatternSlot(
            id: 'slot1',
            position: const Offset(120, 200),
            size: 75,
            expectedType: 'triangle',
            expectedColor: Colors.red,
          ),
          PatternSlot(
            id: 'slot2',
            position: const Offset(200, 200),
            size: 75,
            expectedType: 'star',
            expectedColor: Colors.yellow,
          ),
          PatternSlot(
            id: 'slot3',
            position: const Offset(280, 200),
            size: 75,
            expectedType: 'square',
            expectedColor: Colors.green,
          ),
        ]);
        draggableElements.addAll([
          PatternElement(
            id: 'green_square',
            type: 'square',
            color: Colors.green,
            size: 55,
            position: const Offset(90, 350),
          ),
          PatternElement(
            id: 'red_triangle',
            type: 'triangle',
            color: Colors.red,
            size: 55,
            position: const Offset(150, 350),
          ),
          PatternElement(
            id: 'blue_circle',
            type: 'circle',
            color: Colors.blue,
            size: 55,
            position: const Offset(210, 350),
          ),
          PatternElement(
            id: 'yellow_star',
            type: 'star',
            color: Colors.yellow,
            size: 55,
            position: const Offset(270, 350),
          ),
          PatternElement(
            id: 'pink_heart',
            type: 'heart',
            color: Colors.pink,
            size: 55,
            position: const Offset(330, 350),
          ),
        ]);
        break;

      case 3: // Level 4: Complex Pattern (Alternating shapes with specific colors)
        patternSlots.addAll([
          PatternSlot(
            id: 'slot1',
            position: const Offset(100, 180),
            size: 70,
            expectedType: 'square',
            expectedColor: Colors.purple,
          ),
          PatternSlot(
            id: 'slot2',
            position: const Offset(170, 180),
            size: 70,
            expectedType: 'circle',
            expectedColor: Colors.orange,
          ),
          PatternSlot(
            id: 'slot3',
            position: const Offset(240, 180),
            size: 70,
            expectedType: 'triangle',
            expectedColor: Colors.teal,
          ),
          PatternSlot(
            id: 'slot4',
            position: const Offset(310, 180),
            size: 70,
            expectedType: 'star',
            expectedColor: Colors.indigo,
          ),
        ]);
        draggableElements.addAll([
          PatternElement(
            id: 'orange_circle',
            type: 'circle',
            color: Colors.orange,
            size: 50,
            position: const Offset(80, 350),
          ),
          PatternElement(
            id: 'purple_square',
            type: 'square',
            color: Colors.purple,
            size: 50,
            position: const Offset(130, 350),
          ),
          PatternElement(
            id: 'red_heart',
            type: 'heart',
            color: Colors.red,
            size: 50,
            position: const Offset(180, 350),
          ),
          PatternElement(
            id: 'teal_triangle',
            type: 'triangle',
            color: Colors.teal,
            size: 50,
            position: const Offset(230, 350),
          ),
          PatternElement(
            id: 'indigo_star',
            type: 'star',
            color: Colors.indigo,
            size: 50,
            position: const Offset(280, 350),
          ),
          PatternElement(
            id: 'green_balloon',
            type: 'balloon',
            color: Colors.green,
            size: 50,
            position: const Offset(330, 350),
          ),
        ]);
        break;
    }
  }

  bool _isInsideSlot(Offset position, PatternSlot slot) {
    double distance = (position - slot.position).distance;
    return distance <= (slot.size / 2) - 10;
  }

  bool _isValidPatternMatch(PatternElement element, PatternSlot slot) {
    // Check if both type and color match
    return element.type == slot.expectedType && element.color == slot.expectedColor;
  }

  void _onElementDragEnd(PatternElement element, Offset position) {
    bool wasPlaced = false;
    _totalAttempts++; // Track every placement attempt

    for (PatternSlot slot in patternSlots) {
      if (_isInsideSlot(position, slot)) {
        if (_isValidPatternMatch(element, slot) && !slot.hasElement) {
          setState(() {
            element.position = slot.position;
            element.isMatched = true;
            slot.hasElement = true;
            slot.element = element;
          });
          wasPlaced = true;
          _correctPlacements++; // Track successful placement
          _shapesPlaced++;

          // Track shape type usage
          _shapeTypeUsage[element.type] =
              (_shapeTypeUsage[element.type] ?? 0) + 1;
          break;
        }
      }
    }

    if (!wasPlaced) {
      // Snap back to original position or current position
      setState(() {
        element.position = position;
        element.isMatched = false;
      });
    }

    _checkLevelComplete();
  }

  void _checkLevelComplete() {
    int requiredPlacements = _getRequiredPlacements();
    int actualPlacements = draggableElements.where((element) => element.isMatched).length;

    if (actualPlacements >= requiredPlacements) {
      _showSuccess();
    }
  }

  int _getRequiredPlacements() {
    // All pattern slots must be filled correctly
    return patternSlots.length;
  }

  void _showSuccess() {
    setState(() {
      showSuccess = true;
    });

    _levelsCompleted++; // Track level completion
    _animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _animationController.reverse();
      if (currentLevel < 3) { // 4 levels (0-3)
        setState(() {
          currentLevel++;
        });
        // Save current level progress
        _saveCurrentLevel();
        _loadLevel();
      } else {
        // Game fully completed, save session and reset progress
        _saveGameSession();
        _resetGameProgress();
        _showGameComplete();
      }
    });
  }

  /// Save current level to database
  Future<void> _saveCurrentLevel() async {
    try {
      // Save progress using unified system
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_matcher',
        level: currentLevel + 1, // Convert to 1-based for storage
        score: _correctPlacements * 10 + _levelsCompleted * 50,
        completed: false, // Level advancement, not completion
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'totalAttempts': _totalAttempts,
          'correctPlacements': _correctPlacements,
          'shapeTypeUsage': _shapeTypeUsage,
          'levelAdvancement': true,
        },
      );
    } catch (e) {
      print('Error saving current level: $e');
    }
  }

  /// Reset game progress after completion
  Future<void> _resetGameProgress() async {
    try {
      // Save completion and reset to level 1
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_matcher',
        level: 1, // Reset to level 1
        score: _correctPlacements * 10 + _levelsCompleted * 50,
        completed: true, // Game completed
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'gameCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
          'totalAttempts': _totalAttempts,
          'correctPlacements': _correctPlacements,
        },
      );
    } catch (e) {
      print('Error resetting game progress: $e');
    }
  }

  void _showGameComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.celebration, color: Colors.orange, size: 30),
              SizedBox(width: 10),
              Text('Congratulations!'),
            ],
          ),
          content: const Text('You completed all 4 levels!\nWell done!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentLevel = 0;
                });
                _loadLevel();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  String _getLevelInstruction() {
    switch (currentLevel) {
      case 0:
        return "Match Shapes by Type and Color";
      case 1:
        return "Complete the Color Pattern";
      case 2:
        return "Match Complex Shape Patterns";
      case 3:
        return "Complete the Advanced Pattern";
      default:
        return "Match the pattern correctly";
    }
  }

  String _getHint() {
    switch (currentLevel) {
      case 0:
        return "Drag the red circle and blue square to their matching slots.";
      case 1:
        return "Follow the color sequence: Red, Green, Blue. Ignore the yellow circle.";
      case 2:
        return "Match each shape with its exact color: Red Triangle, Yellow Star, Green Square.";
      case 3:
        return "Complete the pattern: Purple Square, Orange Circle, Teal Triangle, Indigo Star.";
      default:
        return "Drag elements to their matching pattern slots.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade300, Colors.teal.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushReplacementNamed('/gamesoption');
                      },
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.teal.shade300, width: 2),
                      ),
                      child: Text(
                        'Level ${currentLevel + 1}',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadLevel,
                      child: const Icon(Icons.refresh,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),

              // Game Container
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Instruction
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _getLevelInstruction(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Game Area
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            children: [
                              // Draw pattern slots
                              ...patternSlots.map((slot) => Positioned(
                                    left: slot.position.dx - slot.size / 2,
                                    top: slot.position.dy - slot.size / 2,
                                    child: SizedBox(
                                      width: slot.size,
                                      height: slot.size,
                                      child: CustomPaint(
                                        painter: PatternSlotPainter(
                                          shapeType: slot.expectedType,
                                          color: slot.expectedColor.withOpacity(0.3),
                                          size: slot.size,
                                        ),
                                      ),
                                    ),
                                  )),

                              // Draw draggable elements
                              ...draggableElements.map((element) => Positioned(
                                    left: element.position.dx - element.size / 2,
                                    top: element.position.dy - element.size / 2,
                                    child: Draggable<PatternElement>(
                                      data: element,
                                      feedback: SizedBox(
                                        width: element.size * 1.2,
                                        height: element.size * 1.2,
                                        child: CustomPaint(
                                          painter: PatternElementPainter(
                                            shapeType: element.type,
                                            color:
                                                element.color.withOpacity(0.8),
                                            filled: true,
                                            size: element.size * 1.2,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Container(),
                                      onDragEnd: (details) {
                                        RenderBox renderBox = context
                                            .findRenderObject() as RenderBox;
                                        Offset localPosition = renderBox
                                            .globalToLocal(details.offset);
                                        _onElementDragEnd(element, localPosition);
                                      },
                                      child: SizedBox(
                                        width: element.size,
                                        height: element.size,
                                        child: CustomPaint(
                                          painter: PatternElementPainter(
                                            shapeType: element.type,
                                            color: element.color,
                                            filled: true,
                                            size: element.size,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )),

                              // Success animation
                              if (showSuccess)
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _scaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.all(30),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 15,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.white,
                                                size: 60,
                                              ),
                                              SizedBox(height: 15),
                                              Text(
                                                'Excellent!',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Hints section
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HINTS',
                              style: TextStyle(
                                color: Colors.teal.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getHint(),
                              style: TextStyle(
                                color: Colors.teal.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatternSlotPainter extends CustomPainter {
  final String shapeType;
  final Color color;
  final double size;

  PatternSlotPainter({
    required this.shapeType,
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    double centerX = canvasSize.width / 2;
    double centerY = canvasSize.height / 2;
    double radius = min(canvasSize.width, canvasSize.height) / 2 - 5;

    switch (shapeType) {
      case 'square':
        Rect rect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radius * 1.6,
          height: radius * 1.6,
        );
        _drawDashedRect(canvas, paint, rect);
        break;

      case 'circle':
        _drawDashedCircle(canvas, paint, Offset(centerX, centerY), radius);
        break;

      case 'triangle':
        Path path = Path();
        path.moveTo(centerX, centerY - radius);
        path.lineTo(centerX - radius * 0.866, centerY + radius * 0.5);
        path.lineTo(centerX + radius * 0.866, centerY + radius * 0.5);
        path.close();
        canvas.drawPath(path, paint);
        break;

      case 'star':
        Path starPath = _createStarPath(centerX, centerY, radius);
        canvas.drawPath(starPath, paint);
        break;

      case 'heart':
        Path heartPath = _createHeartPath(centerX, centerY, radius);
        canvas.drawPath(heartPath, paint);
        break;
    }
  }

  void _drawDashedRect(Canvas canvas, Paint paint, Rect rect) {
    double dashWidth = 8;
    double dashSpace = 5;

    // Top edge
    for (double i = rect.left; i < rect.right; i += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(i, rect.top),
        Offset(min(i + dashWidth, rect.right), rect.top),
        paint,
      );
    }

    // Right edge
    for (double i = rect.top; i < rect.bottom; i += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(rect.right, i),
        Offset(rect.right, min(i + dashWidth, rect.bottom)),
        paint,
      );
    }

    // Bottom edge
    for (double i = rect.right; i > rect.left; i -= dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(i, rect.bottom),
        Offset(max(i - dashWidth, rect.left), rect.bottom),
        paint,
      );
    }

    // Left edge
    for (double i = rect.bottom; i > rect.top; i -= dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(rect.left, i),
        Offset(rect.left, max(i - dashWidth, rect.top)),
        paint,
      );
    }
  }

  void _drawDashedCircle(
      Canvas canvas, Paint paint, Offset center, double radius) {
    double dashAngle = 0.3;
    double gapAngle = 0.2;
    double currentAngle = 0;

    while (currentAngle < 2 * pi) {
      double startAngle = currentAngle;
      double endAngle = currentAngle + dashAngle;

      if (endAngle > 2 * pi) endAngle = 2 * pi;

      Path arc = Path();
      arc.addArc(Rect.fromCircle(center: center, radius: radius), startAngle,
          endAngle - startAngle);
      canvas.drawPath(arc, paint);

      currentAngle += dashAngle + gapAngle;
    }
  }

  Path _createStarPath(double centerX, double centerY, double radius) {
    Path path = Path();
    double angle = -pi / 2;
    int points = 5;

    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? radius : radius * 0.5;
      double x = centerX + cos(angle) * r;
      double y = centerY + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      angle += pi / points;
    }

    path.close();
    return path;
  }

  Path _createHeartPath(double centerX, double centerY, double radius) {
    Path path = Path();

    path.moveTo(centerX, centerY + radius * 0.3);

    path.cubicTo(
      centerX - radius * 0.5,
      centerY - radius * 0.5,
      centerX - radius,
      centerY + radius * 0.1,
      centerX,
      centerY + radius * 0.7,
    );

    path.cubicTo(
      centerX + radius,
      centerY + radius * 0.1,
      centerX + radius * 0.5,
      centerY - radius * 0.5,
      centerX,
      centerY + radius * 0.3,
    );

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PatternElementPainter extends CustomPainter {
  final String shapeType;
  final Color color;
  final bool filled;
  final double size;

  PatternElementPainter({
    required this.shapeType,
    required this.color,
    required this.filled,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    Paint paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = filled ? 1 : 4;

    double centerX = canvasSize.width / 2;
    double centerY = canvasSize.height / 2;
    double radius = min(canvasSize.width, canvasSize.height) / 2 - 5;

    switch (shapeType) {
      case 'square':
        Rect rect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: radius * 1.6,
          height: radius * 1.6,
        );
        if (filled) {
          canvas.drawRect(rect, paint);
        } else {
          _drawDashedRect(canvas, paint, rect);
        }
        break;

      case 'circle':
        if (filled) {
          canvas.drawCircle(Offset(centerX, centerY), radius, paint);
        } else {
          _drawDashedCircle(canvas, paint, Offset(centerX, centerY), radius);
        }
        break;

      case 'triangle':
        Path path = Path();
        path.moveTo(centerX, centerY - radius);
        path.lineTo(centerX - radius * 0.866, centerY + radius * 0.5);
        path.lineTo(centerX + radius * 0.866, centerY + radius * 0.5);
        path.close();

        if (filled) {
          canvas.drawPath(path, paint);
        } else {
          canvas.drawPath(path, paint);
        }
        break;

      case 'star':
        Path starPath = _createStarPath(centerX, centerY, radius);
        canvas.drawPath(starPath, paint);
        break;

      case 'heart':
        Path heartPath = _createHeartPath(centerX, centerY, radius);
        canvas.drawPath(heartPath, paint);
        break;

      case 'balloon':
        // Balloon body
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(centerX, centerY - 5),
            width: radius * 1.4,
            height: radius * 1.8,
          ),
          paint,
        );

        // Balloon string
        Paint stringPaint = Paint()
          ..color = Colors.black87
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(centerX, centerY + radius * 0.7),
          Offset(centerX, centerY + radius * 1.2),
          stringPaint,
        );

        // Highlight
        if (filled) {
          Paint highlightPaint = Paint()..color = Colors.white.withOpacity(0.4);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(centerX - radius * 0.3, centerY - radius * 0.5),
              width: radius * 0.5,
              height: radius * 0.3,
            ),
            highlightPaint,
          );
        }
        break;
    }
  }

  void _drawDashedRect(Canvas canvas, Paint paint, Rect rect) {
    double dashWidth = 10;
    double dashSpace = 6;

    // Top edge
    for (double i = rect.left; i < rect.right; i += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(i, rect.top),
        Offset(min(i + dashWidth, rect.right), rect.top),
        paint,
      );
    }

    // Right edge
    for (double i = rect.top; i < rect.bottom; i += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(rect.right, i),
        Offset(rect.right, min(i + dashWidth, rect.bottom)),
        paint,
      );
    }

    // Bottom edge
    for (double i = rect.right; i > rect.left; i -= dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(i, rect.bottom),
        Offset(max(i - dashWidth, rect.left), rect.bottom),
        paint,
      );
    }

    // Left edge
    for (double i = rect.bottom; i > rect.top; i -= dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(rect.left, i),
        Offset(rect.left, max(i - dashWidth, rect.top)),
        paint,
      );
    }
  }

  void _drawDashedCircle(
      Canvas canvas, Paint paint, Offset center, double radius) {
    double dashAngle = 0.3;
    double gapAngle = 0.2;
    double currentAngle = 0;

    while (currentAngle < 2 * pi) {
      double startAngle = currentAngle;
      double endAngle = currentAngle + dashAngle;

      if (endAngle > 2 * pi) endAngle = 2 * pi;

      Path arc = Path();
      arc.addArc(Rect.fromCircle(center: center, radius: radius), startAngle,
          endAngle - startAngle);
      canvas.drawPath(arc, paint);

      currentAngle += dashAngle + gapAngle;
    }
  }

  Path _createStarPath(double centerX, double centerY, double radius) {
    Path path = Path();
    double angle = -pi / 2;
    int points = 5;

    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? radius : radius * 0.5;
      double x = centerX + cos(angle) * r;
      double y = centerY + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      angle += pi / points;
    }

    path.close();
    return path;
  }

  Path _createHeartPath(double centerX, double centerY, double radius) {
    Path path = Path();

    path.moveTo(centerX, centerY + radius * 0.3);

    path.cubicTo(
      centerX - radius * 0.5,
      centerY - radius * 0.5,
      centerX - radius,
      centerY + radius * 0.1,
      centerX,
      centerY + radius * 0.7,
    );

    path.cubicTo(
      centerX + radius,
      centerY + radius * 0.1,
      centerX + radius * 0.5,
      centerY - radius * 0.5,
      centerX,
      centerY + radius * 0.3,
    );

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
