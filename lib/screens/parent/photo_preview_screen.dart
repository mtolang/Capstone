import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Photo Preview Screen - Delete, Save, Send
class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewScreen({Key? key, required this.imagePath})
      : super(key: key);

  Future<void> _deletePhoto(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Photo',
          style: TextStyle(color: Color(0xFF006A5B)),
        ),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo deleted'),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePhoto(BuildContext context) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF006A5B)),
                SizedBox(height: 16),
                Text('Saving photo...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Get the app's document directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photoDir = path.join(appDir.path, 'kindora_photos');

      // Create directory if it doesn't exist
      await Directory(photoDir).create(recursive: true);

      // Generate filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'kindora_$timestamp.jpg';
      final String savedPath = path.join(photoDir, fileName);

      // Copy file to saved location
      final File originalFile = File(imagePath);
      await originalFile.copy(savedPath);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, 'saved');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendPhoto(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Send Photo',
          style: TextStyle(color: Color(0xFF006A5B)),
        ),
        content: const Text(
          'Do you want to send this photo to your therapy team? They will be able to view it in your session records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006A5B),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF006A5B)),
                SizedBox(height: 16),
                Text('Sending photo to therapy team...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Upload to your system
      await _uploadToServer(imagePath);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo sent successfully to therapy team!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, 'sent');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadToServer(String filePath) async {
    try {
      // Get user information from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ??
          prefs.getString('parent_id') ??
          'unknown_user';
      final userName = prefs.getString('parent_name') ??
          prefs.getString('user_name') ??
          'Unknown User';

      final file = File(filePath);
      final fileName = path.basename(filePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uniqueFileName = 'kindora_${timestamp}_$fileName';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('therapy_photos')
          .child('parent_uploads')
          .child(uniqueFileName);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('TherapyPhotos').add({
        'photoUrl': downloadUrl,
        'fileName': fileName,
        'uniqueFileName': uniqueFileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': userName,
        'uploadedById': userId,
        'uploaderType': 'parent',
        'sessionId': null, // Can be linked to therapy session later
        'clientId': userId, // Link to the parent's child
        'notes': 'Photo taken with Kindora camera app',
        'isActive': true,
        'fileSize': await file.length(),
        'storagePath': ref.fullPath,
        'category': 'progress_photo',
        'tags': ['kindora_camera', 'parent_upload', 'therapy_progress'],
      });

      print('Photo uploaded successfully to Firebase');
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Photo Preview',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Photo Preview
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF006A5B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Delete Button
                _ActionButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.red,
                  onPressed: () => _deletePhoto(context),
                ),

                // Save Button
                _ActionButton(
                  icon: Icons.save,
                  label: 'Save',
                  color: Colors.blue,
                  onPressed: () => _savePhoto(context),
                ),

                // Send Button
                _ActionButton(
                  icon: Icons.send,
                  label: 'Send',
                  color: Colors.green,
                  onPressed: () => _sendPhoto(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 4,
          ),
          child: Icon(
            icon,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
