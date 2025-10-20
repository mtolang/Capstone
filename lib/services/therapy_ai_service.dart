import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Models for OT Assessment data from your existing database
class OTAssessmentSession {
  final String assessmentId;
  final String clientId;
  final String clientName;
  final String clinicId;
  final DateTime createdAt;
  final String? assessmentType;

  // Skill categories (each has sub-skills rated 1-5)
  final Map<String, dynamic>? fineMotorSkills;
  final Map<String, dynamic>? grossMotorSkills;
  final Map<String, dynamic>? sensoryProcessing;
  final Map<String, dynamic>? cognitiveSkills;

  // Additional fields
  final String? notes;
  final String? goals;
  final String? recommendations;

  OTAssessmentSession({
    required this.assessmentId,
    required this.clientId,
    required this.clientName,
    required this.clinicId,
    required this.createdAt,
    this.assessmentType,
    this.fineMotorSkills,
    this.grossMotorSkills,
    this.sensoryProcessing,
    this.cognitiveSkills,
    this.notes,
    this.goals,
    this.recommendations,
  });

  factory OTAssessmentSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OTAssessmentSession(
      assessmentId: doc.id,
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'] ?? 'Unknown',
      clinicId: data['clinicId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assessmentType: data['assessmentType'],
      fineMotorSkills: data['fineMotorSkills'],
      grossMotorSkills: data['grossMotorSkills'],
      sensoryProcessing: data['sensoryProcessing'],
      cognitiveSkills: data['cognitiveSkills'],
      notes: data['notes'],
      goals: data['goals'],
      recommendations: data['recommendations'],
    );
  }

  /// Calculate overall performance score (0-100)
  double calculateOverallScore() {
    double totalScore = 0;
    int categoryCount = 0;

    // Fine Motor Skills average
    if (fineMotorSkills != null) {
      final scores = [
        fineMotorSkills!['pincerGrasp'] ?? 0,
        fineMotorSkills!['handEyeCoordination'] ?? 0,
        fineMotorSkills!['inHandManipulation'] ?? 0,
        fineMotorSkills!['bilateralCoordination'] ?? 0,
      ];
      final avg = scores.reduce((a, b) => a + b) / scores.length * 20;
      totalScore += avg;
      categoryCount++;
    }

    // Gross Motor Skills average
    if (grossMotorSkills != null) {
      final scores = [
        grossMotorSkills!['balance'] ?? 0,
        grossMotorSkills!['runningJumping'] ?? 0,
        grossMotorSkills!['throwingCatching'] ?? 0,
        grossMotorSkills!['motorPlanning'] ?? 0,
      ];
      final avg = scores.reduce((a, b) => a + b) / scores.length * 20;
      totalScore += avg;
      categoryCount++;
    }

    // Sensory Processing average
    if (sensoryProcessing != null) {
      final scores = [
        sensoryProcessing!['tactileResponse'] ?? 0,
        sensoryProcessing!['auditoryFiltering'] ?? 0,
        sensoryProcessing!['vestibularSeeking'] ?? 0,
        sensoryProcessing!['proprioceptiveAwareness'] ?? 0,
      ];
      final avg = scores.reduce((a, b) => a + b) / scores.length * 20;
      totalScore += avg;
      categoryCount++;
    }

    // Cognitive Skills average
    if (cognitiveSkills != null) {
      final scores = [
        cognitiveSkills!['problemSolving'] ?? 0,
        cognitiveSkills!['attentionSpan'] ?? 0,
        cognitiveSkills!['followingDirections'] ?? 0,
        cognitiveSkills!['sequencingTasks'] ?? 0,
      ];
      final avg = scores.reduce((a, b) => a + b) / scores.length * 20;
      totalScore += avg;
      categoryCount++;
    }

    return categoryCount > 0 ? totalScore / categoryCount : 0.0;
  }

  /// Get category-specific scores
  Map<String, double> getCategoryScores() {
    final Map<String, double> scores = {};

    if (fineMotorSkills != null) {
      final fineScores = [
        fineMotorSkills!['pincerGrasp'] ?? 0,
        fineMotorSkills!['handEyeCoordination'] ?? 0,
        fineMotorSkills!['inHandManipulation'] ?? 0,
        fineMotorSkills!['bilateralCoordination'] ?? 0,
      ];
      scores['Fine Motor'] =
          fineScores.reduce((a, b) => a + b) / fineScores.length * 20;
    }

    if (grossMotorSkills != null) {
      final grossScores = [
        grossMotorSkills!['balance'] ?? 0,
        grossMotorSkills!['runningJumping'] ?? 0,
        grossMotorSkills!['throwingCatching'] ?? 0,
        grossMotorSkills!['motorPlanning'] ?? 0,
      ];
      scores['Gross Motor'] =
          grossScores.reduce((a, b) => a + b) / grossScores.length * 20;
    }

    if (sensoryProcessing != null) {
      final sensoryScores = [
        sensoryProcessing!['tactileResponse'] ?? 0,
        sensoryProcessing!['auditoryFiltering'] ?? 0,
        sensoryProcessing!['vestibularSeeking'] ?? 0,
        sensoryProcessing!['proprioceptiveAwareness'] ?? 0,
      ];
      scores['Sensory Processing'] =
          sensoryScores.reduce((a, b) => a + b) / sensoryScores.length * 20;
    }

    if (cognitiveSkills != null) {
      final cognitiveScores = [
        cognitiveSkills!['problemSolving'] ?? 0,
        cognitiveSkills!['attentionSpan'] ?? 0,
        cognitiveSkills!['followingDirections'] ?? 0,
        cognitiveSkills!['sequencingTasks'] ?? 0,
      ];
      scores['Cognitive'] =
          cognitiveScores.reduce((a, b) => a + b) / cognitiveScores.length * 20;
    }

    return scores;
  }
}

/// Analytics data for category performance
class CategoryPerformanceAnalytics {
  final String category;
  final double averageScore;
  final int totalAssessments;
  final double improvementRate;
  final List<String> topPerformers;
  final List<String> needsAttention;

  CategoryPerformanceAnalytics({
    required this.category,
    required this.averageScore,
    required this.totalAssessments,
    required this.improvementRate,
    required this.topPerformers,
    required this.needsAttention,
  });
}

/// Client-specific progress report with AI insights
class ClientProgressReport {
  final String clientId;
  final String clientName;
  final String category;
  final double currentScore;
  final double averageScore;
  final double progressTrend;
  final int totalAssessments;
  final String aiInsights;
  final List<String> recommendations;
  final List<String> strengths;
  final List<String> areasForImprovement;

  ClientProgressReport({
    required this.clientId,
    required this.clientName,
    required this.category,
    required this.currentScore,
    required this.averageScore,
    required this.progressTrend,
    required this.totalAssessments,
    required this.aiInsights,
    required this.recommendations,
    required this.strengths,
    required this.areasForImprovement,
  });
}

/// Main AI Service for Therapy Progress Analysis
class TherapyProgressAIService {
  late final GenerativeModel _model;
  final String apiKey;

  TherapyProgressAIService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
      ),
    );
  }

  /// Fetch OT Assessments from Firestore for a specific clinic
  Future<List<OTAssessmentSession>> fetchAssessmentsForClinic(
      String clinicId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OTAssessmentSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching assessments: $e');
      return [];
    }
  }

  /// Fetch OT Assessments for a specific client
  Future<List<OTAssessmentSession>> fetchAssessmentsForClient(
      String clientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('OTAssessments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => OTAssessmentSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching client assessments: $e');
      return [];
    }
  }

  /// Calculate category performance analytics
  CategoryPerformanceAnalytics calculateCategoryPerformance(
    String category,
    List<OTAssessmentSession> assessments,
  ) {
    if (assessments.isEmpty) {
      return CategoryPerformanceAnalytics(
        category: category,
        averageScore: 0,
        totalAssessments: 0,
        improvementRate: 0,
        topPerformers: [],
        needsAttention: [],
      );
    }

    // Get all scores for this category
    final List<double> categoryScores = [];
    final Map<String, List<double>> clientScores = {};

    for (var assessment in assessments) {
      final scores = assessment.getCategoryScores();
      if (scores.containsKey(category)) {
        final score = scores[category]!;
        categoryScores.add(score);

        clientScores.putIfAbsent(assessment.clientId, () => []).add(score);
      }
    }

    if (categoryScores.isEmpty) {
      return CategoryPerformanceAnalytics(
        category: category,
        averageScore: 0,
        totalAssessments: 0,
        improvementRate: 0,
        topPerformers: [],
        needsAttention: [],
      );
    }

    // Calculate average score
    final avgScore =
        categoryScores.reduce((a, b) => a + b) / categoryScores.length;

    // Calculate improvement rate (last 5 vs first 5 assessments)
    double improvementRate = 0;
    if (categoryScores.length >= 10) {
      final firstFive = categoryScores.take(5).reduce((a, b) => a + b) / 5;
      final lastFive = categoryScores
              .skip(categoryScores.length - 5)
              .reduce((a, b) => a + b) /
          5;
      improvementRate = ((lastFive - firstFive) / firstFive) * 100;
    } else if (categoryScores.length >= 2) {
      final first = categoryScores.first;
      final last = categoryScores.last;
      improvementRate = ((last - first) / first) * 100;
    }

    // Calculate client averages
    final clientAverages = clientScores.map(
      (clientId, scores) => MapEntry(
        clientId,
        scores.reduce((a, b) => a + b) / scores.length,
      ),
    );

    // Identify top performers (>75 average)
    final topPerformers = <String>[];
    final needsAttention = <String>[];

    for (var entry in clientAverages.entries) {
      // Find client name from assessments
      final clientName =
          assessments.firstWhere((a) => a.clientId == entry.key).clientName;

      if (entry.value >= 75) {
        topPerformers.add(clientName);
      } else if (entry.value < 50) {
        needsAttention.add(clientName);
      }
    }

    return CategoryPerformanceAnalytics(
      category: category,
      averageScore: avgScore,
      totalAssessments: categoryScores.length,
      improvementRate: improvementRate,
      topPerformers: topPerformers,
      needsAttention: needsAttention,
    );
  }

  /// Calculate individual client progress for a specific category
  Map<String, dynamic> calculateClientProgress(
    String clientId,
    String category,
    List<OTAssessmentSession> assessments,
  ) {
    final clientAssessments =
        assessments.where((a) => a.clientId == clientId).toList();

    if (clientAssessments.isEmpty) {
      return {
        'averageScore': 0.0,
        'currentScore': 0.0,
        'progressTrend': 0.0,
        'totalAssessments': 0,
        'recentAssessments': [],
        'categoryScores': <double>[],
      };
    }

    // Get category scores
    final List<double> categoryScores = [];
    for (var assessment in clientAssessments) {
      final scores = assessment.getCategoryScores();
      if (scores.containsKey(category)) {
        categoryScores.add(scores[category]!);
      }
    }

    if (categoryScores.isEmpty) {
      return {
        'averageScore': 0.0,
        'currentScore': 0.0,
        'progressTrend': 0.0,
        'totalAssessments': 0,
        'recentAssessments': [],
        'categoryScores': <double>[],
      };
    }

    final avgScore =
        categoryScores.reduce((a, b) => a + b) / categoryScores.length;
    final currentScore = categoryScores.last;

    // Calculate trend (linear regression on scores)
    double progressTrend = 0;
    if (categoryScores.length >= 2) {
      final firstScore = categoryScores.first;
      final lastScore = categoryScores.last;
      progressTrend = lastScore - firstScore;
    }

    return {
      'averageScore': avgScore,
      'currentScore': currentScore,
      'progressTrend': progressTrend,
      'totalAssessments': categoryScores.length,
      'recentAssessments': clientAssessments.length > 5
          ? clientAssessments.sublist(clientAssessments.length - 5)
          : clientAssessments,
      'categoryScores': categoryScores,
    };
  }

  /// Generate AI insights for category performance
  Future<String> generateCategoryInsights(
    CategoryPerformanceAnalytics analytics,
  ) async {
    final prompt = '''
You are an AI assistant for a child occupational therapy center. Analyze this category performance data and provide professional insights.

Category: ${analytics.category}
Average Performance Score: ${analytics.averageScore.toStringAsFixed(1)}/100
Total Assessments: ${analytics.totalAssessments}
Improvement Rate: ${analytics.improvementRate.toStringAsFixed(1)}%
Top Performers: ${analytics.topPerformers.isNotEmpty ? analytics.topPerformers.join(', ') : 'None yet'}
Clients Needing Attention: ${analytics.needsAttention.isNotEmpty ? analytics.needsAttention.join(', ') : 'None'}

Provide:
1. Overall category performance summary (2-3 sentences)
2. Key trends or patterns observed
3. 2-3 recommendations for program improvement
4. Suggested interventions for clients needing attention (if any)

Keep the response professional, concise, and actionable. Format with clear sections.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Unable to generate insights at this time.';
    } catch (e) {
      return 'Error generating insights: ${e.toString()}';
    }
  }

  /// Generate comprehensive AI insights for individual client
  Future<ClientProgressReport> generateClientReport(
    String clientId,
    String clientName,
    String category,
  ) async {
    // Fetch client assessments
    final assessments = await fetchAssessmentsForClient(clientId);

    if (assessments.isEmpty) {
      return ClientProgressReport(
        clientId: clientId,
        clientName: clientName,
        category: category,
        currentScore: 0,
        averageScore: 0,
        progressTrend: 0,
        totalAssessments: 0,
        aiInsights: 'No assessment data available for this client.',
        recommendations: ['Complete initial assessment'],
        strengths: [],
        areasForImprovement: [],
      );
    }

    final progressData =
        calculateClientProgress(clientId, category, assessments);
    final recentAssessments =
        progressData['recentAssessments'] as List<OTAssessmentSession>;

    // Prepare detailed session summaries for AI
    final sessionSummaries = recentAssessments.map((assessment) {
      final categoryScores = assessment.getCategoryScores();
      final score = categoryScores[category] ?? 0;

      return '''
Date: ${assessment.createdAt.toString().split(' ')[0]}
Score: ${score.toStringAsFixed(1)}/100
Goals: ${assessment.goals ?? 'Not specified'}
Notes: ${assessment.notes ?? 'No notes'}
Recommendations: ${assessment.recommendations ?? 'None'}
''';
    }).join('\n---\n');

    final prompt = '''
You are an AI assistant for a child occupational therapy center. Analyze this client's progress in ${category}.

Client: ${clientName}
Current Performance Score: ${progressData['currentScore'].toStringAsFixed(1)}/100
Average Score: ${progressData['averageScore'].toStringAsFixed(1)}/100
Progress Trend: ${progressData['progressTrend'] > 0 ? 'Improving' : progressData['progressTrend'] < 0 ? 'Declining' : 'Stable'} (${progressData['progressTrend'] > 0 ? '+' : ''}${progressData['progressTrend'].toStringAsFixed(1)} points)
Total Assessments: ${progressData['totalAssessments']}

Recent Assessment Data:
${sessionSummaries}

Provide a structured analysis with:
1. PROGRESS SUMMARY: Brief 2-3 sentence overview of the client's development
2. STRENGTHS: List 2-3 specific areas where the client excels
3. AREAS FOR IMPROVEMENT: List 2-3 specific areas that need focus
4. RECOMMENDATIONS: Provide 3-4 specific, actionable recommendations for therapists and parents

Keep the tone professional, supportive, and focused on the child's development. Be specific and practical.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final insights = response.text ?? 'Unable to generate insights.';

      // Parse the response
      final recommendations = _extractSection(insights, 'RECOMMENDATIONS');
      final strengths = _extractSection(insights, 'STRENGTHS');
      final areasForImprovement =
          _extractSection(insights, 'AREAS FOR IMPROVEMENT');

      return ClientProgressReport(
        clientId: clientId,
        clientName: clientName,
        category: category,
        currentScore: progressData['currentScore'],
        averageScore: progressData['averageScore'],
        progressTrend: progressData['progressTrend'],
        totalAssessments: progressData['totalAssessments'],
        aiInsights: insights,
        recommendations: recommendations,
        strengths: strengths,
        areasForImprovement: areasForImprovement,
      );
    } catch (e) {
      return ClientProgressReport(
        clientId: clientId,
        clientName: clientName,
        category: category,
        currentScore: progressData['currentScore'],
        averageScore: progressData['averageScore'],
        progressTrend: progressData['progressTrend'],
        totalAssessments: progressData['totalAssessments'],
        aiInsights: 'Error generating insights: ${e.toString()}',
        recommendations: [],
        strengths: [],
        areasForImprovement: [],
      );
    }
  }

  /// Helper to extract bulleted items from AI response sections
  List<String> _extractSection(String text, String sectionName) {
    final items = <String>[];
    final lines = text.split('\n');

    bool inSection = false;
    for (var line in lines) {
      if (line.toUpperCase().contains(sectionName)) {
        inSection = true;
        continue;
      }

      // Stop at next section
      if (inSection &&
          (line.contains('**') ||
              line.toUpperCase().contains('SUMMARY') ||
              line.toUpperCase().contains('STRENGTHS') ||
              line.toUpperCase().contains('AREAS') ||
              line.toUpperCase().contains('RECOMMENDATIONS')) &&
          !line.toUpperCase().contains(sectionName)) {
        break;
      }

      if (inSection &&
          (line.trim().startsWith('-') ||
              line.trim().startsWith('•') ||
              line.trim().startsWith('*') ||
              RegExp(r'^\d+\.').hasMatch(line.trim()))) {
        final cleaned =
            line.trim().replaceFirst(RegExp(r'^[-•*\d.]\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          items.add(cleaned);
        }
      }
    }

    return items;
  }

  /// Generate overall clinic dashboard analytics
  Future<Map<String, dynamic>> generateDashboardAnalytics(
    String clinicId,
  ) async {
    final assessments = await fetchAssessmentsForClinic(clinicId);

    if (assessments.isEmpty) {
      return {
        'categoryAnalytics': <String, CategoryPerformanceAnalytics>{},
        'overallAverage': 0.0,
        'totalAssessments': 0,
        'uniqueClients': 0,
      };
    }

    final categories = [
      'Fine Motor',
      'Gross Motor',
      'Sensory Processing',
      'Cognitive',
    ];

    final categoryAnalytics = <String, CategoryPerformanceAnalytics>{};

    for (var category in categories) {
      categoryAnalytics[category] =
          calculateCategoryPerformance(category, assessments);
    }

    // Calculate overall center statistics
    final validAverages = categoryAnalytics.values
        .where((a) => a.averageScore > 0)
        .map((a) => a.averageScore)
        .toList();

    final overallAverage = validAverages.isNotEmpty
        ? validAverages.reduce((a, b) => a + b) / validAverages.length
        : 0.0;

    final uniqueClients = assessments.map((a) => a.clientId).toSet().length;

    return {
      'categoryAnalytics': categoryAnalytics,
      'overallAverage': overallAverage,
      'totalAssessments': assessments.length,
      'uniqueClients': uniqueClients,
    };
  }
}
