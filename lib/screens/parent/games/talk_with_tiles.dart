import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../services/game_data_service.dart';

class TileData {
  final String id;
  final String text;
  final String icon;
  final Color color;

  TileData({
    required this.id,
    required this.text,
    required this.icon,
    required this.color,
  });
}

class LevelData {
  final String prompt;
  final int expectedLength;
  final List<String> hints;
  final List<List<String>>
      acceptedPatterns; // Patterns that are considered correct
  final int maxStars;

  LevelData({
    required this.prompt,
    required this.expectedLength,
    required this.hints,
    required this.acceptedPatterns,
    this.maxStars = 5,
  });
}

class TalkWithTilesGame extends StatefulWidget {
  const TalkWithTilesGame({super.key});

  @override
  _TalkWithTilesGameState createState() => _TalkWithTilesGameState();
}

class _TalkWithTilesGameState extends State<TalkWithTilesGame>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  List<TileData> selectedTiles = [];
  int currentLevel = 1;
  bool showSuccess = false;
  bool showEncouragement = false;
  int gameScore = 0;
  int currentLevelStars = 0;
  int totalStars = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Firebase tracking variables
  DateTime _sessionStart = DateTime.now();
  int _tilesUsed = 0;
  int _sentencesFormed = 0;
  int _levelsCompleted = 0;
  Map<String, int> _categoryUsage = {};

  // Save debouncing to prevent multiple documents
  Timer? _saveTimer;
  bool _hasPendingSave = false;

  // Available tiles organized by category
  final Map<String, List<TileData>> tileCategories = {
    'actions': [
      TileData(id: 'i-want', text: 'I want', icon: '👋', color: Colors.blue),
      TileData(id: 'i-need', text: 'I need', icon: '🙋', color: Colors.blue),
      TileData(id: 'i-like', text: 'I like', icon: '❤️', color: Colors.blue),
      TileData(id: 'i-see', text: 'I see', icon: '👀', color: Colors.blue),
      TileData(id: 'go', text: 'go', icon: '🚶', color: Colors.green),
      TileData(id: 'eat', text: 'eat', icon: '🍽️', color: Colors.green),
      TileData(id: 'play', text: 'play', icon: '🎮', color: Colors.green),
      TileData(id: 'help', text: 'help', icon: '🤝', color: Colors.green),
      TileData(id: 'give', text: 'give', icon: '🤲', color: Colors.green),
      TileData(id: 'take', text: 'take', icon: '✋', color: Colors.green),
      TileData(id: 'stop', text: 'stop', icon: '✋', color: Colors.red),
      TileData(id: 'come', text: 'come', icon: '👋', color: Colors.green),
    ],
    'objects': [
      TileData(id: 'juice', text: 'juice', icon: '🧃', color: Colors.orange),
      TileData(id: 'ball', text: 'ball', icon: '⚽', color: Colors.orange),
      TileData(id: 'toy', text: 'toy', icon: '🧸', color: Colors.orange),
      TileData(id: 'book', text: 'book', icon: '📚', color: Colors.orange),
      TileData(id: 'water', text: 'water', icon: '💧', color: Colors.orange),
      TileData(id: 'food', text: 'food', icon: '🍎', color: Colors.orange),
      TileData(id: 'cookie', text: 'cookie', icon: '🍪', color: Colors.orange),
      TileData(id: 'milk', text: 'milk', icon: '🥛', color: Colors.orange),
      TileData(id: 'banana', text: 'banana', icon: '🍌', color: Colors.orange),
      TileData(id: 'car', text: 'car', icon: '🚗', color: Colors.orange),
      TileData(id: 'phone', text: 'phone', icon: '📱', color: Colors.orange),
      TileData(id: 'shoes', text: 'shoes', icon: '👟', color: Colors.orange),
    ],
    'places': [
      TileData(
          id: 'outside', text: 'outside', icon: '🌳', color: Colors.purple),
      TileData(id: 'home', text: 'home', icon: '🏠', color: Colors.purple),
      TileData(id: 'park', text: 'park', icon: '🏞️', color: Colors.purple),
      TileData(id: 'store', text: 'store', icon: '🏪', color: Colors.purple),
      TileData(id: 'school', text: 'school', icon: '🏫', color: Colors.purple),
      TileData(
          id: 'kitchen', text: 'kitchen', icon: '🍳', color: Colors.purple),
    ],
    'people': [
      TileData(id: 'mama', text: 'mama', icon: '👩', color: Colors.pink),
      TileData(id: 'papa', text: 'papa', icon: '👨', color: Colors.pink),
      TileData(
          id: 'teacher', text: 'teacher', icon: '👩‍🏫', color: Colors.pink),
      TileData(id: 'friend', text: 'friend', icon: '👫', color: Colors.pink),
      TileData(id: 'doctor', text: 'doctor', icon: '👩‍⚕️', color: Colors.pink),
    ],
    'feelings': [
      TileData(id: 'happy', text: 'happy', icon: '😊', color: Colors.yellow),
      TileData(id: 'sad', text: 'sad', icon: '😢', color: Colors.yellow),
      TileData(id: 'tired', text: 'tired', icon: '😴', color: Colors.yellow),
      TileData(id: 'hungry', text: 'hungry', icon: '😋', color: Colors.yellow),
      TileData(id: 'good', text: 'good', icon: '👍', color: Colors.yellow),
      TileData(id: 'bad', text: 'bad', icon: '👎', color: Colors.yellow),
    ],
  };

  // Level-based prompts and expected answers
  final Map<int, LevelData> levelData = {
    1: LevelData(
      prompt: "Tell Hugo what you want",
      expectedLength: 2,
      hints: [
        "Start with 'I want' or 'I need'",
        "Then pick something you want"
      ],
      acceptedPatterns: [
        ['I want', '*'],
        ['I need', '*'],
        ['I like', '*'],
      ],
    ),
    2: LevelData(
      prompt: "Ask for your favorite toy",
      expectedLength: 2,
      hints: ["How do you ask for something?", "What toy do you want?"],
      acceptedPatterns: [
        ['I want', 'toy'],
        ['I need', 'toy'],
        ['I want', 'ball'],
        ['I like', 'toy'],
      ],
    ),
    3: LevelData(
      prompt: "Tell someone where you want to go",
      expectedLength: 3,
      hints: ["Start with 'I want'", "Add 'go'", "Pick a place"],
      acceptedPatterns: [
        ['I want', 'go', '*'],
        ['I need', 'go', '*'],
      ],
    ),
    4: LevelData(
      prompt: "Tell mama how you feel",
      expectedLength: 3,
      hints: ["Start with 'I'", "Say how you feel", "Who are you talking to?"],
      acceptedPatterns: [
        ['I', '*', 'mama'],
        ['mama', 'I', '*'],
      ],
    ),
    5: LevelData(
      prompt: "Ask for help with something",
      expectedLength: 3,
      hints: [
        "Ask for help",
        "What do you need help with?",
        "Who can help you?"
      ],
      acceptedPatterns: [
        ['I need', 'help', '*'],
        ['help', '*', '*'],
        ['*', 'help', '*'],
      ],
    ),
    6: LevelData(
      prompt: "Tell someone what you see",
      expectedLength: 3,
      hints: ["Start with 'I see'", "What do you see?", "Where do you see it?"],
      acceptedPatterns: [
        ['I see', '*', '*'],
        ['I see', '*', 'outside'],
        ['I see', '*', 'home'],
      ],
    ),
    7: LevelData(
      prompt: "Ask someone to come with you",
      expectedLength: 4,
      hints: [
        "Who do you want?",
        "What do you want them to do?",
        "Where do you want to go?"
      ],
      acceptedPatterns: [
        ['*', 'come', '*', '*'],
        ['I want', '*', 'come', '*'],
      ],
    ),
    8: LevelData(
      prompt: "Tell what you want to eat and where",
      expectedLength: 4,
      hints: ["What do you want?", "What action?", "What food?", "Where?"],
      acceptedPatterns: [
        ['I want', 'eat', '*', '*'],
        ['I need', 'eat', '*', '*'],
        ['eat', '*', '*', '*'],
      ],
    ),
    9: LevelData(
      prompt: "Describe how you feel about something",
      expectedLength: 4,
      hints: ["How do you feel?", "About what?", "Be specific!"],
      acceptedPatterns: [
        ['I', '*', '*', '*'],
        ['*', '*', '*', 'good'],
        ['*', '*', '*', 'bad'],
      ],
    ),
    10: LevelData(
      prompt: "Make a complete request with please",
      expectedLength: 5,
      hints: ["Be polite!", "What do you want?", "From whom?", "Add 'please'!"],
      acceptedPatterns: [
        [
          '*',
          '*',
          '*',
          '*',
          '*'
        ], // Any 5-word sentence is considered good effort
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _newSession();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeGame();
  }

  /// Initialize game by loading saved progress
  Future<void> _initializeGame() async {
    try {
      // Load saved progress from unified user progress
      final userProgress = await GameDataService.getUserGameProgress();
      final savedLevel = userProgress.getCurrentLevel('talk_with_tiles');

      // Load saved stars from the most recent session
      final savedStars = await _loadSavedStars();

      setState(() {
        currentLevel = savedLevel;
        totalStars = savedStars;
      });
      print(
          'Talk with Tiles: Starting at level $savedLevel with $savedStars total stars');
    } catch (e) {
      print('Error loading saved level: $e');
      setState(() {
        currentLevel = 1; // Default to level 1
        totalStars = 0; // Default to 0 stars
      });
    }
  }

  /// Load saved stars from the database
  Future<int> _loadSavedStars() async {
    try {
      final userProgress = await GameDataService.getUserGameProgress();
      final gameProgress = userProgress.gameProgress['talk_with_tiles'];

      if (gameProgress != null && gameProgress.gameSpecificData.isNotEmpty) {
        final savedStars = gameProgress.gameSpecificData['totalStars'] as int?;
        return savedStars ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error loading saved stars: $e');
      return 0;
    }
  }

  void _newSession() {
    _sessionStart = DateTime.now();
    _tilesUsed = 0;
    _sentencesFormed = 0;
    _levelsCompleted = 0;
    _categoryUsage.clear();

    // Analyze current database state when starting new session
    _analyzeDatabaseState();
  }

  @override
  void dispose() {
    // Cancel any pending saves and do final save
    _saveTimer?.cancel();
    if (_hasPendingSave) {
      // Force immediate save on exit only
      _saveProgressNow();
    }
    _animationController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  /// Smart save method - maintains only 2 progress documents per user/game
  void _saveProgress() {
    _hasPendingSave = true;

    // Cancel existing timer if running
    _saveTimer?.cancel();

    // Set new timer - save after user stops making progress for 2 seconds
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasPendingSave) {
        _saveProgressNow();
      }
    });
  }

  /// Immediate save - uses smart database management (max 2 documents per user/game)
  Future<void> _saveProgressNow() async {
    if (!_hasPendingSave) return;

    try {
      _hasPendingSave = false;

      // Use the new smart saving system that maintains only 2 progress docs
      await GameDataService.saveGameProgressSmart(
        gameType: 'talk_with_tiles',
        level: currentLevel,
        score: totalStars,
        completed: currentLevel >= 10,
        sessionDuration: DateTime.now().difference(_sessionStart),
        gameSpecificData: {
          'tilesUsed': _tilesUsed,
          'sentencesFormed': _sentencesFormed,
          'levelsCompleted': _levelsCompleted,
          'categoryUsage': _categoryUsage,
          'currentLevel': currentLevel,
          'totalStars': totalStars,
          'gameScore': gameScore,
          'sessionStart': _sessionStart.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Talk with Tiles saved: Level $currentLevel, Stars $totalStars');
    } catch (e) {
      print('❌ Error saving progress: $e');
      _hasPendingSave = true; // Retry later
    }
  }

  /// Analyze current database state for this game
  Future<void> _analyzeDatabaseState() async {
    try {
      final analysis =
          await GameDataService.analyzeGameDocuments('talk_with_tiles');
      print('📊 Database Analysis for Talk with Tiles:');
      print('   Total Documents: ${analysis['totalDocuments']}');
      print('   Document IDs: ${analysis['documentIds']}');
      print('   Levels Found: ${analysis['levels']}');
      print('   Scores Found: ${analysis['scores']}');
      print('   Last Updated: ${analysis['lastUpdated']}');

      if (analysis['currentDocument'] != null) {
        final doc = analysis['currentDocument'];
        print(
            '   Current Progress: Level ${doc['level']}, Score ${doc['score']}');
      }
    } catch (e) {
      print('❌ Error analyzing database: $e');
    }
  }

  _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void handleTileClick(TileData tile) {
    if (selectedTiles.length < levelData[currentLevel]!.expectedLength) {
      setState(() {
        selectedTiles.add(tile);
        _tilesUsed++;

        // Track category usage
        String category = _getTileCategory(tile);
        _categoryUsage[category] = (_categoryUsage[category] ?? 0) + 1;
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      // Show encouragement when getting close to sentence completion
      if (selectedTiles.length == levelData[currentLevel]!.expectedLength - 1) {
        _showEncouragement();
      }
    }
  }

  String _getTileCategory(TileData tile) {
    for (String category in tileCategories.keys) {
      if (tileCategories[category]!.any((t) => t.id == tile.id)) {
        return category;
      }
    }
    return 'unknown';
  }

  void _showEncouragement() {
    setState(() {
      showEncouragement = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        showEncouragement = false;
      });
    });
  }

  bool _checkSentencePattern(List<String> sentence) {
    final patterns = levelData[currentLevel]!.acceptedPatterns;

    for (List<String> pattern in patterns) {
      if (_matchesPattern(sentence, pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesPattern(List<String> sentence, List<String> pattern) {
    if (sentence.length != pattern.length) return false;

    for (int i = 0; i < sentence.length; i++) {
      if (pattern[i] != '*' && pattern[i] != sentence[i]) {
        return false;
      }
    }
    return true;
  }

  int _calculateStars(List<String> sentence) {
    bool isCorrectPattern = _checkSentencePattern(sentence);
    bool isCorrectLength =
        sentence.length >= levelData[currentLevel]!.expectedLength;

    if (isCorrectPattern && isCorrectLength) {
      return 5; // Perfect sentence
    } else if (isCorrectLength) {
      return 3; // Good effort with correct length
    } else if (sentence.length >= levelData[currentLevel]!.expectedLength - 1) {
      return 2; // Close to correct length
    } else {
      return 1; // Participation star
    }
  }

  void speakSentence() async {
    if (selectedTiles.isEmpty) return;

    String sentence = selectedTiles.map((tile) => tile.text).join(' ');
    List<String> sentenceWords =
        selectedTiles.map((tile) => tile.text).toList();
    await flutterTts.speak(sentence);

    // Calculate stars for this attempt
    int starsEarned = _calculateStars(sentenceWords);

    setState(() {
      currentLevelStars = starsEarned;
      totalStars += starsEarned;
      gameScore += starsEarned * 2; // 2 points per star
      _sentencesFormed++;
      showSuccess = true;
    });

    // Save stars immediately (debounced)
    _saveProgress();

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        showSuccess = false;

        // Advance to next level if got 3+ stars or if this is level 10
        if (starsEarned >= 3 || currentLevel >= 10) {
          if (currentLevel < 10) {
            _levelsCompleted++;
            currentLevel++;
            selectedTiles.clear();
            currentLevelStars = 0;
            // Level progression - no immediate save, will save on next speak
          } else {
            // Game completed - no immediate save, will save on next speak
            _resetGameProgress();
          }
        } else {
          // Give another chance but clear tiles
          selectedTiles.clear();
          currentLevelStars = 0;
        }
      });
    });
  }

  /// Reset game progress after completion
  Future<void> _resetGameProgress() async {
    try {
      // Reset game state to level 1 but keep total stars
      setState(() {
        currentLevel = 1;
        currentLevelStars = 0;
        selectedTiles.clear();
        // Note: totalStars is NOT reset - they are cumulative across game completions
      });

      print(
          'Game completed! Reset to level 1, total stars preserved: $totalStars');
    } catch (e) {
      print('Error resetting game progress: $e');
    }
  }

  /// Manual reset - clears all progress including stars
  Future<void> _manualReset() async {
    // Show confirmation dialog first
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Progress'),
          content: const Text(
            'Are you sure you want to reset all progress? This will clear your level and stars.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Reset all progress
        setState(() {
          currentLevel = 1;
          currentLevelStars = 0;
          totalStars = 0;
          gameScore = 0;
          selectedTiles.clear();
          showSuccess = false;
          showEncouragement = false;
        });

        // Start new session
        _newSession();

        // Manual reset - no immediate save, will save on next speak action

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress reset successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print('Manual reset completed');
      } catch (e) {
        print('Error during manual reset: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error resetting progress. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void clearSentence() {
    setState(() {
      selectedTiles.clear();
      showSuccess = false;
      showEncouragement = false;
      currentLevelStars = 0;
    });
  }

  void removeTile(int index) {
    setState(() {
      selectedTiles.removeAt(index);
    });
  }

  Widget buildTileButton(TileData tile) {
    return GestureDetector(
      onTap: () => handleTileClick(tile),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: selectedTiles.contains(tile) ? _scaleAnimation.value : 1.0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tile.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tile.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tile.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildSelectedTile(TileData tile, int index) {
    return GestureDetector(
      onTap: () => removeTile(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: tile.color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tile.icon,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              tile.text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Talk with Tiles',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/gamesoption');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            tooltip: 'Reset Progress',
            onPressed: _manualReset,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.purple.shade50],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Talk with Tiles',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Level $currentLevel',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.yellow.shade600,
                                        size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$totalStars',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Current Level Stars Display
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Level Progress: ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                ...List.generate(5, (index) {
                                  return Icon(
                                    Icons.star,
                                    size: 20,
                                    color: index < currentLevelStars
                                        ? Colors.yellow.shade600
                                        : Colors.grey.shade300,
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Current Prompt
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child:
                                  Text('🗣️', style: TextStyle(fontSize: 40)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            levelData[currentLevel]!.prompt,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap tiles to build your sentence',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Sentence Builder Area
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Sentence:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                                minHeight:
                                    80), // ✅ Fixed: Changed min-height to minHeight
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: selectedTiles.isEmpty
                                ? Center(
                                    child: Text(
                                      'Tap tiles below to start...',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 18,
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    children: selectedTiles
                                        .asMap()
                                        .entries
                                        .map((entry) => buildSelectedTile(
                                            entry.value, entry.key))
                                        .toList(),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: selectedTiles.isEmpty
                                    ? null
                                    : speakSentence,
                                icon: const Icon(Icons.volume_up),
                                label: const Text('Speak'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: clearSentence,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Clear'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _analyzeDatabaseState,
                                icon: const Icon(Icons.analytics),
                                label: const Text('DB'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tile Categories
                    ...tileCategories.entries.map((entry) {
                      String categoryName = entry.key;
                      List<TileData> tiles = entry.value;
                      Color categoryColor = tiles.first.color;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  categoryName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: tiles.length,
                              itemBuilder: (context, index) {
                                return buildTileButton(tiles[index]);
                              },
                            ),
                          ],
                        ),
                      );
                    }),

                    // Hints
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade50,
                        border: Border(
                          left: BorderSide(
                              color: Colors.yellow.shade400, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '💡 Hints:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.yellow.shade800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...levelData[currentLevel]!
                              .hints
                              .map((hint) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $hint',
                                      style: TextStyle(
                                        color: Colors.yellow.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Success Overlay
          if (showSuccess)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: currentLevelStars >= 4
                              ? Colors.green.shade100
                              : currentLevelStars >= 2
                                  ? Colors.orange.shade100
                                  : Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentLevelStars >= 4 ? Icons.star : Icons.thumb_up,
                          size: 40,
                          color: currentLevelStars >= 4
                              ? Colors.green.shade600
                              : currentLevelStars >= 2
                                  ? Colors.orange.shade600
                                  : Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Star display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 32,
                            color: index < currentLevelStars
                                ? Colors.yellow.shade600
                                : Colors.grey.shade300,
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentLevelStars >= 4
                            ? 'Amazing! Perfect sentence!'
                            : currentLevelStars >= 3
                                ? 'Great job! Well done!'
                                : currentLevelStars >= 2
                                    ? "You're so close! Keep trying!"
                                    : 'Good try! You can do it!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentLevelStars >= 3
                            ? 'Moving to next level!'
                            : 'Try again - you\'re doing great!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Encouragement Overlay
          if (showEncouragement)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🌟',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "You're so close!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add one more tile!',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
