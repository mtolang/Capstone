import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../services/game_data_service.dart';

// 🌈 Trace & Pop Adventure: A magical motor skills journey for little hands! ✨
// Kids trace colorful paths, pop rainbow bubbles, and meet friendly characters
// while developing fine motor skills and hand-eye coordination through play!
// 
// Features:
// 🎨 Colorful rainbow traces and sparkling effects
// 🐰 Friendly animal characters that cheer you on
// 🎈 Pop bubbles for bilateral coordination fun
// 🏆 Sticker rewards and celebration animations
// 📚 Shape, color, and alphabet learning integration

class TraceAndPopProGame extends StatefulWidget {
  const TraceAndPopProGame({super.key});

  @override
  State<TraceAndPopProGame> createState() => _TraceAndPopProGameState();
}

enum _Mode { trace, drawMatch, connectPath, shapeSculptor }

class _TraceAndPopProGameState extends State<TraceAndPopProGame>
    with SingleTickerProviderStateMixin {
  int _level = 1; // 1..5 increases complexity
  bool _twoHandMode = false; // bilateral mode
  bool _showGuideDots = true;
  double _targetSpeed = 300; // px/sec target; lower means slower tracing
  _Mode _mode = _Mode.trace;

  List<Offset> _pathPoints = [];
  List<_Bubble> _bubbles = [];
  final Map<int, _PointerSample> _pointers = {}; // track multiple pointers
  double _progress = 0; // 0..1 estimate how much of path covered

  // Draw & Match
  List<Offset> _targetShape = [];
  List<Offset> _drawnStroke = [];

  // Connect the Path
  List<Offset> _dots = [];
  int _nextDotIndex = 0;
  final List<Offset> _connections = []; // pairs

  // Shape Sculptor
  List<Offset> _sculptBase = [];
  Offset _sculptPos = Offset.zero;
  double _sculptScale = 1.0;
  double _sculptRotation = 0.0; // radians
  final List<Offset> _sculptTarget = [];
  Offset _sculptTargetPos = Offset.zero;
  double _sculptTargetScale = 1.0;
  double _sculptTargetRotation = 0.0;

  // Rhythm Tracer



  // Metrics
  DateTime _sessionStart = DateTime.now();
  int _onPathSamples = 0;
  int _totalSamples = 0;
  double _sumSpeed = 0;
  int _speedSamples = 0;
  int _bubblesPoppedCount = 0;
  bool _completed = false;
  
  // Shape validation feedback
  String _shapeValidationMessage = '';
  bool _showShapeValidation = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  /// Initialize game by loading saved progress
  Future<void> _initializeGame() async {
    try {
      // Load saved progress from unified user progress
      final userProgress = await GameDataService.getUserGameProgress();
      final savedLevel = userProgress.getCurrentLevel('trace_and_pop_pro');
      if (mounted) {
        setState(() {
          _level = savedLevel;
        });
      }
      print('Trace and Pop Pro: Starting at level $savedLevel');
    } catch (e) {
      print('Error loading saved level: $e');
      if (mounted) {
        setState(() {
          _level = 1; // Default to level 1
        });
      }
    }
    if (mounted) {
      _generateLevel();
      _newSession();
    }
  }

  @override
  void dispose() {
    // Save session data even if not completed when exiting
    if (!_completed &&
        DateTime.now().difference(_sessionStart).inSeconds > 10) {
      _saveGameSession();
    }
    
    // Properly dispose of all timers to prevent memory leaks

    
    // Clear collections to help with garbage collection
    _pathPoints.clear();
    _bubbles.clear();
    _pointers.clear();
    _targetShape.clear();
    _drawnStroke.clear();
    _dots.clear();
    _connections.clear();
    _sculptBase.clear();
    _sculptTarget.clear();
    
    super.dispose();
  }

  void _newSession() {
    _sessionStart = DateTime.now();
    _onPathSamples = 0;
    _totalSamples = 0;
    _sumSpeed = 0;
    _speedSamples = 0;
    _bubblesPoppedCount = 0;
    _completed = false;
  }

  /// Restart Level - clears current attempt but keeps level number
  void _restartLevel() {
    setState(() {
      // Clear all drawing/tracing progress
      _pointers.clear();
      _progress = 0;
      _completed = false;
      
      // Reset mode-specific variables
      _drawnStroke.clear();
      _nextDotIndex = 0;
      _connections.clear();
      
      // Reset shape validation feedback
      _shapeValidationMessage = '';
      _showShapeValidation = false;
      
      // Reset sculptor position
      _sculptPos = Offset.zero;
      _sculptScale = 1.0;
      _sculptRotation = 0.0;
      
      // Reset metrics for current attempt
      _onPathSamples = 0;
      _totalSamples = 0;
      _sumSpeed = 0;
      _speedSamples = 0;
      _bubblesPoppedCount = 0;
      
      // Reset bubbles to unpopped state
      for (var bubble in _bubbles) {
        bubble.popped = false;
      }
      
      // Start new session timer
      _sessionStart = DateTime.now();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Level $_level restarted!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Save current game session to Firebase
  Future<void> _saveGameSession() async {
    try {
      // Save using the new unified progress system
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'trace_and_pop_pro',
        level: _level,
        score: _bubblesPoppedCount * 10 + (_completed ? 50 : 0),
        completed: _completed,
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'bubblesPopped': _bubblesPoppedCount,
          'averageSpeed': _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
          'accuracy': _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
          'twoHandMode': _twoHandMode,
          'targetSpeed': _targetSpeed,
          'showGuideDots': _showGuideDots,

          'sessionStart': _sessionStart.toIso8601String(),
          'progress': _progress,
          'mode': _mode.name,
        },
      );

      print('Trace and Pop Pro session saved successfully');
    } catch (e) {
      print('Error saving Trace and Pop Pro session: $e');
    }
  }

  /// Show completion dialog when game is finished with lots of encouragement
  void _showCompletionDialog() {
    if (!mounted) return;
    
    // Choose random encouraging messages
    final encouragements = [
      'You\'re absolutely amazing! 🌟',
      'Fantastic work, superstar! ⭐',
      'You did it! You\'re incredible! 🎉',
      'Wow! You\'re getting so good at this! 🚀',
      'Outstanding job! Keep it up! 💫',
    ];
    
    final tips = [
      'Your finger control is getting better!',
      'You\'re learning to trace so smoothly!',
      'Great job following the path!',
      'Your hand movements are so steady!',
      'You\'re becoming a tracing expert!',
    ];
    
    final randomEncouragement = encouragements[Random().nextInt(encouragements.length)];
    final randomTip = tips[Random().nextInt(tips.length)];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.yellow.shade50,
          title: Column(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                randomEncouragement,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Level $_level Complete! 🏆',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Show achievements with fun emojis
                _buildAchievementRow('Bubbles Popped', '$_bubblesPoppedCount', '🎈'),
                _buildAchievementRow('Accuracy', '${_totalSamples > 0 ? (_onPathSamples / _totalSamples * 100).toStringAsFixed(0) : 0}%', '🎯'),
                _buildAchievementRow('Time', '${DateTime.now().difference(_sessionStart).inSeconds}s', '⏰'),
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    randomTip,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                if (_level < 5) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '🌟 Ready for the next adventure? 🌟',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (_level < 5)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _level++;
                  });
                  _generateLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward),
                    SizedBox(width: 4),
                    Text('Next Level! 🚀'),
                  ],
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _level = 1;
                  });
                  _generateLevel();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 4),
                    Text('Play Again! 🎮'),
                  ],
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to games menu
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('Back to Games 🏠'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementRow(String label, String value, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// Show user statistics and achievements dialog
  Future<void> _showStatistics() async {
    try {
      final statistics = await GameDataService.getUserStatistics();
      final progress = await GameDataService.getUserProgress();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => StatisticsDialog(
          statistics: statistics,
          progress: progress,
        ),
      );
    } catch (e) {
      print('Error loading statistics: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading statistics')),
      );
    }
  }

  void _generateLevel() {
    // Save previous session if it was meaningful (played for more than 10 seconds)
    if (DateTime.now().difference(_sessionStart).inSeconds > 10) {
      _saveGameSession();
    }

    // Save current level progress when advancing
    if (_level > 1) {
      _saveCurrentLevel();
    }

    // Generate a path based on level: straight -> curve -> complex -> zigzag -> letters
    _pathPoints = _buildPathForLevel(_level, const Size(360, 600));
    
    // Only spawn bubbles for trace mode - they're meant for bilateral coordination
    if (_mode == _Mode.trace) {
      _bubbles = _spawnBubbles(_level);
    } else {
      _bubbles.clear(); // Clear bubbles for other modes
    }
    
    _progress = 0;
    _lastProgressIndex = 0; // Reset progress tracking cache
    _drawnStroke.clear();
    _dots = _buildDotsForLevel(_level);
    _nextDotIndex = 0;
    _connections.clear();
    _targetShape = _buildTargetShape(_level);
    _initSculptTargets();
    
    // Clear shape validation feedback
    _showShapeValidation = false;
    _shapeValidationMessage = '';

    _newSession();
    setState(() {});
  }

  /// Save current level to database
  Future<void> _saveCurrentLevel() async {
    try {
      // Save progress using unified system
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'trace_and_pop_pro',
        level: _level,
        score: _bubblesPoppedCount * 10,
        completed: false, // Level advancement, not completion
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'mode': _mode.name,
          'bubblesPopped': _bubblesPoppedCount,
          'accuracy': _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
          'averageSpeed': _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
          'twoHandMode': _twoHandMode,
          'levelAdvancement': true,
        },
      );
    } catch (e) {
      print('Error saving current level: $e');
    }
  }



  List<Offset> _buildPathForLevel(int level, Size canvas) {
    final List<Offset> pts = [];
    final double w = canvas.width;
    final double h = canvas.height;
    
    // Adaptive difficulty: start with fewer segments for easier tracing
    final int baseSegments = 40; // Much easier starting point
    final int segments = baseSegments + (level * 15); // Gradual increase
    
    // Make paths child-friendly with larger curves and smoother transitions
    switch (level) {
      case 1: // Big, easy straight line - perfect for little fingers
        final double startY = h * 0.3;
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          // Wider margins for easier tracing
          pts.add(Offset(60 + t * (w - 120), startY));
        }
        break;
        
      case 2: // Simple L-shaped path - like following a corner
        final startX = 60.0;
        final startY = h * 0.3;
        final cornerX = startX + (w - 120) * 0.6;
        final endY = startY + h * 0.2;
        
        // Create L-shaped path: horizontal then vertical
        final waypoints = [
          Offset(startX, startY), // Start left
          Offset(cornerX, startY), // Go right to corner
          Offset(cornerX, endY), // Go down to end
        ];
        
        // Interpolate between waypoints
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final totalDistance = t * (waypoints.length - 1);
          final segmentIndex = totalDistance.floor().clamp(0, waypoints.length - 2);
          final segmentT = totalDistance - segmentIndex;
          
          final start = waypoints[segmentIndex];
          final end = waypoints[segmentIndex + 1];
          
          pts.add(Offset(
            start.dx + (end.dx - start.dx) * segmentT,
            start.dy + (end.dy - start.dy) * segmentT,
          ));
        }
        break;
        
      case 3: // Simple maze path - rectangular path like following walls
        final startX = 60.0;
        final startY = h * 0.25;
        final pathWidth = w - 120;
        final pathHeight = h * 0.3;
        
        // Create a rectangular maze-like path: right -> down -> left -> down -> right
        final waypoints = [
          Offset(startX, startY), // Start top-left
          Offset(startX + pathWidth * 0.7, startY), // Go right
          Offset(startX + pathWidth * 0.7, startY + pathHeight * 0.3), // Go down
          Offset(startX + pathWidth * 0.2, startY + pathHeight * 0.3), // Go left
          Offset(startX + pathWidth * 0.2, startY + pathHeight * 0.6), // Go down
          Offset(startX + pathWidth * 0.9, startY + pathHeight * 0.6), // Go right (end)
        ];
        
        // Interpolate between waypoints to create smooth path
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final totalDistance = t * (waypoints.length - 1);
          final segmentIndex = totalDistance.floor().clamp(0, waypoints.length - 2);
          final segmentT = totalDistance - segmentIndex;
          
          final start = waypoints[segmentIndex];
          final end = waypoints[segmentIndex + 1];
          
          pts.add(Offset(
            start.dx + (end.dx - start.dx) * segmentT,
            start.dy + (end.dy - start.dy) * segmentT,
          ));
        }
        break;
        
      case 4: // Stair-step maze pattern - like climbing stairs
        final startX = 60.0;
        final startY = h * 0.25;
        final pathWidth = w - 120;
        final pathHeight = h * 0.3;
        
        // Create stair-step pattern: right-down-right-down-right
        final waypoints = [
          Offset(startX, startY), // Start
          Offset(startX + pathWidth * 0.25, startY), // Right
          Offset(startX + pathWidth * 0.25, startY + pathHeight * 0.33), // Down
          Offset(startX + pathWidth * 0.5, startY + pathHeight * 0.33), // Right
          Offset(startX + pathWidth * 0.5, startY + pathHeight * 0.66), // Down
          Offset(startX + pathWidth * 0.75, startY + pathHeight * 0.66), // Right
          Offset(startX + pathWidth * 0.75, startY + pathHeight), // Down
          Offset(startX + pathWidth, startY + pathHeight), // Right to end
        ];
        
        // Interpolate between waypoints
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final totalDistance = t * (waypoints.length - 1);
          final segmentIndex = totalDistance.floor().clamp(0, waypoints.length - 2);
          final segmentT = totalDistance - segmentIndex;
          
          final start = waypoints[segmentIndex];
          final end = waypoints[segmentIndex + 1];
          
          pts.add(Offset(
            start.dx + (end.dx - start.dx) * segmentT,
            start.dy + (end.dy - start.dy) * segmentT,
          ));
        }
        break;
        
      case 5: // Advanced maze pattern - complex path like a real maze
      default:
        final startX = 60.0;
        final startY = h * 0.2;
        final pathWidth = w - 120;
        final pathHeight = h * 0.4;
        
        // Create a complex maze-like path with multiple turns
        final waypoints = [
          Offset(startX, startY), // Start
          Offset(startX + pathWidth * 0.6, startY), // Right
          Offset(startX + pathWidth * 0.6, startY + pathHeight * 0.25), // Down
          Offset(startX + pathWidth * 0.2, startY + pathHeight * 0.25), // Left
          Offset(startX + pathWidth * 0.2, startY + pathHeight * 0.5), // Down
          Offset(startX + pathWidth * 0.8, startY + pathHeight * 0.5), // Right
          Offset(startX + pathWidth * 0.8, startY + pathHeight * 0.75), // Down
          Offset(startX + pathWidth * 0.1, startY + pathHeight * 0.75), // Left
          Offset(startX + pathWidth * 0.1, startY + pathHeight), // Down
          Offset(startX + pathWidth * 0.9, startY + pathHeight), // Right to end
        ];
        
        // Interpolate between waypoints to create smooth maze path
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final totalDistance = t * (waypoints.length - 1);
          final segmentIndex = totalDistance.floor().clamp(0, waypoints.length - 2);
          final segmentT = totalDistance - segmentIndex;
          
          final start = waypoints[segmentIndex];
          final end = waypoints[segmentIndex + 1];
          
          pts.add(Offset(
            start.dx + (end.dx - start.dx) * segmentT,
            start.dy + (end.dy - start.dy) * segmentT,
          ));
        }
        break;
    }

    return pts;
  }

  List<_Bubble> _spawnBubbles(int level) {
    final rnd = Random(level * 42); // More predictable randomness
    
    // Adaptive bubble count - fewer bubbles for beginners
    final int baseCount = 4; // Start with just 4 bubbles
    final int count = baseCount + (level * 2); // Gradual increase
    
    final List<_Bubble> bubbles = [];
    final double minRadius = 35; // Much larger minimum size for little fingers
    final double maxRadius = 50; // Even bigger maximum
    
    // Strategic bubble placement - not too close to path
    for (int i = 0; i < count; i++) {
      late Offset center;
      int attempts = 0;
      
      // Try to place bubbles in good spots (not overlapping with path)
      do {
        center = Offset(
          80 + rnd.nextDouble() * 200, // Away from edges
          450 + rnd.nextDouble() * 120, // In lower area, away from main tracing
        );
        attempts++;
      } while (attempts < 10 && _isTooCloseToPath(center));
      
      // Add some colorful variety to bubbles
      final colors = [
        Colors.red.withOpacity(0.7),
        Colors.blue.withOpacity(0.7),
        Colors.green.withOpacity(0.7),
        Colors.yellow.withOpacity(0.7),
        Colors.purple.withOpacity(0.7),
        Colors.orange.withOpacity(0.7),
      ];
      
      bubbles.add(_Bubble(
        center: center,
        radius: minRadius + rnd.nextDouble() * (maxRadius - minRadius),
        color: colors[i % colors.length], // Assign color
      ));
    }
    return bubbles;
  }
  
  bool _isTooCloseToPath(Offset point) {
    // Check if bubble would be too close to tracing path
    for (final pathPoint in _pathPoints) {
      if ((point - pathPoint).distance < 80) { // Give plenty of space
        return true;
      }
    }
    return false;
  }

  List<Offset> _buildDotsForLevel(int level) {
    final count = 5 + level * 2; // Start with fewer dots, increase with level
    final List<Offset> pts = [];
    
    // Create a more structured pattern for challenge
    switch (level) {
      case 1: // Simple line of dots
        for (int i = 0; i < count; i++) {
          final t = i / (count - 1);
          pts.add(Offset(80 + t * 200, 250));
        }
        break;
        
      case 2: // L-shape pattern
        for (int i = 0; i < count; i++) {
          if (i < count ~/ 2) {
            pts.add(Offset(80, 200 + i * 40));
          } else {
            final offset = i - count ~/ 2;
            pts.add(Offset(80 + offset * 40, 200 + (count ~/ 2) * 40));
          }
        }
        break;
        
      case 3: // Triangle pattern
        final center = const Offset(180, 300);
        final radius = 80;
        for (int i = 0; i < count; i++) {
          final angle = i * 2 * pi / count;
          pts.add(Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          ));
        }
        break;
        
      case 4: // Zigzag pattern
        for (int i = 0; i < count; i++) {
          final t = i / (count - 1);
          final x = 60 + t * 240;
          final y = 250.0 + (i % 2 == 0 ? -40.0 : 40.0);
          pts.add(Offset(x, y));
        }
        break;
        
      case 5: // Complex spiral pattern
      default:
        final center = const Offset(180, 300);
        for (int i = 0; i < count; i++) {
          final t = i / (count - 1);
          final angle = t * 4 * pi; // Two full rotations
          final radius = 30 + t * 60; // Expanding spiral
          pts.add(Offset(
            center.dx + cos(angle) * radius,
            center.dy + sin(angle) * radius,
          ));
        }
        break;
    }
    
    return pts;
  }

  List<Offset> _buildTargetShape(int level) {
    switch (level) {
      case 1: // Simple large circle - easy to match
        return _circlePoints(const Offset(180, 280), 50, 48);
        
      case 2: // Square - introduces corners
        return _rectanglePoints(Rect.fromCenter(
            center: const Offset(180, 280), width: 120, height: 120));
            
      case 3: // Triangle - more complex shape
        return _trianglePoints(const Offset(180, 280), 90);
        
      case 4: // Star shape - challenging but fun
        return _starPoints(const Offset(180, 280), 70, 35, 5);
        
      case 5: // Heart shape - most challenging
      default:
        return _heartPoints(const Offset(180, 280), 60);
    }
  }
  
  List<Offset> _starPoints(Offset center, double outerRadius, double innerRadius, int points) {
    final List<Offset> pts = [];
    for (int i = 0; i < points * 2; i++) {
      final angle = i * pi / points - pi / 2;
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      pts.add(Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      ));
    }
    pts.add(pts.first); // Close the shape
    return pts;
  }
  
  List<Offset> _heartPoints(Offset center, double size) {
    final List<Offset> pts = [];
    const steps = 100;
    
    for (int i = 0; i <= steps; i++) {
      final t = i * 2 * pi / steps;
      // Parametric heart equation
      final x = 16 * pow(sin(t), 3);
      final y = -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t));
      
      pts.add(Offset(
        center.dx + x * size / 16,
        center.dy + y * size / 16,
      ));
    }
    
    return pts;
  }

  List<Offset> _circlePoints(Offset c, double r, int n) =>
      List.generate(n, (i) {
        final a = 2 * pi * i / n;
        return Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
      });

  List<Offset> _rectanglePoints(Rect rect) {
    final List<Offset> pts = [];
    const seg = 30;
    for (int i = 0; i <= seg; i++) {
      final t = i / seg;
      pts.add(Offset(lerpDouble(rect.left, rect.right, t)!, rect.top));
    }
    for (int i = 0; i <= seg; i++) {
      final t = i / seg;
      pts.add(Offset(rect.right, lerpDouble(rect.top, rect.bottom, t)!));
    }
    for (int i = 0; i <= seg; i++) {
      final t = i / seg;
      pts.add(Offset(lerpDouble(rect.right, rect.left, t)!, rect.bottom));
    }
    for (int i = 0; i <= seg; i++) {
      final t = i / seg;
      pts.add(Offset(rect.left, lerpDouble(rect.bottom, rect.top, t)!));
    }
    return pts;
  }

  List<Offset> _trianglePoints(Offset center, double size) {
    final double r = size / 2;
    final List<Offset> pts = [];
    for (int i = 0; i < 3; i++) {
      final a = -pi / 2 + i * 2 * pi / 3;
      pts.add(Offset(center.dx + cos(a) * r, center.dy + sin(a) * r));
    }
    pts.add(pts.first);
    return pts;
  }



  void _initSculptTargets() {
    _sculptBase = _trianglePoints(const Offset(0, 0), 100);
    _sculptPos = const Offset(120, 420);
    _sculptScale = 1.0;
    _sculptRotation = 0.0;
    _sculptTargetPos = const Offset(240, 420);
    _sculptTargetScale = 1.2;
    _sculptTargetRotation = pi / 8;
    _sculptTarget
      ..clear()
      ..addAll(_trianglePoints(const Offset(0, 0), 100));
  }



  void _onPointerDown(PointerDownEvent e) {
    if (!mounted) return;
    
    _pointers[e.pointer] =
        _PointerSample(position: e.localPosition, time: DateTime.now());
    
    bool poppedAny = false;
    
    // Handle single taps for bubble popping in single-hand mode
    if (!_twoHandMode) {
      for (final b in _bubbles) {
        if (!b.popped && (e.localPosition - b.center).distance <= b.radius) {
          b.popped = true;
          _bubblesPoppedCount += 1;
          poppedAny = true;
          break; // Only pop one bubble per tap
        }
      }
      
      // Add challenge: penalty for missing bubbles (clicking empty space)
      // Only penalize in advanced levels, not for young children
      if (!poppedAny && _level >= 4) {
        // Small penalty for missing clicks in higher levels only
        if (_bubblesPoppedCount > 0) {
          _bubblesPoppedCount = max(0, _bubblesPoppedCount - 1);
        }
      }
    }
    
    // Only setState if there were actual changes
    if (mounted && (poppedAny || _twoHandMode)) {
      setState(() {});
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!mounted) return;
    
    final prev = _pointers[e.pointer];
    final now = DateTime.now();
    if (prev != null) {
      final dt = now.difference(prev.time).inMicroseconds / 1e6;
      final dist = (e.localPosition - prev.position).distance;
      // Prevent division by zero and invalid speeds
      final speed = dt > 0.001 ? (dist / dt).clamp(0.0, 2000.0) : 0.0; // px/sec with reasonable limits
      _pointers[e.pointer] =
          _PointerSample(position: e.localPosition, time: now, speed: speed);
    } else {
      _pointers[e.pointer] =
          _PointerSample(position: e.localPosition, time: now);
    }

    switch (_mode) {
      case _Mode.trace:
        _progress = _estimateProgress(e.localPosition);
        break;
      case _Mode.drawMatch:
        _drawnStroke.add(e.localPosition);
        // Calculate progress based on drawn stroke length vs target shape length
        if (_targetShape.isNotEmpty && _drawnStroke.isNotEmpty) {
          double targetLength = 0;
          for (int i = 1; i < _targetShape.length; i++) {
            targetLength += (_targetShape[i] - _targetShape[i-1]).distance;
          }
          double drawnLength = 0;
          for (int i = 1; i < _drawnStroke.length; i++) {
            drawnLength += (_drawnStroke[i] - _drawnStroke[i-1]).distance;
          }
          _progress = targetLength > 0 ? (drawnLength / targetLength).clamp(0.0, 1.0) : 0.0;
        }
        break;
      case _Mode.connectPath:
        // Allow dragging to connect dots with child-friendly tolerance
        if (_nextDotIndex < _dots.length) {
          final tolerance = 40.0 + (5 - _level) * 8.0; // Easier for beginners
          final d = (e.localPosition - _dots[_nextDotIndex]).distance;
          if (d <= tolerance) {
            if (_nextDotIndex > 0) {
              _connections.add(_dots[_nextDotIndex - 1]);
              _connections.add(_dots[_nextDotIndex]);
            }
            _nextDotIndex++;
            // Calculate progress based on dots connected, not path tracing
            _progress = _dots.isEmpty ? 0.0 : _nextDotIndex / _dots.length;
            // Force state update when connecting dots
            if (mounted) {
              setState(() {});
            }
          }
        }
        break;
      case _Mode.shapeSculptor:
        // Handle shape transformation during drag
        final center = _sculptPos;
        final delta = e.localPosition - center;
        final distance = delta.distance;
        if (distance > 10 && distance < 150) {
          // Prevent extreme scaling values
          final newScale = (distance / 60).clamp(0.3, 3.0);
          _sculptScale = newScale;
          if (distance > 5) { // Prevent direction calculation on tiny distances
            _sculptRotation = delta.direction;
          }
        }
        break;

    }

    // Bubble popping with second hand while one hand is tracing (bilateral)
    if (_twoHandMode && _pointers.length >= 2) {
      for (final b in _bubbles) {
        if (!b.popped && (e.localPosition - b.center).distance <= b.radius) {
          b.popped = true;
          _bubblesPoppedCount += 1;
          break; // Only pop one bubble per move to prevent double counting
        }
      }
    }

    _totalSamples++;
    _sumSpeed += (_pointers[e.pointer]?.speed ?? 0);
    _speedSamples++;
    if (_mode == _Mode.trace) {
      final d = _distanceToPath(e.localPosition);
      // Much more forgiving tolerance for children - adapts to level
      final tolerance = 35 + (5 - _level) * 8; // Level 1: 67px, Level 5: 35px
      if (d < tolerance) _onPathSamples++;
    }

    final wasCompleted = _completed;
    // Only check for successful completion, not failures during gameplay
    _completed = _checkCompletion(e.localPosition);

    // Save to Firebase when game is completed for the first time
    if (_completed && !wasCompleted) {
      _saveGameSession();
      _showCompletionDialog();
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!mounted) return;
    
    _pointers.remove(e.pointer);
    
    if (mounted) {
      setState(() {});
    }
  }

  int _lastProgressIndex = 0; // Cache for optimization
  
  double _estimateProgress(Offset current) {
    if (_pathPoints.isEmpty) return 0;
    
    // Optimize: Start search from last known position (most touches are sequential)
    int bestIdx = _lastProgressIndex;
    double bestDist = (_pathPoints[bestIdx] - current).distance;
    
    // Search in a small window around last position first
    int searchRadius = min(10, _pathPoints.length ~/ 4);
    int startIdx = max(0, _lastProgressIndex - searchRadius);
    int endIdx = min(_pathPoints.length - 1, _lastProgressIndex + searchRadius);
    
    for (int i = startIdx; i <= endIdx; i++) {
      final d = (_pathPoints[i] - current).distance;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    
    // If we didn't find a good match nearby, do full search (rarely needed)
    if (bestDist > 100) {
      for (int i = 0; i < _pathPoints.length; i++) {
        final d = (_pathPoints[i] - current).distance;
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
    }
    
    _lastProgressIndex = bestIdx;
    final prog = bestIdx / (_pathPoints.length - 1);
    return prog.clamp(0, 1);
  }

  double _distanceToPath(Offset current) {
    if (_pathPoints.isEmpty) return double.infinity;
    
    // Use cached progress index as starting point for efficiency
    double best = (_pathPoints[_lastProgressIndex] - current).distance;
    
    // Check nearby points first (most likely to be closest)
    int searchRadius = min(15, _pathPoints.length ~/ 3);
    int startIdx = max(0, _lastProgressIndex - searchRadius);
    int endIdx = min(_pathPoints.length - 1, _lastProgressIndex + searchRadius);
    
    for (int i = startIdx; i <= endIdx; i++) {
      final d = (_pathPoints[i] - current).distance;
      if (d < best) best = d;
    }
    
    return best;
  }

  int get pathMaxIndex => max(1, _pathPoints.length - 1);

  bool _checkCompletion(Offset current) {
    // Only check for successful completion during gameplay, not failures
    // Failures should only be checked when user explicitly tries to complete or gives up
    
    switch (_mode) {
      case _Mode.trace:
        // Much more forgiving completion criteria - just check if genuinely completed
        final avgSpeed = _speedSamples > 0 ? _sumSpeed / _speedSamples : 0;
        
        // Very lenient completion - focus on completion rather than perfection
        final progressThreshold = 0.95; // Fixed 95% for proper completion - still achievable
        final accuracyRatio = _totalSamples > 0 ? _onPathSamples / _totalSamples : 0;
        final accuracyThreshold = 0.50; // Fixed 50% for all levels - more forgiving
        
        // Only require reasonable speed, not perfect speed
        final speedOk = avgSpeed > 30 && avgSpeed < 1200; // More lenient range
        
        // Also check minimum samples to prevent instant completion
        final minSamples = 20;
        
        return _progress >= progressThreshold && 
               accuracyRatio >= accuracyThreshold && 
               speedOk &&
               _totalSamples >= minSamples;
        
      case _Mode.drawMatch:
        // Require substantial drawing before allowing completion
        if (_drawnStroke.length < 50) {
          setState(() {
            _shapeValidationMessage = 'Keep drawing! Draw more of the shape.';
            _showShapeValidation = true;
          });
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showShapeValidation = false);
          });
          return false;
        }
        
        // Also require minimum drawing length to prevent tiny strokes from completing
        double drawnLength = 0;
        for (int i = 1; i < _drawnStroke.length; i++) {
          drawnLength += (_drawnStroke[i] - _drawnStroke[i-1]).distance;
        }
        if (drawnLength < 100) {
          setState(() {
            _shapeValidationMessage = 'Make your drawing bigger! Trace the shape outline.';
            _showShapeValidation = true;
          });
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showShapeValidation = false);
          });
          return false;
        }
        
        // Require reasonable progress (at least 70% of target shape coverage)
        if (_progress < 0.7) {
          setState(() {
            _shapeValidationMessage = 'Follow the shape outline more closely!';
            _showShapeValidation = true;
          });
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showShapeValidation = false);
          });
          return false;
        }
        
        final score = _matchScore(_drawnStroke, _targetShape);
        if (score >= 12) { // Stricter shape matching - must be more accurate
          // Get shape name for feedback
          String shapeName = _getShapeName(_level);
          setState(() {
            _shapeValidationMessage = 'Try to draw the $shapeName shape more accurately!';
            _showShapeValidation = true;
          });
          Timer(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showShapeValidation = false);
          });
          return false;
        }
        
        return true; // Shape matches well enough
        
      case _Mode.connectPath:
        return _nextDotIndex >= _dots.length;
        
      case _Mode.shapeSculptor:
        final posOk = (_sculptPos - _sculptTargetPos).distance < 30;
        final scaleOk = (_sculptScale - _sculptTargetScale).abs() < 0.25;
        final rotOk = (_sculptRotation - _sculptTargetRotation).abs() < pi / 8;
        return posOk && scaleOk && rotOk;
        

    }
  }
  
  double _matchScore(List<Offset> a, List<Offset> b) {
    double d1 = 0;
    for (final p in a) {
      double best = 1e9;
      for (final q in b) {
        final d = (p - q).distance;
        if (d < best) best = d;
      }
      d1 += best;
    }
    d1 /= max(1, a.length);
    double d2 = 0;
    for (final q in b) {
      double best = 1e9;
      for (final p in a) {
        final d = (p - q).distance;
        if (d < best) best = d;
      }
      d2 += best;
    }
    d2 /= max(1, b.length);
    return (d1 + d2) / 2;
  }
  
  String _getShapeName(int level) {
    switch (level) {
      case 1: return 'circle';
      case 2: return 'square';
      case 3: return 'triangle';
      case 4: return 'star';
      case 5: return 'heart';
      default: return 'shape';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌈 Trace & Pop Adventure ✨', 
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'My Progress 🏆',
              onPressed: _showStatistics,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8FF), // Alice blue
              Color(0xFFE6F3FF), // Light blue
              Color(0xFFFFF0F5), // Lavender blush
            ],
          ),
        ),
        child: Column(
          children: [
            _buildChildFriendlyControls(context),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onScaleStart: _mode == _Mode.shapeSculptor ? (details) {} : null,
                    onScaleUpdate: _mode == _Mode.shapeSculptor
                        ? (details) {
                            setState(() {
                              _sculptPos += details.focalPointDelta;
                              _sculptScale *= details.scale.clamp(0.9, 1.1);
                              _sculptRotation += details.rotation;
                            });
                          }
                        : null,
                    child: Listener(
                      onPointerDown: (e) {
                        if (_mode == _Mode.connectPath) {
                          if (_nextDotIndex < _dots.length) {
                            final d = (e.localPosition - _dots[_nextDotIndex]).distance;
                            if (d < 24) {
                              if (_nextDotIndex > 0) {
                                _connections.add(_dots[_nextDotIndex - 1]);
                                _connections.add(_dots[_nextDotIndex]);
                              }
                              _nextDotIndex++;
                              // Calculate progress based on dots connected
                              _progress = _dots.isEmpty ? 0.0 : _nextDotIndex / _dots.length;
                            }
                          }
                        }
                        _onPointerDown(e);
                      },
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      behavior: HitTestBehavior.opaque,
                      child: CustomPaint(
                        painter: _TracePainter(
                          mode: _mode,
                          path: _pathPoints,
                          pointers: _pointers,
                          showGuideDots: _showGuideDots,
                          targetSpeed: _targetSpeed,
                          bubbles: _bubbles,
                          twoHandMode: _twoHandMode,
                          targetShape: _targetShape,
                          drawnStroke: _drawnStroke,
                          dots: _dots,
                          nextDotIndex: _nextDotIndex,
                          connections: _connections,
                          sculptBase: _sculptBase,
                          sculptPos: _sculptPos,
                          sculptScale: _sculptScale,
                          sculptRotation: _sculptRotation,
                          sculptTarget: _sculptTarget,
                          sculptTargetPos: _sculptTargetPos,
                          sculptTargetScale: _sculptTargetScale,
                          sculptTargetRotation: _sculptTargetRotation,

                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 12,
                              top: 80, // Moved lower to avoid START indicator
                              child: _FriendlyProgressBadge(progress: _progress),
                            ),
                            if (_twoHandMode)
                              Positioned(
                                left: 12,
                                top: 80, // Moved to left side to avoid progress badge
                                child: _BubbleBuddy(
                                    remaining: _bubbles.where((b) => !b.popped).length),
                              ),
                            // Shape validation feedback for draw mode
                            if (_showShapeValidation && _mode == _Mode.drawMatch)
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 200,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.orange.shade300, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _shapeValidationMessage,
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: _ChildStatsPanel(
                                duration: DateTime.now().difference(_sessionStart),
                                avgSpeed: _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
                                onPathRatio: _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
                                bubblesPerMin: _bubblesPoppedCount /
                                    max(1, DateTime.now().difference(_sessionStart).inMinutes).toDouble(),
                                completed: _completed,
                              ),
                            ),
                            // Add challenge progress indicator
                            Positioned(
                              left: 12,
                              bottom: 80,
                              child: _ChallengeProgressIndicator(
                                mode: _mode,
                                level: _level,
                                progress: _progress,
                                accuracy: _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
                                speed: _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
                                targetSpeed: _targetSpeed,
                                timeElapsed: DateTime.now().difference(_sessionStart).inSeconds,
                              ),
                            ),
                            
                            // Add floating encouragement
                            if (_completed)
                              const Positioned.fill(
                                child: _CelebrationOverlay(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildFriendlyControls(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E1), Color(0xFFF0F8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fun Activity Selection - All 5 Types
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFunModeButton('🎨 Trace', _Mode.trace, Icons.brush),
                  _buildFunModeButton('✏️ Draw', _Mode.drawMatch, Icons.draw),
                  _buildFunModeButton('🔗 Connect', _Mode.connectPath, Icons.scatter_plot),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFunModeButton('🏗️ Sculpt', _Mode.shapeSculptor, Icons.architecture),

                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Level Stars (easier to understand for kids)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⭐ Level: ', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...List.generate(5, (i) => 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _level = i + 1;
                    });
                    _generateLevel();
                    _saveCurrentLevel();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _level > i ? Colors.yellow : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: _level > i ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _level > i ? Colors.orange.shade800 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fun Toggle Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToggleOption('🙌 Two Hands', _twoHandMode, (value) {
                setState(() {
                  _twoHandMode = value;
                });
                _generateLevel();
              }),
              _buildToggleOption('✨ Helper Dots', _showGuideDots, (value) {
                setState(() {
                  _showGuideDots = value;
                });
              }),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // New Adventure Button
          ElevatedButton(
            onPressed: () {
              _generateLevel();
              _newSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 8),
                Text('🚀 New Adventure!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Restart Level Button
          ElevatedButton(
            onPressed: () {
              _restartLevel();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.replay, size: 20),
                SizedBox(width: 8),
                Text('🔄 Restart Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunModeButton(String label, _Mode mode, IconData icon) {
    final isSelected = _mode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
        });
        _generateLevel();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
              ? [Colors.purple.shade300, Colors.purple.shade500]
              : [Colors.grey.shade200, Colors.grey.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? Colors.green.shade100 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? Colors.green : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value ? Colors.green : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value ? Colors.green.shade800 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildControlCard(
      {required IconData icon, required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF67AFA5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF67AFA5).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF006A5B), size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006A5B))),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildToggleCard(
      {required IconData icon,
      required String label,
      required bool value,
      required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value
              ? const Color(0xFF006A5B).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value ? const Color(0xFF006A5B) : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: value ? const Color(0xFF006A5B) : Colors.grey.shade600,
                size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF006A5B) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 16,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF006A5B) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.orange.shade700, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final _Mode mode;
  final List<Offset> path;
  final Map<int, _PointerSample> pointers;
  final bool showGuideDots;
  final double targetSpeed;
  final List<_Bubble> bubbles;
  final bool twoHandMode;
  final List<Offset>? targetShape;
  final List<Offset>? drawnStroke;
  final List<Offset>? dots;
  final int? nextDotIndex;
  final List<Offset>? connections;
  final List<Offset>? sculptBase;
  final Offset? sculptPos;
  final double? sculptScale;
  final double? sculptRotation;
  final List<Offset>? sculptTarget;
  final Offset? sculptTargetPos;
  final double? sculptTargetScale;
  final double? sculptTargetRotation;


  _TracePainter({
    required this.mode,
    required this.path,
    required this.pointers,
    required this.showGuideDots,
    required this.targetSpeed,
    required this.bubbles,
    required this.twoHandMode,
    this.targetShape,
    this.drawnStroke,
    this.dots,
    this.nextDotIndex,
    this.connections,
    this.sculptBase,
    this.sculptPos,
    this.sculptScale,
    this.sculptRotation,
    this.sculptTarget,
    this.sculptTargetPos,
    this.sculptTargetScale,
    this.sculptTargetRotation,

  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == _Mode.trace) {
      final Path p = Path();
      for (int i = 0; i < path.length; i++) {
        final pt = path[i];
        if (i == 0) {
          p.moveTo(pt.dx, pt.dy);
        } else {
          p.lineTo(pt.dx, pt.dy);
        }
      }
      
      // Draw outline first for better visibility
      final Paint outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      canvas.drawPath(p, outline);
      
      // Draw main trace path with rainbow gradient
      final Paint guide = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 // Thick and easy to follow
        ..strokeCap = StrokeCap.round;
      
      // Create rainbow gradient effect
      final rainbow = LinearGradient(
        colors: [
          Colors.red.shade400,
          Colors.orange.shade400,
          Colors.yellow.shade400,
          Colors.green.shade400,
          Colors.blue.shade400,
          Colors.purple.shade400,
        ],
      );
      
      guide.shader = rainbow.createShader(Rect.fromLTWH(0, 0, 400, 600));
      canvas.drawPath(p, guide);
      
      // Add clear start indicator - ONLY for trace mode
      if (path.isNotEmpty && mode == _Mode.trace) {
        final startPoint = path.first;
        
        // Bright start circle
        final Paint startPaint = Paint()
          ..color = Colors.green.withOpacity(0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(startPoint, 20, startPaint);
        
        // White border
        final Paint startBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(startPoint, 20, startBorder);
        
        // "START" text
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'START',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(startPoint.dx - textPainter.width / 2, startPoint.dy - textPainter.height / 2),
        );
      }
      
      // Add clear end indicator - ONLY for trace mode
      if (path.length > 1 && mode == _Mode.trace) {
        final startPoint = path.first;
        final endPoint = path.last;
        
        // Check if start and end points are too close
        final distance = (endPoint - startPoint).distance;
        final minDistance = 60.0; // Minimum distance for clear separation
        
        Offset adjustedEndPoint = endPoint;
        if (distance < minDistance && path.length > 2) {
          // Use a point further back from the end for better separation
          final backSteps = max(1, (path.length * 0.1).round()); // Go 10% back from end
          adjustedEndPoint = path[path.length - 1 - backSteps];
        }
        
        // End indicator with different color
        final Paint endPaint = Paint()
          ..color = Colors.red.withOpacity(0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(adjustedEndPoint, 18, endPaint);
        
        // White border
        final Paint endBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(adjustedEndPoint, 18, endBorder);
        
        // "END" text
        final textPainter = TextPainter(
          text: const TextSpan(
            text: 'END',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(adjustedEndPoint.dx - textPainter.width / 2, adjustedEndPoint.dy - textPainter.height / 2),
        );
      }
      
      // Add guide dots along the path - ONLY for trace mode
      if (showGuideDots && path.length > 10 && mode == _Mode.trace) {
        final dotSpacing = max(1, path.length ~/ 15); // Fewer dots, less clutter
        for (int i = dotSpacing; i < path.length - dotSpacing; i += dotSpacing) {
          final dot = Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(path[i], 4, dot);
        }
      }
      

    }

    if (mode == _Mode.drawMatch) {
      if (targetShape != null && targetShape!.isNotEmpty) {
        final tgtPaint = Paint()
          ..color = Colors.teal.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        final tp = Path()..moveTo(targetShape!.first.dx, targetShape!.first.dy);
        for (final pt in targetShape!.skip(1)) {
          tp.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(tp, tgtPaint);
      }
      if (drawnStroke != null && drawnStroke!.length > 1) {
        final up = Path()..moveTo(drawnStroke!.first.dx, drawnStroke!.first.dy);
        for (final pt in drawnStroke!.skip(1)) {
          up.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(
            up,
            Paint()
              ..color = Colors.indigo
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
      }
    }

    if (mode == _Mode.connectPath) {
      if (dots != null) {
        final dotPaint = Paint()..style = PaintingStyle.fill;
        for (int i = 0; i < dots!.length; i++) {
          dotPaint.color =
              i < (nextDotIndex ?? 0) ? Colors.green : Colors.orange;
          canvas.drawCircle(dots![i], 12, dotPaint); // Slightly larger dots
          
          // Add white border to dots
          final borderPaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(dots![i], 12, borderPaint);
          
          // Add START indicator to first dot
          if (i == 0) {
            final startTextPainter = TextPainter(
              text: const TextSpan(
                text: 'START',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            startTextPainter.layout();
            // Position text above the dot
            startTextPainter.paint(
              canvas, 
              Offset(dots![i].dx - startTextPainter.width / 2, dots![i].dy - 25),
            );
          }
          
          // Add END indicator to last dot
          if (i == dots!.length - 1) {
            final endTextPainter = TextPainter(
              text: const TextSpan(
                text: 'END',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            endTextPainter.layout();
            // Position text below the dot
            endTextPainter.paint(
              canvas, 
              Offset(dots![i].dx - endTextPainter.width / 2, dots![i].dy + 20),
            );
          }
          
          // Add number to each dot for sequence guidance - ONLY in connect mode
          if (mode == _Mode.connectPath) {
            final numberPainter = TextPainter(
              text: TextSpan(
                text: '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            numberPainter.layout();
            numberPainter.paint(
              canvas, 
              Offset(dots![i].dx - numberPainter.width / 2, dots![i].dy - numberPainter.height / 2),
            );
          }
        }
      }
      if (connections != null && connections!.length >= 2) {
        final linePaint = Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        for (int i = 0; i < connections!.length; i += 2) {
          if (i + 1 < connections!.length) {
            canvas.drawLine(connections![i], connections![i + 1], linePaint);
          }
        }
      }
    }

    if (mode == _Mode.shapeSculptor) {
      if (sculptTarget != null) {
        final Path tgt = _transformPoly(
            sculptTarget!,
            sculptTargetPos ?? Offset.zero,
            sculptTargetScale ?? 1.0,
            sculptTargetRotation ?? 0.0);
        canvas.drawPath(
            tgt,
            Paint()
              ..color = Colors.teal.shade200
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
      if (sculptBase != null) {
        final Path user = _transformPoly(sculptBase!, sculptPos ?? Offset.zero,
            sculptScale ?? 1.0, sculptRotation ?? 0.0);
        canvas.drawPath(
            user,
            Paint()
              ..color = Colors.indigo
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
      }
    }

    // Draw colorful bubbles for fun popping activity - ONLY for trace mode
    if (mode == _Mode.trace) {
      for (final b in bubbles) {
      if (b.popped) {
        // Simple popped bubble indicator
        final poppedPaint = Paint()
          ..color = Colors.green.withOpacity(0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(b.center, b.radius * 0.6, poppedPaint);
        
        // Simple "✓" checkmark
        final textPainter = TextPainter(
          text: const TextSpan(
            text: '✓',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas, 
          Offset(b.center.dx - textPainter.width / 2, b.center.dy - textPainter.height / 2),
        );
      } else {
        // Simple bubble design
        final bubblePaint = Paint()
          ..color = b.color.withOpacity(0.7)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(b.center, b.radius, bubblePaint);
        
        // Simple white border
        final bubbleStroke = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(b.center, b.radius, bubbleStroke);
      }
      }
    }

    // Draw clean finger tracking with simple, clear feedback
    for (final entry in pointers.entries) {
      final sample = entry.value;
      final double speed = sample.speed ?? 0; // px/s
      
      // Map speed to encouraging colors
      final double t = (speed / targetSpeed).clamp(0.0, 2.0); // 0..2
      
      // Simple color feedback
      Color fingerColor;
      if (t <= 0.7) {
        fingerColor = Colors.green; // Perfect speed
      } else if (t <= 1.3) {
        fingerColor = Colors.blue; // Good speed
      } else {
        fingerColor = Colors.orange; // A bit fast
      }

      // Simple finger indicator - just one clean circle
      final Paint touch = Paint()
        ..color = fingerColor.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sample.position, 12, touch);
      
      // White center for visibility
      final Paint center = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(sample.position, 6, center);
    }
  }

  Path _transformPoly(List<Offset> base, Offset pos, double scale, double rot) {
    final Path p = Path();
    for (int i = 0; i < base.length; i++) {
      final v = base[i];
      final xr = v.dx * cos(rot) - v.dy * sin(rot);
      final yr = v.dx * sin(rot) + v.dy * cos(rot);
      final pt = Offset(xr * scale + pos.dx, yr * scale + pos.dy);
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.path != path ||
        oldDelegate.pointers != pointers ||
        oldDelegate.showGuideDots != showGuideDots ||
        oldDelegate.targetSpeed != targetSpeed ||
        oldDelegate.bubbles != bubbles ||
        oldDelegate.twoHandMode != twoHandMode ||
        oldDelegate.targetShape != targetShape ||
        oldDelegate.drawnStroke != drawnStroke ||
        oldDelegate.dots != dots ||
        oldDelegate.nextDotIndex != nextDotIndex ||
        oldDelegate.connections != connections ||
        oldDelegate.sculptPos != sculptPos ||
        oldDelegate.sculptScale != sculptScale ||
        oldDelegate.sculptRotation != sculptRotation ||
        false;
  }
}

class _PointerSample {
  final Offset position;
  final DateTime time;
  final double? speed;
  _PointerSample({required this.position, required this.time, this.speed});
}

class _Bubble {
  final Offset center;
  final double radius;
  final Color color;
  bool popped = false;
  
  _Bubble({
    required this.center, 
    required this.radius,
    this.color = Colors.lightBlue,
  });
}

class _FriendlyProgressBadge extends StatelessWidget {
  final double progress;
  const _FriendlyProgressBadge({required this.progress});
  
  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final animal = _getProgressAnimal(progress);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cute animal progress indicator
          Text(
            animal,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          
          // Rainbow progress bar
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade200,
                  Colors.orange.shade200,
                  Colors.yellow.shade200,
                  Colors.green.shade200,
                  Colors.blue.shade200,
                  Colors.purple.shade200,
                ],
              ),
            ),
            child: Stack(
              children: [
                Container(
                  width: 80 * (1 - progress),
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Encouraging text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Text(
              '$pct% Great!',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getProgressAnimal(double progress) {
    if (progress < 0.2) return '🐣'; // Just starting
    if (progress < 0.4) return '🐰'; // Getting there
    if (progress < 0.6) return '🐻'; // Halfway
    if (progress < 0.8) return '🦊'; // Almost there
    return '🌟'; // Amazing!
  }
}

class _BubbleBuddy extends StatelessWidget {
  final int remaining;
  const _BubbleBuddy({required this.remaining});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bubble buddy character
          const Text('🫧', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.cyan.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Column(
              children: [
                Text(
                  'Pop Me!',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Text(
                  '$remaining left',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildStatsPanel extends StatelessWidget {
  final Duration duration;
  final double avgSpeed;
  final double onPathRatio;
  final double bubblesPerMin;
  final bool completed;
  
  const _ChildStatsPanel({
    required this.duration,
    required this.avgSpeed,
    required this.onPathRatio,
    required this.bubblesPerMin,
    required this.completed,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.lime.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cheerful header
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                'My Score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Simple kid-friendly stats
          _buildKidStat('⏰', '${duration.inSeconds}s', Colors.blue),
          const SizedBox(height: 4),
          _buildKidStat('🎯', '${(onPathRatio * 100).toStringAsFixed(0)}%', Colors.green),
          
          if (completed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade200, Colors.orange.shade200],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🎉', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Text(
                    'Amazing!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKidStat(String emoji, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// Celebration overlay for when the child completes a level
class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay();
  
  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_controller);
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: Colors.transparent,
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow.shade200,
                        Colors.orange.shade200,
                        Colors.pink.shade200,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 60)),
                      SizedBox(height: 10),
                      Text(
                        'Fantastic Job!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'You\'re amazing!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Statistics dialog showing user progress and achievements
class StatisticsDialog extends StatelessWidget {
  final GameStatistics statistics;
  final UserProgress progress;

  const StatisticsDialog({
    super.key,
    required this.statistics,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A5B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Color(0xFF006A5B)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Progress
                    _buildSectionCard(
                      'Overall Progress',
                      Icons.trending_up,
                      const Color(0xFF006A5B),
                      [
                        _buildStatItem('Highest Level',
                            '${progress.highestLevel}', Icons.stairs),
                        _buildStatItem('Total Sessions',
                            '${progress.totalSessions}', Icons.play_circle),
                        _buildStatItem(
                            'Play Time',
                            _formatDuration(progress.totalPlayTime),
                            Icons.timer),
                        _buildStatItem(
                            'Bubbles Popped',
                            '${progress.totalBubblesPopped}',
                            Icons.bubble_chart),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Performance Stats
                    _buildSectionCard(
                      'Performance',
                      Icons.speed,
                      const Color(0xFF67AFA5),
                      [
                        _buildStatItem(
                            'Average Accuracy',
                            '${(statistics.averageAccuracy * 100).toStringAsFixed(1)}%',
                            Icons.gps_fixed),
                        _buildStatItem(
                            'Average Speed',
                            '${statistics.averageSpeed.toStringAsFixed(0)} px/s',
                            Icons.speed),
                        _buildStatItem(
                            'Completion Rate',
                            '${statistics.totalSessions > 0 ? (statistics.totalCompletedSessions / statistics.totalSessions * 100).toStringAsFixed(1) : 0}%',
                            Icons.check_circle),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Game Modes
                    if (progress.modeCompletions.isNotEmpty) ...[
                      _buildSectionCard(
                        'Game Modes',
                        Icons.games,
                        Colors.blue,
                        progress.modeCompletions.entries
                            .map((entry) => _buildStatItem(
                                _formatModeName(entry.key),
                                '${entry.value} completed',
                                _getModeIcon(entry.key)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Achievements
                    if (progress.achievements.isNotEmpty) ...[
                      _buildSectionCard(
                        'Achievements',
                        Icons.emoji_events,
                        Colors.orange,
                        progress.achievements
                            .map((achievement) =>
                                _buildAchievementItem(achievement))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
      String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String achievement) {
    final achievementInfo = _getAchievementInfo(achievement);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(achievementInfo.icon, size: 16, color: Colors.orange.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievementInfo.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievementInfo.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatModeName(String mode) {
    switch (mode) {
      case 'trace':
        return 'Trace Path';
      case 'drawMatch':
        return 'Draw & Match';
      case 'connectPath':
        return 'Connect Dots';
      case 'shapeSculptor':
        return 'Shape Sculptor';

      default:
        return mode;
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'trace':
        return Icons.touch_app;
      case 'drawMatch':
        return Icons.draw;
      case 'connectPath':
        return Icons.connect_without_contact;
      case 'shapeSculptor':
        return Icons.architecture;

      default:
        return Icons.games;
    }
  }

  ({String title, String description, IconData icon}) _getAchievementInfo(
      String achievement) {
    switch (achievement) {
      case 'first_completion':
        return (
          title: 'First Success!',
          description: 'Completed your first game',
          icon: Icons.star
        );
      case 'level_3_master':
        return (
          title: 'Level 3 Master',
          description: 'Reached level 3',
          icon: Icons.trending_up
        );
      case 'level_5_master':
        return (
          title: 'Level 5 Master',
          description: 'Reached level 5',
          icon: Icons.military_tech
        );
      case 'bubble_buster':
        return (
          title: 'Bubble Buster',
          description: 'Popped 10 bubbles in one session',
          icon: Icons.bubble_chart
        );
      case 'bubble_master':
        return (
          title: 'Bubble Master',
          description: 'Popped 100 bubbles total',
          icon: Icons.stars
        );
      case 'speed_demon':
        return (
          title: 'Speed Demon',
          description: 'Achieved high speed tracing',
          icon: Icons.speed
        );
      case 'precision_master':
        return (
          title: 'Precision Master',
          description: 'Achieved 90%+ accuracy',
          icon: Icons.gps_fixed
        );
      case 'ambidextrous':
        return (
          title: 'Ambidextrous',
          description: 'Completed in two-hand mode',
          icon: Icons.back_hand
        );
      default:
        return (
          title: achievement,
          description: 'Achievement unlocked',
          icon: Icons.emoji_events
        );
    }
  }
}

// Challenge progress indicator to show real-time feedback
class _ChallengeProgressIndicator extends StatelessWidget {
  final _Mode mode;
  final int level;
  final double progress;
  final double accuracy;
  final double speed;
  final double targetSpeed;
  final int timeElapsed;
  
  const _ChallengeProgressIndicator({
    required this.mode,
    required this.level,
    required this.progress,
    required this.accuracy,
    required this.speed,
    required this.targetSpeed,
    required this.timeElapsed,
  });
  
  @override
  Widget build(BuildContext context) {
    final maxTime = 120 + (level * 30);
    final timeProgress = timeElapsed / maxTime;
    
    // Determine challenge status
    Color statusColor = Colors.green;
    String statusEmoji = '😊';
    String statusText = 'Great!';
    
    if (mode == _Mode.trace) {
      final progressThreshold = 0.95; // Consistent 95% completion requirement
      final accuracyThreshold = 0.65 + (level * 0.05);
      final speedMin = targetSpeed * (0.4 + level * 0.03);
      final speedMax = targetSpeed * (1.8 - level * 0.1);
      
      if (progress < progressThreshold * 0.7) {
        statusColor = Colors.orange;
        statusEmoji = '🎯';
        statusText = 'Follow path!';
      } else if (accuracy < accuracyThreshold * 0.8) {
        statusColor = Colors.orange;
        statusEmoji = '✨';
        statusText = 'Stay close!';
      } else if (speed > 0 && (speed < speedMin || speed > speedMax)) {
        statusColor = Colors.orange;
        statusEmoji = speed < speedMin ? '🐌' : '🚀';
        statusText = speed < speedMin ? 'Faster!' : 'Slower!';
      }
    }
    
    if (timeProgress > 0.8) {
      statusColor = Colors.red;
      statusEmoji = '⏰';
      statusText = 'Hurry!';
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(statusEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          // Time progress bar
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                Container(
                  width: 60 * timeProgress.clamp(0.0, 1.0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: timeProgress > 0.8 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
