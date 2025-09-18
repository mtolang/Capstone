import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone_2/chat/calling.dart';
import 'package:capstone_2/services/global_call_service.dart';

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

  // Call timer variables
  Timer? _callTimer;
  DateTime? _callStartTime;
  String _callDuration = '00:00';

  // REMOVED: _incomingCallListener - now handled by GlobalCallService

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _loadContacts();

    // Auto-start call if there are initial participants (caller scenario)
    if (widget.initialParticipants.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDirectCall(widget.initialParticipants.first);
      });
    } else {
      // Check if this is joining an existing call (callee scenario)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinExistingCall();
      });
    }
  }

  Future<void> _joinExistingCall() async {
    try {
      // Get the current call document
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(widget.callId)
          .get();

      if (!callDoc.exists) return;

      final callData = callDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(callData['participants'] ?? []);
      final invitations =
          callData['invitations'] as Map<String, dynamic>? ?? {};
      final offers = callData['offers'] as Map<String, dynamic>? ?? {};

      // Check if this user accepted the call
      if (invitations.containsKey(widget.currentUserId)) {
        final invitation =
            invitations[widget.currentUserId] as Map<String, dynamic>;
        if (invitation['status'] == 'accepted') {
          // Start call timer for the joiner
          _startCallTimer();

          // Setup WebRTC connections with other participants
          for (String participantId in participants) {
            if (participantId != widget.currentUserId) {
              await _setupAnswerPeerConnection(participantId, offers);
            }
          }
        }
      }
    } catch (e) {
      print('Error joining existing call: $e');
    }
  }

  Future<void> _setupAnswerPeerConnection(
      String participantId, Map<String, dynamic> offers) async {
    try {
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };
      final pc = await createPeerConnection(config);
      _peerConnections[participantId] = pc;

      // Add local stream tracks
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) {
          pc.addTrack(track, _localStream!);
        });
      }

      // Listen for remote stream
      pc.onAddStream = (stream) {
        setState(() {
          if (!_remoteRenderers.containsKey(participantId)) {
            _remoteRenderers[participantId] = RTCVideoRenderer();
            _remoteRenderers[participantId]!.initialize().then((_) {
              _remoteRenderers[participantId]!.srcObject = stream;
              setState(() {});
            });
          }
        });
      };

      // Handle ICE candidates
      pc.onIceCandidate = (candidate) {
        FirebaseFirestore.instance
            .collection('Calls')
            .doc(widget.callId)
            .update({
          'iceCandidates': FieldValue.arrayUnion([
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'from': widget.currentUserId,
              'to': participantId,
            }
          ])
        });
      };

      // Check if there's an offer from this participant
      final participantOffers =
          offers[participantId] as Map<String, dynamic>? ?? {};
      final offerData = participantOffers[widget.currentUserId];

      if (offerData != null) {
        // Set remote description from the offer
        final offerDesc =
            RTCSessionDescription(offerData['sdp'], offerData['type']);
        await pc.setRemoteDescription(offerDesc);

        // Create and send answer
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);

        // Save answer to Firestore
        await FirebaseFirestore.instance
            .collection('Calls')
            .doc(widget.callId)
            .update({
          'answers.$participantId.${widget.currentUserId}': {
            'sdp': answer.sdp,
            'type': answer.type,
          }
        });
      }

      print('Setup answer peer connection with $participantId');
    } catch (e) {
      print('Error setting up answer peer connection with $participantId: $e');
    }
  }

  Future<void> _setupPeerConnectionWithParticipant(String participantId) async {
    try {
      final config = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };
      final pc = await createPeerConnection(config);
      _peerConnections[participantId] = pc;

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
            _remoteRenderers[participantId] = renderer;
          });
        });
      };

      // Handle ICE candidates
      pc.onIceCandidate = (candidate) {
        FirebaseFirestore.instance
            .collection('Calls')
            .doc(widget.callId)
            .update({
          'iceCandidates.${widget.currentUserId}.$participantId':
              FieldValue.arrayUnion([candidate.toMap()])
        });
      };

      // Create offer for this participant
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      // Save offer to Firestore
      await FirebaseFirestore.instance
          .collection('Calls')
          .doc(widget.callId)
          .update({'offers.${widget.currentUserId}.$participantId': offer.sdp});

      print('Setup peer connection with $participantId');
    } catch (e) {
      print('Error setting up peer connection with $participantId: $e');
    }
  }

  // REMOVED: _navigateToCallingScreen method - now handled by GlobalCallService
  // This prevents duplicate incoming call handling and infinite loops

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
            // Start the call timer for the caller
            if (_callTimer == null) {
              _startCallTimer();
            }
          } catch (e) {
            print('Error setting remote description: $e');
          }
        }

        if (data['status'] == 'declined') {
          _endCall();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Call declined')),
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
        SnackBar(content: Text('Calling...')),
      );
    } catch (e) {
      print('Error starting call: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start call')),
      );
    }
  }

  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _requestPermissions();
    await _getUserMedia();
  }

  Future<void> _requestPermissions() async {
    // Only request basic permissions on startup
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
      // Show permission dialog first
      bool permissionGranted = await _requestScreenSharePermission();

      if (!permissionGranted) {
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Starting screen share...'),
            ],
          ),
        ),
      );

      MediaStream? screenStream;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile: Use getDisplayMedia which works on newer devices
        try {
          screenStream = await navigator.mediaDevices.getDisplayMedia({
            'video': {
              'width': {'max': 1920},
              'height': {'max': 1080},
              'frameRate': {'max': 15}
            },
            'audio': false // Audio screen capture is complex on mobile
          });
        } catch (e) {
          print('Mobile getDisplayMedia failed: $e');

          // Close loading dialog
          Navigator.pop(context);

          // Show mobile-specific guidance
          _showMobileScreenShareGuide();
          return;
        }
      } else {
        // For web/desktop platforms
        try {
          screenStream = await navigator.mediaDevices.getDisplayMedia({
            'video': {
              'displaySurface': 'monitor',
              'width': {'max': 1920},
              'height': {'max': 1080},
              'frameRate': {'max': 30}
            },
            'audio': true
          });
        } catch (e) {
          print('Desktop getDisplayMedia failed: $e');
          throw e;
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      // Update local renderer
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('✅ Screen sharing started'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Listen for screen share end
      if (screenStream.getVideoTracks().isNotEmpty) {
        screenStream.getVideoTracks().first.onEnded = () {
          print('Screen share ended by user');
          setState(() {
            _isScreenSharing = false;
          });
          _getUserMedia(); // Return to camera
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📱 Screen sharing stopped'),
              backgroundColor: Colors.orange,
            ),
          );
        };
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error starting screen share: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Screen sharing failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMobileScreenShareGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_android, color: Colors.blue),
            SizedBox(width: 8),
            Text('Mobile Screen Share'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Android Screen Share Steps:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700),
                    ),
                    SizedBox(height: 8),
                    Text('1. Pull down notification panel',
                        style: TextStyle(fontSize: 13)),
                    Text('2. Look for "Screen record" or "Cast" button',
                        style: TextStyle(fontSize: 13)),
                    Text('3. Tap it and select this app',
                        style: TextStyle(fontSize: 13)),
                    Text('4. Grant permission when prompted',
                        style: TextStyle(fontSize: 13)),
                    Text('5. Return to this app - screen should be shared',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Alternative Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.videocam,
                title: 'Camera Pointing',
                description:
                    'Point your camera at the screen you want to share',
                onTap: () {
                  Navigator.pop(context);
                  if (_isVideoOff) _toggleVideo();
                },
              ),
              SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.refresh,
                title: 'Try Screen Share Again',
                description: 'Attempt screen sharing one more time',
                onTap: () {
                  Navigator.pop(context);
                  _startScreenShare();
                },
              ),
              SizedBox(height: 8),
              _buildGuideOption(
                icon: Icons.apps,
                title: 'Use External App',
                description: 'Try Google Meet, Zoom, or TeamViewer',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Consider using Google Meet, Zoom, or TeamViewer for reliable screen sharing'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showIOSScreenShareGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_iphone, color: Colors.blue),
            SizedBox(width: 8),
            Text('iOS Screen Share'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 iOS Screen Share Steps:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700),
                  ),
                  SizedBox(height: 8),
                  Text('1. Open Control Center (swipe down from top-right)',
                      style: TextStyle(fontSize: 13)),
                  Text('2. Tap and hold the Screen Recording button',
                      style: TextStyle(fontSize: 13)),
                  Text('3. Select this app from the list',
                      style: TextStyle(fontSize: 13)),
                  Text('4. Tap "Start Broadcast"',
                      style: TextStyle(fontSize: 13)),
                  Text('5. Return to this app', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Note: iOS has strict screen sharing restrictions for security.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startScreenShare();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestScreenSharePermission() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.screen_share, color: Colors.blue),
                SizedBox(width: 8),
                Text('Screen Share Permission'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To share your screen, this app needs permission to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                _buildPermissionItem('📱', 'Capture screen content'),
                _buildPermissionItem('🎥', 'Access camera and microphone'),
                _buildPermissionItem('🔊', 'Share system audio (if available)'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 Mobile Note:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Screen sharing on mobile may have limitations due to security restrictions. We\'ll try our best!',
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Actually request the permissions
                  final results = await [
                    Permission.camera,
                    Permission.microphone,
                    Permission.systemAlertWindow,
                  ].request();

                  bool allGranted = results.values.every((status) =>
                      status == PermissionStatus.granted ||
                      status == PermissionStatus.limited);

                  Navigator.pop(context, allGranted);

                  if (!allGranted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '⚠️ Some permissions were denied. Screen sharing may not work properly.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text('Grant Permissions',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildPermissionItem(String emoji, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(description, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
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

  void _startCallTimer() {
    _callStartTime = DateTime.now();
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        setState(() {
          _callDuration = _formatDuration(duration);
        });
      }
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
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
        final data = doc.data() as Map<String, dynamic>;
        if (doc.id != widget.currentUserId) {
          // Don't include current user
          loadedContacts.add(Contact(
            id: doc.id,
            name: data['Clinic Name'] ?? 'Unknown Clinic',
            avatar: 'asset/icons/logo_ther.png', // Use existing asset
            isOnline: true, // You can implement online status later
          ));
        }
      }

      // Load parents from ParentsAcc collection
      final parentsSnapshot =
          await FirebaseFirestore.instance.collection('ParentsAcc').get();

      for (var doc in parentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (doc.id != widget.currentUserId) {
          // Don't include current user
          loadedContacts.add(Contact(
            id: doc.id,
            name: data['Name'] ?? 'Unknown Parent',
            avatar: 'asset/icons/user (1).png', // Use existing asset
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

  void _inviteToCall(Contact contact) async {
    if (!mounted) return;

    try {
      // Use GlobalCallService to initiate the call
      final peerConnectionConfig = {
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      };

      final callId = await GlobalCallService().initiateCall(
        targetUserId: contact.id,
        peerConnectionConfig: peerConnectionConfig,
      );

      if (callId != null) {
        // Setup peer connection for this call
        await _setupPeerConnectionForCall(callId, contact.id);

        if (mounted) {
          Navigator.pop(context); // Close invite bottom sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling ${contact.name}...')),
          );
        }
      } else {
        throw Exception('Failed to create call');
      }
    } catch (e) {
      print('Error inviting to call: $e');
      if (mounted) {
        Navigator.pop(context); // Close invite bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call ${contact.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setupPeerConnectionForCall(
      String callId, String targetUserId) async {
    try {
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
          if (!_remoteRenderers.containsKey(targetUserId)) {
            _remoteRenderers[targetUserId] = RTCVideoRenderer();
            _remoteRenderers[targetUserId]!.initialize().then((_) {
              _remoteRenderers[targetUserId]!.srcObject = stream;
              setState(() {});
            });
          }
        });
      };

      // Handle ICE candidates
      pc.onIceCandidate = (candidate) {
        FirebaseFirestore.instance.collection('Calls').doc(callId).update({
          'iceCandidates': FieldValue.arrayUnion([
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
              'from': widget.currentUserId,
              'to': targetUserId,
            }
          ])
        });
      };

      // Create offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      // Save offer to Firestore
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'offers.${widget.currentUserId}.$targetUserId': {
          'sdp': offer.sdp,
          'type': offer.type,
        }
      });

      // Listen for answer and call status changes
      _listenForCallUpdates(callId, targetUserId);

      print('Setup peer connection for call $callId with $targetUserId');
    } catch (e) {
      print('Error setting up peer connection for call: $e');
      throw e;
    }
  }

  void _listenForCallUpdates(String callId, String targetUserId) {
    FirebaseFirestore.instance
        .collection('Calls')
        .doc(callId)
        .snapshots()
        .listen((docSnap) async {
      if (!docSnap.exists) return;

      final data = docSnap.data() as Map<String, dynamic>;
      final invitations = data['invitations'] as Map<String, dynamic>? ?? {};

      // Check if target user accepted the call
      if (invitations.containsKey(targetUserId)) {
        final invitation = invitations[targetUserId] as Map<String, dynamic>;
        if (invitation['status'] == 'accepted') {
          _startCallTimer();

          // Handle answer if available
          final answers = data['answers'] as Map<String, dynamic>? ?? {};
          final userAnswers =
              answers[targetUserId] as Map<String, dynamic>? ?? {};
          final answer = userAnswers[widget.currentUserId];

          if (answer != null && _peerConnections.containsKey(targetUserId)) {
            final pc = _peerConnections[targetUserId]!;
            final answerDesc =
                RTCSessionDescription(answer['sdp'], answer['type']);
            await pc.setRemoteDescription(answerDesc);
          }
        } else if (invitation['status'] == 'declined') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Call declined')),
            );
          }
          // Clean up peer connection
          _peerConnections[targetUserId]?.close();
          _peerConnections.remove(targetUserId);
        }
      }

      // Handle ICE candidates
      final iceCandidates = data['iceCandidates'] as List? ?? [];
      for (var candidate in iceCandidates) {
        if (candidate['to'] == widget.currentUserId &&
            candidate['from'] == targetUserId &&
            _peerConnections.containsKey(targetUserId)) {
          final pc = _peerConnections[targetUserId]!;
          await pc.addCandidate(RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  Future<String?> _findActiveCall() async {
    try {
      // Look for active calls where current user is participant
      final snapshot = await FirebaseFirestore.instance
          .collection('Calls')
          .where('participants', arrayContains: widget.currentUserId)
          .where('status', whereIn: ['active', 'ringing'])
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('Error finding active call: $e');
      return null;
    }
  }

  Future<void> _addParticipantToCall(String callId, Contact contact) async {
    try {
      // Get current call data
      final callDoc = await FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get();

      if (!callDoc.exists) return;

      final callData = callDoc.data() as Map<String, dynamic>;
      final currentParticipants =
          List<String>.from(callData['participants'] ?? []);

      // Limit to 4 participants maximum
      if (currentParticipants.length >= 4) {
        throw 'Maximum 4 participants allowed in a call';
      }

      // Add new participant
      await FirebaseFirestore.instance.collection('Calls').doc(callId).update({
        'participants': FieldValue.arrayUnion([contact.id]),
        'type': 'group',
        'invitations.${contact.id}': {
          'status': 'pending',
          'invitedBy': widget.currentUserId,
          'invitedAt': DateTime.now(),
        }
      });

      print('Added ${contact.name} to existing call $callId');
    } catch (e) {
      print('Error adding participant: $e');
      throw e;
    }
  }

  Future<void> _createNewCall(Contact contact) async {
    try {
      final callDoc = FirebaseFirestore.instance.collection('Calls').doc();

      // Create call document with proper structure
      await callDoc.set({
        'callId': callDoc.id,
        'participants': [widget.currentUserId, contact.id],
        'status': 'ringing',
        'type': '1-on-1',
        'createdBy': widget.currentUserId,
        'createdAt': DateTime.now(),
        'offers': {},
        'answers': {},
        'iceCandidates': {},
        'invitations': {
          contact.id: {
            'status': 'pending',
            'invitedBy': widget.currentUserId,
            'invitedAt': DateTime.now(),
          }
        }
      });

      print('Created new call ${callDoc.id} for ${contact.name}');
    } catch (e) {
      print('Error creating new call: $e');
      throw e;
    }
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
    // Stop the call timer
    _stopCallTimer();

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

    // Check if widget is still mounted before navigation
    if (mounted) {
      Navigator.pop(context);
    }
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Video Call',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  _callDuration,
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
    _stopCallTimer();
    // REMOVED: _incomingCallListener disposal - now handled by GlobalCallService
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
