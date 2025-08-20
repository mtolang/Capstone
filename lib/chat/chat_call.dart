import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatCallScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final List<String> initialParticipants;

  const ChatCallScreen({
    Key? key,
    required this.callId,
    required this.currentUserId,
    required this.initialParticipants,
  }) : super(key: key);

  @override
  State<ChatCallScreen> createState() => _ChatCallScreenState();
}

class _ChatCallScreenState extends State<ChatCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  bool _isScreenSharing = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _loadContacts();
  }

  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _requestPermissions();
    await _getUserMedia();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'user',
      }
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(constraints);
      _localRenderer.srcObject = _localStream;
      setState(() {});
    } catch (e) {
      print('Error getting user media: $e');
    }
  }

  Future<void> _toggleScreenShare() async {
    if (_isScreenSharing) {
      await _stopScreenShare();
    } else {
      await _startScreenShare();
    }
  }

  Future<void> _startScreenShare() async {
    try {
      final screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': true,
      });

      _localRenderer.srcObject = screenStream;

      // Replace video track in all peer connections
      for (var connection in _peerConnections.values) {
        final senders = await connection.getSenders();
        for (var sender in senders) {
          if (sender.track?.kind == 'video') {
            await sender.replaceTrack(screenStream.getVideoTracks().first);
          }
        }
      }

      setState(() {
        _isScreenSharing = true;
      });
    } catch (e) {
      print('Error starting screen share: $e');
    }
  }

  Future<void> _stopScreenShare() async {
    try {
      await _getUserMedia();

      // Replace back to camera in all peer connections
      for (var connection in _peerConnections.values) {
        final senders = await connection.getSenders();
        for (var sender in senders) {
          if (sender.track?.kind == 'video' && _localStream != null) {
            await sender.replaceTrack(_localStream!.getVideoTracks().first);
          }
        }
      }

      setState(() {
        _isScreenSharing = false;
      });
    } catch (e) {
      print('Error stopping screen share: $e');
    }
  }

  void _loadContacts() {
    // Mock contacts data - replace with actual contact fetching
    _contacts = [
      Contact(
          id: '1',
          name: 'Martin Rey Talang',
          avatar: 'assets/martin.jpg',
          isOnline: true),
      Contact(
          id: '2',
          name: 'Andrew Ravago',
          avatar: 'assets/andrew.jpg',
          isOnline: true),
      Contact(
          id: '3',
          name: 'Divata Pares',
          avatar: 'assets/divata.jpg',
          isOnline: false),
      Contact(
          id: '4',
          name: 'Kuma Toss',
          avatar: 'assets/kuma.jpg',
          isOnline: true),
    ];
    _filteredContacts = List.from(_contacts);
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _showInviteBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInviteBottomSheet(),
    );
  }

  Widget _buildInviteBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.group_add, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Invite People',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contacts list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return _buildContactTile(contact);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(contact.avatar),
          ),
          if (contact.isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(contact.name),
      subtitle: Text(contact.isOnline ? 'Online' : 'Offline'),
      trailing: ElevatedButton(
        onPressed: contact.isOnline ? () => _inviteToCall(contact) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('RING', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _inviteToCall(Contact contact) {
    // Implement call invitation logic
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inviting ${contact.name} to call...')),
    );
    // Here you would send the invitation through your backend/signaling server
  }

  void _toggleMute() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
      setState(() {
        _isMuted = !audioTrack.enabled;
      });
    }
  }

  void _toggleVideo() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
      setState(() {
        _isVideoOff = !videoTrack.enabled;
      });
    }
  }

  void _endCall() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video view
          if (_remoteRenderers.isNotEmpty)
            _buildRemoteVideos()
          else
            _buildLocalVideoFullScreen(),

          // Local video (small view when remote exists)
          if (_remoteRenderers.isNotEmpty)
            Positioned(
              top: 50,
              right: 20,
              child: _buildLocalVideoSmall(),
            ),

          // Top bar with call info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteVideos() {
    if (_remoteRenderers.length == 1) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: RTCVideoView(_remoteRenderers.values.first),
      );
    } else {
      // Grid view for multiple participants
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _remoteRenderers.length > 4 ? 3 : 2,
        ),
        itemCount: _remoteRenderers.length,
        itemBuilder: (context, index) {
          final renderer = _remoteRenderers.values.elementAt(index);
          return Container(
            margin: const EdgeInsets.all(2),
            child: RTCVideoView(renderer),
          );
        },
      );
    }
  }

  Widget _buildLocalVideoFullScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: RTCVideoView(_localRenderer, mirror: true),
    );
  }

  Widget _buildLocalVideoSmall() {
    return Container(
      width: 120,
      height: 160,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: RTCVideoView(_localRenderer, mirror: true),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Group Call',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '00:45',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            onPressed: _toggleMute,
            backgroundColor:
                _isMuted ? Colors.red : Colors.white.withOpacity(0.3),
          ),

          // Video toggle button
          _buildControlButton(
            icon: _isVideoOff ? Icons.videocam_off : Icons.videocam,
            onPressed: _toggleVideo,
            backgroundColor:
                _isVideoOff ? Colors.red : Colors.white.withOpacity(0.3),
          ),

          // Screen share button
          _buildControlButton(
            icon:
                _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            onPressed: _toggleScreenShare,
            backgroundColor:
                _isScreenSharing ? Colors.blue : Colors.white.withOpacity(0.3),
          ),

          // Invite people button
          _buildControlButton(
            icon: Icons.person_add,
            onPressed: _showInviteBottomSheet,
            backgroundColor: Colors.green,
          ),

          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: _endCall,
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderers.values.forEach((renderer) => renderer.dispose());
    _localStream?.dispose();
    _peerConnections.values.forEach((connection) => connection.dispose());
    _searchController.dispose();
    super.dispose();
  }
}

class Contact {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;

  Contact({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
  });
}
