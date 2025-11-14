import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration script to add 'isInitialAssessment' field to existing assessments
/// This will mark the first assessment for each patient/clinic combination as the initial assessment
/// 
/// To run this migration:
/// 1. Make sure Flutter app is connected to Firebase
/// 2. Run: dart migrate_initial_assessments.dart
/// 
Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    print('🚀 Starting migration: Adding isInitialAssessment field to assessments');
    print('================================================\n');

    final firestore = FirebaseFirestore.instance;

    // Get all assessments
    final assessmentsSnapshot = await firestore
        .collection('OTAssessments')
        .orderBy('createdAt')
        .get();

    print('📊 Found ${assessmentsSnapshot.docs.length} total assessments\n');

    // Group assessments by patientId + clinicId
    final Map<String, List<QueryDocumentSnapshot>> patientAssessments = {};

    for (var doc in assessmentsSnapshot.docs) {
      final data = doc.data();
      final patientId = data['patientId'] as String?;
      final clinicId = data['clinicId'] as String?;

      if (patientId != null && clinicId != null) {
        final key = '$patientId-$clinicId';
        patientAssessments.putIfAbsent(key, () => []);
        patientAssessments[key]!.add(doc);
      }
    }

    print('👥 Processing ${patientAssessments.length} unique patient/clinic combinations\n');

    int updatedCount = 0;
    int skippedCount = 0;

    // For each patient, mark the first assessment as initial
    for (var entry in patientAssessments.entries) {
      final key = entry.key;
      final assessments = entry.value;

      if (assessments.isEmpty) continue;

      // Sort by createdAt to get the first assessment
      assessments.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;
        final aTime = (aData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (bData?['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return aTime.compareTo(bTime);
      });

      final firstAssessment = assessments.first;
      final firstData = firstAssessment.data() as Map<String, dynamic>?;

      if (firstData == null) continue;

      // Check if isInitialAssessment field already exists
      if (firstData.containsKey('isInitialAssessment')) {
        print('⏭️  Skipping $key - already has isInitialAssessment field');
        skippedCount++;
        continue;
      }

      // Update the first assessment to mark it as initial
      await firestore
          .collection('OTAssessments')
          .doc(firstAssessment.id)
          .update({
        'isInitialAssessment': true,
      });

      print('✅ Updated $key - Marked assessment ${firstAssessment.id} as initial (${firstData['childName'] ?? 'Unknown'})');
      updatedCount++;

      // Update remaining assessments to mark them as NOT initial
      for (var i = 1; i < assessments.length; i++) {
        final assessment = assessments[i];
        final data = assessment.data() as Map<String, dynamic>?;

        if (data != null && !data.containsKey('isInitialAssessment')) {
          await firestore
              .collection('OTAssessments')
              .doc(assessment.id)
              .update({
            'isInitialAssessment': false,
          });

          print('   ➡️  Marked assessment ${assessment.id} as NOT initial');
        }
      }
    }

    print('\n================================================');
    print('✨ Migration completed successfully!');
    print('📊 Statistics:');
    print('   - Total assessments: ${assessmentsSnapshot.docs.length}');
    print('   - Updated as initial: $updatedCount');
    print('   - Skipped (already had field): $skippedCount');
    print('   - Patients processed: ${patientAssessments.length}');
    print('================================================\n');
  } catch (e) {
    print('❌ Error during migration: $e');
  }
}
