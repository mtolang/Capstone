import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class PhotoSendFormScreen extends StatefulWidget {
  final String imagePath;

  const PhotoSendFormScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<PhotoSendFormScreen> createState() => _PhotoSendFormScreenState();
}

class _PhotoSendFormScreenState extends State<PhotoSendFormScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _selectedMaterial;
  Map<String, dynamic>? _selectedMaterialData;
  List<Map<String, dynamic>> _availableMaterials = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _parentId = '';
  String _clinicId = '';
  String _childId = '';
  String _childName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _parentId = prefs.getString('user_id') ?? 
                  prefs.getString('parent_id') ?? 
                  'ParAcc02'; // Default for testing
    });
    
    await _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First, try to get materials that match the parent ID
      print('Loading materials for parent: $_parentId');
      
      // Get materials from ClinicMaterials collection
      final clinicMaterialsQuery = await _firestore
          .collection('ClinicMaterials')
          .where('parentId', isEqualTo: _parentId)
          .where('isActive', isEqualTo: true)
          .get();

      // Also check the main Materials collection
      final generalMaterialsQuery = await _firestore
          .collection('Materials')
          .where('parentId', isEqualTo: _parentId)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> materials = [];

      // Add clinic materials
      for (var doc in clinicMaterialsQuery.docs) {
        var data = doc.data();
        data['docId'] = doc.id;
        data['collection'] = 'ClinicMaterials';
        materials.add(data);
        
        // Store child and clinic info for the form (from first material)
        if (_childId.isEmpty && data['childId'] != null) {
          _childId = data['childId'];
          _childName = data['childName'] ?? '';
          _clinicId = data['clinicId'] ?? '';
        }
      }

      // Add general materials
      for (var doc in generalMaterialsQuery.docs) {
        var data = doc.data();
        data['docId'] = doc.id;
        data['collection'] = 'Materials';
        materials.add(data);
        
        // Store child and clinic info if not already set
        if (_childId.isEmpty && data['childId'] != null) {
          _childId = data['childId'];
          _childName = data['childName'] ?? '';
          _clinicId = data['clinicId'] ?? '';
        }
      }

      // Sort materials by category and title
      materials.sort((a, b) {
        int categoryCompare = (a['category'] ?? '').compareTo(b['category'] ?? '');
        if (categoryCompare != 0) return categoryCompare;
        return (a['title'] ?? '').compareTo(b['title'] ?? '');
      });

      setState(() {
        _availableMaterials = materials;
        _isLoading = false;
      });

      print('Loaded ${materials.length} materials for parent $_parentId');
      if (materials.isNotEmpty) {
        print('Child ID: $_childId, Child Name: $_childName, Clinic ID: $_clinicId');
      }
    } catch (e) {
      print('Error loading materials: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading materials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendPhoto() async {
    if (_selectedMaterial == null || _selectedMaterialData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a material to associate with this photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // Upload photo to Firebase Storage
      final file = File(widget.imagePath);
      final fileName = path.basename(widget.imagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final uniqueFileName = 'therapy_${timestamp}_$fileName';

      final ref = FirebaseStorage.instance
          .ref()
          .child('therapy_photos')
          .child('parent_uploads')
          .child(uniqueFileName);

      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Get user information
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('parent_name') ?? 
                      prefs.getString('user_name') ?? 
                      'Unknown Parent';

      // Save to TherapyPhotos collection with material association
      await _firestore.collection('TherapyPhotos').add({
        'photoUrl': downloadUrl,
        'fileName': fileName,
        'uniqueFileName': uniqueFileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': userName,
        'uploadedById': _parentId,
        'uploaderType': 'parent',
        
        // Child and clinic information
        'childId': _childId,
        'childName': _childName,
        'clinicId': _clinicId,
        'parentId': _parentId,
        
        // Associated material information
        'associatedMaterialId': _selectedMaterialData!['docId'],
        'associatedMaterialTitle': _selectedMaterialData!['title'],
        'associatedMaterialCategory': _selectedMaterialData!['category'],
        'materialCollection': _selectedMaterialData!['collection'],
        
        // Photo metadata
        'fileSize': await file.length(),
        'storagePath': ref.fullPath,
        'category': 'therapy_progress',
        'isActive': true,
        'viewed': false,
        'tags': [
          'kindora_camera',
          'parent_upload',
          'therapy_progress',
          _selectedMaterialData!['category'],
        ],
        'notes': 'Photo taken for material: ${_selectedMaterialData!['title']}',
      });

      if (mounted) {
        Navigator.pop(context, 'sent');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo sent successfully to therapy team!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error sending photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Send Photo to Therapy Team',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF006A5B)),
                  SizedBox(height: 16),
                  Text('Loading your materials...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo Preview Section
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.photo_camera,
                                      color: const Color(0xFF006A5B),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Photo Preview',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF006A5B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(widget.imagePath),
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error_outline, color: Colors.grey),
                                              Text('Failed to load image'),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Material Selection Section
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_special,
                                      color: const Color(0xFF006A5B),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Associate with Material',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF006A5B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Select the therapy material this photo relates to:',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Dropdown
                                if (_availableMaterials.isEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange[700]),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'No materials found for your account',
                                                style: TextStyle(
                                                  color: Colors.orange[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please contact your therapist to ensure materials are assigned to your account ($_parentId)',
                                          style: TextStyle(
                                            color: Colors.orange[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _selectedMaterial,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(color: Color(0xFF006A5B)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          hintText: 'Select a material...',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        isExpanded: true,
                                        menuMaxHeight: 300,
                                    items: _availableMaterials.map((material) {
                                      String categoryDisplay = (material['category'] ?? 'unknown').toLowerCase();
                                      String categoryIcon = '';
                                      switch (categoryDisplay) {
                                        case 'speech':
                                          categoryIcon = '🗣️';
                                          break;
                                        case 'motor':
                                        case 'physical':
                                          categoryIcon = '🏃';
                                          break;
                                        case 'occupational':
                                          categoryIcon = '🧩';
                                          break;
                                        case 'cognitive':
                                          categoryIcon = '🧠';
                                          break;
                                        default:
                                          categoryIcon = '📚';
                                      }
                                      
                                      return DropdownMenuItem<String>(
                                        value: material['docId'],
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(categoryIcon, style: const TextStyle(fontSize: 16)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      material['title'] ?? 'Untitled Material',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 24),
                                                child: Text(
                                                  '${categoryDisplay.toUpperCase()} • ${material['collection']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedMaterial = value;
                                            _selectedMaterialData = _availableMaterials
                                                .firstWhere((material) => material['docId'] == value);
                                          });
                                        },
                                      ),
                                      
                                      // Show material count
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_availableMaterials.length} materials available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),

                                // Selected Material Details
                                if (_selectedMaterialData != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006A5B).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF006A5B).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Selected Material Details:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF006A5B),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildDetailRow('Title:', _selectedMaterialData!['title']),
                                        _buildDetailRow('Category:', _selectedMaterialData!['category']),
                                        _buildDetailRow('Description:', _selectedMaterialData!['description']),
                                        if (_selectedMaterialData!['childName'] != null)
                                          _buildDetailRow('Child:', _selectedMaterialData!['childName']),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Send Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSending || _selectedMaterial == null ? null : _sendPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006A5B),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSending
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sending...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Send to Therapy Team',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Not specified',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}