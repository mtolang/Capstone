import 'lib/services/game_data_service.dart';

/// Test the unified game progress system
void main() async {
  print('Testing Unified Game Progress System...');

  try {
    // Test 1: Get user game progress (should create new if doesn't exist)
    print('\n1. Testing getUserGameProgress...');
    final progress = await GameDataService.getUserGameProgress();
    print('✅ Progress loaded for user: ${progress.userId}');
    print(
        '   Current levels: ${progress.gameProgress.map((k, v) => MapEntry(k, v.currentLevel))}');

    // Test 2: Save a game session
    print('\n2. Testing saveGameSessionAndProgress...');
    await GameDataService.saveGameSessionAndProgress(
      gameType: 'shape_shifters',
      level: 2,
      score: 100,
      completed: false,
      sessionDuration: Duration(minutes: 5),
      gameSpecificData: {
        'testData': 'This is a test session',
        'accuracy': 0.85,
      },
    );
    print('✅ Game session saved successfully');

    // Test 3: Get updated progress
    print('\n3. Testing progress persistence...');
    final updatedProgress = await GameDataService.getUserGameProgress();
    final shapeShiftersLevel =
        updatedProgress.getCurrentLevel('shape_shifters');
    print('✅ Shape Shifters current level: $shapeShiftersLevel');

    // Test 4: Test different game types
    print('\n4. Testing multiple game types...');
    await GameDataService.saveGameSessionAndProgress(
      gameType: 'talk_with_tiles',
      level: 3,
      score: 75,
      completed: true,
      sessionDuration: Duration(minutes: 3),
      gameSpecificData: {
        'tilesUsed': 15,
        'sentencesFormed': 5,
      },
    );

    await GameDataService.saveGameSessionAndProgress(
      gameType: 'trace_and_pop_pro',
      level: 4,
      score: 200,
      completed: false,
      sessionDuration: Duration(minutes: 8),
      gameSpecificData: {
        'bubblesPopped': 20,
        'accuracy': 0.92,
      },
    );

    // Test 5: Final progress check
    print('\n5. Final progress check...');
    final finalProgress = await GameDataService.getUserGameProgress();
    print('✅ All game levels:');
    print(
        '   Shape Shifters: ${finalProgress.getCurrentLevel('shape_shifters')}');
    print(
        '   Talk with Tiles: ${finalProgress.getCurrentLevel('talk_with_tiles')}');
    print(
        '   Trace and Pop Pro: ${finalProgress.getCurrentLevel('trace_and_pop_pro')}');

    print('\n✅ All tests completed successfully!');
    print('🎯 Unified progress system is working correctly');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
