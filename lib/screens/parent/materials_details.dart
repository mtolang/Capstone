import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kindora_camera_screen.dart';

// Material Details Screen with integrated camera functionality
class MaterialDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> material;
  final String materialId;
  final Color categoryColor;

  const MaterialDetailsScreen({
    super.key,
    required this.material,
    required this.materialId,
    required this.categoryColor,
  });

  @override
  State<MaterialDetailsScreen> createState() => _MaterialDetailsScreenState();
}

class _MaterialDetailsScreenState extends State<MaterialDetailsScreen> {
  List<Map<String, dynamic>> _progressPhotos = [];
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _loadProgressPhotos();
  }

  Future<void> _loadProgressPhotos() async {
    setState(() {
      _loadingPhotos = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('user_id') ??
          prefs.getString('parent_id') ??
          'ParAcc02';

      // Load photos related to this material
      final photosQuery = await FirebaseFirestore.instance
          .collection('TherapyPhotos')
          .where('uploadedById', isEqualTo: parentId)
          .where('materialId', isEqualTo: widget.materialId)
          .orderBy('uploadedAt', descending: true)
          .limit(10)
          .get();

      setState(() {
        _progressPhotos = photosQuery.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        _loadingPhotos = false;
      });
    } catch (e) {
      print('Error loading progress photos: $e');
      setState(() {
        _loadingPhotos = false;
      });
    }
  }

  Future<void> _takePictureForMaterial() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KindoraCameraScreen(),
        ),
      );

      if (result != null && mounted) {
        String message = '';
        Color bgColor = Colors.green;

        switch (result) {
          case 'sent':
            message = '📸 Photo sent to therapy team successfully!';
            bgColor = Colors.green;
            // Save photo reference to material
            await _savePhotoReference('sent');
            break;
          case 'saved':
            message = '💾 Photo saved to device successfully!';
            bgColor = Colors.blue;
            await _savePhotoReference('saved');
            break;
          case 'deleted':
            message = '🗑️ Photo deleted';
            bgColor = Colors.red;
            break;
          default:
            message = 'Camera closed';
            bgColor = Colors.grey;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: bgColor,
            duration: const Duration(seconds: 3),
          ),
        );

        // Reload photos if photo was saved or sent
        if (result == 'sent' || result == 'saved') {
          _loadProgressPhotos();
        }
      }
    } catch (e) {
      print('Error opening camera: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open camera. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePhotoReference(String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('user_id') ??
          prefs.getString('parent_id') ??
          'ParAcc02';
      final parentName = prefs.getString('parent_name') ??
          prefs.getString('user_name') ??
          'Parent';

      // Save reference to this material in Firestore
      await FirebaseFirestore.instance.collection('MaterialProgress').add({
        'materialId': widget.materialId,
        'materialTitle': widget.material['title'],
        'materialCategory': widget.material['category'],
        'parentId': parentId,
        'parentName': parentName,
        'action': action,
        'actionType': 'photo_taken',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': 'Photo taken for material: ${widget.material['title']}',
      });
    } catch (e) {
      print('Error saving photo reference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String materialTitle = widget.material['title'] ?? 'Material';
    final String? description = widget.material['description'];
    final String category =
        widget.material['category']?.toString().toUpperCase() ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          materialTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.categoryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showMaterialInfo(),
            tooltip: 'Material Info',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Material Info Card
            _buildMaterialInfoCard(materialTitle, description, category),

            const SizedBox(height: 24),

            // Camera Section
            _buildCameraSection(),

            const SizedBox(height: 24),

            // Progress Photos Gallery
            _buildProgressPhotosGallery(),

            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialInfoCard(
      String title, String? description, String category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: widget.categoryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: $category',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Uploaded: ${_formatDate(widget.material['uploadedAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.camera_alt,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Therapy Progress Camera',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Take photos to document therapy progress and activities related to this material.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _takePictureForMaterial,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Progress Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPhotosGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Progress Photos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Spacer(),
            if (_loadingPhotos)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_progressPhotos.isEmpty && !_loadingPhotos)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_camera_back_outlined,
                  color: Colors.grey[500],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No progress photos yet. Take your first photo using the camera button above!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _progressPhotos.length,
              itemBuilder: (context, index) {
                final photo = _progressPhotos[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.photo,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            _formatDate(photo['uploadedAt']),
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final String? fileUrl =
        widget.material['downloadUrl'] ?? widget.material['fileUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: fileUrl != null ? () => _viewInApp() : null,
                icon: const Icon(Icons.visibility),
                label: const Text('View in App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePictureForMaterial,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.categoryColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'speech':
        return Icons.record_voice_over;
      case 'motor':
        return Icons.accessibility_new;
      case 'cognitive':
        return Icons.psychology;
      case 'general':
        return Icons.folder_open;
      default:
        return Icons.description;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _viewInApp() {
    final String? fileUrl =
        widget.material['downloadUrl'] ?? widget.material['fileUrl'];

    if (fileUrl != null && fileUrl.isNotEmpty) {
      // Navigate to PDF viewer or appropriate viewer
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${widget.material['title']}'),
          backgroundColor: widget.categoryColor,
        ),
      );
      // TODO: Implement in-app viewer navigation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File URL not available for this material.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMaterialInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.material['title'] ?? 'Material Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${widget.material['category']}'),
            if (widget.material['description'] != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${widget.material['description']}'),
            ],
            const SizedBox(height: 8),
            Text('Uploaded: ${_formatDate(widget.material['uploadedAt'])}'),
            if (widget.material['fileSize'] != null) ...[
              const SizedBox(height: 8),
              Text('File Size: ${widget.material['fileSize']} bytes'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Enhanced Material Viewer based on MaterialDetailsScreen
class MaterialViewer extends StatefulWidget {
  final String materialTitle;
  final Map<String, dynamic>? materialData;
  final String? materialId;
  final Color? categoryColor;

  const MaterialViewer({
    super.key, 
    required this.materialTitle,
    this.materialData,
    this.materialId,
    this.categoryColor,
  });

  @override
  State<MaterialViewer> createState() => _MaterialViewerState();
}

class _MaterialViewerState extends State<MaterialViewer> {
  late Map<String, dynamic> _material;
  late String _materialId;
  late Color _categoryColor;

  @override
  void initState() {
    super.initState();
    _initializeMaterial();
  }

  void _initializeMaterial() {
    // Use provided data or create a default material object
    _material = widget.materialData ?? {
      'title': widget.materialTitle,
      'category': 'general',
      'description': 'Material content for ${widget.materialTitle}',
      'fileName': '${widget.materialTitle}.pdf',
      'uploadedAt': Timestamp.now(),
      'downloadUrl': null,
      'fileUrl': null,
    };
    
    _materialId = widget.materialId ?? 'default_material_id';
    _categoryColor = widget.categoryColor ?? const Color(0xFF006A5B);
  }

  @override
  Widget build(BuildContext context) {
    final String materialTitle = _material['title'] ?? widget.materialTitle;
    final String? description = _material['description'];
    final String category = _material['category']?.toString().toUpperCase() ?? 'GENERAL';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          materialTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _categoryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showMaterialInfo(),
            tooltip: 'Material Info',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Info Card
                _buildMaterialInfoCard(materialTitle, description, category),

                const SizedBox(height: 24),

                // How to view this material section
                _buildViewInstructions(),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 24),

                // Additional Info Section
                _buildAdditionalInfo(),

                const SizedBox(height: 80), // Extra space for camera button
              ],
            ),
          ),
          // Camera button at center bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: _buildCameraButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialInfoCard(String title, String? description, String category) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _categoryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: $category',
                        style: TextStyle(
                          fontSize: 14,
                          color: _categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Uploaded: ${_formatDate(_material['uploadedAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'How to view this material:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Tap "View in App" to view the PDF directly in the app',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '• Tap "Camera" to take progress photos related to this material',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            '• Photos can be sent to your therapy team or saved to your device',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final String? fileUrl = _material['downloadUrl'] ?? _material['fileUrl'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: fileUrl != null ? () => _viewInApp() : null,
                icon: const Icon(Icons.visibility),
                label: const Text('View in App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _launchCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _categoryColor.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('File Name', _material['fileName'] ?? 'Unknown'),
            _buildInfoRow('File Size', _formatFileSize(_material['fileSize'])),
            _buildInfoRow('Category', _material['category'] ?? 'General'),
            _buildInfoRow('Upload Date', _formatDate(_material['uploadedAt'])),
            if (_material['downloadCount'] != null)
              _buildInfoRow('Downloads', '${_material['downloadCount']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'speech':
        return Icons.record_voice_over;
      case 'motor':
      case 'occupational':
        return Icons.accessibility_new;
      case 'cognitive':
        return Icons.psychology;
      case 'physical':
        return Icons.fitness_center;
      case 'general':
        return Icons.folder_open;
      default:
        return Icons.description;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatFileSize(dynamic fileSize) {
    if (fileSize == null) return 'Unknown size';
    if (fileSize is String) return fileSize;
    if (fileSize is int) {
      if (fileSize < 1024) return '$fileSize B';
      if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return 'Unknown size';
  }

  void _viewInApp() {
    final String? fileUrl = _material['downloadUrl'] ?? _material['fileUrl'];

    if (fileUrl != null && fileUrl.isNotEmpty) {
      // Show loading indicator first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening: ${_material['title']}'),
          backgroundColor: _categoryColor,
        ),
      );
      // TODO: Implement in-app PDF viewer navigation
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File URL not available for this material.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMaterialInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_material['title'] ?? 'Material Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Material ID: $_materialId'),
            const SizedBox(height: 8),
            Text('Category: ${_material['category']}'),
            if (_material['description'] != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${_material['description']}'),
            ],
            const SizedBox(height: 8),
            Text('Uploaded: ${_formatDate(_material['uploadedAt'])}'),
            if (_material['fileSize'] != null) ...[
              const SizedBox(height: 8),
              Text('File Size: ${_formatFileSize(_material['fileSize'])}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Camera functionality for MaterialViewer
  Widget _buildCameraButton() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _categoryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _openKindoraCamera,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // Camera functionality
  Future<void> _openKindoraCamera() async {
    // Show camera options dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Kindora Camera',
            style: TextStyle(
              color: Color(0xFF006A5B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Take a photo for "${_material['title']}" to share with your therapy team or save therapy progress.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _launchCamera();
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Open Camera',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _categoryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchCamera() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => KindoraCameraScreen(),
        ),
      );

      if (result == 'sent') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo sent successfully to therapy team!'),
            backgroundColor: _categoryColor,
            duration: const Duration(seconds: 3),
          ),
        );
        // Save photo reference for this material
        _savePhotoReference('sent');
      } else if (result == 'saved') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo saved to device!'),
            backgroundColor: _categoryColor,
            duration: const Duration(seconds: 3),
          ),
        );
        // Save photo reference for this material
        _savePhotoReference('saved');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening camera: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _savePhotoReference(String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('user_id') ??
          prefs.getString('parent_id') ??
          'ParAcc02';
      final parentName = prefs.getString('parent_name') ??
          prefs.getString('user_name') ??
          'Parent';

      // Save reference to this material in Firestore
      await FirebaseFirestore.instance.collection('MaterialProgress').add({
        'materialId': _materialId,
        'materialTitle': _material['title'],
        'materialCategory': _material['category'],
        'parentId': parentId,
        'parentName': parentName,
        'action': action,
        'actionType': 'photo_taken',
        'timestamp': FieldValue.serverTimestamp(),
        'notes': 'Photo taken for material: ${_material['title']}',
      });
    } catch (e) {
      print('Error saving photo reference: $e');
    }
  }
}
