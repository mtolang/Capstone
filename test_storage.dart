// Test SharedPreferences storage for parent login
// Run this after login to verify data is stored correctly

import 'package:shared_preferences/shared_preferences.dart';

Future<void> testParentStorage() async {
  final prefs = await SharedPreferences.getInstance();

  print('=== PARENT LOGIN STORAGE TEST ===');
  print('user_id: ${prefs.getString('user_id')}');
  print('user_name: ${prefs.getString('user_name')}');
  print('user_email: ${prefs.getString('user_email')}');
  print('user_phone: ${prefs.getString('user_phone')}');
  print('user_type: ${prefs.getString('user_type')}');
  print('is_logged_in: ${prefs.getBool('is_logged_in')}');
  print('===============================');

  final userId = prefs.getString('user_id');
  final userName = prefs.getString('user_name');

  if (userId != null && userName != null) {
    print('✅ Storage successful!');
    print('Can display: Welcome back! Logged in as $userName');
    print('User ID: $userId');
  } else {
    print('❌ Storage failed!');
    print('Missing user_id: $userId');
    print('Missing user_name: $userName');
  }
}
