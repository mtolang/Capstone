import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GiveMaterialsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String? parentId;

  const GiveMaterialsScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
    this.parentId,
  }) : super(key: key);

  @override
  State<GiveMaterialsScreen> createState() => _GiveMaterialsScreenState();
}

class _GiveMaterialsScreenState extends State<GiveMaterialsScreen> {
  String? _clinicId;
  final Set<String> _selectedMaterials = {};
  String _selectedCategory = 'all';
  bool _isSending = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'all', 'label': 'All', 'icon': Icons.apps, 'color': Colors.grey},
    {
      'value': 'motor',
      'label': 'Motor',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFF4CAF50)
    },
    {
      'value': 'speech',
      'label': 'Speech',
      'icon': Icons.record_voice_over,
      'color': const Color(0xFF2196F3)
    },
    {
      'value': 'cognitive',
      'label': 'Cognitive',
      'icon': Icons.psychology,
      'color': const Color(0xFF9C27B0)
    },
    {
      'value': 'general',
      'label': 'General',
      'icon': Icons.folder,
      'color': const Color(0xFFFF9800)
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadClinicId();
  }

  Future<void> _loadClinicId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clinicId = prefs.getString('clinic_id') ??
          prefs.getString('user_id') ??
          prefs.getString('clinicId') ??
          prefs.getString('userId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006D63),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Give Materials',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'To: ${widget.patientName}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedMaterials.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedMaterials.length} selected',
                    style: const TextStyle(
                      color: Color(0xFF006D63),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _clinicId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(child: _buildMaterialsList()),
              ],
            ),
      floatingActionButton: _selectedMaterials.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSending ? null : _sendMaterialsToPatient,
              backgroundColor: const Color(0xFF006D63),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_isSending ? 'Sending...' : 'Send Materials'),
            ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 120,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Select Materials',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : category['color'] as Color,
                        ),
                        const SizedBox(width: 6),
                        Text(category['label'] as String),
                      ],
                    ),
                    selectedColor: category['color'] as Color,
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category['value'] as String;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ClinicMaterials')
          .where('clinicId', isEqualTo: _clinicId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading materials',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No materials available',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Filter materials by category on the client side
        var filteredDocs = snapshot.data!.docs;
        if (_selectedCategory != 'all') {
          filteredDocs = filteredDocs.where((doc) {
            final material = doc.data() as Map<String, dynamic>;
            return material['category'] == _selectedCategory;
          }).toList();
        }

        // Sort by uploadedAt
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['uploadedAt'] as Timestamp?;
          final bTime = bData['uploadedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // descending order
        });

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No materials in this category',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final material = doc.data() as Map<String, dynamic>;
            final materialId = doc.id;
            final isSelected = _selectedMaterials.contains(materialId);

            return _buildMaterialCard(material, materialId, isSelected);
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(
      Map<String, dynamic> material, String materialId, bool isSelected) {
    final category = material['category'] ?? 'general';
    final categoryData = _categories.firstWhere(
      (c) => c['value'] == category,
      orElse: () => _categories.last,
    );

    final uploadedAt = material['uploadedAt'] as Timestamp?;
    final dateStr = uploadedAt != null
        ? '${uploadedAt.toDate().day}/${uploadedAt.toDate().month}/${uploadedAt.toDate().year}'
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF006D63) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedMaterials.remove(materialId);
            } else {
              _selectedMaterials.add(materialId);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF006D63)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF006D63) : Colors.white,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              // File icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (categoryData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getFileIcon(material['fileName'] ?? ''),
                  color: categoryData['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Material info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (material['description'] != null &&
                        material['description'].toString().isNotEmpty)
                      Text(
                        material['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                (categoryData['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (categoryData['label'] as String).toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: categoryData['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _sendMaterialsToPatient() async {
    if (_selectedMaterials.isEmpty || _clinicId == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      String? parentId = widget.parentId;
      String? parentName;

      // If parentId was passed directly from patient profile, use it
      if (parentId != null && parentId.isNotEmpty) {
        print('✅ Using provided Parent ID: $parentId');
      } else {
        // Otherwise, search for it in AcceptedBooking
        // Get the parent ID from the patient's AcceptedBooking record
        print('🔍 Searching for booking - Patient Name: ${widget.patientName}, Patient ID: ${widget.patientId}, Clinic ID: $_clinicId');
      
      // Get all bookings and search manually for flexibility
      print('⚠️ Fetching all AcceptedBooking records...');
      final allBookings = await FirebaseFirestore.instance
          .collection('AcceptedBooking')
          .get();
      
      print('� Total bookings in database: ${allBookings.docs.length}');
      
      // Search through all bookings to find a match
      QueryDocumentSnapshot? matchingBooking;
      
      for (var doc in allBookings.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final childName = data['childName']?.toString().toLowerCase() ?? '';
        final patientName = widget.patientName.toLowerCase();
        
        print('  📄 Checking booking ${doc.id}:');
        print('    - childName: ${data['childName']}');
        print('    - Match? ${childName == patientName}');
        
        // Check if this booking matches our patient
        if (childName == patientName) {
          matchingBooking = doc;
          print('  ✅ MATCH FOUND!');
          break;
        }
      }

      if (matchingBooking == null) {
        print('❌ No matching booking found!');
        print('📋 Available children in bookings:');
        for (var doc in allBookings.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('  - "${data['childName']}" (ID: ${doc.id})');
        }
        throw Exception('Could not find booking for patient "${widget.patientName}"');
      }
      
      final bookingData = matchingBooking.data() as Map<String, dynamic>;
      print('✅ Found matching booking: ${matchingBooking.id}');
      print('📋 Booking data keys: ${bookingData.keys.toList()}');

        // Extract parent ID from parentInfo map        
        if (bookingData.containsKey('parentInfo') && bookingData['parentInfo'] != null) {
          final parentInfo = bookingData['parentInfo'] as Map<String, dynamic>;
          parentId = parentInfo['parentId'] as String?;
          parentName = parentInfo['parentName'] as String?;
          print('👤 From parentInfo - Parent ID: $parentId, Name: $parentName');
        } else if (bookingData.containsKey('parentId')) {
          // Fallback in case some records have direct parentId
          parentId = bookingData['parentId'] as String?;
          parentName = bookingData['parentName'] as String?;
          print('👤 Direct fields - Parent ID: $parentId, Name: $parentName');
        }

        if (parentId == null || parentId.isEmpty) {
          print('❌ Available fields: ${bookingData.keys.toList()}');
          throw Exception('Parent ID not found in booking. Available fields: ${bookingData.keys.toList()}');
        }
      }

      print('✅ Using Parent ID: $parentId');

      final prefs = await SharedPreferences.getInstance();
      final therapistName = prefs.getString('therapist_name') ?? 
                           prefs.getString('name') ?? 
                           'Therapist';
      final clinicName = prefs.getString('clinic_name') ?? 'Clinic';

      print('💾 Sending ${_selectedMaterials.length} material(s) to Materials collection...');
      print('   Clinic: $_clinicId, Parent: $parentId');

      // Create a batch to send all materials at once
      final batch = FirebaseFirestore.instance.batch();
      int materialCount = 0;

      for (final materialId in _selectedMaterials) {
        // Get the material details from ClinicMaterials
        final materialDoc = await FirebaseFirestore.instance
            .collection('ClinicMaterials')
            .doc(materialId)
            .get();

        if (!materialDoc.exists) {
          print('⚠️ Material $materialId not found, skipping...');
          continue;
        }

        final materialData = materialDoc.data() as Map<String, dynamic>;
        materialCount++;

        // Create a document in Materials collection with clinicId and parentId
        // This ensures only this parent can see materials from this clinic
        final materialRef =
            FirebaseFirestore.instance.collection('Materials').doc();

        batch.set(materialRef, {
          // Original material reference
          'clinicMaterialId': materialId,
          
          // Access control - IMPORTANT: both clinicId and parentId determine access
          'clinicId': _clinicId,
          'parentId': parentId,
          
          // Clinic and therapist info
          'clinicName': clinicName,
          'therapistName': therapistName,
          
          // Parent and child info
          'parentName': parentName ?? 'Parent',
          'childId': widget.patientId,
          'childName': widget.patientName,
          
          // Material details
          'title': materialData['title'] ?? 'Untitled',
          'description': materialData['description'] ?? '',
          'category': materialData['category'] ?? 'general',
          'downloadUrl': materialData['downloadUrl'] ?? '',
          'fileName': materialData['fileName'] ?? 'file',
          'fileSize': materialData['fileSize'] ?? 0,
          'fileExtension': materialData['fileExtension'] ?? '',
          'mimeType': materialData['mimeType'] ?? '',
          
          // File type flags
          'isImage': materialData['isImage'] ?? false,
          'isVideo': materialData['isVideo'] ?? false,
          'isDocument': materialData['isDocument'] ?? false,
          
          // Timestamps and status
          'uploadedAt': materialData['uploadedAt'], // Original upload time
          'sharedAt': FieldValue.serverTimestamp(), // When it was shared
          'isActive': true,
          'viewed': false,
          'downloaded': false,
          'downloadCount': 0,
          
          // Tags for search
          'tags': materialData['tags'] ?? [],
        });
        
        print('  ✓ Prepared: ${materialData['title']} (Clinic: $_clinicId → Parent: $parentId)');
      }

      if (materialCount == 0) {
        throw Exception('No valid materials found to send');
      }

      print('📤 Committing batch write to Materials collection...');
      await batch.commit();
      print('✅ Successfully sent $materialCount material(s) to Materials collection!');
      print('🔍 Check Firebase Console > Materials collection');
      print('   Filter by: clinicId = $_clinicId AND parentId = $parentId');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ $materialCount material(s) sent to ${widget.patientName}'),
            backgroundColor: const Color(0xFF006D63),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error sending materials: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
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
}
