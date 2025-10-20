import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';

class ParentJournalPage extends StatefulWidget {
  const ParentJournalPage({Key? key}) : super(key: key);

  @override
  State<ParentJournalPage> createState() => _ParentJournalPageState();
}

class _ParentJournalPageState extends State<ParentJournalPage> {
  String? _parentId;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getParentId();
  }

  Future<void> _getParentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _parentId = prefs.getString('parent_id') ??
          prefs.getString('user_id') ??
          prefs.getString('clinic_id');
      print('Parent ID loaded: $_parentId');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting parent ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Journal',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter',
          ),
        ],
      ),
      drawer: const ParentNavbar(),
      body: _parentId == null
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF006A5B),
              ),
            )
          : Stack(
              children: [
                _buildJournalList(),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006A5B),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddJournalDialog(),
        backgroundColor: const Color(0xFF006A5B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Entry',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Journal')
          .where('parentId', isEqualTo: _parentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading journal entries',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final journals = snapshot.data?.docs ?? [];

        if (journals.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Journal Entries Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start documenting your child\'s journey!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddJournalDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006A5B),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create First Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: journals.length,
          itemBuilder: (context, index) {
            final journal = journals[index];
            final data = journal.data() as Map<String, dynamic>;
            return _buildJournalCard(journal.id, data);
          },
        );
      },
    );
  }

  Widget _buildJournalCard(String journalId, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final images = List<String>.from(data['images'] ?? []);
    final videos = List<String>.from(data['videos'] ?? []);
    final createdAt = data['createdAt'] as Timestamp?;
    final mood = data['mood'] ?? 'neutral';

    final dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showJournalDetail(journalId, data),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with mood and menu
                Row(
                  children: [
                    _buildMoodIcon(mood),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              color: Color(0xFF006A5B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () => _showJournalOptions(journalId, data),
                    ),
                  ],
                ),

                // Description
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Media preview
                if (images.isNotEmpty || videos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildMediaPreview(images, videos),
                ],

                // Footer
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (images.isNotEmpty) ...[
                      Icon(Icons.image, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${images.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (videos.isNotEmpty) ...[
                      Icon(Icons.videocam, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${videos.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodIcon(String mood) {
    IconData icon;
    Color color;

    switch (mood.toLowerCase()) {
      case 'happy':
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        break;
      case 'sad':
        icon = Icons.sentiment_dissatisfied;
        color = Colors.blue;
        break;
      case 'excited':
        icon = Icons.celebration;
        color = Colors.orange;
        break;
      case 'worried':
        icon = Icons.sentiment_neutral;
        color = Colors.amber;
        break;
      case 'calm':
        icon = Icons.spa;
        color = Colors.teal;
        break;
      default:
        icon = Icons.sentiment_satisfied;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildMediaPreview(List<String> images, List<String> videos) {
    final allMedia = [...images, ...videos];
    final displayCount = allMedia.length > 3 ? 3 : allMedia.length;

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          ...List.generate(displayCount, (index) {
            final isVideo = index >= images.length;
            final url = allMedia[index];

            return Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!isVideo)
                      Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image,
                                color: Colors.grey),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          if (allMedia.length > 3)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '+${allMedia.length - 3}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddJournalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddJournalSheet(
        parentId: _parentId!,
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Journal entry created successfully!'),
                backgroundColor: Color(0xFF006A5B),
              ),
            );
          }
        },
      ),
    );
  }

  void _showJournalDetail(String journalId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalDetailPage(
          journalId: journalId,
          data: data,
        ),
      ),
    );
  }

  void _showJournalOptions(String journalId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF006A5B)),
              title: const Text(
                'Edit',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditJournalDialog(journalId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteJournal(journalId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditJournalDialog(String journalId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddJournalSheet(
        parentId: _parentId!,
        journalId: journalId,
        existingData: data,
        onSuccess: () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Journal entry updated successfully!'),
                backgroundColor: Color(0xFF006A5B),
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteJournal(String journalId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This journal entry will be permanently deleted.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteJournal(journalId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJournal(String journalId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection('Journal')
          .doc(journalId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting journal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Filter Entries',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Entries', style: TextStyle(fontFamily: 'Poppins')),
              leading: Radio(value: 0, groupValue: 0, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('This Week', style: TextStyle(fontFamily: 'Poppins')),
              leading: Radio(value: 1, groupValue: 0, onChanged: (v) {}),
            ),
            ListTile(
              title: const Text('This Month', style: TextStyle(fontFamily: 'Poppins')),
              leading: Radio(value: 2, groupValue: 0, onChanged: (v) {}),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF006A5B),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Journal Sheet Widget
class _AddJournalSheet extends StatefulWidget {
  final String parentId;
  final String? journalId;
  final Map<String, dynamic>? existingData;
  final VoidCallback onSuccess;

  const _AddJournalSheet({
    required this.parentId,
    this.journalId,
    this.existingData,
    required this.onSuccess,
  });

  @override
  State<_AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends State<_AddJournalSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];
  List<String> _existingImages = [];
  List<String> _existingVideos = [];
  
  String _selectedMood = 'neutral';
  bool _isUploading = false;

  final List<Map<String, dynamic>> _moods = [
    {'value': 'happy', 'label': 'Happy', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green},
    {'value': 'sad', 'label': 'Sad', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.blue},
    {'value': 'excited', 'label': 'Excited', 'icon': Icons.celebration, 'color': Colors.orange},
    {'value': 'worried', 'label': 'Worried', 'icon': Icons.sentiment_neutral, 'color': Colors.amber},
    {'value': 'calm', 'label': 'Calm', 'icon': Icons.spa, 'color': Colors.teal},
    {'value': 'neutral', 'label': 'Neutral', 'icon': Icons.sentiment_satisfied, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _titleController.text = widget.existingData!['title'] ?? '';
      _descriptionController.text = widget.existingData!['description'] ?? '';
      _selectedMood = widget.existingData!['mood'] ?? 'neutral';
      _existingImages = List<String>.from(widget.existingData!['images'] ?? []);
      _existingVideos = List<String>.from(widget.existingData!['videos'] ?? []);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                widget.journalId != null ? 'Edit Journal Entry' : 'New Journal Entry',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF006A5B),
                ),
              ),
              const SizedBox(height: 24),

              // Title field
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF006A5B), width: 2),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 16),

              // Mood selector
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (mood['color'] as Color).withOpacity(0.2)
                            : Colors.grey[100],
                        border: Border.all(
                          color: isSelected
                              ? (mood['color'] as Color)
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mood['icon'] as IconData,
                            color: mood['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mood['label'],
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? mood['color'] as Color : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Media buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickImages,
                      icon: const Icon(Icons.image),
                      label: const Text('Add Photos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006A5B),
                        side: const BorderSide(color: Color(0xFF006A5B)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickVideos,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Add Videos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF006A5B),
                        side: const BorderSide(color: Color(0xFF006A5B)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Selected media preview
              if (_selectedImages.isNotEmpty || _selectedVideos.isNotEmpty || 
                  _existingImages.isNotEmpty || _existingVideos.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Selected Media',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                _buildMediaGrid(),
              ],

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006A5B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.journalId != null ? 'Update Entry' : 'Save Entry',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    final allMedia = <Widget>[];

    // Existing images
    for (var i = 0; i < _existingImages.length; i++) {
      allMedia.add(_buildMediaThumbnail(
        url: _existingImages[i],
        isVideo: false,
        isExisting: true,
        index: i,
      ));
    }

    // New images
    for (var i = 0; i < _selectedImages.length; i++) {
      allMedia.add(_buildMediaThumbnail(
        file: _selectedImages[i],
        isVideo: false,
        isExisting: false,
        index: i,
      ));
    }

    // Existing videos
    for (var i = 0; i < _existingVideos.length; i++) {
      allMedia.add(_buildMediaThumbnail(
        url: _existingVideos[i],
        isVideo: true,
        isExisting: true,
        index: i,
      ));
    }

    // New videos
    for (var i = 0; i < _selectedVideos.length; i++) {
      allMedia.add(_buildMediaThumbnail(
        file: _selectedVideos[i],
        isVideo: true,
        isExisting: false,
        index: i,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allMedia,
    );
  }

  Widget _buildMediaThumbnail({
    XFile? file,
    String? url,
    required bool isVideo,
    required bool isExisting,
    required int index,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isExisting
                ? (isVideo
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white, size: 32),
                        ),
                      )
                    : Image.network(url!, fit: BoxFit.cover))
                : (isVideo
                    ? Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(Icons.play_circle_outline,
                              color: Colors.white, size: 32),
                        ),
                      )
                    : Image.file(File(file!.path), fit: BoxFit.cover)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (isExisting) {
                  if (isVideo) {
                    _existingVideos.removeAt(index);
                  } else {
                    _existingImages.removeAt(index);
                  }
                } else {
                  if (isVideo) {
                    _selectedVideos.removeAt(index);
                  } else {
                    _selectedImages.removeAt(index);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideos() async {
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideos.add(video);
        });
      }
    } catch (e) {
      print('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveJournal() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload new images
      List<String> imageUrls = List.from(_existingImages);
      for (var image in _selectedImages) {
        final url = await _uploadFile(File(image.path), 'images');
        if (url != null) imageUrls.add(url);
      }

      // Upload new videos
      List<String> videoUrls = List.from(_existingVideos);
      for (var video in _selectedVideos) {
        final url = await _uploadFile(File(video.path), 'videos');
        if (url != null) videoUrls.add(url);
      }

      // Save to Firestore
      final data = {
        'parentId': widget.parentId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mood': _selectedMood,
        'images': imageUrls,
        'videos': videoUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.journalId != null) {
        // Update existing
        await FirebaseFirestore.instance
            .collection('Journal')
            .doc(widget.journalId)
            .update(data);
      } else {
        // Create new
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('Journal').add(data);
      }

      widget.onSuccess();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving journal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
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

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('journal')
          .child(widget.parentId)
          .child(folder)
          .child(fileName);

      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }
}

// Journal Detail Page
class JournalDetailPage extends StatelessWidget {
  final String journalId;
  final Map<String, dynamic> data;

  const JournalDetailPage({
    Key? key,
    required this.journalId,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Untitled';
    final description = data['description'] ?? '';
    final images = List<String>.from(data['images'] ?? []);
    final videos = List<String>.from(data['videos'] ?? []);
    final createdAt = data['createdAt'] as Timestamp?;
    final mood = data['mood'] ?? 'neutral';

    final dateStr = createdAt != null
        ? DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt.toDate())
        : 'Unknown date';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal Entry',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF006A5B).withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Color(0xFF006A5B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),

            // Description
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                ),
              ),

            // Images
            if (images.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Videos
            if (videos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Videos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
