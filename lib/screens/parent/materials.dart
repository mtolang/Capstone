import 'package:flutter/material.dart';
import 'package:kindora/screens/parent/dashboard_tabbar.dart';
import 'package:kindora/screens/parent/parent_navbar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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

  // Therapy categories for filtering
  final List<String> _therapyCategories = [
    'All',
    'Speech Therapy',
    'Occupational Therapy',
    'Physical Therapy',
    'Behavioral Therapy',
    'Play Therapy',
    'Sensory Integration',
    'Social Skills',
    'Communication',
    'Motor Skills',
  ];

  final List<Map<String, dynamic>> materials = [
    {
      'title': 'Learning to Read',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...',
      'image': 'asset/images/tiny.png', // Replace with actual reading image
      'color': const Color(0xFF67AFA5),
    },
    {
      'title': 'Motor Skills',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...',
      'image':
          'asset/images/tiny.png', // Replace with actual motor skills image
      'color': const Color(0xFFE8A87C),
    },
    {
      'title': 'Speech Therapy',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...',
      'image':
          'asset/images/tiny.png', // Replace with actual speech therapy image
      'color': const Color(0xFFFFA07A),
    },
    {
      'title': 'Math Skills',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...',
      'image': 'asset/images/tiny.png', // Replace with actual math image
      'color': const Color(0xFF87CEEB),
    },
    {
      'title': 'Phonics Lessons',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor...',
      'image': 'asset/images/tiny.png', // Replace with actual phonics image
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
                    colors: [Color(0xFF006A5B), Color(0xFF67AFA5)],
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
                const SliverAppBar(
                  automaticallyImplyLeading: false,
                  pinned: true,
                  expandedHeight: 70.0,
                  toolbarHeight: 70.0,
                  backgroundColor: Color(0xFF006A5B),
                  flexibleSpace: FlexibleSpaceBar(
                    title: DashTab(
                        initialSelectedIndex: 2), // Set to materials tab
                    centerTitle: true,
                  ),
                ),
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
                // Materials grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        // Filter materials based on search query and category
                        final filteredMaterials = materials.where((material) {
                          final title =
                              material['title'].toString().toLowerCase();
                          final matchesSearch = _searchQuery.isEmpty ||
                              title.contains(_searchQuery);
                          final matchesCategory = _selectedCategory == 'All' ||
                              material['title']
                                  .toString()
                                  .contains(_selectedCategory.split(' ')[0]);
                          return matchesSearch && matchesCategory;
                        }).toList();

                        if (index >= filteredMaterials.length) return null;

                        final material = filteredMaterials[index];
                        return GestureDetector(
                          onTap: () => _openMaterialViewer(material['title']),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.0),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Image container
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: material['color'].withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                    child: Image.asset(
                                      material['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: material['color']
                                              .withOpacity(0.2),
                                          child: Icon(
                                            Icons.book,
                                            size: 50,
                                            color: material['color'],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material['title'],
                                          style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: material['color'],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: Text(
                                            material['description'],
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
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
                      },
                      childCount: materials.where((material) {
                        final title =
                            material['title'].toString().toLowerCase();
                        final matchesSearch = _searchQuery.isEmpty ||
                            title.contains(_searchQuery);
                        final matchesCategory = _selectedCategory == 'All' ||
                            material['title']
                                .toString()
                                .contains(_selectedCategory.split(' ')[0]);
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
