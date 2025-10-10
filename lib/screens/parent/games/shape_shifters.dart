import 'package:flutter/material.dart';
import 'dart:math';
import '../../../services/game_data_service.dart';

class ShapeShiftersGame extends StatelessWidget {
  const ShapeShiftersGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drag to Shape Game',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: const DragToShapeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameShape {
  final String type;
  final Offset center;
  final double size;
  final Color color;
  bool hasObject;

  GameShape({
    required this.type,
    required this.center,
    required this.size,
    required this.color,
    this.hasObject = false,
  });
}

class GameDragObject {
  final String id;
  final String type;
  final Color color;
  final double size;
  Offset position;
  bool isPlaced;
  String? placedInShape;

  GameDragObject({
    required this.id,
    required this.type,
    required this.color,
    required this.size,
    required this.position,
    this.isPlaced = false,
    this.placedInShape,
  });
}

class DragToShapeGame extends StatefulWidget {
  const DragToShapeGame({super.key});

  @override
  _DragToShapeGameState createState() => _DragToShapeGameState();
}

class _DragToShapeGameState extends State<DragToShapeGame>
    with SingleTickerProviderStateMixin {
  int currentLevel = 0; // Start from 0 for Level 1
  bool showSuccess = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<GameShape> shapes = [];
  List<GameDragObject> objects = [];

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
      final savedLevel = userProgress.getCurrentLevel('shape_shifters');
      setState(() {
        currentLevel = savedLevel - 1; // Convert from 1-based to 0-based
      });
      print('Shape Shifters: Starting at level $savedLevel');
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
        gameType: 'shape_shifters',
        level: currentLevel + 1, // currentLevel is 0-based, save as 1-based
        score: _correctPlacements * 10 + _levelsCompleted * 50,
        completed: currentLevel >= 4, // All 5 levels completed
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

      print('Shape Shifters session saved successfully');
    } catch (e) {
      print('Error saving Shape Shifters session: $e');
    }
  }

  void _loadLevel() {
    setState(() {
      shapes.clear();
      objects.clear();
      showSuccess = false;
    });

    switch (currentLevel) {
      case 0: // Level 1
        shapes.add(GameShape(
          type: 'square',
          center: const Offset(200, 250),
          size: 100,
          color: Colors.grey.shade400,
        ));
        objects.add(GameDragObject(
          id: 'balloon1',
          type: 'balloon',
          color: Colors.red,
          size: 60,
          position: const Offset(200, 400),
        ));
        break;

      case 1: // Level 2
        shapes.add(GameShape(
          type: 'circle',
          center: const Offset(200, 250),
          size: 120,
          color: Colors.blue.shade300,
        ));
        objects.addAll([
          GameDragObject(
            id: 'star1',
            type: 'star',
            color: Colors.yellow,
            size: 50,
            position: const Offset(150, 400),
          ),
          GameDragObject(
            id: 'heart1',
            type: 'heart',
            color: Colors.pink,
            size: 50,
            position: const Offset(250, 400),
          ),
        ]);
        break;

      case 2: // Level 3
        shapes.addAll([
          GameShape(
            type: 'square',
            center: const Offset(150, 250),
            size: 90,
            color: Colors.green.shade300,
          ),
          GameShape(
            type: 'circle',
            center: const Offset(270, 250),
            size: 90,
            color: Colors.purple.shade300,
          ),
        ]);
        objects.addAll([
          GameDragObject(
            id: 'square_obj',
            type: 'square',
            color: Colors.green,
            size: 60,
            position: const Offset(120, 400),
          ),
          GameDragObject(
            id: 'circle_obj',
            type: 'circle',
            color: Colors.purple,
            size: 60,
            position: const Offset(280, 400),
          ),
        ]);
        break;

      case 3: // Level 4
        shapes.addAll([
          GameShape(
            type: 'triangle',
            center: const Offset(140, 250),
            size: 90,
            color: Colors.orange.shade300,
          ),
          GameShape(
            type: 'star',
            center: const Offset(280, 250),
            size: 90,
            color: Colors.teal.shade300,
          ),
        ]);
        objects.addAll([
          GameDragObject(
            id: 'triangle_obj',
            type: 'triangle',
            color: Colors.orange,
            size: 50,
            position: const Offset(100, 400),
          ),
          GameDragObject(
            id: 'star_obj',
            type: 'star',
            color: Colors.teal,
            size: 50,
            position: const Offset(180, 400),
          ),
          GameDragObject(
            id: 'balloon2',
            type: 'balloon',
            color: Colors.red,
            size: 50,
            position: const Offset(300, 400),
          ),
        ]);
        break;

      case 4: // Level 5
        shapes.addAll([
          GameShape(
            type: 'square',
            center: const Offset(110, 250),
            size: 80,
            color: Colors.red.shade300,
          ),
          GameShape(
            type: 'circle',
            center: const Offset(200, 250),
            size: 80,
            color: Colors.blue.shade300,
          ),
          GameShape(
            type: 'triangle',
            center: const Offset(290, 250),
            size: 80,
            color: Colors.green.shade300,
          ),
        ]);
        objects.addAll([
          GameDragObject(
            id: 'red_square',
            type: 'square',
            color: Colors.red,
            size: 45,
            position: const Offset(80, 400),
          ),
          GameDragObject(
            id: 'blue_circle',
            type: 'circle',
            color: Colors.blue,
            size: 45,
            position: const Offset(160, 400),
          ),
          GameDragObject(
            id: 'green_triangle',
            type: 'triangle',
            color: Colors.green,
            size: 45,
            position: const Offset(240, 400),
          ),
          GameDragObject(
            id: 'extra_balloon',
            type: 'balloon',
            color: Colors.yellow,
            size: 45,
            position: const Offset(320, 400),
          ),
        ]);
        break;
    }
  }

  bool _isInsideShape(Offset position, GameShape shape) {
    double distance = (position - shape.center).distance;
    return distance <= (shape.size / 2) - 10;
  }

  bool _isValidPlacement(GameDragObject object, GameShape shape) {
    // Level 1-2: Any object can go in any shape
    if (currentLevel <= 1) return true;

    // Level 3+: Objects must match shape types
    if (object.type == shape.type) return true;

    // Balloons can go anywhere (extra objects)
    if (object.type == 'balloon') return false;

    return false;
  }

  void _onObjectDragEnd(GameDragObject object, Offset position) {
    bool wasPlaced = false;
    _totalAttempts++; // Track every placement attempt

    for (GameShape shape in shapes) {
      if (_isInsideShape(position, shape)) {
        if (_isValidPlacement(object, shape) && !shape.hasObject) {
          setState(() {
            object.position = shape.center;
            object.isPlaced = true;
            object.placedInShape = shape.type;
            shape.hasObject = true;
          });
          wasPlaced = true;
          _correctPlacements++; // Track successful placement
          _shapesPlaced++;

          // Track shape type usage
          _shapeTypeUsage[object.type] =
              (_shapeTypeUsage[object.type] ?? 0) + 1;
          break;
        }
      }
    }

    if (!wasPlaced) {
      // Snap back to original position or current position
      setState(() {
        object.position = position;
        object.isPlaced = false;
        if (object.placedInShape != null) {
          // Remove from previous shape
          for (GameShape shape in shapes) {
            if (shape.type == object.placedInShape) {
              shape.hasObject = false;
              break;
            }
          }
          object.placedInShape = null;
        }
      });
    }

    _checkLevelComplete();
  }

  void _checkLevelComplete() {
    int requiredPlacements = _getRequiredPlacements();
    int actualPlacements = objects.where((obj) => obj.isPlaced).length;

    if (actualPlacements >= requiredPlacements) {
      _showSuccess();
    }
  }

  int _getRequiredPlacements() {
    switch (currentLevel) {
      case 0:
        return 1; // Level 1: 1 object
      case 1:
        return 2; // Level 2: 2 objects
      case 2:
        return 2; // Level 3: 2 objects
      case 3:
        return 2; // Level 4: 2 objects (triangle and star)
      case 4:
        return 3; // Level 5: 3 objects
      default:
        return objects.length;
    }
  }

  void _showSuccess() {
    setState(() {
      showSuccess = true;
    });

    _levelsCompleted++; // Track level completion
    _animationController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _animationController.reverse();
      if (currentLevel < 4) {
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
        gameType: 'shape_shifters',
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
        gameType: 'shape_shifters',
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
          content: const Text('You completed all 5 levels!\nWell done!'),
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
        return "Trace the Square and pop the balloon";
      case 1:
        return "Place objects on the Circle";
      case 2:
        return "Match objects to their shapes";
      case 3:
        return "Sort the shapes correctly";
      case 4:
        return "Complete the pattern challenge";
      default:
        return "Drag objects to shapes";
    }
  }

  String _getHint() {
    switch (currentLevel) {
      case 0:
        return "Drag the balloon into the square shape to continue.";
      case 1:
        return "Place both objects inside the circle.";
      case 2:
        return "Match each object with its corresponding shape.";
      case 3:
        return "Only triangle and star objects belong in their shapes.";
      case 4:
        return "Place each colored object in its matching colored shape.";
      default:
        return "Drag objects to their correct positions.";
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
                              // Draw shapes
                              ...shapes.map((shape) => Positioned(
                                    left: shape.center.dx - shape.size / 2,
                                    top: shape.center.dy - shape.size / 2,
                                    child: SizedBox(
                                      width: shape.size,
                                      height: shape.size,
                                      child: CustomPaint(
                                        painter: ShapePainter(
                                          shapeType: shape.type,
                                          color: shape.color,
                                          filled: false,
                                          size: shape.size,
                                        ),
                                      ),
                                    ),
                                  )),

                              // Draw draggable objects
                              ...objects.map((object) => Positioned(
                                    left: object.position.dx - object.size / 2,
                                    top: object.position.dy - object.size / 2,
                                    child: Draggable<GameDragObject>(
                                      data: object,
                                      feedback: SizedBox(
                                        width: object.size * 1.2,
                                        height: object.size * 1.2,
                                        child: CustomPaint(
                                          painter: ShapePainter(
                                            shapeType: object.type,
                                            color:
                                                object.color.withOpacity(0.8),
                                            filled: true,
                                            size: object.size * 1.2,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Container(),
                                      onDragEnd: (details) {
                                        RenderBox renderBox = context
                                            .findRenderObject() as RenderBox;
                                        Offset localPosition = renderBox
                                            .globalToLocal(details.offset);
                                        _onObjectDragEnd(object, localPosition);
                                      },
                                      child: SizedBox(
                                        width: object.size,
                                        height: object.size,
                                        child: CustomPaint(
                                          painter: ShapePainter(
                                            shapeType: object.type,
                                            color: object.color,
                                            filled: true,
                                            size: object.size,
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

class ShapePainter extends CustomPainter {
  final String shapeType;
  final Color color;
  final bool filled;
  final double size;

  ShapePainter({
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
