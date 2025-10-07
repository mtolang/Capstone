import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../services/game_data_service.dart';

// Trace & Pop Pro: A motor skills trainer with tracing paths, visual "pressure" feedback,
// progressive difficulty, optional two-hand mode, and bubble popping for bilateral coordination.
// Notes:
// - Mobile devices don't expose real touch pressure broadly; we simulate "pressure" using
//   speed + pointer size heuristics. On web/desktop, we just use speed.

class TraceAndPopProGame extends StatefulWidget {
  const TraceAndPopProGame({super.key});

  @override
  State<TraceAndPopProGame> createState() => _TraceAndPopProGameState();
}

enum _Mode { trace, drawMatch, connectPath, shapeSculptor, rhythmTracer }

class _TraceAndPopProGameState extends State<TraceAndPopProGame> with SingleTickerProviderStateMixin {
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
  int _bpm = 80;
  Timer? _beatTimer;
  double _beatT = 0; // 0..1 expected point along the path

  // Metrics
  DateTime _sessionStart = DateTime.now();
  int _onPathSamples = 0;
  int _totalSamples = 0;
  double _sumSpeed = 0;
  int _speedSamples = 0;
  int _bubblesPoppedCount = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _generateLevel();
    _newSession();
  }

  @override
  void dispose() {
    // Save session data even if not completed when exiting
    if (!_completed && DateTime.now().difference(_sessionStart).inSeconds > 10) {
      _saveGameSession();
    }
    _beatTimer?.cancel();
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

  /// Save current game session to Firebase
  Future<void> _saveGameSession() async {
    try {
      final sessionData = GameSessionData(
        timestamp: DateTime.now(),
        gameType: 'trace_pop_pro',
        gameMode: _mode.name,
        level: _level,
        sessionDuration: DateTime.now().difference(_sessionStart),
        progress: _progress,
        score: _bubblesPoppedCount * 10 + (_completed ? 50 : 0),
        completed: _completed,
        gameSpecificData: {
          'bubblesPopped': _bubblesPoppedCount,
          'averageSpeed': _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
          'accuracy': _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
          'twoHandMode': _twoHandMode,
          'targetSpeed': _targetSpeed,
          'showGuideDots': _showGuideDots,
          'bpm': _bpm,
        },
        metadata: {
          'gameVersion': '1.0',
          'deviceType': 'mobile',
        },
      );

      await GameDataService.saveGameSession(sessionData);
      
      // Update user progress
      await _updateUserProgress();
      
      print('Game session saved successfully');
    } catch (e) {
      print('Error saving game session: $e');
    }
  }

  /// Update user progress and achievements
  Future<void> _updateUserProgress() async {
    try {
      final currentProgress = await GameDataService.getUserProgress();
      
      // Calculate new progress
      final newProgress = UserProgress(
        highestLevel: max(currentProgress.highestLevel, _level),
        modeCompletions: {
          ...currentProgress.modeCompletions,
          _mode.name: (currentProgress.modeCompletions[_mode.name] ?? 0) + (_completed ? 1 : 0),
        },
        totalSessions: currentProgress.totalSessions + 1,
        totalBubblesPopped: currentProgress.totalBubblesPopped + _bubblesPoppedCount,
        totalPlayTime: currentProgress.totalPlayTime + DateTime.now().difference(_sessionStart),
        achievements: _checkNewAchievements(currentProgress),
        lastPlayed: DateTime.now(),
      );

      await GameDataService.saveUserProgress(newProgress);
    } catch (e) {
      print('Error updating user progress: $e');
    }
  }

  /// Check for new achievements based on current session
  List<String> _checkNewAchievements(UserProgress currentProgress) {
    final achievements = List<String>.from(currentProgress.achievements);
    
    // First completion achievement
    if (_completed && currentProgress.totalSessions == 0) {
      achievements.add('first_completion');
    }
    
    // Level achievements
    if (_level >= 3 && !achievements.contains('level_3_master')) {
      achievements.add('level_3_master');
    }
    if (_level >= 5 && !achievements.contains('level_5_master')) {
      achievements.add('level_5_master');
    }
    
    // Bubble popping achievements
    if (_bubblesPoppedCount >= 10 && !achievements.contains('bubble_buster')) {
      achievements.add('bubble_buster');
    }
    if (currentProgress.totalBubblesPopped + _bubblesPoppedCount >= 100 && !achievements.contains('bubble_master')) {
      achievements.add('bubble_master');
    }
    
    // Speed achievements
    final avgSpeed = _speedSamples > 0 ? _sumSpeed / _speedSamples : 0;
    if (avgSpeed >= 400 && !achievements.contains('speed_demon')) {
      achievements.add('speed_demon');
    }
    
    // Accuracy achievements
    final accuracy = _totalSamples > 0 ? _onPathSamples / _totalSamples : 0;
    if (accuracy >= 0.9 && !achievements.contains('precision_master')) {
      achievements.add('precision_master');
    }
    
    // Two-hand mode achievement
    if (_twoHandMode && _completed && !achievements.contains('ambidextrous')) {
      achievements.add('ambidextrous');
    }
    
    return achievements;
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
    
    // Generate a path based on level: straight -> curve -> complex -> zigzag -> letters
    _pathPoints = _buildPathForLevel(_level, const Size(360, 600));
    _bubbles = _spawnBubbles(_level);
    _progress = 0;
    _drawnStroke.clear();
    _dots = _buildDotsForLevel(_level);
    _nextDotIndex = 0;
    _connections.clear();
    _targetShape = _buildTargetShape(_level);
    _initSculptTargets();
    _setupRhythm();
    _newSession();
    setState(() {});
  }

  List<Offset> _buildPathForLevel(int level, Size canvas) {
    final List<Offset> pts = [];
    final double w = canvas.width;
    final double h = canvas.height;
    final int segments = 60 + level * 20;

    switch (level) {
      case 1: // straight lines
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          pts.add(Offset(40 + t * (w - 80), h * 0.2));
        }
        break;
      case 2: // curve
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final x = 40 + t * (w - 80);
          final y = h * 0.2 + sin(t * pi) * 80;
          pts.add(Offset(x, y));
        }
        break;
      case 3: // complex wave + midline cross
        for (int i = 0; i < segments; i++) {
          final t = i / (segments - 1);
          final x = 40 + t * (w - 80);
          final y = h * 0.25 + sin(t * 2 * pi) * 100;
          pts.add(Offset(x, y));
        }
        break;
      case 4: // zigzag
        final int zig = 10;
        for (int z = 0; z <= zig; z++) {
          final t = z / zig;
          final x = 40 + t * (w - 80);
          final y = (z % 2 == 0) ? h * 0.2 : h * 0.4;
          pts.add(Offset(x, y));
        }
        break;
      case 5: // letter-like (circle)
      default:
        final cx = w / 2;
        final cy = h * 0.32;
        final r = min(w, h) * 0.18;
        for (int i = 0; i < segments; i++) {
          final a = i / segments * 2 * pi;
          pts.add(Offset(cx + cos(a) * r, cy + sin(a) * r));
        }
        break;
    }

    // optionally add a second parallel path for two-hand mode (not drawn, but validated)
    return pts;
  }

  List<_Bubble> _spawnBubbles(int level) {
    final rnd = Random(level);
    final count = 6 + level * 3;
    final List<_Bubble> bubbles = [];
    for (int i = 0; i < count; i++) {
      bubbles.add(_Bubble(
        center: Offset(60 + rnd.nextDouble() * 240, 380 + rnd.nextDouble() * 160),
        radius: 16 + rnd.nextDouble() * 16,
      ));
    }
    return bubbles;
  }

  List<Offset> _buildDotsForLevel(int level) {
    final rnd = Random(100 + level);
    final count = 6 + level * 2;
    final List<Offset> pts = [];
    for (int i = 0; i < count; i++) {
      pts.add(Offset(50 + rnd.nextDouble() * 260, 200 + rnd.nextDouble() * 260));
    }
    return pts;
  }

  List<Offset> _buildTargetShape(int level) {
    switch (level) {
      case 1:
        return _circlePoints(const Offset(180, 260), 60, 72);
      case 2:
  return _rectanglePoints(Rect.fromCenter(center: const Offset(180, 260), width: 140, height: 80));
      case 3:
        return _trianglePoints(const Offset(180, 260), 100);
      case 4:
        return _zigZagPoints(const Offset(60, 220), 240, 80, 6);
      default:
        return _circlePoints(const Offset(180, 260), 90, 96);
    }
  }

  List<Offset> _circlePoints(Offset c, double r, int n) =>
      List.generate(n, (i) { final a = 2 * pi * i / n; return Offset(c.dx + cos(a) * r, c.dy + sin(a) * r); });

  List<Offset> _rectanglePoints(Rect rect) {
    final List<Offset> pts = [];
    const seg = 30;
    for (int i = 0; i <= seg; i++) { final t = i / seg; pts.add(Offset(lerpDouble(rect.left, rect.right, t)!, rect.top)); }
    for (int i = 0; i <= seg; i++) { final t = i / seg; pts.add(Offset(rect.right, lerpDouble(rect.top, rect.bottom, t)!)); }
    for (int i = 0; i <= seg; i++) { final t = i / seg; pts.add(Offset(lerpDouble(rect.right, rect.left, t)!, rect.bottom)); }
    for (int i = 0; i <= seg; i++) { final t = i / seg; pts.add(Offset(rect.left, lerpDouble(rect.bottom, rect.top, t)!)); }
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

  List<Offset> _zigZagPoints(Offset start, double width, double height, int zigs) {
    final List<Offset> pts = [];
    for (int i = 0; i <= zigs; i++) {
      final t = i / zigs;
      final x = start.dx + t * width;
      final y = (i % 2 == 0) ? start.dy : start.dy + height;
      pts.add(Offset(x, y));
    }
    return pts;
  }

  void _initSculptTargets() {
    _sculptBase = _trianglePoints(const Offset(0, 0), 100);
    _sculptPos = const Offset(120, 420);
    _sculptScale = 1.0; _sculptRotation = 0.0;
    _sculptTargetPos = const Offset(240, 420);
    _sculptTargetScale = 1.2; _sculptTargetRotation = pi / 8;
    _sculptTarget
      ..clear()
      ..addAll(_trianglePoints(const Offset(0,0), 100));
  }

  void _setupRhythm() {
    _beatTimer?.cancel();
    if (_mode == _Mode.rhythmTracer) {
      final beatDurMs = (60000 / _bpm).round();
      _beatTimer = Timer.periodic(Duration(milliseconds: (beatDurMs / 6).round()), (timer) {
        setState(() {
          _beatT += 1 / (pathMaxIndex.clamp(1, 100));
          if (_beatT > 1) _beatT -= 1;
        });
      });
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = _PointerSample(position: e.localPosition, time: DateTime.now());
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent e) {
    final prev = _pointers[e.pointer];
    final now = DateTime.now();
    if (prev != null) {
      final dt = now.difference(prev.time).inMicroseconds / 1e6;
      final dist = (e.localPosition - prev.position).distance;
  final speed = dt > 0 ? dist / dt : 0.0; // px/sec
      _pointers[e.pointer] = _PointerSample(position: e.localPosition, time: now, speed: speed);
    } else {
      _pointers[e.pointer] = _PointerSample(position: e.localPosition, time: now);
    }

    switch (_mode) {
      case _Mode.trace:
        _progress = _estimateProgress(e.localPosition);
        break;
      case _Mode.drawMatch:
        _drawnStroke.add(e.localPosition);
        break;
      case _Mode.connectPath:
        break;
      case _Mode.shapeSculptor:
        break;
      case _Mode.rhythmTracer:
        _progress = _estimateProgress(e.localPosition);
        break;
    }

    // Bubble popping with second hand while one hand is tracing (bilateral)
    if (_twoHandMode && _pointers.length >= 2) {
      for (final b in _bubbles) {
        if (!b.popped && (e.localPosition - b.center).distance <= b.radius) {
          b.popped = true; _bubblesPoppedCount += 1;
        }
      }
    }

    _totalSamples++;
    _sumSpeed += (_pointers[e.pointer]?.speed ?? 0);
    _speedSamples++;
    if (_mode == _Mode.trace || _mode == _Mode.rhythmTracer) {
      final d = _distanceToPath(e.localPosition);
      if (d < 20) _onPathSamples++;
    }

    final wasCompleted = _completed;
    _completed = _checkCompletion(e.localPosition);
    
    // Save to Firebase when game is completed for the first time
    if (_completed && !wasCompleted) {
      _saveGameSession();
    }
    
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    setState(() {});
  }

  double _estimateProgress(Offset current) {
    if (_pathPoints.isEmpty) return 0;
    // Compute nearest index along path, map index to progress 0..1
    int bestIdx = 0;
    double bestDist = double.infinity;
    for (int i = 0; i < _pathPoints.length; i++) {
      final d = (_pathPoints[i] - current).distance;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    final prog = bestIdx / (_pathPoints.length - 1);
    return prog.clamp(0, 1);
  }

  double _distanceToPath(Offset current) {
    double best = double.infinity;
    for (final p in _pathPoints) {
      final d = (p - current).distance;
      if (d < best) best = d;
    }
    return best;
  }

  int get pathMaxIndex => max(1, _pathPoints.length - 1);

  bool _checkCompletion(Offset current) {
    switch (_mode) {
      case _Mode.trace:
        final avgSpeed = _speedSamples > 0 ? _sumSpeed / _speedSamples : 0;
        final speedOk = avgSpeed > _targetSpeed * 0.5 && avgSpeed < _targetSpeed * 1.5;
        return _progress > 0.95 && speedOk;
      case _Mode.drawMatch:
        if (_drawnStroke.length < 20) return false;
        final score = _matchScore(_drawnStroke, _targetShape);
        return score < 18;
      case _Mode.connectPath:
        return _nextDotIndex >= _dots.length;
      case _Mode.shapeSculptor:
        final posOk = (_sculptPos - _sculptTargetPos).distance < 15;
        final scaleOk = (_sculptScale - _sculptTargetScale).abs() < 0.12;
        final rotOk = (_sculptRotation - _sculptTargetRotation).abs() < pi / 18;
        return posOk && scaleOk && rotOk;
      case _Mode.rhythmTracer:
        final ratio = _totalSamples > 0 ? _onPathSamples / _totalSamples : 0;
        return ratio > 0.7;
    }
  }

  double _matchScore(List<Offset> a, List<Offset> b) {
    double d1 = 0;
    for (final p in a) {
      double best = 1e9;
      for (final q in b) { final d = (p - q).distance; if (d < best) best = d; }
      d1 += best;
    }
    d1 /= max(1, a.length);
    double d2 = 0;
    for (final q in b) {
      double best = 1e9;
      for (final p in a) { final d = (p - q).distance; if (d < best) best = d; }
      d2 += best;
    }
    d2 /= max(1, b.length);
    return (d1 + d2) / 2;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Trace & Pop Pro',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: IconButton.filled(
              tooltip: 'View Statistics',
              onPressed: _showStatistics,
              icon: const Icon(Icons.analytics, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF67AFA5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton.filled(
              tooltip: 'New Level',
              onPressed: _generateLevel,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF67AFA5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(context),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onScaleStart: _mode == _Mode.shapeSculptor ? (details) {} : null,
                  onScaleUpdate: _mode == _Mode.shapeSculptor ? (details) {
                    setState(() {
                      _sculptPos += details.focalPointDelta;
                      _sculptScale *= details.scale.clamp(0.9, 1.1);
                      _sculptRotation += details.rotation;
                    });
                  } : null,
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
                        beatT: _mode == _Mode.rhythmTracer ? _beatT : null,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 12,
                            top: 12,
                            child: _ProgressBadge(progress: _progress),
                          ),
                          if (_twoHandMode)
                            Positioned(
                              right: 12,
                              top: 12,
                              child: _BubbleBadge(remaining: _bubbles.where((b) => !b.popped).length),
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: _MetricsPanel(
                              duration: DateTime.now().difference(_sessionStart),
                              avgSpeed: _speedSamples > 0 ? _sumSpeed / _speedSamples : 0,
                              onPathRatio: _totalSamples > 0 ? _onPathSamples / _totalSamples : 0,
                              bubblesPerMin: _bubblesPoppedCount / max(1, DateTime.now().difference(_sessionStart).inMinutes).toDouble(),
                              completed: _completed,
                            ),
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
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mode Selection with Icons
          Row(
            children: [
              const Icon(Icons.games, color: Color(0xFF006A5B)),
              const SizedBox(width: 8),
              const Text('Activity:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF006A5B))),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF67AFA5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF67AFA5).withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_Mode>(
                      value: _mode,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      onChanged: (m) { if (m != null) { setState(() { _mode = m; }); _setupRhythm(); } },
                      items: const [
                        DropdownMenuItem(value: _Mode.trace, child: Text('🖐️ Trace Path')),
                        DropdownMenuItem(value: _Mode.drawMatch, child: Text('✏️ Draw & Match')),
                        DropdownMenuItem(value: _Mode.connectPath, child: Text('🔗 Connect Dots')),
                        DropdownMenuItem(value: _Mode.shapeSculptor, child: Text('🎨 Shape Sculptor')),
                        DropdownMenuItem(value: _Mode.rhythmTracer, child: Text('🎵 Rhythm Tracer')),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Level and Options in Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildControlCard(
                icon: Icons.stairs,
                label: 'Level',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) => 
                    GestureDetector(
                      onTap: () { setState(() { _level = i + 1; }); _generateLevel(); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _level == i + 1 ? const Color(0xFF006A5B) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: _level == i + 1 ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              _buildToggleCard(
                icon: Icons.scatter_plot,
                label: 'Guide Dots',
                value: _showGuideDots,
                onChanged: (v) => setState(() => _showGuideDots = v),
              ),
              
              _buildToggleCard(
                icon: Icons.back_hand,
                label: 'Two Hands',
                value: _twoHandMode,
                onChanged: (v) => setState(() => _twoHandMode = v),
              ),
              
              if (_mode == _Mode.rhythmTracer)
                _buildControlCard(
                  icon: Icons.music_note,
                  label: 'Beat Speed',
                  child: SizedBox(
                    width: 120,
                    child: Slider(
                      value: _bpm.toDouble(),
                      min: 60,
                      max: 140,
                      divisions: 8,
                      activeColor: const Color(0xFF006A5B),
                      onChanged: (v) { setState(() { _bpm = v.round(); }); _setupRhythm(); },
                    ),
                  ),
                ),
              
              if (_mode == _Mode.drawMatch)
                _buildActionCard(
                  icon: Icons.clear,
                  label: 'Clear',
                  onTap: () { _drawnStroke.clear(); setState(() {}); },
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlCard({required IconData icon, required String label, required Widget child}) {
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
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF006A5B))),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
  
  Widget _buildToggleCard({required IconData icon, required String label, required bool value, required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF006A5B).withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? const Color(0xFF006A5B) : Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? const Color(0xFF006A5B) : Colors.grey.shade600, size: 20),
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
  
  Widget _buildActionCard({required IconData icon, required String label, required VoidCallback onTap}) {
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
  final double? beatT;

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
    this.beatT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == _Mode.trace || mode == _Mode.rhythmTracer) {
      final Paint guide = Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final Path p = Path();
      for (int i = 0; i < path.length; i++) {
        final pt = path[i];
        if (i == 0) { p.moveTo(pt.dx, pt.dy); } else { p.lineTo(pt.dx, pt.dy); }
      }
      canvas.drawPath(p, guide);
      if (showGuideDots) {
        final dot = Paint()..color = Colors.grey.shade400;
        for (int i = 0; i < path.length; i += max(1, path.length ~/ 30)) {
          canvas.drawCircle(path[i], 3, dot);
        }
      }
      if (mode == _Mode.rhythmTracer && beatT != null && path.isNotEmpty) {
        final idx = (beatT!.clamp(0, 1) * (path.length - 1)).round();
        final pExp = path[idx];
        final paintBeat = Paint()..color = Colors.purple..style = PaintingStyle.fill;
        canvas.drawCircle(pExp, 10, paintBeat);
      }
    }

    if (mode == _Mode.drawMatch) {
      if (targetShape != null && targetShape!.isNotEmpty) {
        final tgtPaint = Paint()
          ..color = Colors.teal.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        final tp = Path()..moveTo(targetShape!.first.dx, targetShape!.first.dy);
        for (final pt in targetShape!.skip(1)) { tp.lineTo(pt.dx, pt.dy); }
        canvas.drawPath(tp, tgtPaint);
      }
      if (drawnStroke != null && drawnStroke!.length > 1) {
        final up = Path()..moveTo(drawnStroke!.first.dx, drawnStroke!.first.dy);
        for (final pt in drawnStroke!.skip(1)) { up.lineTo(pt.dx, pt.dy); }
        canvas.drawPath(up, Paint()..color = Colors.indigo..style = PaintingStyle.stroke..strokeWidth = 4);
      }
    }

    if (mode == _Mode.connectPath) {
      if (dots != null) {
        final dotPaint = Paint()..style = PaintingStyle.fill;
        for (int i = 0; i < dots!.length; i++) {
          dotPaint.color = i < (nextDotIndex ?? 0) ? Colors.green : Colors.orange;
          canvas.drawCircle(dots![i], 8, dotPaint);
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
        final Path tgt = _transformPoly(sculptTarget!, sculptTargetPos ?? Offset.zero, sculptTargetScale ?? 1.0, sculptTargetRotation ?? 0.0);
        canvas.drawPath(tgt, Paint()..color = Colors.teal.shade200..style = PaintingStyle.stroke..strokeWidth = 3);
      }
      if (sculptBase != null) {
        final Path user = _transformPoly(sculptBase!, sculptPos ?? Offset.zero, sculptScale ?? 1.0, sculptRotation ?? 0.0);
        canvas.drawPath(user, Paint()..color = Colors.indigo..style = PaintingStyle.stroke..strokeWidth = 4);
      }
    }

    // Draw bubbles for two-hand activity
    if (twoHandMode) {
      final bubblePaint = Paint()..style = PaintingStyle.fill;
      for (final b in bubbles) {
        bubblePaint.color = b.popped ? Colors.greenAccent.withOpacity(0.4) : Colors.lightBlueAccent.withOpacity(0.6);
        canvas.drawCircle(b.center, b.radius, bubblePaint);
      }
    }

    // Draw current pointers with pressure-like feedback (speed -> width/color)
    for (final entry in pointers.entries) {
      final sample = entry.value;
      final double speed = sample.speed ?? 0; // px/s
      // Map speed to a color/width delta: slower -> green & thicker; too fast -> red & thinner
      final double t = (speed / targetSpeed).clamp(0.0, 2.0); // 0..2
      final double width = 12 - (t * 4); // 12 -> 4
      final Color col = (t <= 1.0)
          ? Color.lerp(Colors.green, Colors.orange, t)!
          : Color.lerp(Colors.orange, Colors.red, t - 1)!;

      final Paint touch = Paint()
        ..color = col.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sample.position, max(6, width), touch);

      // Small time-fade trail
      final trail = Paint()
        ..color = col.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(3, width - 2)
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(sample.position, max(12, width * 2), trail);
    }
  }

  Path _transformPoly(List<Offset> base, Offset pos, double scale, double rot) {
    final Path p = Path();
    for (int i = 0; i < base.length; i++) {
      final v = base[i];
      final xr = v.dx * cos(rot) - v.dy * sin(rot);
      final yr = v.dx * sin(rot) + v.dy * cos(rot);
      final pt = Offset(xr * scale + pos.dx, yr * scale + pos.dy);
      if (i == 0) { p.moveTo(pt.dx, pt.dy); } else { p.lineTo(pt.dx, pt.dy); }
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
        oldDelegate.beatT != beatT;
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
  bool popped = false;
  _Bubble({required this.center, required this.radius});
}

class _ProgressBadge extends StatelessWidget {
  final double progress;
  const _ProgressBadge({required this.progress});
  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A5B).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF006A5B).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF006A5B), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Progress',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF006A5B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF67AFA5).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 60 * progress,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF006A5B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF006A5B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleBadge extends StatelessWidget {
  final int remaining;
  const _BubbleBadge({required this.remaining});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF67AFA5).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFF67AFA5).withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bubble_chart, color: Color(0xFF67AFA5), size: 18),
              const SizedBox(width: 6),
              const Text(
                'Bubbles',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF67AFA5)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF67AFA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$remaining',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF67AFA5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  final Duration duration;
  final double avgSpeed;
  final double onPathRatio;
  final double bubblesPerMin;
  final bool completed;
  const _MetricsPanel({
    required this.duration,
    required this.avgSpeed,
    required this.onPathRatio,
    required this.bubblesPerMin,
    required this.completed,
  });
  @override
  Widget build(BuildContext context) {
    String fmt(double v) => v.isNaN || v.isInfinite ? '-' : v.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF67AFA5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.analytics, color: Color(0xFF006A5B), size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Performance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006A5B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Metrics in card format
          _buildMetricItem(Icons.timer, 'Time', '${duration.inSeconds}s', const Color(0xFF67AFA5)),
          const SizedBox(height: 8),
          _buildMetricItem(Icons.speed, 'Speed', '${fmt(avgSpeed)} px/s', Colors.blue),
          const SizedBox(height: 8),
          _buildMetricItem(Icons.gps_fixed, 'Accuracy', '${(onPathRatio * 100).toStringAsFixed(0)}%', Colors.green),
          const SizedBox(height: 8),
          _buildMetricItem(Icons.bubble_chart, 'Rate', '${fmt(bubblesPerMin)}/min', Colors.orange),
          
          if (completed) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Completed!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
  
  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
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
                        _buildStatItem('Highest Level', '${progress.highestLevel}', Icons.stairs),
                        _buildStatItem('Total Sessions', '${progress.totalSessions}', Icons.play_circle),
                        _buildStatItem('Play Time', _formatDuration(progress.totalPlayTime), Icons.timer),
                        _buildStatItem('Bubbles Popped', '${progress.totalBubblesPopped}', Icons.bubble_chart),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Performance Stats
                    _buildSectionCard(
                      'Performance',
                      Icons.speed,
                      const Color(0xFF67AFA5),
                      [
                        _buildStatItem('Average Accuracy', '${(statistics.averageAccuracy * 100).toStringAsFixed(1)}%', Icons.gps_fixed),
                        _buildStatItem('Average Speed', '${statistics.averageSpeed.toStringAsFixed(0)} px/s', Icons.speed),
                        _buildStatItem('Completion Rate', '${statistics.totalSessions > 0 ? (statistics.totalCompletedSessions / statistics.totalSessions * 100).toStringAsFixed(1) : 0}%', Icons.check_circle),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Game Modes
                    if (progress.modeCompletions.isNotEmpty) ...[
                      _buildSectionCard(
                        'Game Modes',
                        Icons.games,
                        Colors.blue,
                        progress.modeCompletions.entries.map((entry) =>
                          _buildStatItem(_formatModeName(entry.key), '${entry.value} completed', _getModeIcon(entry.key))
                        ).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Achievements
                    if (progress.achievements.isNotEmpty) ...[
                      _buildSectionCard(
                        'Achievements',
                        Icons.emoji_events,
                        Colors.orange,
                        progress.achievements.map((achievement) =>
                          _buildAchievementItem(achievement)
                        ).toList(),
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

  Widget _buildSectionCard(String title, IconData icon, Color color, List<Widget> children) {
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
      case 'rhythmTracer':
        return 'Rhythm Tracer';
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
      case 'rhythmTracer':
        return Icons.music_note;
      default:
        return Icons.games;
    }
  }

  ({String title, String description, IconData icon}) _getAchievementInfo(String achievement) {
    switch (achievement) {
      case 'first_completion':
        return (title: 'First Success!', description: 'Completed your first game', icon: Icons.star);
      case 'level_3_master':
        return (title: 'Level 3 Master', description: 'Reached level 3', icon: Icons.trending_up);
      case 'level_5_master':
        return (title: 'Level 5 Master', description: 'Reached level 5', icon: Icons.military_tech);
      case 'bubble_buster':
        return (title: 'Bubble Buster', description: 'Popped 10 bubbles in one session', icon: Icons.bubble_chart);
      case 'bubble_master':
        return (title: 'Bubble Master', description: 'Popped 100 bubbles total', icon: Icons.stars);
      case 'speed_demon':
        return (title: 'Speed Demon', description: 'Achieved high speed tracing', icon: Icons.speed);
      case 'precision_master':
        return (title: 'Precision Master', description: 'Achieved 90%+ accuracy', icon: Icons.gps_fixed);
      case 'ambidextrous':
        return (title: 'Ambidextrous', description: 'Completed in two-hand mode', icon: Icons.back_hand);
      default:
        return (title: achievement, description: 'Achievement unlocked', icon: Icons.emoji_events);
    }
  }
}
