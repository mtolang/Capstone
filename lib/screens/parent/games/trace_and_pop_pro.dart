import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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

  void _newSession() {
    _sessionStart = DateTime.now();
    _onPathSamples = 0;
    _totalSamples = 0;
    _sumSpeed = 0;
    _speedSamples = 0;
    _bubblesPoppedCount = 0;
    _completed = false;
  }

  void _generateLevel() {
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

    _completed = _checkCompletion(e.localPosition);
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
      appBar: AppBar(
        title: const Text('Trace & Pop Pro'),
        actions: [
          IconButton(
            tooltip: 'Restart Level',
            onPressed: _generateLevel,
            icon: const Icon(Icons.refresh),
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
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Mode:'),
            const SizedBox(width: 8),
            DropdownButton<_Mode>(
              value: _mode,
              onChanged: (m) { if (m != null) { setState(() { _mode = m; }); _setupRhythm(); } },
              items: const [
                DropdownMenuItem(value: _Mode.trace, child: Text('Trace')),
                DropdownMenuItem(value: _Mode.drawMatch, child: Text('Draw & Match')),
                DropdownMenuItem(value: _Mode.connectPath, child: Text('Connect the Path')),
                DropdownMenuItem(value: _Mode.shapeSculptor, child: Text('Shape Sculptor')),
                DropdownMenuItem(value: _Mode.rhythmTracer, child: Text('Rhythm Tracer')),
              ],
            ),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Level:'),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _level,
              onChanged: (v) { if (v != null) { setState(() { _level = v; }); _generateLevel(); } },
              items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
            ),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Guide Dots:'),
            Switch(value: _showGuideDots, onChanged: (v) => setState(() => _showGuideDots = v)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Two-hand Mode:'),
            Switch(value: _twoHandMode, onChanged: (v) => setState(() => _twoHandMode = v)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Target Speed'),
            Slider(
              value: _targetSpeed,
              min: 100,
              max: 800,
              divisions: 7,
              label: _targetSpeed.round().toString(),
              onChanged: (v) => setState(() => _targetSpeed = v),
            ),
          ]),
          if (_mode == _Mode.rhythmTracer)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('BPM'),
              Slider(
                value: _bpm.toDouble(), min: 60, max: 140, divisions: 8,
                label: '$_bpm',
                onChanged: (v) { setState(() { _bpm = v.round(); }); _setupRhythm(); },
              ),
            ]),
          if (_mode == _Mode.drawMatch)
            ElevatedButton(
              onPressed: () { _drawnStroke.clear(); setState(() {}); },
              child: const Text('Clear Drawing'),
            ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Progress: $pct%', style: const TextStyle(color: Colors.white)),
    );
  }
}

class _BubbleBadge extends StatelessWidget {
  final int remaining;
  const _BubbleBadge({required this.remaining});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Bubbles: $remaining', style: const TextStyle(color: Colors.white)),
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${duration.inSeconds}s'),
            Text('Avg speed: ${fmt(avgSpeed)} px/s'),
            Text('On-path: ${(onPathRatio * 100).toStringAsFixed(0)}%'),
            Text('Bubbles/min: ${fmt(bubblesPerMin)}'),
            if (completed)
              const Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Text('Completed!', style: TextStyle(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
