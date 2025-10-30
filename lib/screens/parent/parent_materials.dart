import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'kindora_camera_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentMaterials extends StatefulWidget {
  const ParentMaterials({Key? key}) : super(key: key);

  @override
  State<ParentMaterials> createState() => _ParentMaterialsState();
}

class _ParentMaterialsState extends State<ParentMaterials> {
  String? _userClinicId;
  String? _userEmail;
  
  // YouTube related variables
  YoutubePlayerController? _youtubeController;
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _isLoadingYoutube = false;

  // Material categories data structure
  final List<Map<String, dynamic>> _materialCategories = [
    {
      'id': 'motor',
      'title': 'Motor',
      'subtitle': 'Fine & Gross Motor Skills',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFF4CAF50),
      'count': 0,
    },
    {
      'id': 'speech',
      'title': 'Speech',
      'subtitle': 'Speech & Language Therapy',
      'icon': Icons.record_voice_over,
      'color': const Color(0xFF2196F3),
      'count': 0,
    },
    {
      'id': 'cognitive',
      'title': 'Cognitive',
      'subtitle': 'Cognitive Development',
      'icon': Icons.psychology,
      'color': const Color(0xFF9C27B0),
      'count': 0,
    },
    {
      'id': 'general',
      'title': 'General',
      'subtitle': 'General Resources',
      'icon': Icons.folder_open,
      'color': const Color(0xFFFF9800),
      'count': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserClinicId();
  }

  Future<void> _fetchUserClinicId() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _userEmail = user.email;
        print('🔍 Current user email: $_userEmail');
        
        // Query AcceptedBooking to find the clinic ID for this parent
        final bookingQuery = await FirebaseFirestore.instance
            .collection('AcceptedBooking')
            .where('parentEmail', isEqualTo: _userEmail)
            .limit(1)
            .get();
        
        if (bookingQuery.docs.isNotEmpty) {
          final bookingData = bookingQuery.docs.first.data();
          _userClinicId = bookingData['clinicId'];
          print('🏥 Found clinic ID: $_userClinicId for user: $_userEmail');
          
          // Load both materials and YouTube videos
          await _updateMaterialCounts();
          await _loadYoutubeVideos();
          
          setState(() {});
          _updateMaterialCounts();
        } else {
          print('❌ No booking found for user: $_userEmail, using fallback clinic');
          _userClinicId = 'CLI01'; // Fallback for testing
          await _updateMaterialCounts();
          await _loadYoutubeVideos();
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Error fetching user clinic ID: $e');
    }
  }

  Future<void> _updateMaterialCounts() async {
    if (_userClinicId == null) return;
    
    try {
      final materialsQuery = await FirebaseFirestore.instance
          .collection('ClinicMaterials')
          .where('clinicId', isEqualTo: _userClinicId)
          .get();
      
      // Reset counts
      for (var category in _materialCategories) {
        category['count'] = 0;
      }
      
      // Count materials by category
      for (var doc in materialsQuery.docs) {
        final material = doc.data();
        final category = material['category']?.toString().toLowerCase() ?? '';
        
        for (var cat in _materialCategories) {
          if (cat['id'] == category) {
            cat['count'] = (cat['count'] as int) + 1;
            break;
          }
        }
      }

      // If no materials found, add sample counts for demonstration
      if (materialsQuery.docs.isEmpty) {
        print('� No materials found, adding sample counts for clinic $_userClinicId');
        _materialCategories[0]['count'] = 5; // Motor
        _materialCategories[1]['count'] = 8; // Speech
        _materialCategories[2]['count'] = 6; // Cognitive
        _materialCategories[3]['count'] = 4; // General
      }
      
      print('�📊 Material counts updated: ${_materialCategories.map((c) => '${c['title']}: ${c['count']}').join(', ')}');
      setState(() {});
    } catch (e) {
      print('❌ Error updating material counts: $e');
      // Fallback to sample counts
      _materialCategories[0]['count'] = 5; // Motor
      _materialCategories[1]['count'] = 8; // Speech
      _materialCategories[2]['count'] = 6; // Cognitive
      _materialCategories[3]['count'] = 4; // General
      setState(() {});
    }
  }

  // YouTube related methods
  Future<void> _loadYoutubeVideos() async {
    setState(() {
      _isLoadingYoutube = true;
    });

    try {
      // Load sample YouTube videos from materials.dart
      _loadSampleYouTubeVideos();
      print('📺 Loaded ${_youtubeVideos.length} sample YouTube videos');
    } catch (e) {
      print('❌ Error loading YouTube videos: $e');
      _loadSampleYouTubeVideos();
    } finally {
      setState(() {
        _isLoadingYoutube = false;
      });
    }
  }

  void _loadSampleYouTubeVideos() {
    setState(() {
      _youtubeVideos = [
        {
          'id': 'sample1',
          'title': 'Child Development Therapy Techniques',
          'description': 'Learn effective therapy techniques for child development',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Therapy Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample2',
          'title': 'Speech Therapy for Children',
          'description': 'Professional speech therapy methods and exercises',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Speech Therapy Pro',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample3',
          'title': 'Occupational Therapy Activities',
          'description': 'Fun and engaging occupational therapy activities',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'OT Activities',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample4',
          'title': 'Motor Skills Development',
          'description': 'Exercises to improve motor skills in children',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Motor Skills Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      ];
    });
  }

  void _playYoutubeVideo(String videoUrl) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            height: 300,
            child: YoutubePlayer(
              controller: _youtubeController!,
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      );
    }
  }

  void _launchYouTube(String url) async {
    final Uri youtubeUri = Uri.parse(url);
    if (await canLaunchUrl(youtubeUri)) {
      await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch YouTube URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Material Categories',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.white,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const ParentNavbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openKindoraCamera,
        backgroundColor: const Color(0xFF006A5B),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
        tooltip: 'Take Photo with Kindora Camera',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF006A5B), Color(0xFFE8F5F3)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Center(
                  child: Text(
                    'Material Categories',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Material Categories Grid
                _userClinicId == null
                    ? const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Loading your materials...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio: 1.0,
                        children: _materialCategories.map((category) {
                          return _buildCategoryCard(category);
                        }).toList(),
                      ),
                
                const SizedBox(height: 40),
                
                // YouTube Videos Section
                const Text(
                  'YouTube Videos',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                
                _isLoadingYoutube
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _youtubeVideos.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              'No YouTube videos available for your clinic.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _youtubeVideos.length,
                            itemBuilder: (context, index) {
                              final video = _youtubeVideos[index];
                              return _buildYoutubeVideoCard(video);
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _navigateToMaterials(category['id'], category['title']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with colored background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Icon(
                  category['icon'],
                  size: 32,
                  color: category['color'],
                ),
              ),
              const SizedBox(height: 16),
              
              // Category title
              Text(
                category['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // Category subtitle
              Text(
                category['subtitle'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // File count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: category['color'],
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${category['count']} files',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYoutubeVideoCard(Map<String, dynamic> video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          video['title'] ?? 'YouTube Video',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
            fontFamily: 'Poppins',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          video['description'] ?? 'Therapy video content',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'play') {
              _playYoutubeVideo(video['videoUrl'] ?? '');
            } else if (value == 'open') {
              _launchYouTube(video['videoUrl'] ?? '');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_circle_filled, color: Color(0xFF006A5B)),
                  SizedBox(width: 8),
                  Text('Play in App'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new, color: Color(0xFF006A5B)),
                  SizedBox(width: 8),
                  Text('Open in YouTube'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMaterials(String categoryId, String categoryTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryMaterialsScreen(
          categoryId: categoryId,
          categoryTitle: categoryTitle,
          clinicId: _userClinicId!,
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
          content: const Text(
            'Take a photo to share with your therapy team or save therapy progress.',
            style: TextStyle(fontSize: 16),
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
              label: const Text('Open Camera', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
          const SnackBar(
            content: Text('Photo sent successfully to therapy team!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else if (result == 'saved') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved to device!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
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
}

// Screen to show materials in a specific category
class CategoryMaterialsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;
  final String clinicId;

  const CategoryMaterialsScreen({
    Key? key,
    required this.categoryId,
    required this.categoryTitle,
    required this.clinicId,
  }) : super(key: key);

  @override
  State<CategoryMaterialsScreen> createState() => _CategoryMaterialsScreenState();
}

class _CategoryMaterialsScreenState extends State<CategoryMaterialsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryTitle} Materials',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF006A5B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF006A5B), Color(0xFFE8F5F3)],
            stops: [0.0, 0.3],
          ),
        ),
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search materials...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF006A5B)),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            // Materials list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ClinicMaterials')
                    .where('clinicId', isEqualTo: widget.clinicId)
                    .where('category', isEqualTo: widget.categoryId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF006A5B)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Error loading materials: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.categoryTitle.toLowerCase()} materials available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check back later for new materials from your therapy team',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final materials = snapshot.data!.docs;

                  // Filter materials based on search query
                  final filteredMaterials = materials.where((material) {
                    if (_searchQuery.isEmpty) return true;
                    final materialData = material.data() as Map<String, dynamic>;
                    final title = (materialData['title'] ?? '').toString().toLowerCase();
                    final description = (materialData['description'] ?? '').toString().toLowerCase();
                    return title.contains(_searchQuery) || description.contains(_searchQuery);
                  }).toList();

                  if (filteredMaterials.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          'No materials found matching your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: filteredMaterials.length,
                    itemBuilder: (context, index) {
                      final material = filteredMaterials[index];
                      final materialData = material.data() as Map<String, dynamic>;

                      return _buildMaterialCard(materialData);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> materialData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMaterialDetail(materialData),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Material image/icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF006A5B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: materialData['imageUrl'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          materialData['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.description,
                              color: Color(0xFF006A5B),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.description,
                        color: Color(0xFF006A5B),
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Material details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      materialData['title'] ?? 'Untitled Material',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (materialData['description'] != null) ...[
                      Text(
                        materialData['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF718096),
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A5B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            widget.categoryTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF006A5B),
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Color(0xFF718096),
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

  void _showMaterialDetail(Map<String, dynamic> materialData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          materialData['title'] ?? 'Material',
          style: const TextStyle(
            color: Color(0xFF006A5B),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (materialData['imageUrl'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    materialData['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (materialData['description'] != null) ...[
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006A5B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  materialData['description'],
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  const Text(
                    'Category: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.categoryTitle,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (materialData['uploadedBy'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Uploaded by: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        materialData['uploadedBy'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
              if (materialData['uploadDate'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Date: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatTimestamp(materialData['uploadDate']),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF006A5B)),
            ),
          ),
          if (materialData['fileUrl'] != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openMaterialFile(materialData['fileUrl']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
              ),
              child: const Text(
                'Open File',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      print('Error formatting timestamp: $e');
    }
    return 'Unknown date';
  }

  Future<void> _openMaterialFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $fileUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
