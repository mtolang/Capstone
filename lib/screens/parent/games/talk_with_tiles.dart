import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

  LevelData({
    required this.prompt,
    required this.expectedLength,
    required this.hints,
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
  int gameScore = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Available tiles organized by category
  final Map<String, List<TileData>> tileCategories = {
    'actions': [
      TileData(id: 'i-want', text: 'I want', icon: '👋', color: Colors.blue),
      TileData(id: 'i-need', text: 'I need', icon: '🙋', color: Colors.blue),
      TileData(id: 'go', text: 'go', icon: '🚶', color: Colors.green),
      TileData(id: 'eat', text: 'eat', icon: '🍽️', color: Colors.green),
      TileData(id: 'play', text: 'play', icon: '🎮', color: Colors.green),
      TileData(id: 'help', text: 'help', icon: '🤝', color: Colors.green),
    ],
    'objects': [
      TileData(id: 'juice', text: 'juice', icon: '🧃', color: Colors.orange),
      TileData(id: 'ball', text: 'ball', icon: '⚽', color: Colors.orange),
      TileData(id: 'toy', text: 'toy', icon: '🧸', color: Colors.orange),
      TileData(id: 'book', text: 'book', icon: '📚', color: Colors.orange),
      TileData(id: 'water', text: 'water', icon: '💧', color: Colors.orange),
      TileData(id: 'food', text: 'food', icon: '🍎', color: Colors.orange),
    ],
    'places': [
      TileData(
          id: 'outside', text: 'outside', icon: '🌳', color: Colors.purple),
      TileData(id: 'home', text: 'home', icon: '🏠', color: Colors.purple),
      TileData(id: 'park', text: 'park', icon: '🏞️', color: Colors.purple),
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
    ),
    2: LevelData(
      prompt: "Ask for your favorite toy",
      expectedLength: 2,
      hints: ["How do you ask for something?", "What toy do you want?"],
    ),
    3: LevelData(
      prompt: "Tell someone where you want to go",
      expectedLength: 3,
      hints: ["Start with 'I want'", "Add 'go'", "Pick a place"],
    ),
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  void handleTileClick(TileData tile) {
    if (selectedTiles.length < (currentLevel <= 2 ? 2 : 3)) {
      setState(() {
        selectedTiles.add(tile);
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  void speakSentence() async {
    if (selectedTiles.isEmpty) return;

    String sentence = selectedTiles.map((tile) => tile.text).join(' ');
    await flutterTts.speak(sentence);

    // Show success if sentence is complete for the level
    if (selectedTiles.length >= levelData[currentLevel]!.expectedLength) {
      setState(() {
        showSuccess = true;
        gameScore += 10;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          showSuccess = false;
          if (currentLevel < 3) {
            currentLevel++;
            selectedTiles.clear();
          }
        });
      });
    }
  }

  void clearSentence() {
    setState(() {
      selectedTiles.clear();
      showSuccess = false;
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
            Navigator.pop(context);
          },
        ),
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
                                      '$gameScore',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

          // Success Overlay - ✅ Fixed: Moved inside Stack
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
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          size: 32,
                          color: Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Great job!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You built a complete sentence!',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
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
