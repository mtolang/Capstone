import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../../services/game_data_service.dart';

class PatternMasterApp extends StatelessWidget {
  const PatternMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pattern Master',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Comic Sans MS', // More child-friendly font
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
      home: const PatternMasterGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CognitiveElement {
  final String id;
  final String type; // 'shape', 'number', 'letter', 'color'
  final String value;
  final Color color;
  final double size;
  Offset position;
  bool isVisible;
  bool isMatched;
  bool isObstacle;
  Duration? flashDuration;
  double animationScale; // For bouncy animations
  
  CognitiveElement({
    required this.id,
    required this.type,
    required this.value,
    required this.color,
    required this.size,
    required this.position,
    this.isVisible = true,
    this.isMatched = false,
    this.isObstacle = false,
    this.flashDuration,
    this.animationScale = 1.0, // Default scale
  });
}

class GameObstacle {
  final String type; // 'timer', 'memory_flash', 'distractor', 'sequence'
  final Map<String, dynamic> properties;
  bool isActive;

  GameObstacle({
    required this.type,
    required this.properties,
    this.isActive = true,
  });
}

class PatternMasterGame extends StatefulWidget {
  const PatternMasterGame({super.key});

  @override
  _PatternMasterGameState createState() => _PatternMasterGameState();
}

class _PatternMasterGameState extends State<PatternMasterGame>
    with TickerProviderStateMixin {
  
  int currentLevel = 0; // 0-4 for 5 levels
  bool gameActive = false;
  bool showSuccess = false;
  late AnimationController _successController;
  late AnimationController _timerController;
  late Animation<double> _successAnimation;

  List<CognitiveElement> gameElements = [];
  List<CognitiveElement> targetPattern = [];
  List<GameObstacle> activeObstacles = [];
  
  Timer? _gameTimer;
  Timer? _memoryFlashTimer;
  int timeRemaining = 0;
  bool memoryPhase = false;
  List<String> sequenceToRemember = [];
  List<String> userSequence = [];

  // Cognitive tracking
  DateTime _sessionStart = DateTime.now();
  int _correctMatches = 0;
  int _totalAttempts = 0;
  int _levelsCompleted = 0;
  Map<String, int> _cognitiveSkillsUsed = {};

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _successAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      final userProgress = await GameDataService.getUserGameProgress();
      final savedLevel = userProgress.getCurrentLevel('pattern_master');
      setState(() {
        currentLevel = savedLevel - 1;
      });
      print('Pattern Master: Starting at level $savedLevel');
    } catch (e) {
      print('Error loading saved level: $e');
      setState(() {
        currentLevel = 0;
      });
    }
    _loadLevel();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _memoryFlashTimer?.cancel();
    _successController.dispose();
    _timerController.dispose();
    if (DateTime.now().difference(_sessionStart).inSeconds > 10) {
      _saveGameSession();
    }
    super.dispose();
  }

  void _loadLevel() {
    setState(() {
      gameElements.clear();
      targetPattern.clear();
      activeObstacles.clear();
      showSuccess = false;
      gameActive = false;
      memoryPhase = false;
      userSequence.clear();
      sequenceToRemember.clear();
    });

    _gameTimer?.cancel();
    _memoryFlashTimer?.cancel();

    switch (currentLevel) {
      case 0:
        _loadLevel1(); // Visual Pattern Memory
        break;
      case 1:
        _loadLevel2(); // Sequence Recognition with Timer
        break;
      case 2:
        _loadLevel3(); // Multi-Modal Pattern with Distractors
        break;
      case 3:
        _loadLevel4(); // Working Memory Challenge
        break;
      case 4:
        _loadLevel5(); // Executive Function Master
        break;
    }
  }

  // Level 1: Visual Pattern Memory
  void _loadLevel1() {
    _cognitiveSkillsUsed['visual_memory'] = (_cognitiveSkillsUsed['visual_memory'] ?? 0) + 1;
    
    // Create a pattern to memorize
    List<String> shapes = ['circle', 'square', 'triangle', 'star'];
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
    
    for (int i = 0; i < 4; i++) {
      targetPattern.add(CognitiveElement(
        id: 'target_$i',
        type: 'shape',
        value: shapes[i],
        color: colors[i],
        size: 60,
        position: Offset(100 + (i * 80), 200),
      ));
    }

    // Create selectable elements (more than needed)
    for (int i = 0; i < 6; i++) {
      gameElements.add(CognitiveElement(
        id: 'element_$i',
        type: 'shape',
        value: shapes[i % shapes.length],
        color: colors[i % colors.length],
        size: 50,
        position: Offset(80 + (i * 60), 350),
      ));
    }

    // Memory flash obstacle with 1-minute total time
    activeObstacles.add(GameObstacle(
      type: 'memory_flash',
      properties: {
        'flashDuration': 3000, // 3 seconds to memorize
        'instructions': 'Memorize the pattern above!'
      },
    ));

    _startMemoryPhase();
    // Start 1-minute timer after memory phase
    Timer(const Duration(seconds: 3), () {
      _startTimerChallenge(60); // 1 minute for gameplay
    });
  }

  // Level 2: Sequence Recognition with Timer
  void _loadLevel2() {
    _cognitiveSkillsUsed['sequence_recognition'] = (_cognitiveSkillsUsed['sequence_recognition'] ?? 0) + 1;
    _cognitiveSkillsUsed['time_pressure'] = (_cognitiveSkillsUsed['time_pressure'] ?? 0) + 1;

    List<String> numbers = ['1', '2', '3', '4', '5'];
    sequenceToRemember = [numbers[0], numbers[2], numbers[1], numbers[4], numbers[3]]; // 1,3,2,5,4

    for (int i = 0; i < numbers.length; i++) {
      gameElements.add(CognitiveElement(
        id: 'num_$i',
        type: 'number',
        value: numbers[i],
        color: Colors.deepPurple,
        size: 50,
        position: Offset(70 + (i * 60), 350),
      ));
    }

    activeObstacles.add(GameObstacle(
      type: 'timer',
      properties: {
        'timeLimit': 60, // 1 minute
        'instructions': 'Tap numbers in this order: 1, 3, 2, 5, 4'
      },
    ));

    _startTimerChallenge(60); // 1 minute
    setState(() {
      gameActive = true;
    });
  }

  // Level 3: Multi-Modal Pattern with Distractors
  void _loadLevel3() {
    _cognitiveSkillsUsed['attention_focus'] = (_cognitiveSkillsUsed['attention_focus'] ?? 0) + 1;
    _cognitiveSkillsUsed['pattern_recognition'] = (_cognitiveSkillsUsed['pattern_recognition'] ?? 0) + 1;

    // Target: All red shapes
    List<String> shapes = ['circle', 'square', 'triangle'];
    
    for (int i = 0; i < 3; i++) {
      targetPattern.add(CognitiveElement(
        id: 'target_$i',
        type: 'shape',
        value: shapes[i],
        color: Colors.red,
        size: 50,
        position: Offset(150 + (i * 70), 180),
      ));
    }

    // Mixed elements with distractors
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.orange];
    Random random = Random();
    
    for (int i = 0; i < 9; i++) {
      bool isRedShape = i < 3; // First 3 are red target shapes
      gameElements.add(CognitiveElement(
        id: 'element_$i',
        type: 'shape',
        value: shapes[i % 3],
        color: isRedShape ? Colors.red : colors[random.nextInt(colors.length - 1) + 1], // Avoid red for distractors
        size: 45,
        position: Offset(60 + (i % 3) * 80, 320 + (i ~/ 3) * 70),
        isObstacle: !isRedShape,
      ));
    }

    activeObstacles.add(GameObstacle(
      type: 'distractor',
      properties: {
        'instructions': 'Find and tap only the RED shapes that match the pattern above!',
        'distractorCount': gameElements.where((e) => e.isObstacle).length,
        'timeLimit': 60, // 1 minute
      },
    ));

    _startTimerChallenge(60); // 1 minute
    setState(() {
      gameActive = true;
    });
  }

  // Level 4: Working Memory Challenge
  void _loadLevel4() {
    _cognitiveSkillsUsed['working_memory'] = (_cognitiveSkillsUsed['working_memory'] ?? 0) + 1;
    _cognitiveSkillsUsed['cognitive_flexibility'] = (_cognitiveSkillsUsed['cognitive_flexibility'] ?? 0) + 1;

    List<String> letters = ['A', 'B', 'C', 'D', 'E', 'F'];
    sequenceToRemember = ['B', 'D', 'A', 'F', 'C']; // Non-alphabetical order

    for (int i = 0; i < 6; i++) {
      gameElements.add(CognitiveElement(
        id: 'letter_$i',
        type: 'letter',
        value: letters[i],
        color: Colors.indigo,
        size: 50,
        position: Offset(50 + (i % 3) * 100, 300 + (i ~/ 3) * 80),
      ));
    }

    activeObstacles.add(GameObstacle(
      type: 'sequence',
      properties: {
        'sequence': sequenceToRemember,
        'instructions': 'Remember: B → D → A → F → C. Tap in this order!',
        'memoryTime': 4000,
        'timeLimit': 60, // 1 minute after memory phase
      },
    ));

    _startSequenceMemoryPhase();
    // Start 1-minute timer after memory phase
    Timer(const Duration(seconds: 4), () {
      _startTimerChallenge(60); // 1 minute for gameplay
    });
  }

  // Level 5: Executive Function Master
  void _loadLevel5() {
    _cognitiveSkillsUsed['executive_function'] = (_cognitiveSkillsUsed['executive_function'] ?? 0) + 1;
    _cognitiveSkillsUsed['inhibitory_control'] = (_cognitiveSkillsUsed['inhibitory_control'] ?? 0) + 1;

    // Complex multi-step challenge
    List<Map<String, dynamic>> tasks = [
      {'type': 'shape', 'value': 'circle', 'color': Colors.blue, 'rule': 'tap'},
      {'type': 'number', 'value': '3', 'color': Colors.red, 'rule': 'avoid'},
      {'type': 'shape', 'value': 'square', 'color': Colors.green, 'rule': 'tap'},
      {'type': 'letter', 'value': 'X', 'color': Colors.purple, 'rule': 'avoid'},
    ];

    Random random = Random();
    for (int i = 0; i < 12; i++) {
      var task = tasks[random.nextInt(tasks.length)];
      gameElements.add(CognitiveElement(
        id: 'complex_$i',
        type: task['type'],
        value: task['value'],
        color: task['color'],
        size: 45,
        position: Offset(60 + (i % 4) * 70, 280 + (i ~/ 4) * 70),
        isObstacle: task['rule'] == 'avoid',
      ));
    }

    activeObstacles.add(GameObstacle(
      type: 'executive',
      properties: {
        'instructions': 'TAP: Blue circles & Green squares. AVOID: Red 3s & Purple Xs',
        'timeLimit': 60, // 1 minute
        'penaltyForMistakes': true,
      },
    ));

    _startTimerChallenge(60); // 1 minute
    setState(() {
      gameActive = true;
    });
  }

  void _startMemoryPhase() {
    setState(() {
      memoryPhase = true;
      gameActive = false;
    });

    _memoryFlashTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        targetPattern.forEach((element) => element.isVisible = false);
        memoryPhase = false;
        gameActive = true;
      });
    });
  }

  void _startSequenceMemoryPhase() {
    setState(() {
      memoryPhase = true;
      gameActive = false;
    });

    _memoryFlashTimer = Timer(const Duration(seconds: 4), () {
      setState(() {
        memoryPhase = false;
        gameActive = true;
      });
    });
  }

  void _startTimerChallenge(int seconds) {
    timeRemaining = seconds;
    _timerController.duration = Duration(seconds: seconds);
    _timerController.forward();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeRemaining--;
      });

      if (timeRemaining <= 0) {
        timer.cancel();
        _handleTimeUp();
      }
    });
  }

  void _handleTimeUp() {
    setState(() {
      gameActive = false;
    });
    
    // Check if level was completed in time
    if (_checkLevelCompletion()) {
      _showSuccess();
    } else {
      _showTimeUpMessage();
    }
  }

  void _onElementTapped(CognitiveElement element) {
    if (!gameActive) return;
    
    // Trigger bounce animation
    setState(() {
      element.animationScale = 1.3; // Scale up
    });
    
    // Return to normal scale after animation
    Timer(const Duration(milliseconds: 150), () {
      setState(() {
        element.animationScale = 1.0;
      });
    });
    
    _totalAttempts++;

    switch (currentLevel) {
      case 0:
        _handleLevel1Tap(element);
        break;
      case 1:
        _handleLevel2Tap(element);
        break;
      case 2:
        _handleLevel3Tap(element);
        break;
      case 3:
        _handleLevel4Tap(element);
        break;
      case 4:
        _handleLevel5Tap(element);
        break;
    }
  }

  void _handleLevel1Tap(CognitiveElement element) {
    // Add bounce animation to the tapped element
    setState(() {
      element.animationScale = 0.8;
    });
    Timer(const Duration(milliseconds: 100), () {
      setState(() {
        element.animationScale = 1.2;
      });
    });
    Timer(const Duration(milliseconds: 200), () {
      setState(() {
        element.animationScale = 1.0;
      });
    });
    
    // Check if tapped element EXACTLY matches target pattern (both shape and color)
    bool isCorrect = false;
    CognitiveElement? matchedTarget;
    
    for (var target in targetPattern) {
      if (target.value == element.value && target.color == element.color && !target.isMatched) {
        isCorrect = true;
        matchedTarget = target;
        break;
      }
    }
    
    if (isCorrect && !element.isMatched && matchedTarget != null) {
      setState(() {
        element.isMatched = true;
        matchedTarget!.isMatched = true; // Mark target as matched too
      });
      _correctMatches++;
      _showPositiveFeedback();
    } else if (!isCorrect) {
      // Show negative feedback for wrong selection
      _showNegativeFeedback();
    }

    if (_checkLevelCompletion()) {
      _showSuccess();
    }
  }

  void _handleLevel2Tap(CognitiveElement element) {
    // Add bounce animation to the tapped element
    setState(() {
      element.animationScale = 0.8;
    });
    Timer(const Duration(milliseconds: 100), () {
      setState(() {
        element.animationScale = 1.2;
      });
    });
    Timer(const Duration(milliseconds: 200), () {
      setState(() {
        element.animationScale = 1.0;
      });
    });
    
    if (userSequence.length < sequenceToRemember.length && !element.isMatched) {
      // Check if this is the correct next number in sequence
      String expectedNext = sequenceToRemember[userSequence.length];
      
      if (element.value == expectedNext) {
        userSequence.add(element.value);
        setState(() {
          element.isMatched = true;
        });
        _showPositiveFeedback();
        
        // Check if sequence is complete
        if (userSequence.length == sequenceToRemember.length) {
          _correctMatches++;
          _showSuccess();
        }
      } else {
        // Wrong number in sequence - reset
        _showNegativeFeedback();
        _showIncorrectSequence();
      }
    }
  }

  void _handleLevel3Tap(CognitiveElement element) {
    // Only process red shapes that haven't been matched yet
    if (element.color == Colors.red && !element.isMatched) {
      // Check if this red shape exactly matches one of the target patterns
      bool matchesPattern = false;
      CognitiveElement? matchedTarget;
      
      for (var target in targetPattern) {
        if (target.value == element.value && target.color == Colors.red && !target.isMatched) {
          matchesPattern = true;
          matchedTarget = target;
          break;
        }
      }
      
      if (matchesPattern && matchedTarget != null) {
        setState(() {
          element.isMatched = true;
          matchedTarget!.isMatched = true;
        });
        _correctMatches++;
        _showPositiveFeedback();
      } else {
        _showNegativeFeedback();
      }
    } else if (element.color != Colors.red || element.isObstacle) {
      // Penalty for tapping non-red shapes or distractors
      _totalAttempts += 2; // Double penalty
      _showNegativeFeedback();
      timeRemaining = max(0, timeRemaining - 2); // Time penalty
    }

    if (_checkLevelCompletion()) {
      _showSuccess();
    }
  }

  void _handleLevel4Tap(CognitiveElement element) {
    if (userSequence.length < sequenceToRemember.length && !element.isMatched) {
      // Check if this is the correct next letter in sequence
      String expectedNext = sequenceToRemember[userSequence.length];
      
      if (element.value == expectedNext) {
        userSequence.add(element.value);
        setState(() {
          element.isMatched = true;
        });
        _showPositiveFeedback();
        
        // Check if sequence is complete
        if (userSequence.length == sequenceToRemember.length) {
          _correctMatches++;
          _showSuccess();
        }
      } else {
        // Wrong letter in sequence - reset
        _showNegativeFeedback();
        _showIncorrectSequence();
      }
    }
  }

  void _handleLevel5Tap(CognitiveElement element) {
    bool shouldTap = (element.type == 'shape' && element.value == 'circle' && element.color == Colors.blue) ||
                     (element.type == 'shape' && element.value == 'square' && element.color == Colors.green);
    
    bool shouldAvoid = (element.type == 'number' && element.value == '3' && element.color == Colors.red) ||
                       (element.type == 'letter' && element.value == 'X' && element.color == Colors.purple);

    if (shouldTap && !element.isMatched) {
      setState(() {
        element.isMatched = true;
      });
      _correctMatches++;
      _showPositiveFeedback();
    } else if (shouldAvoid) {
      // Penalty for tapping items that should be avoided
      _totalAttempts += 3;
      timeRemaining = max(0, timeRemaining - 3); // Time penalty
      _showNegativeFeedback();
    } else if (!shouldTap && !shouldAvoid) {
      // Tapped something that's neither correct nor forbidden
      _showNegativeFeedback();
    }

    if (_checkLevelCompletion()) {
      _showSuccess();
    }
  }

  bool _checkLevelCompletion() {
    switch (currentLevel) {
      case 0: // Level 1: All target patterns must be matched
        return targetPattern.every((target) => target.isMatched);
      case 1: // Level 2: Correct sequence completion
        return userSequence.length == sequenceToRemember.length &&
               _listsEqual(userSequence, sequenceToRemember);
      case 2: // Level 3: All red target shapes must be matched
        return targetPattern.every((target) => target.isMatched);
      case 3: // Level 4: Correct sequence completion
        return userSequence.length == sequenceToRemember.length &&
               _listsEqual(userSequence, sequenceToRemember);
      case 4: // Level 5: All correct elements tapped, no penalties from wrong taps
        int correctTargets = gameElements.where((e) => 
            !e.isObstacle && 
            ((e.type == 'shape' && e.value == 'circle' && e.color == Colors.blue) ||
             (e.type == 'shape' && e.value == 'square' && e.color == Colors.green))).length;
        int matchedCorrect = gameElements.where((e) => 
            e.isMatched && !e.isObstacle &&
            ((e.type == 'shape' && e.value == 'circle' && e.color == Colors.blue) ||
             (e.type == 'shape' && e.value == 'square' && e.color == Colors.green))).length;
        return matchedCorrect >= correctTargets;
      default:
        return false;
    }
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _showPositiveFeedback() {
    List<String> encouragingMessages = [
      "🌟 Great job!",
      "✨ Awesome!",
      "🎉 Well done!",
      "⭐ Fantastic!",
      "🚀 Amazing!",
      "🏆 Super!",
      "💫 Excellent!",
      "🎊 Brilliant!",
    ];
    
    String message = encouragingMessages[Random().nextInt(encouragingMessages.length)];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showNegativeFeedback() {
    List<String> encouragingMessages = [
      "🤔 Try again!",
      "💪 Keep trying!",
      "🎯 Look closer!",
      "🧐 Not quite!",
      "🔍 Check again!",
      "👀 Look carefully!",
    ];
    
    String message = encouragingMessages[Random().nextInt(encouragingMessages.length)];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade400,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showSuccess() {
    setState(() {
      showSuccess = true;
      gameActive = false;
    });

    _gameTimer?.cancel();
    _levelsCompleted++;
    _successController.forward();

    Future.delayed(const Duration(seconds: 2), () {
      _successController.reverse();
      if (currentLevel < 4) {
        setState(() {
          currentLevel++;
        });
        _saveCurrentLevel();
        _loadLevel();
      } else {
        _saveGameSession();
        _resetGameProgress();
        _showGameComplete();
      }
    });
  }

  void _showIncorrectSequence() {
    setState(() {
      userSequence.clear();
      gameElements.forEach((element) => element.isMatched = false);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Incorrect sequence! Try again.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showTimeUpMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time\'s up! Try again.'),
        backgroundColor: Colors.red,
      ),
    );
    
    Future.delayed(const Duration(seconds: 1), () {
      _loadLevel(); // Restart level
    });
  }

  Future<void> _saveCurrentLevel() async {
    try {
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_master',
        level: currentLevel + 1,
        score: _correctMatches * 20 + _levelsCompleted * 100,
        completed: false,
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'totalAttempts': _totalAttempts,
          'correctMatches': _correctMatches,
          'cognitiveSkillsUsed': _cognitiveSkillsUsed,
          'levelAdvancement': true,
        },
      );
    } catch (e) {
      print('Error saving current level: $e');
    }
  }

  Future<void> _saveGameSession() async {
    try {
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_master',
        level: currentLevel + 1,
        score: _correctMatches * 20 + _levelsCompleted * 100,
        completed: currentLevel >= 4,
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'cognitiveSkillsUsed': _cognitiveSkillsUsed,
          'levelsCompleted': _levelsCompleted,
          'totalAttempts': _totalAttempts,
          'correctMatches': _correctMatches,
          'accuracy': _totalAttempts > 0 ? _correctMatches / _totalAttempts : 0.0,
          'sessionStart': _sessionStart.toIso8601String(),
        },
      );
      print('Pattern Master session saved successfully');
    } catch (e) {
      print('Error saving Pattern Master session: $e');
    }
  }

  Future<void> _resetGameProgress() async {
    try {
      await GameDataService.saveGameSessionAndProgress(
        gameType: 'pattern_master',
        level: 1,
        score: _correctMatches * 20 + _levelsCompleted * 100,
        completed: true,
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'gameCompleted': true,
          'completedAt': DateTime.now().toIso8601String(),
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
              Icon(Icons.psychology, color: Colors.purple, size: 30),
              SizedBox(width: 10),
              Text('Pattern Master!'),
            ],
          ),
          content: Text(
            'Amazing work! You\'ve completed all 5 pattern challenges!\n\n'
            'Skills developed:\n'
            '• Visual Memory\n'
            '• Sequence Recognition\n'
            '• Attention & Focus\n'
            '• Working Memory\n'
            '• Executive Function'
          ),
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

  String _getLevelTitle() {
    switch (currentLevel) {
      case 0:
        return "Visual Pattern Memory";
      case 1:
        return "Sequence Recognition";
      case 2:
        return "Attention & Focus";
      case 3:
        return "Working Memory";
      case 4:
        return "Executive Function";
      default:
        return "Cognitive Challenge";
    }
  }

  String _getCurrentInstruction() {
    for (var obstacle in activeObstacles) {
      if (obstacle.properties.containsKey('instructions')) {
        return obstacle.properties['instructions'];
      }
    }
    return "Follow the pattern!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE082), // Bright sunny yellow
              Color(0xFFFFB74D), // Warm orange
              Color(0xFF81C784), // Fresh green
              Color(0xFF64B5F6), // Sky blue
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
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
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.orange.shade700, size: 28),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Level ${currentLevel + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLevelTitle(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (timeRemaining > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: timeRemaining <= 5 
                                  ? [Colors.red.shade400, Colors.red.shade600]
                                  : [Colors.green.shade400, Colors.green.shade600],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (timeRemaining <= 5 ? Colors.red : Colors.green).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  '$timeRemaining',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _loadLevel,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(Icons.refresh, color: Colors.blue.shade600, size: 24),
                          ),
                        ),
                      ],
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
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.cyan.shade50, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(Icons.lightbulb, color: Colors.orange.shade600, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getCurrentInstruction(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            if (memoryPhase)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '👀 Remember the pattern!',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Game Area
                      Expanded(
                        child: Stack(
                          children: [
                            // Target Pattern (for memory phases)
                            if (currentLevel == 0 || currentLevel == 2)
                              ...targetPattern.map((element) => Positioned(
                                left: element.position.dx - element.size / 2,
                                top: element.position.dy - element.size / 2,
                                child: AnimatedOpacity(
                                  opacity: element.isVisible ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    width: element.size,
                                    height: element.size,
                                    child: CustomPaint(
                                      painter: CognitiveElementPainter(
                                        element: element,
                                        isTarget: true,
                                      ),
                                    ),
                                  ),
                                ),
                              )),

                            // Interactive Game Elements
                            ...gameElements.map((element) => Positioned(
                              left: element.position.dx - (element.size * element.animationScale) / 2,
                              top: element.position.dy - (element.size * element.animationScale) / 2,
                              child: GestureDetector(
                                onTap: () => _onElementTapped(element),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.bounceOut, // Bouncy animation
                                  transform: Matrix4.identity()..scale(element.animationScale),
                                  width: element.size * 1.2, // Make elements bigger
                                  height: element.size * 1.2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15), // More rounded for child-friendly look
                                    border: element.isMatched
                                        ? Border.all(color: Colors.green.shade400, width: 4)
                                        : element.isObstacle
                                            ? Border.all(color: Colors.red.shade300, width: 3)
                                            : Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                    boxShadow: element.isMatched
                                        ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)]
                                        : [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                                  ),
                                  child: CustomPaint(
                                    painter: CognitiveElementPainter(
                                      element: element,
                                      isTarget: false,
                                    ),
                                  ),
                                ),
                              ),
                            )),

                            // Success Animation
                            if (showSuccess)
                              Center(
                                child: AnimatedBuilder(
                                  animation: _successAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _successAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade400,
                                              Colors.pink.shade400,
                                              Colors.orange.shade400,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(25),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withOpacity(0.4),
                                              blurRadius: 25,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.yellow.shade300,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.star,
                                                color: Colors.orange,
                                                size: 60,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const Text(
                                              '🎉 Awesome! 🎉',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'You did great!',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
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

class CognitiveElementPainter extends CustomPainter {
  final CognitiveElement element;
  final bool isTarget;

  CognitiveElementPainter({
    required this.element,
    required this.isTarget,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = element.color
      ..style = isTarget ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = isTarget ? 4 : 2; // Thicker strokes for better visibility
    
    // Add shadow effect for depth
    Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double radius = min(size.width, size.height) / 2 - 8; // Bigger radius for larger shapes
    
    // Draw shadow first (offset slightly)
    double shadowOffset = 3;
    shadowPaint.color = Colors.black.withOpacity(0.15);

    switch (element.type) {
      case 'shape':
        // Draw shadow first
        _drawShape(canvas, shadowPaint, centerX + shadowOffset, centerY + shadowOffset, radius);
        // Then draw the actual shape
        _drawShape(canvas, paint, centerX, centerY, radius);
        break;
      case 'number':
      case 'letter':
        _drawText(canvas, centerX, centerY);
        break;
    }
  }

  void _drawShape(Canvas canvas, Paint paint, double centerX, double centerY, double radius) {
    switch (element.value) {
      case 'circle':
        canvas.drawCircle(Offset(centerX, centerY), radius * 0.9, paint); // Slightly bigger
        break;
      case 'square':
        // Make squares with rounded corners for child-friendly look
        RRect roundedRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX, centerY),
            width: radius * 1.8, // Bigger squares
            height: radius * 1.8,
          ),
          const Radius.circular(8), // Rounded corners
        );
        canvas.drawRRect(roundedRect, paint);
        break;
      case 'triangle':
        Path path = Path();
        path.moveTo(centerX, centerY - radius * 0.9);
        path.lineTo(centerX - radius * 0.9 * 0.866, centerY + radius * 0.9 * 0.5);
        path.lineTo(centerX + radius * 0.9 * 0.866, centerY + radius * 0.9 * 0.5);
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 'star':
        Path starPath = _createStarPath(centerX, centerY, radius);
        canvas.drawPath(starPath, paint);
        break;
    }
  }

  void _drawText(Canvas canvas, double centerX, double centerY) {
    // Draw text shadow first
    TextPainter shadowPainter = TextPainter(
      text: TextSpan(
        text: element.value,
        style: TextStyle(
          color: Colors.black.withOpacity(0.3),
          fontSize: element.size * 0.8, // Bigger text
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    shadowPainter.layout();
    shadowPainter.paint(
      canvas,
      Offset(
        centerX - shadowPainter.width / 2 + 2,
        centerY - shadowPainter.height / 2 + 2,
      ),
    );
    
    // Draw main text
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: element.value,
        style: TextStyle(
          color: element.color,
          fontSize: element.size * 0.8, // Bigger text for better readability
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY - textPainter.height / 2,
      ),
    );
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}