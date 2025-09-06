import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatCallScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final List<String> initialParticipants;

  const ChatCallScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.initialParticipants,
  });

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

    // Auto-start call if there are initial participants
    if (widget.initialParticipants.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDirectCall(widget.initialParticipants.first);
      });
    }

    // Listen for incoming calls where this user is the callee and status is 'ringing'
    FirebaseFirestore.instance
        .collection('Calls')
        .where('calleeId', isEqualTo: widget.currentUserId)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        _showIncomingCallDialog(doc.id, doc.data()['callerId']);
      }
    });
  }

  void _startDirectCall(String targetUserId) async {
    // Create a new call document in Firestore and start WebRTC offer
    final callsCollection = FirebaseFirestore.instance.collection('Calls');
    final newCallDoc = callsCollection.doc();

    try {
      await newCallDoc.set({
        'callerId': widget.currentUserId,
        'calleeId': targetUserId,
        'status': 'ringing',
        'offer': 'Blank',
        'answer': 'Blank',
        'iceCandidates': [],
        'timestamp': DateTime.now(),
      });

      // Start WebRTC offer
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };
      final pc = await createPeerConnection(config);
      _peerConnections[targetUserId] = pc;

      // Add local stream tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }

      // Listen for remote stream
      pc.onAddStream = (stream) {
        setState(() {
          final renderer = RTCVideoRenderer();
          renderer.initialize().then((_) {
            renderer.srcObject = stream;
            _remoteRenderers[targetUserId] = renderer;
          });
        });
      };

      // Listen for ICE candidates and save to Firestore
      pc.onIceCandidate = (candidate) {
        newCallDoc.update({
          'iceCandidates': FieldValue.arrayUnion([
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            }
          ])
        });
      };

      // Create offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      // Save offer to Firestore
      await newCallDoc.update({'offer': offer.sdp});

      // Listen for answer from callee
      newCallDoc.snapshots().listen((docSnap) async {
        final data = docSnap.data();
        if (data == null) return;

        if (data['status'] == 'accepted' && data['answer'] != 'Blank') {
          try {
            await pc.setRemoteDescription(
                RTCSessionDescription(data['answer'], 'answer'));
          } catch (e) {
            print('Error setting remote description: $e');
          }
        }

        if (data['status'] == 'declined') {
          _endCall();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Call declined')),
          );
        }

        // Handle ICE candidates
        if (data['iceCandidates'] != null && data['iceCandidates'] is List) {
          for (var cand in data['iceCandidates']) {
            try {
              await pc.addCandidate(RTCIceCandidate(
                cand['candidate'],
                cand['sdpMid'],
                cand['sdpMLineIndex'],
              ));
            } catch (e) {
              print('Error adding ICE candidate: $e');
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling...')),
      );
    } catch (e) {
      print('Error starting call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start call')),
      );
    }
  }

  void _showIncomingCallDialog(String callDocId, String callerId) async {
    // Get caller name from Firestore
    String callerName = 'Unknown';
    try {
      // Try ClinicAcc first
      final clinicDoc = await FirebaseFirestore.instance
          .collection('ClinicAcc')
          .doc(callerId)
          .get();
      if (clinicDoc.exists) {
        final data = clinicDoc.data() as Map<String, dynamic>;
        callerName = data['Clinic Name'] ?? 'Unknown Clinic';
      } else {
        // Try ParentsAcc
        final parentDoc = await FirebaseFirestore.instance
            .collection('ParentsAcc')
            .doc(callerId)
            .get();
        if (parentDoc.exists) {
          final data = parentDoc.data() as Map<String, dynamic>;
          callerName = data['Name'] ?? 'Unknown Parent';
        }
      }
    } catch (e) {
      print('Error fetching caller name: $e');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Incoming Call'),
          content: Text('You have an incoming call from: $callerName'),
          actions: [
            TextButton(
              onPressed: () {
                // Decline: update status to 'declined'
                FirebaseFirestore.instance
                    .collection('Calls')
                    .doc(callDocId)
                    .update({'status': 'declined'});
                Navigator.of(context).pop();
              },
              child: const Text('Decline'),
            ),
            TextButton(
              onPressed: () async {
                // Accept: update status to 'accepted'
                await FirebaseFirestore.instance
                    .collection('Calls')
                    .doc(callDocId)
                    .update({'status': 'accepted'});
                Navigator.of(context).pop();

                // --- Callee WebRTC answer logic ---
                final callDoc = await FirebaseFirestore.instance
                    .collection('Calls')
                    .doc(callDocId)
                    .get();
                final offerSdp = callDoc['offer'];
                final config = {
                  'iceServers': [
                    {'urls': 'stun:stun.l.google.com:19302'},
                  ]
                };
                final pc = await createPeerConnection(config);
                _peerConnections[callerId] = pc;

                // Add local stream tracks
                if (_localStream != null) {
                  _localStream!.getTracks().forEach((track) {
                    pc.addTrack(track, _localStream!);
                  });
                }

                // Listen for remote stream
                pc.onAddStream = (stream) {
                  setState(() {
                    final renderer = RTCVideoRenderer();
                    renderer.initialize().then((_) {
                      renderer.srcObject = stream;
                      _remoteRenderers[callerId] = renderer;
                    });
                  });
                };

                // Set remote offer
                await pc.setRemoteDescription(
                    RTCSessionDescription(offerSdp, 'offer'));

                // Create answer
                final answer = await pc.createAnswer();
                await pc.setLocalDescription(answer);

                // Save answer to Firestore
                await FirebaseFirestore.instance
                    .collection('Calls')
                    .doc(callDocId)
                    .update({'answer': answer.sdp});

                // Listen for ICE candidates and save to Firestore
                pc.onIceCandidate = (candidate) {
                  FirebaseFirestore.instance
                      .collection('Calls')
                      .doc(callDocId)
                      .update({
                    'iceCandidates': FieldValue.arrayUnion([
                      {
                        'candidate': candidate.candidate,
                        'sdpMid': candidate.sdpMid,
                        'sdpMLineIndex': candidate.sdpMLineIndex,
                      }
                    ])
                  });
                };

                // Listen for remote ICE candidates from caller
                FirebaseFirestore.instance
                    .collection('Calls')
                    .doc(callDocId)
                    .snapshots()
                    .listen((docSnap) async {
                  final data = docSnap.data();
                  if (data == null) return;
                  if (data['iceCandidates'] != null &&
                      data['iceCandidates'] is List) {
                    for (var cand in data['iceCandidates']) {
                      try {
                        await pc.addCandidate(RTCIceCandidate(
                          cand['candidate'],
                          cand['sdpMid'],
                          cand['sdpMLineIndex'],
                        ));
                      } catch (e) {
                        print('Error adding ICE candidate: $e');
                      }
                    }
                  }
                });
              },
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
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

  void _loadContacts() async {
    // Load actual contacts from Firestore
    try {
      List<Contact> loadedContacts = [];

      // Load clinics from ClinicAcc collection
      final clinicsSnapshot =
          await FirebaseFirestore.instance.collection('ClinicAcc').get();

      for (var doc in clinicsSnapshot.docs) {
        final data = doc.data();
        if (doc.id != widget.currentUserId) {
          // Don't include current user
          loadedContacts.add(Contact(
            id: doc.id,
            name: data['Clinic Name'] ?? 'Unknown Clinic',
            avatar: 'assets/clinic.jpg',
            isOnline: true, // You can implement online status later
          ));
        }
      }

      // Load parents from ParentsAcc collection
      final parentsSnapshot =
          await FirebaseFirestore.instance.collection('ParentsAcc').get();

      for (var doc in parentsSnapshot.docs) {
        final data = doc.data();
        if (doc.id != widget.currentUserId) {
          // Don't include current user
          loadedContacts.add(Contact(
            id: doc.id,
            name: data['Name'] ?? 'Unknown Parent',
            avatar: 'assets/parent.jpg',
            isOnline: true, // You can implement online status later
          ));
        }
      }

      setState(() {
        _contacts = loadedContacts;
        _filteredContacts = List.from(_contacts);
      });
    } catch (e) {
      print('Error loading contacts: $e');
      // Fallback to empty list
      setState(() {
        _contacts = [];
        _filteredContacts = [];
      });
    }
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
    // Create a new call document in Firestore and start WebRTC offer
    final callsCollection = FirebaseFirestore.instance.collection('Calls');
    final newCallDoc = callsCollection.doc();
    newCallDoc.set({
      'callerId': widget.currentUserId,
      'calleeId': contact.id,
      'status': 'ringing',
      'offer': 'Blank',
      'answer': 'Blank',
      'iceCandidates': 'Blank',
    }).then((_) async {
      // Start WebRTC offer
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };
      final pc = await createPeerConnection(config);
      _peerConnections[contact.id] = pc;
      // Add local stream tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }
      // Listen for ICE candidates and save to Firestore
      pc.onIceCandidate = (candidate) {
        newCallDoc.update({
          'iceCandidates': FieldValue.arrayUnion([candidate.toMap()])
        });
      };
      // Create offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      // Save offer to Firestore
      await newCallDoc.update({'offer': offer.sdp});
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inviting ${contact.name} to call...')),
    );
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

  void _endCall() async {
    // Update call status to 'ended' in Firestore
    try {
      final callsSnapshot = await FirebaseFirestore.instance
          .collection('Calls')
          .where('callerId', isEqualTo: widget.currentUserId)
          .where('status', whereIn: ['ringing', 'accepted']).get();

      for (var doc in callsSnapshot.docs) {
        await doc.reference.update({'status': 'ended'});
      }

      final calleeSnapshot = await FirebaseFirestore.instance
          .collection('Calls')
          .where('calleeId', isEqualTo: widget.currentUserId)
          .where('status', whereIn: ['ringing', 'accepted']).get();

      for (var doc in calleeSnapshot.docs) {
        await doc.reference.update({'status': 'ended'});
      }
    } catch (e) {
      print('Error ending call in Firestore: $e');
    }

    // Close all peer connections
    for (var connection in _peerConnections.values) {
      await connection.close();
    }
    _peerConnections.clear();

    // Dispose remote renderers
    for (var renderer in _remoteRenderers.values) {
      await renderer.dispose();
    }
    _remoteRenderers.clear();

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
      return SizedBox(
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
    return SizedBox(
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
    for (var renderer in _remoteRenderers.values) {
      renderer.dispose();
    }
    _localStream?.dispose();
    for (var connection in _peerConnections.values) {
      connection.dispose();
    }
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
