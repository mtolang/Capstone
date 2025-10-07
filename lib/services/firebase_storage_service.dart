import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  ///
  /// [file] - The XFile to upload
  /// [folderPath] - The folder path in storage (e.g., 'parent_documents', 'clinic_documents')
  /// [fileName] - Optional custom file name. If null, uses original file name
  ///
  /// Returns the download URL of the uploaded file
  static Future<String?> uploadFile({
    required XFile file,
    required String folderPath,
    String? fileName,
  }) async {
    try {
      // Generate file name if not provided
      final String uploadFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

      // Create reference to storage location
      final Reference ref = _storage.ref().child('$folderPath/$uploadFileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(File(file.path));

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Upload parent government ID document
  ///
  /// [file] - The government ID file to upload
  /// [parentId] - The parent's user ID for organizing files
  ///
  /// Returns the download URL of the uploaded document
  static Future<String?> uploadParentDocument({
    required XFile file,
    required String parentId,
  }) async {
    return await uploadFile(
      file: file,
      folderPath: 'ParentsReg/$parentId/documents',
      fileName:
          'government_id_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}',
    );
  }

  /// Upload clinic registration documents
  ///
  /// [file] - The clinic document file to upload
  /// [clinicId] - The clinic's user ID for organizing files
  /// [documentType] - Type of document (e.g., 'registration', 'permit', 'license')
  ///
  /// Returns the download URL of the uploaded document
  static Future<String?> uploadClinicDocument({
    required XFile file,
    required String clinicId,
    String documentType = 'registration',
  }) async {
    return await uploadFile(
      file: file,
      folderPath: 'ClinicReg/$clinicId/documents',
      fileName:
          '${documentType}_${DateTime.now().millisecondsSinceEpoch}.${file.name.split('.').last}',
    );
  }

  /// Upload profile picture
  ///
  /// [file] - The profile picture file to upload
  /// [userId] - The user's ID
  /// [userType] - Type of user ('parent' or 'clinic')
  ///
  /// Returns the download URL of the uploaded profile picture
  static Future<String?> uploadProfilePicture({
    required XFile file,
    required String userId,
    required String userType,
  }) async {
    return await uploadFile(
      file: file,
      folderPath: '$userType/$userId/profile',
      fileName: 'profile_picture.${file.name.split('.').last}',
    );
  }

  /// Delete a file from Firebase Storage
  ///
  /// [downloadUrl] - The download URL of the file to delete
  ///
  /// Returns true if deletion was successful, false otherwise
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      // Get reference from download URL
      final Reference ref = _storage.refFromURL(downloadUrl);

      // Delete the file
      await ref.delete();

      print('File deleted successfully: $downloadUrl');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Get all files in a specific folder
  ///
  /// [folderPath] - The folder path to list files from
  ///
  /// Returns a list of download URLs for all files in the folder
  static Future<List<String>> listFiles(String folderPath) async {
    try {
      final Reference ref = _storage.ref().child(folderPath);
      final ListResult result = await ref.listAll();

      List<String> downloadUrls = [];

      for (Reference fileRef in result.items) {
        final String downloadUrl = await fileRef.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }

  /// Get file metadata
  ///
  /// [downloadUrl] - The download URL of the file
  ///
  /// Returns file metadata including size, creation time, etc.
  static Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata;
    } catch (e) {
      print('Error getting file metadata: $e');
      return null;
    }
  }
}
