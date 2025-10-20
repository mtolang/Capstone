# AI Therapy Progress Integration Guide

## Overview
This guide explains how to integrate Google's Gemini AI to analyze therapy progress and generate insights for your Capstone child therapy booking system.

## 📦 What's Been Added

### 1. **AI Service** (`lib/services/therapy_ai_service.dart`)
- Connects to your existing `OTAssessments` collection in Firebase
- Calculates performance metrics for Fine Motor, Gross Motor, Sensory Processing, and Cognitive skills
- Generates AI-powered insights using Google's Gemini 1.5 Flash model

### 2. **AI Insights Screen** (`lib/screens/clinic/ai_insights_screen.dart`)
- Beautiful UI with tabs for Overview and Categories
- Real-time dashboard showing overall clinic statistics
- Category-wise performance analytics
- AI-generated insights with one tap

### 3. **Package** (`google_generative_ai: ^0.4.6`)
- Already added to `pubspec.yaml`
- Already installed with `flutter pub add`

## 🔑 API Key Configuration

Your API key is: `AIzaSyC2yYSFl7NSxVyicp3oKPqUbpMkkYPit98`

### Option 1: Direct Usage (Current Implementation)
The AI service is already configured with your API key in `ai_insights_screen.dart`:
```dart
_aiService = TherapyProgressAIService('AIzaSyC2yYSFl7NSxVyicp3oKPqUbpMkkYPit98');
```

### Option 2: Secure Storage (Recommended for Production)
For production apps, store the API key securely:

1. Install flutter_secure_storage:
```bash
flutter pub add flutter_secure_storage
```

2. Store the key:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
await storage.write(key: 'gemini_api_key', value: 'AIzaSyC2yYSFl7NSxVyicp3oKPqUbpMkkYPit98');
```

3. Retrieve and use:
```dart
final apiKey = await storage.read(key: 'gemini_api_key');
_aiService = TherapyProgressAIService(apiKey!);
```

## 🚀 How to Use

### Method 1: Standalone AI Insights Screen

Add a navigation button anywhere in your app:

```dart
import 'package:capstone_2/screens/clinic/ai_insights_screen.dart';

// In your widget:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIInsightsScreen(),
      ),
    );
  },
  child: const Text('AI Insights'),
)
```

### Method 2: Add to Clinic Progress AppBar

Update `lib/screens/clinic/clinic_progress.dart`:

```dart
// Add import at the top
import 'ai_insights_screen.dart';

// Inside your Scaffold, add an AppBar with actions:
return Scaffold(
  appBar: AppBar(
    title: const Text(
      'Progress Analytics',
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    backgroundColor: const Color(0xFF006A5B),
    elevation: 0,
    centerTitle: true,
    actions: [
      IconButton(
        icon: const Icon(Icons.psychology, color: Colors.white),
        tooltip: 'AI Insights',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIInsightsScreen(),
            ),
          );
        },
      ),
    ],
  ),
  body: Stack(
    // ... your existing body content
  ),
);
```

### Method 3: Add a Floating Action Button

```dart
return Scaffold(
  body: // ... your content,
  floatingActionButton: FloatingActionButton.extended(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AIInsightsScreen(),
        ),
      );
    },
    backgroundColor: const Color(0xFF006A5B),
    icon: const Icon(Icons.psychology),
    label: const Text('AI Insights'),
  ),
);
```

## 📊 Features

### Overview Tab
- **Overall Average Score**: Combined performance across all categories
- **Total Assessments**: Number of OT assessments completed
- **Active Clients**: Number of unique clients with assessments
- **Category Performance Cards**: Quick view of each skill category

### Categories Tab
- **Detailed Category Analytics**: Expandable cards for each category
- **Performance Metrics**: Average scores and improvement rates
- **Top Performers**: Clients excelling in each category (>75% average)
- **Needs Attention**: Clients requiring additional support (<50% average)
- **AI Insights Button**: Generate professional analysis with one tap

### AI-Generated Insights Include:
1. **Performance Summary**: Overall assessment of category performance
2. **Key Trends**: Patterns observed in the data
3. **Program Recommendations**: Suggestions for improving therapy programs
4. **Interventions**: Specific strategies for clients needing attention

## 🔄 How It Works

### Data Flow
```
1. Fetch OTAssessments from Firestore
   ↓
2. Calculate scores from skill ratings (1-5 scale)
   ↓
3. Aggregate data by category
   ↓
4. Send summarized data to Gemini AI
   ↓
5. Display AI-generated insights
```

### Score Calculation
Each category has 4 sub-skills rated 1-5:

**Fine Motor Skills:**
- Pincer Grasp
- Hand-Eye Coordination
- In-Hand Manipulation
- Bilateral Coordination

**Gross Motor Skills:**
- Balance
- Running/Jumping
- Throwing/Catching
- Motor Planning

**Sensory Processing:**
- Tactile Response
- Auditory Filtering
- Vestibular Seeking
- Proprioceptive Awareness

**Cognitive Skills:**
- Problem Solving
- Attention Span
- Following Directions
- Sequencing Tasks

**Formula:**
```
Category Score = (sum of 4 sub-skills / 4) × 20
Overall Score = average of all category scores
```

## 🎯 Use Cases

### 1. Clinic Dashboard
Show overall clinic performance with AI recommendations

### 2. Client Progress Reports
Generate detailed AI analysis for individual clients:
```dart
final report = await aiService.generateClientReport(
  clientId,
  clientName,
  'Fine Motor', // or any category
);

// Access:
// report.aiInsights
// report.recommendations
// report.strengths
// report.areasForImprovement
```

### 3. Category Analysis
Analyze specific therapy categories:
```dart
final analytics = aiService.calculateCategoryPerformance(
  'Sensory Processing',
  allAssessments,
);

final insights = await aiService.generateCategoryInsights(analytics);
```

## 🛠️ Customization

### Change AI Model
In `therapy_ai_service.dart`:
```dart
_model = GenerativeModel(
  model: 'gemini-1.5-flash', // or 'gemini-1.5-pro' for more detailed analysis
  apiKey: apiKey,
  generationConfig: GenerationConfig(
    temperature: 0.7, // Adjust creativity (0.0-1.0)
    maxOutputTokens: 1000, // Adjust response length
  ),
);
```

### Adjust Performance Thresholds
In `therapy_ai_service.dart`, modify the `calculateCategoryPerformance` method:
```dart
// Current thresholds:
if (entry.value >= 75) { // Top performers
  topPerformers.add(clientName);
} else if (entry.value < 50) { // Needs attention
  needsAttention.add(clientName);
}

// Customize as needed
```

### Add Custom Prompts
Modify the `generateCategoryInsights` or `generateClientReport` methods to customize AI analysis:
```dart
final prompt = '''
You are an expert pediatric occupational therapist...
[Your custom instructions]
''';
```

## 📱 Testing

1. **Open the AI Insights screen**
2. **Check Overview tab** - Should show:
   - Overall average score
   - Total assessments count
   - Number of unique clients
   - Category performance cards

3. **Switch to Categories tab** - Should display:
   - Expandable category cards
   - Performance metrics
   - Top performers and clients needing attention
   - AI Insights button

4. **Tap "View AI Insights"** - Should:
   - Show loading dialog
   - Generate AI analysis (takes 2-5 seconds)
   - Display insights in a dialog

## 🐛 Troubleshooting

### "No Data Available"
- Ensure OTAssessments exist in Firestore with `clinicId` field
- Check that clinic ID is properly stored in SharedPreferences

### "Error Generating Insights"
- Verify API key is correct
- Check internet connection
- Ensure Firebase collection structure matches expected format

### "Clinic ID Not Found"
- Verify user is logged in as clinic
- Check SharedPreferences keys: `clinic_id`, `user_id`, `clinicId`, etc.

## 📝 Database Structure Expected

```
OTAssessments/
  └── {documentId}/
      ├── assessmentId: string
      ├── clientId: string
      ├── clientName: string
      ├── clinicId: string (REQUIRED for filtering)
      ├── createdAt: Timestamp
      ├── assessmentType: string (optional)
      ├── fineMotorSkills: {
      │   ├── pincerGrasp: number (1-5)
      │   ├── handEyeCoordination: number (1-5)
      │   ├── inHandManipulation: number (1-5)
      │   └── bilateralCoordination: number (1-5)
      │ }
      ├── grossMotorSkills: {
      │   ├── balance: number (1-5)
      │   ├── runningJumping: number (1-5)
      │   ├── throwingCatching: number (1-5)
      │   └── motorPlanning: number (1-5)
      │ }
      ├── sensoryProcessing: {
      │   ├── tactileResponse: number (1-5)
      │   ├── auditoryFiltering: number (1-5)
      │   ├── vestibularSeeking: number (1-5)
      │   └── proprioceptiveAwareness: number (1-5)
      │ }
      ├── cognitiveSkills: {
      │   ├── problemSolving: number (1-5)
      │   ├── attentionSpan: number (1-5)
      │   ├── followingDirections: number (1-5)
      │   └── sequencingTasks: number (1-5)
      │ }
      ├── notes: string (optional)
      ├── goals: string (optional)
      └── recommendations: string (optional)
```

## 🎉 Ready to Use!

The AI integration is complete and ready to use. Simply navigate to the `AIInsightsScreen` from anywhere in your app to start getting AI-powered therapy insights!

## 📚 Additional Resources

- [Google AI Dart SDK](https://pub.dev/packages/google_generative_ai)
- [Gemini API Documentation](https://ai.google.dev/docs)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)

## 🔐 Security Notes

- **Never commit API keys to Git** - Use environment variables or secure storage
- **Add to .gitignore**: Any files containing API keys
- **Production**: Consider using Firebase Cloud Functions to proxy AI requests
- **Rate Limiting**: Implement request throttling for production use
