import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle game data storage in Firebase
class GameDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user ID from SharedPreferences
  static Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Get current user information for game context
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userType = prefs.getString('user_type');

      if (userId == null) return null;

      return {
        'userId': userId,
        'userName': userName ?? 'Unknown User',
        'userEmail': userEmail ?? '',
        'userType': userType ?? 'parent',
      };
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  /// Get or create user's unified game progress document
  static Future<UserGameProgress> getUserGameProgress() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return UserGameProgress.empty();

      final docRef = _firestore.collection('UserGameProgress').doc(userId);
      final doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        return UserGameProgress.fromMap(doc.data()!, userId);
      } else {
        // Create new progress document for user
        final newProgress = UserGameProgress.empty();
        await docRef.set(newProgress.toMap());
        return newProgress;
      }
    } catch (e) {
      print('Error getting user game progress: $e');
      return UserGameProgress.empty();
    }
  }

  /// Update user's game progress (single document per user)
  static Future<void> updateUserGameProgress(UserGameProgress progress) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      final docRef = _firestore.collection('UserGameProgress').doc(userId);
      await docRef.set(progress.toMap(), SetOptions(merge: true));

      print('User game progress updated successfully');
    } catch (e) {
      print('Error updating user game progress: $e');
    }
  }

  /// Smart save method that maintains only 2 progress documents per user/game
  /// Simplified version that doesn't require complex indexes
  static Future<void> saveGameProgressSmart({
    required String gameType,
    required int level,
    required int score,
    required bool completed,
    required Duration sessionDuration,
    Map<String, dynamic>? gameSpecificData,
  }) async {
    try {
      final userId = await getCurrentUserId();
      final userInfo = await getCurrentUserInfo();
      if (userId == null || userInfo == null) return;

      // Create unique document ID based on user and game
      final docId = '${userId}_${gameType}_progress';

      final progressData = {
        'userId': userId,
        'documentId': docId,
        'type': 'game_progress',
        'gameType': gameType,
        'gameMode': _getGameMode(gameType),
        'level': level,
        'score': score,
        'completed': completed,
        'sessionDuration': sessionDuration.inMilliseconds,
        'progress': level / _getMaxLevel(gameType),
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'gameSpecificData': {
          ...gameSpecificData ?? {},
          'playerId': userInfo['userId'],
          'playerName': userInfo['userName'],
          'playerType': userInfo['userType'],
        },
        'metadata': {
          'gameVersion': '1.0',
          'platform': 'flutter',
          'gameCategory': _getGameCategory(gameType),
        },
      };

      // Use set with merge to create or update the document
      await _firestore
          .collection('Games')
          .doc(docId)
          .set(progressData, SetOptions(merge: true));
      print(
          '📝 Updated progress document: $docId (Level $level, Score $score)');

      // Also update unified progress for overall tracking
      final currentProgress = await getUserGameProgress();
      final updatedProgress = currentProgress.updateFromSession(
        gameType: gameType,
        level: level,
        score: score,
        completed: completed,
        sessionDuration: sessionDuration,
        gameSpecificData: gameSpecificData ?? {},
      );
      await updateUserGameProgress(updatedProgress);
    } catch (e) {
      print('❌ Error in smart save: $e');
    }
  }

  /// Analyze game documents for a specific game type and user (simplified)
  static Future<Map<String, dynamic>> analyzeGameDocuments(
      String gameType) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        return {
          'error': 'No user ID found',
          'totalDocuments': 0,
          'documentIds': [],
          'levels': [],
          'scores': [],
          'lastUpdated': null,
        };
      }

      // Get the specific progress document for this user/game
      final docId = '${userId}_${gameType}_progress';
      final doc = await _firestore.collection('Games').doc(docId).get();

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalDocuments': 1,
          'documentIds': [doc.id],
          'levels': [data['level'] ?? 0],
          'scores': [data['score'] ?? 0],
          'types': [data['type'] ?? 'unknown'],
          'lastUpdated': data['timestamp'],
          'userId': userId,
          'gameType': gameType,
          'currentDocument': data,
        };
      } else {
        return {
          'totalDocuments': 0,
          'documentIds': [],
          'levels': [],
          'scores': [],
          'types': [],
          'lastUpdated': null,
          'userId': userId,
          'gameType': gameType,
        };
      }
    } catch (e) {
      print('❌ Error analyzing documents: $e');
      return {
        'error': e.toString(),
        'totalDocuments': 0,
        'documentIds': [],
        'levels': [],
        'scores': [],
        'lastUpdated': null,
      };
    }
  }

  /// Save a game session and update progress
  static Future<void> saveGameSessionAndProgress({
    required String gameType,
    required int level,
    required int score,
    required bool completed,
    required Duration sessionDuration,
    Map<String, dynamic>? gameSpecificData,
  }) async {
    try {
      final userId = await getCurrentUserId();
      final userInfo = await getCurrentUserInfo();
      if (userId == null || userInfo == null) return;

      // Get current progress
      final currentProgress = await getUserGameProgress();

      // Update progress based on game session
      final updatedProgress = currentProgress.updateFromSession(
        gameType: gameType,
        level: level,
        score: score,
        completed: completed,
        sessionDuration: sessionDuration,
        gameSpecificData: gameSpecificData ?? {},
      );

      // Save updated progress
      await updateUserGameProgress(updatedProgress);

      // Also save session data for detailed analytics
      final sessionData = GameSessionData(
        timestamp: DateTime.now(),
        gameType: gameType,
        gameMode: _getGameMode(gameType),
        level: level,
        sessionDuration: sessionDuration,
        progress: level / _getMaxLevel(gameType),
        score: score,
        completed: completed,
        gameSpecificData: {
          ...gameSpecificData ?? {},
          'playerId': userInfo['userId'],
          'playerName': userInfo['userName'],
          'playerType': userInfo['userType'],
        },
        metadata: {
          'gameVersion': '1.0',
          'platform': 'flutter',
          'gameCategory': _getGameCategory(gameType),
        },
      );

      await saveGameSession(sessionData);
    } catch (e) {
      print('Error saving game session and progress: $e');
    }
  }

  /// Save game session data to Firebase Games collection (for analytics)
  static Future<void> saveGameSession(GameSessionData sessionData) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) {
        print('No user ID found, cannot save game session');
        return;
      }

      // Save to Games collection with user ID
      final docRef = _firestore.collection('Games').doc();

      final gameData = {
        ...sessionData.toMap(),
        'userId': userId,
        'documentId': docRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(gameData);
      print('Game session saved with ID: ${docRef.id}');
    } catch (e) {
      print('Error saving game session: $e');
    }
  }

  /// Get game sessions for current user with filtering options
  static Future<List<GameSessionData>> getGameSessions({
    int limit = 50,
    String? gameType,
    String? gameMode,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return [];

      Query query =
          _firestore.collection('Games').where('userId', isEqualTo: userId);

      // Add filters if provided
      if (gameType != null) {
        query = query.where('gameType', isEqualTo: gameType);
      }

      if (gameMode != null) {
        query = query.where('gameMode', isEqualTo: gameMode);
      }

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final result =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return result.docs
          .map((doc) => GameSessionData.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching game sessions: $e');
      return [];
    }
  }

  /// Save user's current game level for specific game type
  static Future<void> saveGameLevel({
    required String gameType,
    required int level,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) return;

      final docRef = _firestore.collection('Games').doc();
      await docRef.set({
        'userId': userInfo['userId'],
        'documentId': docRef.id,
        'type': 'game_level_save',
        'gameType': gameType,
        'currentLevel': level,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalData': additionalData ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Game level saved: $gameType - Level $level');
    } catch (e) {
      print('Error saving game level: $e');
    }
  }

  /// Get user's last saved level for specific game type
  static Future<int> getGameLevel(String gameType,
      {int defaultLevel = 1}) async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) return defaultLevel;

      final query = await _firestore
          .collection('Games')
          .where('userId', isEqualTo: userInfo['userId'])
          .where('type', isEqualTo: 'game_level_save')
          .where('gameType', isEqualTo: gameType)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        final savedLevel = data['currentLevel'] as int?;
        print('Retrieved saved level for $gameType: $savedLevel');
        return savedLevel ?? defaultLevel;
      }

      return defaultLevel;
    } catch (e) {
      print('Error getting game level: $e');
      return defaultLevel;
    }
  }

  /// Get user's game progress data for specific game type
  static Future<Map<String, dynamic>?> getGameProgressData(
      String gameType) async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) return null;

      final query = await _firestore
          .collection('Games')
          .where('userId', isEqualTo: userInfo['userId'])
          .where('type', isEqualTo: 'game_level_save')
          .where('gameType', isEqualTo: gameType)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return {
          'currentLevel': data['currentLevel'],
          'additionalData': data['additionalData'] ?? {},
          'lastSaved': data['timestamp'],
        };
      }

      return null;
    } catch (e) {
      print('Error getting game progress data: $e');
      return null;
    }
  }

  /// Test database connection and user authentication
  static Future<bool> testConnection() async {
    try {
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) {
        print('❌ Test failed: No user information found');
        return false;
      }

      print(
          '✅ User authenticated: ${userInfo['userName']} (${userInfo['userId']})');

      // Test writing to Games collection
      final testDoc = _firestore.collection('Games').doc();
      await testDoc.set({
        'type': 'connection_test',
        'userId': userInfo['userId'],
        'timestamp': FieldValue.serverTimestamp(),
        'testData': {
          'message': 'Database connection test successful',
          'userName': userInfo['userName'],
        },
      });

      print('✅ Database write test successful');

      // Clean up test document
      await testDoc.delete();
      print('✅ Test document cleaned up');

      return true;
    } catch (e) {
      print('❌ Database connection test failed: $e');
      return false;
    }
  }

  /// Get leaderboard data for a specific game type
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    required String gameType,
    int limit = 10,
  }) async {
    try {
      final result = await _firestore
          .collection('Games')
          .where('gameType', isEqualTo: gameType)
          .where('completed', isEqualTo: true)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return result.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'score': data['score'],
          'level': data['level'],
          'timestamp': data['timestamp'],
          'gameSpecificData': data['gameSpecificData'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get user's game statistics
  static Future<GameStatistics> getUserStatistics() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return GameStatistics.empty();

      final sessions = await getGameSessions(limit: 100);
      return GameStatistics.fromSessions(sessions);
    } catch (e) {
      print('Error calculating statistics: $e');
      return GameStatistics.empty();
    }
  }

  /// Save user progress/achievements to Games collection with progress type
  static Future<void> saveUserProgress(UserProgress progress) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      // Save progress data to Games collection with specific type
      final docRef = _firestore.collection('Games').doc();
      await docRef.set({
        'userId': userId,
        'documentId': docRef.id,
        'type': 'user_progress',
        'timestamp': FieldValue.serverTimestamp(),
        'progressData': progress.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user progress: $e');
    }
  }

  /// Get user progress from Games collection
  static Future<UserProgress> getUserProgress() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return UserProgress.empty();

      final query = await _firestore
          .collection('Games')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'user_progress')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        return UserProgress.fromMap(
            data['progressData'] as Map<String, dynamic>);
      }
      return UserProgress.empty();
    } catch (e) {
      print('Error fetching user progress: $e');
      return UserProgress.empty();
    }
  }

  // Helper methods for game configuration
  static String _getGameMode(String gameType) {
    switch (gameType) {
      case 'shape_shifters':
        return 'drag_drop';
      case 'talk_with_tiles':
        return 'communication';
      case 'trace_and_pop_pro':
        return 'trace';
      default:
        return 'unknown';
    }
  }

  static int _getMaxLevel(String gameType) {
    switch (gameType) {
      case 'shape_shifters':
        return 5;
      case 'talk_with_tiles':
        return 3;
      case 'trace_and_pop_pro':
        return 5;
      default:
        return 1;
    }
  }

  static String _getGameCategory(String gameType) {
    switch (gameType) {
      case 'shape_shifters':
        return 'spatial';
      case 'talk_with_tiles':
        return 'communication';
      case 'trace_and_pop_pro':
        return 'motor_skills';
      default:
        return 'general';
    }
  }

  /// Clean up duplicate/old game session documents to save storage
  static Future<void> cleanupOldGameSessions({int keepLastSessions = 5}) async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      // Get all game sessions for this user, ordered by timestamp
      final sessions = await _firestore
          .collection('Games')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      if (sessions.docs.length <= keepLastSessions) {
        print(
            'No cleanup needed. Only ${sessions.docs.length} sessions found.');
        return;
      }

      // Keep only the most recent sessions, delete the rest
      final sessionsToDelete = sessions.docs.skip(keepLastSessions);
      final batch = _firestore.batch();
      int deleteCount = 0;

      for (final doc in sessionsToDelete) {
        batch.delete(doc.reference);
        deleteCount++;
      }

      await batch.commit();
      print(
          '✅ Cleaned up $deleteCount old game sessions. Kept $keepLastSessions most recent.');
    } catch (e) {
      print('Error cleaning up old sessions: $e');
    }
  }

  /// Merge duplicate progress data and keep the highest levels
  static Future<void> mergeDuplicateProgress() async {
    try {
      final userId = await getCurrentUserId();
      if (userId == null) return;

      // Get current unified progress
      final currentProgress = await getUserGameProgress();

      // Get all game sessions to extract the highest levels achieved
      final sessions = await _firestore
          .collection('Games')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      Map<String, int> highestLevels = {};
      Map<String, int> bestScores = {};
      Map<String, int> totalCompletions = {};

      // Analyze all sessions to find the best data
      for (final doc in sessions.docs) {
        final data = doc.data();
        final gameType = data['gameType'] as String?;
        final level = data['level'] as int? ?? 1;
        final score = data['score'] as int? ?? 0;
        final completed = data['completed'] as bool? ?? false;

        if (gameType != null) {
          // Track highest level
          highestLevels[gameType] = (highestLevels[gameType] ?? 1) > level
              ? highestLevels[gameType]!
              : level;

          // Track best score
          bestScores[gameType] = (bestScores[gameType] ?? 0) > score
              ? bestScores[gameType]!
              : score;

          // Count completions
          if (completed) {
            totalCompletions[gameType] = (totalCompletions[gameType] ?? 0) + 1;
          }
        }
      }

      // Update unified progress with the best data
      final updatedGameProgress = <String, GameProgress>{};

      for (final gameType in highestLevels.keys) {
        final existingProgress =
            currentProgress.gameProgress[gameType] ?? GameProgress.empty();

        updatedGameProgress[gameType] = GameProgress(
          currentLevel: highestLevels[gameType]!,
          highestLevel: highestLevels[gameType]!,
          bestScore: bestScores[gameType] ?? existingProgress.bestScore,
          totalCompletions:
              totalCompletions[gameType] ?? existingProgress.totalCompletions,
          bestTime: existingProgress.bestTime,
          totalTime: existingProgress.totalTime,
          achievements: existingProgress.achievements,
          gameSpecificData: existingProgress.gameSpecificData,
          lastPlayed: DateTime.now(),
        );
      }

      // Create updated progress with merged data
      final mergedProgress = UserGameProgress(
        userId: currentProgress.userId,
        gameProgress: {...currentProgress.gameProgress, ...updatedGameProgress},
        totalScores: {...currentProgress.totalScores, ...bestScores},
        totalSessions: currentProgress.totalSessions,
        totalPlayTime: currentProgress.totalPlayTime,
        globalAchievements: currentProgress.globalAchievements,
        lastPlayed: DateTime.now(),
        createdAt: currentProgress.createdAt,
      );

      // Save the merged progress
      await updateUserGameProgress(mergedProgress);

      print('✅ Successfully merged progress data:');
      print('   Highest levels: $highestLevels');
      print('   Best scores: $bestScores');
    } catch (e) {
      print('Error merging duplicate progress: $e');
    }
  }

  /// Complete database optimization: merge progress + cleanup old sessions
  static Future<void> optimizeUserGameData() async {
    try {
      print('🔧 Starting database optimization...');

      // Step 1: Merge duplicate progress and keep highest levels
      await mergeDuplicateProgress();

      // Step 2: Clean up old session documents (keep last 3 for analytics)
      await cleanupOldGameSessions(keepLastSessions: 3);

      print('✅ Database optimization complete!');
      print('💾 Storage space saved by removing duplicate data');
    } catch (e) {
      print('Error during database optimization: $e');
    }
  }
}

/// Game session data model - supports all game types
class GameSessionData {
  final String? id;
  final DateTime timestamp;
  final String gameType; // 'trace_pop_pro', 'talk_with_tiles', 'shape_shifters'
  final String gameMode;
  final int level;
  final Duration sessionDuration;
  final double progress;
  final int score;
  final bool completed;
  final Map<String, dynamic> gameSpecificData; // Game-specific metrics
  final Map<String, dynamic> metadata;

  GameSessionData({
    this.id,
    required this.timestamp,
    required this.gameType,
    required this.gameMode,
    required this.level,
    required this.sessionDuration,
    required this.progress,
    required this.score,
    required this.completed,
    required this.gameSpecificData,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'gameType': gameType,
      'gameMode': gameMode,
      'level': level,
      'sessionDuration': sessionDuration.inMilliseconds,
      'progress': progress,
      'score': score,
      'completed': completed,
      'gameSpecificData': gameSpecificData,
      'metadata': metadata,
    };
  }

  factory GameSessionData.fromMap(Map<String, dynamic> map, String id) {
    return GameSessionData(
      id: id,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      gameType: map['gameType'] ?? 'trace_pop_pro',
      gameMode: map['gameMode'] ?? 'trace',
      level: map['level'] ?? 1,
      sessionDuration: Duration(milliseconds: map['sessionDuration'] ?? 0),
      progress: (map['progress'] ?? 0.0).toDouble(),
      score: map['score'] ?? 0,
      completed: map['completed'] ?? false,
      gameSpecificData:
          Map<String, dynamic>.from(map['gameSpecificData'] ?? {}),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// User progress and achievements
class UserProgress {
  final int highestLevel;
  final Map<String, int> modeCompletions; // mode -> count
  final int totalSessions;
  final int totalBubblesPopped;
  final Duration totalPlayTime;
  final List<String> achievements;
  final DateTime lastPlayed;

  UserProgress({
    required this.highestLevel,
    required this.modeCompletions,
    required this.totalSessions,
    required this.totalBubblesPopped,
    required this.totalPlayTime,
    required this.achievements,
    required this.lastPlayed,
  });

  factory UserProgress.empty() {
    return UserProgress(
      highestLevel: 1,
      modeCompletions: {},
      totalSessions: 0,
      totalBubblesPopped: 0,
      totalPlayTime: Duration.zero,
      achievements: [],
      lastPlayed: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'highestLevel': highestLevel,
      'modeCompletions': modeCompletions,
      'totalSessions': totalSessions,
      'totalBubblesPopped': totalBubblesPopped,
      'totalPlayTime': totalPlayTime.inMilliseconds,
      'achievements': achievements,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
    };
  }

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      highestLevel: map['highestLevel'] ?? 1,
      modeCompletions: Map<String, int>.from(map['modeCompletions'] ?? {}),
      totalSessions: map['totalSessions'] ?? 0,
      totalBubblesPopped: map['totalBubblesPopped'] ?? 0,
      totalPlayTime: Duration(milliseconds: map['totalPlayTime'] ?? 0),
      achievements: List<String>.from(map['achievements'] ?? []),
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Game statistics for analytics
class GameStatistics {
  final double averageAccuracy;
  final double averageSpeed;
  final int totalCompletedSessions;
  final int totalSessions;
  final Duration averageSessionDuration;
  final Map<String, int> modePlayCounts;
  final Map<int, int> levelPlayCounts;

  GameStatistics({
    required this.averageAccuracy,
    required this.averageSpeed,
    required this.totalCompletedSessions,
    required this.totalSessions,
    required this.averageSessionDuration,
    required this.modePlayCounts,
    required this.levelPlayCounts,
  });

  factory GameStatistics.empty() {
    return GameStatistics(
      averageAccuracy: 0.0,
      averageSpeed: 0.0,
      totalCompletedSessions: 0,
      totalSessions: 0,
      averageSessionDuration: Duration.zero,
      modePlayCounts: {},
      levelPlayCounts: {},
    );
  }

  factory GameStatistics.fromSessions(List<GameSessionData> sessions) {
    if (sessions.isEmpty) return GameStatistics.empty();

    double totalAccuracy = 0;
    double totalSpeed = 0;
    int completedCount = 0;
    Duration totalDuration = Duration.zero;
    Map<String, int> modeCounts = {};
    Map<int, int> levelCounts = {};

    for (final session in sessions) {
      // Extract accuracy and speed from gameSpecificData if available
      final accuracy = session.gameSpecificData['accuracy']?.toDouble() ?? 0.0;
      final speed = session.gameSpecificData['averageSpeed']?.toDouble() ?? 0.0;

      totalAccuracy += accuracy;
      totalSpeed += speed;
      totalDuration += session.sessionDuration;

      if (session.completed) completedCount++;

      modeCounts[session.gameMode] = (modeCounts[session.gameMode] ?? 0) + 1;
      levelCounts[session.level] = (levelCounts[session.level] ?? 0) + 1;
    }

    return GameStatistics(
      averageAccuracy:
          sessions.isNotEmpty ? totalAccuracy / sessions.length : 0.0,
      averageSpeed: sessions.isNotEmpty ? totalSpeed / sessions.length : 0.0,
      totalCompletedSessions: completedCount,
      totalSessions: sessions.length,
      averageSessionDuration: Duration(
        milliseconds: sessions.isNotEmpty
            ? totalDuration.inMilliseconds ~/ sessions.length
            : 0,
      ),
      modePlayCounts: modeCounts,
      levelPlayCounts: levelCounts,
    );
  }
}

/// Unified game progress for a single user across all games
class UserGameProgress {
  final String userId;
  final Map<String, GameProgress> gameProgress; // gameType -> progress
  final Map<String, int> totalScores; // gameType -> total score
  final Map<String, int> totalSessions; // gameType -> session count
  final Map<String, Duration> totalPlayTime; // gameType -> total time
  final List<String> globalAchievements;
  final DateTime lastPlayed;
  final DateTime createdAt;

  UserGameProgress({
    required this.userId,
    required this.gameProgress,
    required this.totalScores,
    required this.totalSessions,
    required this.totalPlayTime,
    required this.globalAchievements,
    required this.lastPlayed,
    required this.createdAt,
  });

  factory UserGameProgress.empty() {
    return UserGameProgress(
      userId: '',
      gameProgress: {},
      totalScores: {},
      totalSessions: {},
      totalPlayTime: {},
      globalAchievements: [],
      lastPlayed: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  factory UserGameProgress.fromMap(Map<String, dynamic> map, String userId) {
    return UserGameProgress(
      userId: userId,
      gameProgress: Map<String, GameProgress>.from(
        (map['gameProgress'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
              key, GameProgress.fromMap(value as Map<String, dynamic>)),
        ),
      ),
      totalScores: Map<String, int>.from(map['totalScores'] ?? {}),
      totalSessions: Map<String, int>.from(map['totalSessions'] ?? {}),
      totalPlayTime: Map<String, Duration>.from(
        (map['totalPlayTime'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, Duration(milliseconds: value as int)),
        ),
      ),
      globalAchievements: List<String>.from(map['globalAchievements'] ?? []),
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameProgress': gameProgress.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'totalScores': totalScores,
      'totalSessions': totalSessions,
      'totalPlayTime': totalPlayTime.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'globalAchievements': globalAchievements,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Update progress from a game session
  UserGameProgress updateFromSession({
    required String gameType,
    required int level,
    required int score,
    required bool completed,
    required Duration sessionDuration,
    required Map<String, dynamic> gameSpecificData,
  }) {
    final currentGameProgress = gameProgress[gameType] ?? GameProgress.empty();
    final updatedGameProgress = currentGameProgress.updateFromSession(
      level: level,
      score: score,
      completed: completed,
      sessionDuration: sessionDuration,
      gameSpecificData: gameSpecificData,
    );

    return UserGameProgress(
      userId: userId,
      gameProgress: {
        ...gameProgress,
        gameType: updatedGameProgress,
      },
      totalScores: {
        ...totalScores,
        gameType: (totalScores[gameType] ?? 0) + score,
      },
      totalSessions: {
        ...totalSessions,
        gameType: (totalSessions[gameType] ?? 0) + 1,
      },
      totalPlayTime: {
        ...totalPlayTime,
        gameType: (totalPlayTime[gameType] ?? Duration.zero) + sessionDuration,
      },
      globalAchievements: globalAchievements, // TODO: Add achievement checking
      lastPlayed: DateTime.now(),
      createdAt: createdAt,
    );
  }

  /// Get current level for a specific game
  int getCurrentLevel(String gameType) {
    return gameProgress[gameType]?.currentLevel ?? 1;
  }

  /// Get best score for a specific game
  int getBestScore(String gameType) {
    return gameProgress[gameType]?.bestScore ?? 0;
  }
}

/// Progress data for a specific game
class GameProgress {
  final int currentLevel;
  final int highestLevel;
  final int bestScore;
  final int totalCompletions;
  final Duration bestTime;
  final Duration totalTime;
  final List<String> achievements;
  final Map<String, dynamic> gameSpecificData;
  final DateTime lastPlayed;

  GameProgress({
    required this.currentLevel,
    required this.highestLevel,
    required this.bestScore,
    required this.totalCompletions,
    required this.bestTime,
    required this.totalTime,
    required this.achievements,
    required this.gameSpecificData,
    required this.lastPlayed,
  });

  factory GameProgress.empty() {
    return GameProgress(
      currentLevel: 1,
      highestLevel: 1,
      bestScore: 0,
      totalCompletions: 0,
      bestTime: Duration.zero,
      totalTime: Duration.zero,
      achievements: [],
      gameSpecificData: {},
      lastPlayed: DateTime.now(),
    );
  }

  factory GameProgress.fromMap(Map<String, dynamic> map) {
    return GameProgress(
      currentLevel: map['currentLevel'] ?? 1,
      highestLevel: map['highestLevel'] ?? 1,
      bestScore: map['bestScore'] ?? 0,
      totalCompletions: map['totalCompletions'] ?? 0,
      bestTime: Duration(milliseconds: map['bestTime'] ?? 0),
      totalTime: Duration(milliseconds: map['totalTime'] ?? 0),
      achievements: List<String>.from(map['achievements'] ?? []),
      gameSpecificData:
          Map<String, dynamic>.from(map['gameSpecificData'] ?? {}),
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentLevel': currentLevel,
      'highestLevel': highestLevel,
      'bestScore': bestScore,
      'totalCompletions': totalCompletions,
      'bestTime': bestTime.inMilliseconds,
      'totalTime': totalTime.inMilliseconds,
      'achievements': achievements,
      'gameSpecificData': gameSpecificData,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
    };
  }

  /// Update progress from a game session
  GameProgress updateFromSession({
    required int level,
    required int score,
    required bool completed,
    required Duration sessionDuration,
    required Map<String, dynamic> gameSpecificData,
  }) {
    return GameProgress(
      currentLevel: level,
      highestLevel: level > highestLevel ? level : highestLevel,
      bestScore: score > bestScore ? score : bestScore,
      totalCompletions: completed ? totalCompletions + 1 : totalCompletions,
      bestTime: (completed &&
              (bestTime == Duration.zero || sessionDuration < bestTime))
          ? sessionDuration
          : bestTime,
      totalTime: totalTime + sessionDuration,
      achievements: achievements, // TODO: Add achievement checking
      gameSpecificData: {
        ...this.gameSpecificData,
        ...gameSpecificData,
      },
      lastPlayed: DateTime.now(),
    );
  }
}
