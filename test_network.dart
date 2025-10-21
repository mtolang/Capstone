import 'dart:io';

void main() async {
  print('🔍 Testing network connectivity...');
  
  try {
    // Test basic internet connectivity
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ Basic internet connection: OK');
    }
  } catch (e) {
    print('❌ Basic internet connection: Failed - $e');
  }
  
  try {
    // Test Firebase connectivity
    final result = await InternetAddress.lookup('firestore.googleapis.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ Firebase connectivity: OK');
    }
  } catch (e) {
    print('❌ Firebase connectivity: Failed - $e');
  }
  
  try {
    // Test Firebase Auth
    final result = await InternetAddress.lookup('identitytoolkit.googleapis.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ Firebase Auth connectivity: OK');
    }
  } catch (e) {
    print('❌ Firebase Auth connectivity: Failed - $e');
  }
}