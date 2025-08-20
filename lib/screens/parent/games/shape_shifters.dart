import 'package:flutter/material.dart';
import 'dart:math';

class ShapeShiftersGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shape Shifters',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Arial',
      ),
      home: DragToShapeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameLevel {
  final int level;
  final String instruction;
  final List<ShapeData> shapes;
  final List<DragObject> objects;

  GameLevel({
    required this.level,
    required this.instruction,
    required this.shapes,
    required this.objects,
  });
}

class ShapeData {
  final String type; // 'square', 'circle', 'triangle', 'star'
  final Offset position;
  final double size;
  final Color outlineColor;

  ShapeData({
    required this.type,
    required this.position,
    required this.size,
    required this.outlineColor,
  });
}

class DragObject {
  final String id;
  final String type;
  final Color color;
  final double size;
  Offset position;
  bool isDragging;
  bool isPlaced;

  DragObject({
    required this.id,
    required this.type,
    required this.color,
    required this.size,
    required this.position,
    this.isDragging = false,
    this.isPlaced = false,
  });
}

class DragToShapeGame extends StatefulWidget {
  @override
  _DragToShapeGameState createState() => _DragToShapeGameState();
}

class _DragToShapeGameState extends State<DragToShapeGame>
    with TickerProviderStateMixin {
  int currentLevel = 1;
  bool showSuccess = false;
  late AnimationController _successController;
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _popAnimation;

  List<GameLevel> levels = [];
  late GameLevel activeLevel;
  List<DragObject> dragObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeLevels();
    _loadLevel(currentLevel);
  }

  void _initializeAnimations() {
    _successController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _popController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _popAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _popController, curve: Curves.elasticOut),
    );
  }

  void _initializeLevels() {
    levels = [
      // Level 1: 1 shape, 1 object
      GameLevel(
        level: 1,
        instruction: "Trace the Square and pop the balloon",
        shapes: [
          ShapeData(
            type: 'square',
            position: Offset(200, 300),
            size: 120,
            outlineColor: Colors.grey,
          ),
        ],
        objects: [
          DragObject(
            id: 'balloon1',
            type: 'balloon',
            color: Colors.red,
            size: 80,
            position: Offset(200, 500),
          ),
        ],
      ),

      // Level 2: 1 shape, 2 objects
      GameLevel(
        level: 2,
        instruction: "Place objects on the Circle",
        shapes: [
          ShapeData(
            type: 'circle',
            position: Offset(200, 300),
            size: 120,
            outlineColor: Colors.blue,
          ),
        ],
        objects: [
          DragObject(
            id: 'star1',
            type: 'star',
            color: Colors.yellow,
            size: 60,
            position: Offset(150, 500),
          ),
          DragObject(
            id: 'heart1',
            type: 'heart',
            color: Colors.pink,
            size: 60,
            position: Offset(250, 500),
          ),
        ],
      ),

      // Level 3: 2 shapes, 2 objects
      GameLevel(
        level: 3,
        instruction: "Match objects to their shapes",
        shapes: [
          ShapeData(
            type: 'square',
            position: Offset(150, 280),
            size: 100,
            outlineColor: Colors.green,
          ),
          ShapeData(
            type: 'circle',
            position: Offset(270, 280),
            size: 100,
            outlineColor: Colors.purple,
          ),
        ],
        objects: [
          DragObject(
            id: 'square_obj',
            type: 'square_filled',
            color: Colors.green,
            size: 70,
            position: Offset(120, 450),
          ),
          DragObject(
            id: 'circle_obj',
            type: 'circle_filled',
            color: Colors.purple,
            size: 70,
            position: Offset(280, 450),
          ),
        ],
      ),

      // Level 4: 2 shapes, 3 objects
      GameLevel(
        level: 4,
        instruction: "Sort the shapes correctly",
        shapes: [
          ShapeData(
            type: 'triangle',
            position: Offset(150, 280),
            size: 100,
            outlineColor: Colors.orange,
          ),
          ShapeData(
            type: 'star',
            position: Offset(270, 280),
            size: 100,
            outlineColor: Colors.teal,
          ),
        ],
        objects: [
          DragObject(
            id: 'triangle_obj',
            type: 'triangle_filled',
            color: Colors.orange,
            size: 60,
            position: Offset(100, 450),
          ),
          DragObject(
            id: 'star_obj1',
            type: 'star_filled',
            color: Colors.teal,
            size: 60,
            position: Offset(200, 450),
          ),
          DragObject(
            id: 'balloon2',
            type: 'balloon',
            color: Colors.red,
            size: 60,
            position: Offset(300, 450),
          ),
        ],
      ),

      // Level 5: 3 shapes, 4 objects
      GameLevel(
        level: 5,
        instruction: "Complete the pattern challenge",
        shapes: [
          ShapeData(
            type: 'square',
            position: Offset(120, 260),
            size: 80,
            outlineColor: Colors.red,
          ),
          ShapeData(
            type: 'circle',
            position: Offset(220, 260),
            size: 80,
            outlineColor: Colors.blue,
          ),
          ShapeData(
            type: 'triangle',
            position: Offset(320, 260),
            size: 80,
            outlineColor: Colors.green,
          ),
        ],
        objects: [
          DragObject(
            id: 'red_square',
            type: 'square_filled',
            color: Colors.red,
            size: 50,
            position: Offset(80, 450),
          ),
          DragObject(
            id: 'blue_circle',
            type: 'circle_filled',
            color: Colors.blue,
            size: 50,
            position: Offset(160, 450),
          ),
          DragObject(
            id: 'green_triangle',
            type: 'triangle_filled',
            color: Colors.green,
            size: 50,
            position: Offset(240, 450),
          ),
          DragObject(
            id: 'extra_star',
            type: 'star_filled',
            color: Colors.yellow,
            size: 50,
            position: Offset(320, 450),
          ),
        ],
      ),
    ];
  }

  void _loadLevel(int level) {
    setState(() {
      activeLevel = levels[level - 1];
      dragObjects = activeLevel.objects
          .map((obj) => DragObject(
                id: obj.id,
                type: obj.type,
                color: obj.color,
                size: obj.size,
                position: obj.position,
              ))
          .toList();
      showSuccess = false;
    });
  }

  bool _isObjectInShape(DragObject object, ShapeData shape) {
    double distance = (object.position - shape.position).distance;
    return distance < (shape.size / 2);
  }

  void _checkLevelComplete() {
    bool allPlaced = true;

    for (var object in dragObjects) {
      bool foundValidShape = false;

      for (var shape in activeLevel.shapes) {
        if (_isObjectInShape(object, shape)) {
          // Check if object type matches shape type (for matching levels)
          if (_isValidMatch(object.type, shape.type)) {
            foundValidShape = true;
            break;
          }
        }
      }

      if (!foundValidShape) {
        allPlaced = false;
        break;
      }
    }

    if (allPlaced) {
      _showSuccess();
    }
  }

  bool _isValidMatch(String objectType, String shapeType) {
    // For levels 1-2, any object can go in any shape
    if (currentLevel <= 2) return true;

    // For levels 3-5, check specific matches
    Map<String, String> validMatches = {
      'square_filled': 'square',
      'circle_filled': 'circle',
      'triangle_filled': 'triangle',
      'star_filled': 'star',
    };

    return validMatches[objectType] == shapeType ||
        objectType == 'balloon' ||
        objectType == 'star' ||
        objectType == 'heart';
  }

  void _showSuccess() {
    setState(() {
      showSuccess = true;
    });

    _successController.forward();
    _popController.forward().then((_) {
      _popController.reverse();
    });

    Future.delayed(Duration(seconds: 2), () {
      if (currentLevel < 5) {
        _nextLevel();
      } else {
        _showGameComplete();
      }
    });
  }

  void _nextLevel() {
    setState(() {
      currentLevel++;
      showSuccess = false;
    });
    _successController.reset();
    _loadLevel(currentLevel);
  }

  void _showGameComplete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('🎉 Congratulations!'),
          content: Text('You completed all levels!\nGreat job!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              child: Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void _resetGame() {
    setState(() {
      currentLevel = 1;
      showSuccess = false;
    });
    _successController.reset();
    _popController.reset();
    _loadLevel(currentLevel);
  }

  Widget _buildShape(ShapeData shape) {
    return Positioned(
      left: shape.position.dx - shape.size / 2,
      top: shape.position.dy - shape.size / 2,
      child: CustomPaint(
        size: Size(shape.size, shape.size),
        painter: ShapePainter(
          shapeType: shape.type,
          color: shape.outlineColor,
          filled: false,
        ),
      ),
    );
  }

  Widget _buildDragObject(DragObject object, int index) {
    return Positioned(
      left: object.position.dx - object.size / 2,
      top: object.position.dy - object.size / 2,
      child: Draggable<DragObject>(
        data: object,
        child: AnimatedBuilder(
          animation: _popAnimation,
          builder: (context, child) {
            double scale = object.isPlaced ? _popAnimation.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size(object.size, object.size),
                painter: ShapePainter(
                  shapeType: object.type,
                  color: object.color,
                  filled: true,
                ),
              ),
            );
          },
        ),
        feedback: CustomPaint(
          size: Size(object.size * 1.2, object.size * 1.2),
          painter: ShapePainter(
            shapeType: object.type,
            color: object.color.withOpacity(0.8),
            filled: true,
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            object.position =
                details.offset + Offset(object.size / 2, object.size / 2);
            object.isDragging = false;
          });
          _checkLevelComplete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.teal.shade400, Colors.teal.shade600],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Spacer(),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.teal.shade300, width: 2),
                      ),
                      child: Text(
                        'Level ${currentLevel}',
                        style: TextStyle(
                          color: Colors.teal.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: _resetGame,
                      icon: Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Game Area
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Instruction
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        child: Text(
                          activeLevel.instruction,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Game Canvas
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              // Shapes
                              ...activeLevel.shapes
                                  .map((shape) => _buildShape(shape)),

                              // Drag Objects
                              ...dragObjects.asMap().entries.map((entry) =>
                                  _buildDragObject(entry.value, entry.key)),

                              // Success Animation
                              if (showSuccess)
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _scaleAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _scaleAnimation.value,
                                        child: Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                offset: Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Great Job!',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
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

                      // Hints Section
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(12),
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
                            SizedBox(height: 8),
                            Text(
                              _getHintForLevel(currentLevel),
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

  String _getHintForLevel(int level) {
    switch (level) {
      case 1:
        return 'Drag the balloon into the square shape to continue to the next level.';
      case 2:
        return 'Place both objects inside the circle to complete this level.';
      case 3:
        return 'Match each object with its corresponding shape outline.';
      case 4:
        return 'Sort the shapes - only triangle and star objects belong in their shapes.';
      case 5:
        return 'Place each colored object in its matching colored shape outline.';
      default:
        return 'Drag objects to their correct positions.';
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    _popController.dispose();
    super.dispose();
  }
}

class ShapePainter extends CustomPainter {
  final String shapeType;
  final Color color;
  final bool filled;

  ShapePainter({
    required this.shapeType,
    required this.color,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 3;

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = size.width / 2;

    switch (shapeType) {
      case 'square':
      case 'square_filled':
        if (!filled) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 3;
          // Draw dashed outline
          _drawDashedRect(canvas, paint,
              Rect.fromLTWH(10, 10, size.width - 20, size.height - 20));
        } else {
          canvas.drawRect(
            Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
            paint,
          );
        }
        break;

      case 'circle':
      case 'circle_filled':
        if (!filled) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 3;
          _drawDashedCircle(canvas, paint, centerX, centerY, radius - 10);
        } else {
          canvas.drawCircle(Offset(centerX, centerY), radius - 5, paint);
        }
        break;

      case 'triangle':
      case 'triangle_filled':
        Path trianglePath = Path();
        trianglePath.moveTo(centerX, 5);
        trianglePath.lineTo(5, size.height - 5);
        trianglePath.lineTo(size.width - 5, size.height - 5);
        trianglePath.close();

        if (!filled) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 3;
          _drawDashedPath(canvas, paint, trianglePath);
        } else {
          canvas.drawPath(trianglePath, paint);
        }
        break;

      case 'star':
      case 'star_filled':
        Path starPath = _createStarPath(centerX, centerY, radius - 5, 5);
        if (!filled) {
          paint.style = PaintingStyle.stroke;
          paint.strokeWidth = 3;
          _drawDashedPath(canvas, paint, starPath);
        } else {
          canvas.drawPath(starPath, paint);
        }
        break;

      case 'balloon':
        // Balloon body
        canvas.drawOval(
          Rect.fromLTWH(10, 5, size.width - 20, size.height - 25),
          paint,
        );

        // Balloon string
        Paint stringPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(centerX, size.height - 20),
          Offset(centerX, size.height - 5),
          stringPaint,
        );

        // Highlight
        Paint highlightPaint = Paint()..color = Colors.white.withOpacity(0.6);
        canvas.drawOval(
          Rect.fromLTWH(size.width * 0.3, size.height * 0.2, size.width * 0.2,
              size.height * 0.15),
          highlightPaint,
        );
        break;

      case 'heart':
        Path heartPath = _createHeartPath(size);
        canvas.drawPath(heartPath, paint);
        break;
    }
  }

  void _drawDashedRect(Canvas canvas, Paint paint, Rect rect) {
    double dashWidth = 8;
    double dashSpace = 5;
    double startX = rect.left;

    // Top line
    while (startX < rect.right) {
      canvas.drawLine(
        Offset(startX, rect.top),
        Offset(min(startX + dashWidth, rect.right), rect.top),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Right line
    double startY = rect.top;
    while (startY < rect.bottom) {
      canvas.drawLine(
        Offset(rect.right, startY),
        Offset(rect.right, min(startY + dashWidth, rect.bottom)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }

    // Bottom line
    startX = rect.right;
    while (startX > rect.left) {
      canvas.drawLine(
        Offset(startX, rect.bottom),
        Offset(max(startX - dashWidth, rect.left), rect.bottom),
        paint,
      );
      startX -= dashWidth + dashSpace;
    }

    // Left line
    startY = rect.bottom;
    while (startY > rect.top) {
      canvas.drawLine(
        Offset(rect.left, startY),
        Offset(rect.left, max(startY - dashWidth, rect.top)),
        paint,
      );
      startY -= dashWidth + dashSpace;
    }
  }

  void _drawDashedCircle(Canvas canvas, Paint paint, double centerX,
      double centerY, double radius) {
    double dashWidth = 0.2;
    double dashSpace = 0.1;
    double angle = 0;

    while (angle < 2 * pi) {
      double startAngle = angle;
      double endAngle = min(angle + dashWidth, 2 * pi);

      Path dashPath = Path();
      dashPath.addArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        endAngle - startAngle,
      );

      canvas.drawPath(dashPath, paint);
      angle += dashWidth + dashSpace;
    }
  }

  void _drawDashedPath(Canvas canvas, Paint paint, Path path) {
    // For simplicity, just draw the path with stroke
    canvas.drawPath(path, paint);
  }

  Path _createStarPath(
      double centerX, double centerY, double radius, int points) {
    Path path = Path();
    double angle = -pi / 2;
    double angleIncrement = pi / points;

    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? radius : radius * 0.5;
      double x = centerX + cos(angle) * r;
      double y = centerY + sin(angle) * r;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      angle += angleIncrement;
    }

    path.close();
    return path;
  }

  Path _createHeartPath(Size size) {
    Path path = Path();
    double width = size.width;
    double height = size.height;

    path.moveTo(width / 2, height * 0.3);

    path.cubicTo(
      width * 0.2,
      height * 0.1,
      -width * 0.25,
      height * 0.6,
      width / 2,
      height,
    );

    path.cubicTo(
      width * 1.25,
      height * 0.6,
      width * 0.8,
      height * 0.1,
      width / 2,
      height * 0.3,
    );

    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
