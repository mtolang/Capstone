import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kindora/services/firebase_storage_service.dart';

/// Debug utility to test Firebase Storage uploads
/// Use this to isolate and test file upload functionality
class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({Key? key}) : super(key: key);

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  XFile? _selectedFile;
  String _status = 'No file selected';
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _selectedFile = image;
          _status = 'File selected: ${image.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error picking image: $e';
      });
    }
  }

  Future<void> _testUpload() async {
    if (_selectedFile == null) {
      setState(() {
        _status = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _status = 'Uploading file...';
    });

    try {
      print('Starting upload test...');
      print('File path: ${_selectedFile!.path}');
      print('File name: ${_selectedFile!.name}');
      
      // Test basic file upload
      final String? downloadUrl = await FirebaseStorageService.uploadFile(
        file: _selectedFile!,
        folderPath: 'test_uploads',
        fileName: 'test_${DateTime.now().millisecondsSinceEpoch}.${_selectedFile!.name.split('.').last}',
      );

      if (downloadUrl != null) {
        setState(() {
          _status = 'SUCCESS! File uploaded.\nURL: $downloadUrl';
        });
        print('Upload successful: $downloadUrl');
      } else {
        setState(() {
          _status = 'FAILED: Upload returned null';
        });
        print('Upload failed: returned null');
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR: $e';
      });
      print('Upload error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _testParentDocumentUpload() async {
    if (_selectedFile == null) {
      setState(() {
        _status = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _status = 'Testing parent document upload...';
    });

    try {
      print('Starting parent document upload test...');
      
      final String? downloadUrl = await FirebaseStorageService.uploadParentDocument(
        file: _selectedFile!,
        parentId: 'TEST_PARENT_01',
      );

      if (downloadUrl != null) {
        setState(() {
          _status = 'SUCCESS! Parent document uploaded.\nURL: $downloadUrl';
        });
        print('Parent upload successful: $downloadUrl');
      } else {
        setState(() {
          _status = 'FAILED: Parent upload returned null';
        });
        print('Parent upload failed: returned null');
      }
    } catch (e) {
      setState(() {
        _status = 'ERROR in parent upload: $e';
      });
      print('Parent upload error: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Storage Test'),
        backgroundColor: const Color(0xFF006A5B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Storage Upload Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // File picker
            ElevatedButton(
              onPressed: _isUploading ? null : _pickImage,
              child: const Text('Pick Image from Gallery'),
            ),
            const SizedBox(height: 10),
            
            // Show selected file
            if (_selectedFile != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(
                  File(_selectedFile!.path),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
            ],
            
            // Test buttons
            ElevatedButton(
              onPressed: (_selectedFile != null && !_isUploading) ? _testUpload : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Basic Upload'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: (_selectedFile != null && !_isUploading) ? _testParentDocumentUpload : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test Parent Document Upload'),
            ),
            const SizedBox(height: 20),
            
            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            
            if (_isUploading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
