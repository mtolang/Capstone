import 'package:flutter/material.dart';
import 'package:capstone_2/screens/parent/parent_navbar.dart';
import 'package:capstone_2/screens/parent/dashboard_tabbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:url_launcher/url_launcher.dart';

class ParentMaterials extends StatefulWidget {
  const ParentMaterials({Key? key}) : super(key: key);

  @override
  State<ParentMaterials> createState() => _ParentMaterialsState();
}

class _ParentMaterialsState extends State<ParentMaterials> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // YouTube API configuration
  static const String _youtubeApiKey =
      'AIzaSyBG_j6o7Sp2d1LPMFP5yEHfWx1FhM3I4u4';
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

  @override
  void initState() {
    super.initState();
    _fetchYouTubeVideos();
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

      print('Fetching YouTube videos for: $searchQuery'); // Debug log

      final response = await http.get(
        Uri.parse(
          '$_youtubeBaseUrl?part=snippet&q=${Uri.encodeComponent(searchQuery)}&type=video&maxResults=3&key=$_youtubeApiKey',
        ),
      );

      print('YouTube API Response Status: ${response.statusCode}'); // Debug log
      print('YouTube API Response Body: ${response.body}'); // Debug log

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
          // No videos found, use sample data for demonstration
          _loadSampleYouTubeVideos();
        }
      } else {
        print('YouTube API Error: ${response.statusCode} - ${response.body}');
        // Load sample videos as fallback
        _loadSampleYouTubeVideos();
      }
    } catch (e) {
      print('YouTube API Exception: $e'); // Debug log
      // Load sample videos as fallback
      _loadSampleYouTubeVideos();
    }
  }

  void _loadSampleYouTubeVideos() {
    // Sample videos for demonstration when API fails
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Materials',
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
          // Background images with fallback gradients (same as dashboard)
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
                  child: SizedBox(height: 50),
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
                                child: Text(
                                  value,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
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

                // Materials Section Header
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Therapy Materials',
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
                _buildTherapistMaterials(),

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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistMaterials() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('TherapyMaterials').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading materials: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No therapy materials available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Check back later for new materials from therapists',
                      style: TextStyle(
                        fontSize: 14,
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

        final materials = snapshot.data!.docs;

        // Filter materials based on search query and category
        final filteredMaterials = materials.where((material) {
          final materialData = material.data() as Map<String, dynamic>;
          final title = (materialData['title'] ?? '').toString().toLowerCase();
          final category = (materialData['category'] ?? '').toString();

          final matchesSearch =
              _searchQuery.isEmpty || title.contains(_searchQuery);
          final matchesCategory =
              _selectedCategory == 'All' || category == _selectedCategory;

          return matchesSearch && matchesCategory;
        }).toList();

        if (filteredMaterials.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No materials found matching your criteria',
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

        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.0,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 0.75, // 3:4 ratio for image to title
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              final material = filteredMaterials[index];
              final materialData = material.data() as Map<String, dynamic>;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    _showMaterialDetail(materialData);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
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
                    child: Column(
                      children: [
                        // Image takes 3/4 of the card
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10.0),
                                topRight: Radius.circular(10.0),
                              ),
                              child: materialData['imageUrl'] != null
                                  ? Image.network(
                                      materialData['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.folder,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        // Title takes 1/4 of the card
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              materialData['title'] ?? 'Untitled Material',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF006A5B),
                                fontFamily: 'Poppins',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: filteredMaterials.length,
          ),
        );
      },
    );
  }

  void _showMaterialDetail(Map<String, dynamic> materialData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(materialData['title'] ?? 'Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (materialData['imageUrl'] != null)
                Image.network(
                  materialData['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                'Category: ${materialData['category'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (materialData['description'] != null)
                Text(materialData['description']),
              if (materialData['uploadedBy'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Uploaded by: ${materialData['uploadedBy']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (materialData['fileUrl'] != null)
            ElevatedButton(
              onPressed: () {
                // TODO: Implement file download/view
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening material...')),
                );
              },
              child: const Text('Open'),
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
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.video_library,
                                    size: 40,
                                    color: Colors.grey,
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
                                color: Colors.red.withOpacity(0.8),
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
                                fontWeight: FontWeight.w600,
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
                                fontSize: 12,
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
              _openYouTubeVideo(videoData['id']);
            },
            child: const Text('Watch Video'),
          ),
        ],
      ),
    );
  }

  void _openYouTubeVideo(String videoId) async {
    final youtubeUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    final youtubeAppUrl = Uri.parse('youtube://watch?v=$videoId');

    try {
      // Try to open in YouTube app first
      if (await canLaunchUrl(youtubeAppUrl)) {
        await launchUrl(youtubeAppUrl);
      } else if (await canLaunchUrl(youtubeUrl)) {
        // Fallback to web browser
        await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication);
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
