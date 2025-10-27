import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ClinicMaterials extends StatefulWidget {
  const ClinicMaterials({Key? key}) : super(key: key);

  @override
  State<ClinicMaterials> createState() => _ClinicMaterialsState();
}

class _ClinicMaterialsState extends State<ClinicMaterials> {
  String? _clinicId;

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mq = MediaQuery.of(context).size;
          return Stack(
            children: [
              // Top color fill to match ellipse (covers the gap)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 120, // Covers area above ellipse
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF006A5B), // Teal green to match ellipse
                        Color(0xFF006A5B), // Slightly lighter green
                      ],
                    ),
                  ),
                ),
              ),

              // Top full-width ellipse image (positioned lower to show header)
              Positioned(
                top: 80, // Moved down from 0 to show header
                left: 0,
                right: 0,
                child: ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                      height: mq.height * 0.20), // Reduced from 0.22
                  child: Image.asset(
                    'asset/images/Ellipse 1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),

              // Bottom full-width ellipse image (no gradient)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints.tightFor(height: mq.height * 0.20),
                  child: Image.asset(
                    'asset/images/Ellipse 2.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),

              // Floating Add Button
              Positioned(
                bottom: 30,
                right: 30,
                child: _buildFloatingAddButton(),
              ),
            ],
          ); // close Stack
        }, // close builder
      ), // close LayoutBuilder
    ); // close Scaffold
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding from 20
      // Removed blue gradient decoration - only ellipse background shows
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 22), // Reduced size
              ),
              const Expanded(
                child: Text(
                  'Materials Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => _showSearchDialog(),
                icon: const Icon(Icons.search,
                    color: Colors.white, size: 22), // Reduced size
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced from 10
          const Text(
            'Organize and share therapy materials with parents',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14, // Reduced from 16
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Material Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95, // slightly taller tiles
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMaterialFolder(
                  'Motor',
                  Icons.accessibility_new,
                  const Color(0xFF48BB78),
                  'Fine & Gross Motor Skills',
                ),
                _buildMaterialFolder(
                  'Speech',
                  Icons.record_voice_over,
                  const Color(0xFF4A90E2),
                  'Speech & Language Therapy',
                ),
                _buildMaterialFolder(
                  'Cognitive',
                  Icons.psychology,
                  const Color(0xFF9F7AEA),
                  'Cognitive Development',
                ),
                _buildMaterialFolder(
                  'General',
                  Icons.folder_open,
                  const Color(0xFFED8936),
                  'General Resources',
                ),
              ],
            ),
          ),
          const SizedBox(height: 100), // Space for floating button
        ],
      ),
    );
  }

  Widget _buildMaterialFolder(
      String title, IconData icon, Color color, String subtitle) {
    return StreamBuilder<QuerySnapshot>(
      stream: _clinicId != null
          ? ClinicMaterialsService.getMaterialsByCategory(
              _clinicId!, title.toLowerCase())
          : null,
      builder: (context, snapshot) {
        int materialCount = 0;
        if (snapshot.hasData) {
          materialCount = snapshot.data!.docs.length;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openMaterialFolder(title, color),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$materialCount files',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingAddButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D5016), // Dark green theme
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5016).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: _showAddMaterialDialog,
          child: Container(
            width: 60,
            height: 60,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _openMaterialFolder(String category, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialFolderView(
          category: category,
          categoryColor: color,
          clinicId: _clinicId,
        ),
      ),
    );
  }

  void _showAddMaterialDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddMaterialDialog(
          clinicId: _clinicId,
          onMaterialAdded: () {
            setState(() {}); // Refresh the page
          },
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SearchMaterialsDialog(clinicId: _clinicId);
      },
    );
  }
}

// Material Folder View Page
class MaterialFolderView extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String? clinicId;

  const MaterialFolderView({
    Key? key,
    required this.category,
    required this.categoryColor,
    required this.clinicId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: categoryColor,
        title: Text(
          '$category Materials',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: clinicId != null
            ? ClinicMaterialsService.getMaterialsByCategory(
                clinicId!, category.toLowerCase())
            : null,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: categoryColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No materials in this folder yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some materials to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
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
                  Icon(Icons.folder_open,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No materials in this folder yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some materials to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final material =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildMaterialCard(
                  context, material, snapshot.data!.docs[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(
      BuildContext context, Map<String, dynamic> material, String docId) {
    final uploadedAt = material['uploadedAt'] as Timestamp?;
    final dateStr = uploadedAt != null
        ? '${uploadedAt.toDate().day}/${uploadedAt.toDate().month}/${uploadedAt.toDate().year}'
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _openMaterial(context, material),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(material['fileName'] ?? ''),
                    color: categoryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
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
                          Icon(Icons.schedule,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.file_present,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            _getFileExtension(material['fileName'] ?? '')
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) =>
                      _handleMenuAction(context, value, docId, material),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
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

  String _getFileExtension(String fileName) {
    return fileName.split('.').last;
  }

  void _openMaterial(
      BuildContext context, Map<String, dynamic> material) async {
    final downloadUrl = material['downloadUrl'] as String?;
    final materialId = material['materialId'] as String?;
    final fileName = material['fileName'] as String?;

    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Increment download count
      if (materialId != null && clinicId != null) {
        await ClinicMaterialsService.incrementDownloadCount(
            clinicId!, materialId);
      }

      // Show options for different file types
      final isImage = material['isImage'] == true;

      if (isImage) {
        // Show image in a dialog
        _showImageDialog(
            context, downloadUrl, material['title'] ?? fileName ?? 'Image');
      } else {
        // For other files, show download/open options
        _showFileOptionsDialog(
            context, downloadUrl, material['title'] ?? fileName ?? 'File');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(title, style: const TextStyle(fontSize: 16)),
                backgroundColor: categoryColor,
                foregroundColor: Colors.white,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileOptionsDialog(
      BuildContext context, String downloadUrl, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Open $fileName'),
        content: const Text('Choose how you want to open this file:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Try to launch the URL (will open in browser/default app)
                // TODO: Add url_launcher package and use launchUrl(uri)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Opening $fileName...'),
                    backgroundColor: categoryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error opening file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action, String docId,
      Map<String, dynamic> material) {
    switch (action) {
      case 'share':
        // TODO: Implement sharing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing ${material['title']}...'),
            backgroundColor: categoryColor,
          ),
        );
        break;
      case 'edit':
        // TODO: Implement editing
        _showEditMaterialDialog(context, docId, material);
        break;
      case 'delete':
        _showDeleteConfirmation(context, docId, material['title']);
        break;
    }
  }

  void _showEditMaterialDialog(
      BuildContext context, String docId, Map<String, dynamic> material) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon...')),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Material'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  // Use the new service method for safe deletion
                  final success = await ClinicMaterialsService.deleteMaterial(
                      clinicId!, docId);

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$title deleted successfully'),
                        backgroundColor: categoryColor,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Could not delete material'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting material: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Add Material Dialog
class AddMaterialDialog extends StatefulWidget {
  final String? clinicId;
  final VoidCallback onMaterialAdded;

  const AddMaterialDialog({
    Key? key,
    required this.clinicId,
    required this.onMaterialAdded,
  }) : super(key: key);

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'motor';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'motor',
      'label': 'Motor Skills',
      'icon': Icons.accessibility_new
    },
    {
      'value': 'speech',
      'label': 'Speech Therapy',
      'icon': Icons.record_voice_over
    },
    {
      'value': 'cognitive',
      'label': 'Cognitive Development',
      'icon': Icons.psychology
    },
    {
      'value': 'general',
      'label': 'General Resources',
      'icon': Icons.folder_open
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(
            maxWidth: 500, maxHeight: 700), // Increased height from 600
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AppBar for better navigation
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D5016), // Dark green theme
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.white,
                  tooltip: 'Back',
                ),
                title: const Text(
                  'Add Material',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.white,
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText:
                            'Material Title *', // Added asterisk to show required
                        hintText: 'Enter a descriptive title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                        errorText:
                            _titleController.text.trim().isEmpty && _isUploading
                                ? 'Title is required'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16

                    // Description field
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2, // Reduced from 3 to save space
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Brief description of the material...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 16

                    // Category selection
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories.map((category) {
                        final isSelected =
                            _selectedCategory == category['value'];
                        return FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category['icon'],
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(
                                        0xFF2D5016), // Dark green theme
                              ),
                              const SizedBox(width: 4),
                              Text(category['label']),
                            ],
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category['value'];
                            });
                          },
                          selectedColor:
                              const Color(0xFF2D5016), // Dark green theme
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF2D5016), // Dark green theme
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12), // Reduced from 20

                    // File selection
                    Container(
                      padding: const EdgeInsets.all(12), // Reduced from 16
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (_selectedFile == null) ...[
                            Icon(
                              Icons.cloud_upload,
                              size: 40, // Reduced from 48
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 6), // Reduced from 8
                            Text(
                              'No file selected',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6), // Reduced from 8
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Choose File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF2D5016), // Dark green theme
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  color: const Color(
                                      0xFF2D5016), // Dark green theme
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFile!.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedFile = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 24

                    // Upload button
                    ElevatedButton(
                      onPressed: _isUploading ||
                              _selectedFile == null ||
                              _titleController.text.trim().isEmpty
                          ? null
                          : _uploadMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF2D5016), // Dark green theme
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Uploading...'),
                              ],
                            )
                          : const Text(
                              'Submit Material',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      print('🔍 Starting file picker...'); // Debug log

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'jpg',
          'jpeg',
          'png',
          'mp4',
          'mp3',
          'wav'
        ],
        withData: true, // Ensure bytes are loaded
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('📁 File selected: ${file.name}'); // Debug log
        print('📏 File size: ${file.size} bytes'); // Debug log
        print('🔗 Has bytes: ${file.bytes != null}'); // Debug log
        print('📂 Has path: ${file.path != null}'); // Debug log

        // Validate file
        if (file.size <= 0) {
          throw Exception('Selected file is empty');
        }

        if (file.bytes == null && file.path == null) {
          throw Exception('Cannot access file data');
        }

        setState(() {
          _selectedFile = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selected: ${file.name}'),
            backgroundColor: const Color(0xFF2D5016),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        print('❌ No file selected or result is null'); // Debug log
      }
    } catch (e) {
      print('❌ Error picking file: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadMaterial() async {
    if (_selectedFile == null ||
        widget.clinicId == null ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields and select a file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional validation: Check if file has data
    if (_selectedFile!.bytes == null && _selectedFile!.path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Selected file has no data. Please try selecting the file again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      print('🚀 Starting material upload process...'); // Debug log
      print('📁 File name: ${_selectedFile!.name}'); // Debug log
      print('📏 File size: ${_selectedFile!.size} bytes'); // Debug log
      print('🔗 Has bytes: ${_selectedFile!.bytes != null}'); // Debug log
      print('📂 Has path: ${_selectedFile!.path != null}'); // Debug log

      // Get clinic and user information
      final prefs = await SharedPreferences.getInstance();
      final clinicName = prefs.getString('clinic_name') ?? 'Unknown Clinic';
      final uploaderName = prefs.getString('therapist_name') ?? 'Unknown User';
      final uploaderId = prefs.getString('therapist_id') ??
          prefs.getString('user_id') ??
          'unknown';

      // Generate clinic-specific unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _selectedFile!.name.split('.').last;
      final clinicPrefix = widget.clinicId!.length > 8
          ? widget.clinicId!.substring(0, 8)
          : widget.clinicId!;
      final uniqueFileName =
          'clinic_${clinicPrefix}_${timestamp}_${_selectedCategory}_${_selectedFile!.name}';

      print('Uploading file with unique name: $uniqueFileName'); // Debug log

      // Upload file to Firebase Storage with organized structure
      final storageRef = FirebaseStorage.instance.ref().child(
          'clinic_materials/${widget.clinicId}/${_selectedCategory}/$uniqueFileName');

      print('Uploading file to Storage: ${storageRef.fullPath}'); // Debug log

      // Check if bytes are available, if not try to read from path
      UploadTask uploadTask;
      if (_selectedFile!.bytes != null) {
        print('Uploading using bytes data'); // Debug log
        uploadTask = storageRef.putData(_selectedFile!.bytes!);
      } else if (_selectedFile!.path != null) {
        print('Uploading using file path: ${_selectedFile!.path}'); // Debug log
        final file = File(_selectedFile!.path!);
        uploadTask = storageRef.putFile(file);
      } else {
        throw Exception('No file data available - neither bytes nor path');
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print(
          'File uploaded successfully. Download URL: $downloadUrl'); // Debug log

      // Create comprehensive metadata for both collections
      final materialData = {
        // Basic information
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,

        // File information
        'fileName': _selectedFile!.name,
        'originalFileName': _selectedFile!.name,
        'uniqueFileName': uniqueFileName,
        'fileSize': _selectedFile!.size,
        'fileExtension': fileExtension,
        'mimeType': _getFileMimeType(fileExtension),

        // Storage information
        'downloadUrl': downloadUrl,
        'storagePath': storageRef.fullPath,

        // Clinic and user information
        'clinicId': widget.clinicId,
        'clinicName': clinicName,
        'uploadedBy': uploaderName,
        'uploadedById': uploaderId,

        // Timestamps
        'uploadedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),

        // Status and metadata
        'isActive': true,
        'isPublic': false,
        'downloadCount': 0,
        'tags': _generateTags(_selectedCategory, _titleController.text.trim()),

        // Additional metadata based on file type
        if (_isImageFile(fileExtension)) ...{
          'isImage': true,
          'thumbnailUrl': downloadUrl,
        },
        if (_isVideoFile(fileExtension)) ...{
          'isVideo': true,
          'duration': null,
        },
        if (_isDocumentFile(fileExtension)) ...{
          'isDocument': true,
          'pageCount': null,
        },
      };

      print(
          'Saving material data to both collections: $materialData'); // Debug log

      // Save to both collections simultaneously
      final batch = FirebaseFirestore.instance.batch();

      // Save to ClinicMaterials collection (clinic-specific)
      final clinicMaterialRef =
          FirebaseFirestore.instance.collection('ClinicMaterials').doc();
      batch.set(clinicMaterialRef, {
        ...materialData,
        'materialId': clinicMaterialRef.id,
      });

      // Save to Materials collection (global, with clinic reference)
      final materialRef =
          FirebaseFirestore.instance.collection('Materials').doc();
      batch.set(materialRef, {
        ...materialData,
        'materialId': materialRef.id,
        'clinicMaterialId':
            clinicMaterialRef.id, // Reference to clinic-specific document
        'isClinicMaterial': true,
      });

      // Execute batch write
      await batch.commit();

      print(
          'Material saved to both Firestore collections successfully'); // Debug log
      print('ClinicMaterials ID: ${clinicMaterialRef.id}'); // Debug log
      print('Materials ID: ${materialRef.id}'); // Debug log

      Navigator.pop(context);
      widget.onMaterialAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Material submitted successfully to both database and storage!'),
          backgroundColor: Color(0xFF2D5016), // Dark green theme
        ),
      );
    } catch (e) {
      print('❌ Error uploading material: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Helper functions for file type detection and metadata
  String _getFileMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }

  bool _isImageFile(String extension) {
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
        .contains(extension.toLowerCase());
  }

  bool _isVideoFile(String extension) {
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']
        .contains(extension.toLowerCase());
  }

  bool _isDocumentFile(String extension) {
    return ['pdf', 'doc', 'docx', 'txt', 'rtf']
        .contains(extension.toLowerCase());
  }

  List<String> _generateTags(String category, String title) {
    final tags = <String>[category];

    // Add tags based on title words
    if (title.isNotEmpty) {
      final titleWords = title.toLowerCase().split(' ');
      tags.addAll(titleWords.where((word) => word.length > 2));
    }

    // Add category-specific tags
    switch (category) {
      case 'motor':
        tags.addAll(['fine motor', 'gross motor', 'movement', 'coordination']);
        break;
      case 'speech':
        tags.addAll(
            ['language', 'communication', 'articulation', 'vocabulary']);
        break;
      case 'cognitive':
        tags.addAll(['thinking', 'memory', 'problem solving', 'attention']);
        break;
      case 'general':
        tags.addAll(['therapy', 'general', 'resources']);
        break;
    }

    return tags.toSet().toList(); // Remove duplicates
  }
}

// Materials Service for comprehensive data retrieval and management
class ClinicMaterialsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'ClinicMaterials';

  // Get all materials for a specific clinic
  static Stream<QuerySnapshot> getMaterialsForClinic(String clinicId) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Get materials by category for a specific clinic
  static Stream<QuerySnapshot> getMaterialsByCategory(
      String clinicId, String category) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('category', isEqualTo: category.toLowerCase())
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Get materials by file type for a specific clinic
  static Stream<QuerySnapshot> getMaterialsByFileType(
      String clinicId, String fileType) {
    String fieldName = '';
    switch (fileType.toLowerCase()) {
      case 'image':
        fieldName = 'isImage';
        break;
      case 'video':
        fieldName = 'isVideo';
        break;
      case 'document':
        fieldName = 'isDocument';
        break;
      default:
        return const Stream.empty();
    }

    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where(fieldName, isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Search materials by title or description for a specific clinic
  static Stream<QuerySnapshot> searchMaterials(
      String clinicId, String searchTerm) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('tags', arrayContains: searchTerm.toLowerCase())
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Get material count for each category for a specific clinic
  static Future<Map<String, int>> getMaterialCountsByCategory(
      String clinicId) async {
    final categories = ['motor', 'speech', 'cognitive', 'general'];
    final Map<String, int> counts = {};

    for (final category in categories) {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      counts[category] = snapshot.docs.length;
    }

    return counts;
  }

  // Get material by ID for a specific clinic
  static Future<DocumentSnapshot?> getMaterialById(
      String clinicId, String materialId) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(materialId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['clinicId'] == clinicId && data['isActive'] == true) {
          return doc;
        }
      }
      return null;
    } catch (e) {
      print('Error getting material by ID: $e');
      return null;
    }
  }

  // Update material metadata
  static Future<bool> updateMaterial(
      String clinicId, String materialId, Map<String, dynamic> updates) async {
    try {
      // Verify the material belongs to the clinic
      final doc = await getMaterialById(clinicId, materialId);
      if (doc == null) return false;

      // Add lastModified timestamp
      updates['lastModified'] = FieldValue.serverTimestamp();

      await _firestore.collection(_collection).doc(materialId).update(updates);
      return true;
    } catch (e) {
      print('Error updating material: $e');
      return false;
    }
  }

  // Soft delete material (mark as inactive)
  static Future<bool> deleteMaterial(String clinicId, String materialId) async {
    try {
      // Verify the material belongs to the clinic
      final doc = await getMaterialById(clinicId, materialId);
      if (doc == null) return false;

      await _firestore.collection(_collection).doc(materialId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error deleting material: $e');
      return false;
    }
  }

  // Permanently delete material from both Firestore and Storage
  static Future<bool> permanentlyDeleteMaterial(
      String clinicId, String materialId) async {
    try {
      // Get the material document first
      final doc = await getMaterialById(clinicId, materialId);
      if (doc == null) return false;

      final data = doc.data() as Map<String, dynamic>;
      final storagePath = data['storagePath'] as String?;

      // Delete from Storage if storage path exists
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await _storage.ref(storagePath).delete();
          print('File deleted from Storage: $storagePath');
        } catch (storageError) {
          print(
              'Error deleting from Storage (file may not exist): $storageError');
          // Continue with Firestore deletion even if Storage deletion fails
        }
      }

      // Delete from Firestore
      await _firestore.collection(_collection).doc(materialId).delete();
      print('Material deleted from Firestore: $materialId');
      return true;
    } catch (e) {
      print('Error permanently deleting material: $e');
      return false;
    }
  }

  // Increment download count
  static Future<void> incrementDownloadCount(
      String clinicId, String materialId) async {
    try {
      final doc = await getMaterialById(clinicId, materialId);
      if (doc != null) {
        await _firestore.collection(_collection).doc(materialId).update({
          'downloadCount': FieldValue.increment(1),
          'lastDownloaded': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error incrementing download count: $e');
    }
  }

  // Get recently uploaded materials for a specific clinic
  static Stream<QuerySnapshot> getRecentMaterials(String clinicId,
      {int limit = 10}) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get most downloaded materials for a specific clinic
  static Stream<QuerySnapshot> getPopularMaterials(String clinicId,
      {int limit = 10}) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('isActive', isEqualTo: true)
        .orderBy('downloadCount', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Get materials uploaded by a specific user in a clinic
  static Stream<QuerySnapshot> getMaterialsByUploader(
      String clinicId, String uploaderId) {
    return _firestore
        .collection(_collection)
        .where('clinicId', isEqualTo: clinicId)
        .where('uploadedById', isEqualTo: uploaderId)
        .where('isActive', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Batch operations for multiple materials
  static Future<bool> batchDeleteMaterials(
      String clinicId, List<String> materialIds) async {
    try {
      final batch = _firestore.batch();

      for (final materialId in materialIds) {
        // Verify each material belongs to the clinic
        final doc = await getMaterialById(clinicId, materialId);
        if (doc != null) {
          batch.update(_firestore.collection(_collection).doc(materialId), {
            'isActive': false,
            'deletedAt': FieldValue.serverTimestamp(),
            'lastModified': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error batch deleting materials: $e');
      return false;
    }
  }

  // Get storage usage statistics for a clinic
  static Future<Map<String, dynamic>> getStorageStats(String clinicId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('clinicId', isEqualTo: clinicId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalFiles = 0;
      int totalSize = 0;
      Map<String, int> categoryCounts = {
        'motor': 0,
        'speech': 0,
        'cognitive': 0,
        'general': 0
      };
      Map<String, int> fileTypeCounts = {
        'images': 0,
        'videos': 0,
        'documents': 0,
        'others': 0
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalFiles++;
        totalSize += (data['fileSize'] as int? ?? 0);

        final category = data['category'] as String? ?? 'general';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        if (data['isImage'] == true) {
          fileTypeCounts['images'] = fileTypeCounts['images']! + 1;
        } else if (data['isVideo'] == true) {
          fileTypeCounts['videos'] = fileTypeCounts['videos']! + 1;
        } else if (data['isDocument'] == true) {
          fileTypeCounts['documents'] = fileTypeCounts['documents']! + 1;
        } else {
          fileTypeCounts['others'] = fileTypeCounts['others']! + 1;
        }
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).round(),
        'categoryCounts': categoryCounts,
        'fileTypeCounts': fileTypeCounts,
      };
    } catch (e) {
      print('Error getting storage stats: $e');
      return {};
    }
  }
}

// Search Materials Dialog
class SearchMaterialsDialog extends StatefulWidget {
  final String? clinicId;

  const SearchMaterialsDialog({Key? key, required this.clinicId})
      : super(key: key);

  @override
  State<SearchMaterialsDialog> createState() => _SearchMaterialsDialogState();
}

class _SearchMaterialsDialogState extends State<SearchMaterialsDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.search,
                    color: Color(0xFF2D5016)), // Dark green theme
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Search Materials',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title or description...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isNotEmpty) ...[
              const Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: widget.clinicId != null
                      ? FirebaseFirestore.instance
                          .collection('ClinicMaterials')
                          .where('clinicId', isEqualTo: widget.clinicId)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final materials = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final title = (data['title'] ?? '').toLowerCase();
                      final description =
                          (data['description'] ?? '').toLowerCase();
                      return title.contains(_searchQuery) ||
                          description.contains(_searchQuery);
                    }).toList();

                    if (materials.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No materials found',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        final material =
                            materials[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: Icon(
                            Icons.insert_drive_file,
                            color: const Color(0xFF2D5016), // Dark green theme
                          ),
                          title: Text(material['title'] ?? 'Untitled'),
                          subtitle: Text(
                              material['category']?.toString().toUpperCase() ??
                                  ''),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Open material
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Enter keywords to search materials',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
