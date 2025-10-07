import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle Trace & Pop Pro game data storage in Firebase
class GameDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save game session data to Firebase
  static Future<void> saveGameSession(GameSessionData sessionData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('game_sessions')
          .doc();

      await docRef.set(sessionData.toMap());
    } catch (e) {
      print('Error saving game session: $e');
    }
  }

  /// Get all game sessions for current user
  static Future<List<GameSessionData>> getGameSessions({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('game_sessions')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => GameSessionData.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching game sessions: $e');
      return [];
    }
  }

  /// Get user's game statistics
  static Future<GameStatistics> getUserStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return GameStatistics.empty();

      final sessions = await getGameSessions(limit: 100);
      return GameStatistics.fromSessions(sessions);
    } catch (e) {
      print('Error calculating statistics: $e');
      return GameStatistics.empty();
    }
  }

  /// Save user progress/achievements
  static Future<void> saveUserProgress(UserProgress progress) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('current')
          .set(progress.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user progress: $e');
    }
  }

  /// Get user progress
  static Future<UserProgress> getUserProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return UserProgress.empty();

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('current')
          .get();

      if (doc.exists) {
        return UserProgress.fromMap(doc.data()!);
      }
      return UserProgress.empty();
    } catch (e) {
      print('Error fetching user progress: $e');
      return UserProgress.empty();
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
      gameSpecificData: Map<String, dynamic>.from(map['gameSpecificData'] ?? {}),
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
      averageAccuracy: sessions.isNotEmpty ? totalAccuracy / sessions.length : 0.0,
      averageSpeed: sessions.isNotEmpty ? totalSpeed / sessions.length : 0.0,
      totalCompletedSessions: completedCount,
      totalSessions: sessions.length,
      averageSessionDuration: Duration(
        milliseconds: sessions.isNotEmpty ? totalDuration.inMilliseconds ~/ sessions.length : 0,
      ),
      modePlayCounts: modeCounts,
      levelPlayCounts: levelCounts,
    );
  }
}