import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Materials Service for parent access to clinic materials
class ParentMaterialsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'Materials';

  // Get all public materials (accessible to parents)
  static Stream<QuerySnapshot> getAllPublicMaterials() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Get materials by category (for all clinics, public materials only)
  static Stream<QuerySnapshot> getMaterialsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.toLowerCase())
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Get material count for each category
  static Future<Map<String, int>> getMaterialCountsByCategory() async {
    final categories = ['motor', 'speech', 'cognitive', 'general'];
    final Map<String, int> counts = {};

    for (final category in categories) {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .where('isPublic', isEqualTo: true)
          .get();
      counts[category] = snapshot.docs.length;
    }

    return counts;
  }

  // Search materials by title or tags
  static Stream<QuerySnapshot> searchMaterials(String searchTerm) {
    return _firestore
        .collection(_collection)
        .where('tags', arrayContains: searchTerm.toLowerCase())
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  // Increment download count
  static Future<void> incrementDownloadCount(String materialId) async {
    try {
      await _firestore.collection(_collection).doc(materialId).update({
        'downloadCount': FieldValue.increment(1),
        'lastDownloaded': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing download count: $e');
    }
  }

  // Get recently uploaded materials
  static Stream<QuerySnapshot> getRecentMaterials({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .orderBy('uploadedAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // YouTube API configuration with new API key
  static const String _youtubeApiKey =
      'AIzaSyDQaMiBpfKXc5JlPckBYtQRRkLmrdRv0jo';
  static const String _youtubeBaseUrl =
      'https://www.googleapis.com/youtube/v3/search';
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _loadingYouTubeVideos = false;

  // Therapy categories for filtering (reduced to 3 as requested)
  final List<String> _therapyCategories = [
    'All',
    'Motor',
    'Cognitive', 
    'Speech',
  ];

  // Dynamic material categories
  final List<Map<String, dynamic>> materialCategories = [
    {
      'value': 'motor',
      'title': 'Motor Skills',
      'description': 'Physical development and motor coordination activities',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFFE8A87C),
    },
    {
      'value': 'speech',
      'title': 'Speech Therapy',
      'description': 'Language development and communication tools',
      'icon': Icons.record_voice_over,
      'color': const Color(0xFFFFA07A),
    },
    {
      'value': 'cognitive',
      'title': 'Cognitive Development',
      'description': 'Thinking skills and cognitive enhancement materials',
      'icon': Icons.psychology,
      'color': const Color(0xFF87CEEB),
    },
    {
      'value': 'general',
      'title': 'General Resources',
      'description': 'Comprehensive therapy resources and materials',
      'icon': Icons.folder_open,
      'color': const Color(0xFF98FB98),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchYouTubeVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeVideos() async {
    setState(() {
      _loadingYouTubeVideos = true;
    });

    try {
      String searchQuery = 'child development therapy';
      if (_selectedCategory != 'All') {
        searchQuery = '$_selectedCategory child development therapy';
      }

      print('Fetching YouTube videos for: $searchQuery');

      final response = await http.get(
        Uri.parse(
          '$_youtubeBaseUrl?part=snippet&q=${Uri.encodeComponent(searchQuery)}&type=video&maxResults=3&key=$_youtubeApiKey',
        ),
      );

      print('YouTube API Response Status: ${response.statusCode}');
      print('YouTube API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          setState(() {
            _youtubeVideos = List<Map<String, dynamic>>.from(
              data['items'].map((item) => {
                    'id': item['id']['videoId'],
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'thumbnail': item['snippet']['thumbnails']['medium']['url'],
                    'channelTitle': item['snippet']['channelTitle'],
                    'publishedAt': item['snippet']['publishedAt'],
                  }),
            );
            _loadingYouTubeVideos = false;
          });
        } else {
          _loadSampleYouTubeVideos();
        }
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
        _loadSampleYouTubeVideos();
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      _loadSampleYouTubeVideos();
    }
  }

  void _loadSampleYouTubeVideos() {
    setState(() {
      _youtubeVideos = [
        {
          'id': 'sample1',
          'title': 'Child Development Therapy Techniques',
          'description':
              'Learn effective therapy techniques for child development',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Therapy Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample2',
          'title': 'Speech Therapy for Children',
          'description': 'Professional speech therapy methods and exercises',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Speech Therapy Pro',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample3',
          'title': 'Occupational Therapy Activities',
          'description':
              'Fun and effective occupational therapy activities for kids',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'OT for Kids',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      ];
      _loadingYouTubeVideos = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Using sample videos - YouTube API temporarily unavailable'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildMaterialFolder(
      String title, IconData icon, Color color, String subtitle, String category) {
    return StreamBuilder<QuerySnapshot>(
      stream: ParentMaterialsService.getMaterialsByCategory(category),
      builder: (context, snapshot) {
        int materialCount = 0;
        if (snapshot.hasData) {
          materialCount = snapshot.data!.docs.length;
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => _openMaterialFolder(category, color, title),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        icon,
                        size: 30,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$materialCount files',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
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

  void _openMaterialFolder(String category, Color color, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentMaterialFolderView(
          category: category,
          categoryColor: color,
          title: title,
        ),
      ),
    );
  }

  void _openMaterialViewer(String title) {
    // TODO: Replace this with actual PDF viewer or content viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialViewer(materialTitle: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
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
      body: Stack(
        children: [
          // Background images with fallback gradients
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.30),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.3),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF67AFA5), Colors.white],
                  ),
                ),
                child: Image.asset(
                  'asset/images/Ellipse 2.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Gradient fallback
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomScrollView(
              slivers: <Widget>[
                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),

                // Search bar
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
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
                        hintText: 'Search therapy materials...',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF006A5B)),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Filter dropdown button
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter by Category:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF006A5B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFF006A5B)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Color(0xFF006A5B)),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(color: Color(0xFF006A5B)),
                            underline: Container(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCategory = newValue!;
                              });
                              _fetchYouTubeVideos(); // Refresh YouTube videos with new category
                            },
                            items: _therapyCategories
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Digital Materials',
                      style: TextStyle(
                        color: Color(0xFF67AFA5),
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                // Materials folders grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        // Filter categories based on search query
                        final filteredCategories = materialCategories.where((category) {
                          final title = category['title'].toString().toLowerCase();
                          final matchesSearch = _searchQuery.isEmpty ||
                              title.contains(_searchQuery);
                          final matchesCategory = _selectedCategory == 'All' ||
                              category['title'].toString().contains(_selectedCategory);
                          return matchesSearch && matchesCategory;
                        }).toList();

                        if (index >= filteredCategories.length) return null;

                        final category = filteredCategories[index];
                        return _buildMaterialFolder(
                          category['title'],
                          category['icon'],
                          category['color'],
                          category['description'],
                          category['value'],
                        );
                      },
                      childCount: materialCategories.where((category) {
                        final title = category['title'].toString().toLowerCase();
                        final matchesSearch = _searchQuery.isEmpty ||
                            title.contains(_searchQuery);
                        final matchesCategory = _selectedCategory == 'All' ||
                            category['title'].toString().contains(_selectedCategory);
                        return matchesSearch && matchesCategory;
                      }).length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),

                // YouTube Videos Section Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'YouTube Therapy Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 15),
                ),
                _buildYouTubeVideos(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80), // Extra space at bottom
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeVideos() {
    if (_loadingYouTubeVideos) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          ),
        ),
      );
    }

    if (_youtubeVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                Icon(
                  Icons.video_library,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No YouTube videos found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Filter videos based on search query and limit to 3 videos
    final filteredVideos = _youtubeVideos
        .where((video) {
          if (_searchQuery.isEmpty) return true;
          final title = video['title'].toString().toLowerCase();
          final description = video['description'].toString().toLowerCase();
          return title.contains(_searchQuery) ||
              description.contains(_searchQuery);
        })
        .take(3)
        .toList(); // Limit to exactly 3 videos

    if (filteredVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No YouTube videos found for the selected category',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredVideos.length,
          itemBuilder: (context, index) {
            final video = filteredVideos[index];

            return Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  _showVideoDetail(video);
                },
                child: Column(
                  children: [
                    // Video thumbnail
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12.0),
                              topRight: Radius.circular(12.0),
                            ),
                            child: Image.network(
                              video['thumbnail'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color:
                                      const Color(0xFF006A5B).withOpacity(0.1),
                                  child: const Icon(
                                    Icons.play_circle_outline,
                                    size: 50,
                                    color: Color(0xFF006A5B),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Play button overlay
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Video info
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              video['title'] ?? 'Untitled Video',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video['channelTitle'] ?? '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showVideoDetail(Map<String, dynamic> videoData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          videoData['title'] ?? 'Video',
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                videoData['thumbnail'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                'Channel: ${videoData['channelTitle'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (videoData['description'] != null)
                Text(
                  videoData['description'].toString().length > 200
                      ? '${videoData['description'].toString().substring(0, 200)}...'
                      : videoData['description'].toString(),
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 8),
              Text(
                'Published: ${_formatDate(videoData['publishedAt'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _playVideoInApp(videoData['id'], videoData['title']);
            },
            child: const Text('Watch in App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openYouTubeVideo(videoData['id']);
            },
            child: const Text('Open in YouTube'),
          ),
        ],
      ),
    );
  }

  void _playVideoInApp(String videoId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmbeddedVideoPlayer(
          videoId: videoId,
          title: title.isNotEmpty ? title : 'Therapy Video',
        ),
      ),
    );
  }

  void _openYouTubeVideo(String videoId) async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
    final youtubeAppUrl = 'youtube://watch?v=$videoId';

    try {
      // Try to open in YouTube app first
      if (await canLaunch(youtubeAppUrl)) {
        await launch(youtubeAppUrl);
      } else if (await canLaunch(youtubeUrl)) {
        // Fallback to web browser
        await launch(youtubeUrl, forceWebView: false, enableJavaScript: true);
      } else {
        throw 'Could not launch video';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video: $e')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// TODO: This is where you'll implement the PDF viewer or content viewer
class MaterialViewer extends StatelessWidget {
  final String materialTitle;

  const MaterialViewer({super.key, required this.materialTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          materialTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'PDF Viewer for: $materialTitle',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'TODO: Implement PDF viewer here\n\n'
                'You can use packages like:\n'
                '• flutter_pdfview\n'
                '• syncfusion_flutter_pdfviewer\n'
                '• native_pdf_view\n\n'
                'This is where the actual content will be displayed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Add functionality to load and display PDF
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loading $materialTitle content...'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A5B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Load Content'),
            ),
          ],
        ),
      ),
    );
  }
}

// Embedded YouTube Video Player for in-app video viewing
class EmbeddedVideoPlayer extends StatefulWidget {
  final String videoId;
  final String title;

  const EmbeddedVideoPlayer({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        loop: false,
        enableCaption: true,
        captionLanguage: 'en',
      ),
    );

    _controller.setFullScreenListener((isFullScreen) {
      // Handle fullscreen changes
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF006A5B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: () => _openInYouTube(),
            tooltip: 'Open in YouTube',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player with fixed height
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),

          // Video Controls and Information Panel
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006A5B),
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Action Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.replay_10,
                          label: 'Replay 10s',
                          onPressed: () async {
                            final currentTime = await _controller.currentTime;
                            final newTime =
                                (currentTime - 10).clamp(0.0, double.infinity);
                            _controller.seekTo(seconds: newTime);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.play_arrow,
                          label: 'Play/Pause',
                          onPressed: () async {
                            final playerState = await _controller.playerState;
                            if (playerState == PlayerState.playing) {
                              _controller.pauseVideo();
                            } else {
                              _controller.playVideo();
                            }
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.forward_10,
                          label: 'Forward 10s',
                          onPressed: () async {
                            final currentTime = await _controller.currentTime;
                            final newTime = currentTime + 10;
                            _controller.seekTo(seconds: newTime);
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.fullscreen,
                          label: 'Fullscreen',
                          onPressed: () {
                            _controller.enterFullScreen();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Help Text
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006A5B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFF006A5B).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF006A5B),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This therapeutic video is playing within the Kindora app for a seamless learning experience.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF006A5B),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            elevation: 3,
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF006A5B),
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _openInYouTube() async {
    final youtubeUrl = 'https://www.youtube.com/watch?v=${widget.videoId}';
    final youtubeAppUrl = 'youtube://watch?v=${widget.videoId}';

    try {
      if (await canLaunch(youtubeAppUrl)) {
        await launch(youtubeAppUrl);
      } else if (await canLaunch(youtubeUrl)) {
        await launch(youtubeUrl, forceWebView: false, enableJavaScript: true);
      } else {
        throw 'Could not launch video';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open video in YouTube: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Parent Material Folder View Page
class ParentMaterialFolderView extends StatelessWidget {
  final String category;
  final Color categoryColor;
  final String title;

  const ParentMaterialFolderView({
    Key? key,
    required this.category,
    required this.categoryColor,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: categoryColor,
        title: Text(
          '$title Materials',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ParentMaterialsService.getMaterialsByCategory(category),
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading materials',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
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
                  Icon(
                    Icons.folder_open_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No materials found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No materials available in this category',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final material = doc.data() as Map<String, dynamic>;
              return _buildMaterialCard(context, material, doc.id, categoryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, Map<String, dynamic> material, String docId, Color categoryColor) {
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
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
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
                // File icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(material['fileName'] ?? ''),
                    size: 28,
                    color: categoryColor,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (material['description'] != null && material['description'].toString().isNotEmpty)
                        Text(
                          material['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.download_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${material['downloadCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
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

  void _openMaterial(BuildContext context, Map<String, dynamic> material) async {
    final downloadUrl = material['downloadUrl'] as String?;
    final materialId = material['materialId'] as String?;
    final fileName = material['fileName'] as String?;

    if (downloadUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Increment download count
      if (materialId != null) {
        await ParentMaterialsService.incrementDownloadCount(materialId);
      }

      // Show options for different file types
      final isImage = material['isImage'] == true;

      if (isImage) {
        // Show image in a dialog
        _showImageDialog(context, downloadUrl, material['title'] ?? fileName ?? 'Image');
      } else {
        // For other files, show download/open options
        _showFileOptionsDialog(context, downloadUrl, fileName ?? 'file');
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
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                backgroundColor: categoryColor,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
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
                          color: categoryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text('Failed to load image'),
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

  void _showFileOptionsDialog(BuildContext context, String downloadUrl, String fileName) {
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (await canLaunch(downloadUrl)) {
                  await launch(downloadUrl, forceWebView: false, enableJavaScript: true);
                } else {
                  throw 'Could not launch file';
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open file: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

// Content-only version (no AppBar, Drawer, or TabBar)
class MaterialsPageContent extends StatefulWidget {
  const MaterialsPageContent({super.key});

  @override
  State<MaterialsPageContent> createState() => _MaterialsPageContentState();
}

class _MaterialsPageContentState extends State<MaterialsPageContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const String _youtubeApiKey =
      'AIzaSyDQaMiBpfKXc5JlPckBYtQRRkLmrdRv0jo';
  static const String _youtubeBaseUrl =
      'https://www.googleapis.com/youtube/v3/search';
  List<Map<String, dynamic>> _youtubeVideos = [];
  bool _loadingYouTubeVideos = false;

  final List<Map<String, dynamic>> materialCategories = [
    {
      'value': 'motor',
      'title': 'Motor Skills',
      'description': 'Physical development and motor coordination activities',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFFE8A87C),
    },
    {
      'value': 'speech',
      'title': 'Speech Therapy',
      'description': 'Language development and communication tools',
      'icon': Icons.record_voice_over,
      'color': const Color(0xFFFFA07A),
    },
    {
      'value': 'cognitive',
      'title': 'Cognitive Development',
      'description': 'Thinking skills and cognitive enhancement materials',
      'icon': Icons.psychology,
      'color': const Color(0xFF87CEEB),
    },
    {
      'value': 'general',
      'title': 'General Resources',
      'description': 'Comprehensive therapy resources and materials',
      'icon': Icons.folder_open,
      'color': const Color(0xFF98FB98),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchYouTubeVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchYouTubeVideos() async {
    setState(() {
      _loadingYouTubeVideos = true;
    });

    try {
      String searchQuery = 'child development therapy';
      if (_selectedCategory != 'All') {
        searchQuery = '$_selectedCategory child development therapy';
      }

      final response = await http.get(
        Uri.parse(
          '$_youtubeBaseUrl?part=snippet&q=${Uri.encodeComponent(searchQuery)}&type=video&maxResults=3&key=$_youtubeApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          setState(() {
            _youtubeVideos = List<Map<String, dynamic>>.from(
              data['items'].map((item) => {
                    'id': item['id']['videoId'],
                    'title': item['snippet']['title'],
                    'description': item['snippet']['description'],
                    'thumbnail': item['snippet']['thumbnails']['high']['url'],
                    'channelTitle': item['snippet']['channelTitle'],
                    'publishedAt': item['snippet']['publishedAt'],
                  }),
            );
            _loadingYouTubeVideos = false;
          });
        } else {
          _loadSampleYouTubeVideos();
        }
      } else {
        _loadSampleYouTubeVideos();
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      _loadSampleYouTubeVideos();
    }
  }

  void _loadSampleYouTubeVideos() {
    setState(() {
      _youtubeVideos = [
        {
          'id': 'sample1',
          'title': 'Child Development Therapy Techniques',
          'description':
              'Learn effective therapy techniques for child development',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Therapy Channel',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample2',
          'title': 'Speech Therapy for Children',
          'description': 'Professional speech therapy methods and exercises',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'Speech Therapy Pro',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
        {
          'id': 'sample3',
          'title': 'Occupational Therapy Activities',
          'description':
              'Fun and effective occupational therapy activities for kids',
          'thumbnail':
              'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
          'channelTitle': 'OT for Kids',
          'publishedAt': '2024-01-01T00:00:00Z',
        },
      ];
      _loadingYouTubeVideos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.30),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 224, 241, 239)],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 1.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints.expand(height: mq.height * 0.3),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF67AFA5), Colors.white],
                ),
              ),
              child: Image.asset(
                'asset/images/Ellipse 2.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Learning Materials',
                    style: TextStyle(
                      color: Color(0xFF67AFA5),
                      fontSize: 24,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search materials...',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF67AFA5),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Therapy Videos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              _buildYouTubeVideos(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Educational Resources',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006A5B),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 10),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = materialCategories[index];
                    if (_searchQuery.isNotEmpty &&
                        !category['title']
                            .toLowerCase()
                            .contains(_searchQuery)) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: GestureDetector(
                        onTap: () => _openMaterialFolder(category['value'], category['color'], category['title']),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: category['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: category['color'],
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: category['color'].withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  category['icon'],
                                  color: category['color'],
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category['title'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: category['color'],
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category['description'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontFamily: 'Poppins',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: category['color'],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: materialCategories.length,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubeVideos() {
    if (_loadingYouTubeVideos) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(
              color: Color(0xFF006A5B),
            ),
          ),
        ),
      );
    }

    if (_youtubeVideos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'No videos available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      );
    }

    final filteredVideos = _youtubeVideos.take(3).toList();

    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: filteredVideos.length,
          itemBuilder: (context, index) {
            final video = filteredVideos[index];
            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Image.network(
                        video['thumbnail'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF67AFA5),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        video['title'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
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
    );
  }

  void _openMaterialFolder(String category, Color color, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParentMaterialFolderView(
          category: category,
          categoryColor: color,
          title: title,
        ),
      ),
    );
  }

  void _openMaterialViewer(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialViewer(materialTitle: title),
      ),
    );
  }
}
