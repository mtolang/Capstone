import 'package:kindora/services/firebase_storage_service.dart';
import 'package:image_picker/image_picker.dart';

/// Example usage of Firebase Storage Service
///
/// This demonstrates how to use the FirebaseStorageService to upload files
/// to your Firebase Storage with proper folder organization
class StorageExample {
  /// Example: Upload a parent's government ID document
  static Future<void> uploadParentDocument() async {
    // Pick an image file
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Upload to Firebase Storage
      final String? downloadUrl =
          await FirebaseStorageService.uploadParentDocument(
        file: image,
        parentId: 'PARReg01', // This would be the actual parent ID
      );

      if (downloadUrl != null) {
        print('Government ID uploaded successfully!');
        print('Download URL: $downloadUrl');
        // Save this URL to Firestore in your registration process
      } else {
        print('Failed to upload government ID');
      }
    }
  }

  /// Example: Upload clinic registration documents
  static Future<void> uploadClinicDocument() async {
    // Pick an image file
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Upload to Firebase Storage
      final String? downloadUrl =
          await FirebaseStorageService.uploadClinicDocument(
        file: image,
        clinicId: 'CLIReg01', // This would be the actual clinic ID
        documentType:
            'permit', // Can be 'registration', 'permit', 'license', etc.
      );

      if (downloadUrl != null) {
        print('Clinic document uploaded successfully!');
        print('Download URL: $downloadUrl');
        // Save this URL to Firestore in your registration process
      } else {
        print('Failed to upload clinic document');
      }
    }
  }

  /// Example: Upload a profile picture
  static Future<void> uploadProfilePicture() async {
    // Pick an image file
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Upload to Firebase Storage
      final String? downloadUrl =
          await FirebaseStorageService.uploadProfilePicture(
        file: image,
        userId: 'USER123',
        userType: 'parent', // or 'clinic'
      );

      if (downloadUrl != null) {
        print('Profile picture uploaded successfully!');
        print('Download URL: $downloadUrl');
        // Save this URL to Firestore user profile
      } else {
        print('Failed to upload profile picture');
      }
    }
  }

  /// Example: List all files in a folder
  static Future<void> listUserFiles() async {
    final List<String> files =
        await FirebaseStorageService.listFiles('ParentsReg/PARReg01/documents');

    print('Found ${files.length} files:');
    for (String fileUrl in files) {
      print('File: $fileUrl');
    }
  }

  /// Example: Delete a file
  static Future<void> deleteFile(String downloadUrl) async {
    final bool success = await FirebaseStorageService.deleteFile(downloadUrl);

    if (success) {
      print('File deleted successfully');
    } else {
      print('Failed to delete file');
    }
  }
}
