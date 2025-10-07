import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:capstone_2/services/global_call_service.dart';
import 'package:capstone_2/services/agora_call_service.dart';
import 'package:capstone_2/services/agora_config.dart';

class AgoraChatCallScreen extends StatefulWidget {
  final String callId;
  final String currentUserId;
  final List<String> initialParticipants;

  const AgoraChatCallScreen({
    super.key,
    required this.callId,
    required this.currentUserId,
    required this.initialParticipants,
  });

  @override
  State<AgoraChatCallScreen> createState() => _AgoraChatCallScreenState();
}

class _AgoraChatCallScreenState extends State<AgoraChatCallScreen> {
  late AgoraCallService _agoraService;
  RtcEngine? _engine;
  bool _isScreenSharing = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  // Remote users in the call
  final Set<int> _remoteUids = {};
  final Set<int> _remoteScreenSharing = {};

  // Add timer functionality
  DateTime? _callStartTime;
  Timer? _callTimer;
  String _callDuration = '00:00';
  bool _isCallActive = false;
  StreamSubscription<DocumentSnapshot>? _callStatusListener;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _startCallTimer();
    _agoraService = AgoraCallService();
    _initializeCall();
    _loadContacts();

    // Join existing call using the provided callId
    if (widget.callId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinExistingCall(widget.callId);
      });
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        setState(() {
          _callDuration = _formatDuration(duration);
        });
      }
    });
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

  Future<void> _initializeCall() async {
    try {
      print('🚀 Starting optimized Agora initialization...');

      // Request permissions first (in parallel)
      final permissionFuture =
          [Permission.microphone, Permission.camera].request();

      // Initialize Agora service
      final initSuccess = await _agoraService.initialize();

      if (!initSuccess) {
        throw Exception('Failed to initialize Agora engine');
      }

      _engine = _agoraService.engine;

      // Wait for permissions
      await permissionFuture;

      // Set up event handlers
      _setupAgoraEventHandlers();

      print('✅ Agora initialized successfully');

      // Enable video immediately for faster connection
      await _engine?.enableVideo();
      await _engine?.enableAudio();
    } catch (e) {
      print('❌ Error initializing Agora: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize call: $e')),
      );
    }
  }

  void _setupAgoraEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print(
            '📞 ✅ Local user ${connection.localUid} joined channel: ${connection.channelId} successfully in ${elapsed}ms');
        if (mounted) {
          setState(() {
            _isCallActive = true;
          });

          // Show immediate feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '✅ Connected to channel! Waiting for other participant...'),
                backgroundColor: Colors.green),
          );
        }
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print(
            '👥 ✅ Remote user $remoteUid joined channel ${connection.channelId} - Call is now active!');
        if (mounted) {
          setState(() {
            _remoteUids.add(remoteUid);
            _isCallActive = true;
          });

          // Show call active feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 Call connected! Both participants ready.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      onUserOffline: (RtcConnection connection, int remoteUid,
          UserOfflineReasonType reason) {
        print(
            '👋 Remote user $remoteUid left channel ${connection.channelId}: $reason');
        if (mounted) {
          setState(() {
            _remoteUids.remove(remoteUid);
            // Keep call active if we're still in channel
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Other participant left the call')),
          );
        }
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        print('📱 Left channel ${connection.channelId}');
        if (mounted) {
          setState(() {
            _isCallActive = false;
            _remoteUids.clear();
          });
        }
      },
      onConnectionStateChanged: (RtcConnection connection,
          ConnectionStateType state, ConnectionChangedReasonType reason) {
        print(
            '🔗 Connection state changed: $state, reason: $reason for channel: ${connection.channelId}');

        if (state == ConnectionStateType.connectionStateConnected && mounted) {
          setState(() {
            _isCallActive = true;
          });
        } else if (state == ConnectionStateType.connectionStateFailed) {
          print('❌ Connection failed for channel: ${connection.channelId}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Connection failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onError: (ErrorCodeType err, String msg) {
        print('❌ Agora error: $err - $msg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Call error: $msg'), backgroundColor: Colors.red),
          );
        }
      },
      onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state, LocalVideoStreamReason reason) {
        print('📹 Local video state changed: source=$source, state=$state, reason=$reason');
        if (source == VideoSourceType.videoSourceScreen) {
          if (state == LocalVideoStreamState.localVideoStreamStateStopped) {
            print('📱 Screen sharing stopped');
            if (mounted) {
              setState(() {
                _isScreenSharing = false;
              });
            }
          } else if (state == LocalVideoStreamState.localVideoStreamStateCapturing) {
            print('📱 Screen sharing started');
            if (mounted) {
              setState(() {
                _isScreenSharing = true;
              });
            }
          }
        }
      },
      onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        print('📹 Remote video state changed: uid=$remoteUid, state=$state, reason=$reason');
        if (mounted) {
          setState(() {
            // Track screen sharing based on video state
            if (state == RemoteVideoState.remoteVideoStateStarting || state == RemoteVideoState.remoteVideoStateDecoding) {
              // Check if this is screen sharing (you might need to use other indicators)
              // For now, we'll track it based on stream type in the future
            } else if (state == RemoteVideoState.remoteVideoStateStopped) {
              _remoteScreenSharing.remove(remoteUid);
            }
          });
        }
      },
    ));
  }

  void _joinExistingCall(String callId) async {
    try {
      print('🔄 Starting optimized call join for: $callId');
      print('🔑 Using Agora App ID: ${AgoraConfig.getAppId()}');
      print('👤 Current User ID: ${widget.currentUserId}');

      // Check if widget is still mounted
      if (!mounted) {
        print('⚠️ Widget unmounted, cancelling call join');
        return;
      }

      // Critical: Add a small delay to ensure both users are ready
      await Future.delayed(Duration(milliseconds: 1000));

      if (!mounted) return;

      // Join Agora channel immediately - don't wait for Firebase
      print('🚀 Attempting to join Agora channel: $callId');
      final joinSuccess = await _agoraService.joinVideoCall(callId);

      if (!mounted) return; // Check again after async operation

      if (joinSuccess) {
        print('✅ Successfully joined Agora channel: $callId');
        if (mounted) {
          setState(() {
            _isCallActive = true; // Set active immediately on successful join
          });

          // Show success immediately
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Joined call channel successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Failed to join Agora channel: $callId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Failed to connect to call. Please check your connection.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get call document in background (non-blocking)
      FirebaseFirestore.instance
          .collection('Calls')
          .doc(callId)
          .get()
          .then((callDoc) {
        if (!mounted) return; // Check mounted status

        if (callDoc.exists) {
          final callData = callDoc.data()!;
          final callerId = callData['callerId'] as String?;
          final recipientId = callData['recipientId'] as String?;
          final status = callData['status'] as String?;

          print(
              '📋 Call info retrieved: Caller: $callerId, Recipient: $recipientId, Status: $status');

          // Set up status listener
          _setupCallStatusListener(callId);
        }
      }).catchError((e) {
        print('⚠️ Error getting call document (non-critical): $e');
      });
    } catch (e) {
      print('❌ Error joining call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join call: $e')),
        );
      }
    }
  }

  void _setupCallStatusListener(String callId) {
    _callStatusListener = FirebaseFirestore.instance
        .collection('Calls')
        .doc(callId)
        .snapshots()
        .listen((docSnap) async {
      if (!docSnap.exists) return;

      final data = docSnap.data()!;
      final status = data['status'] as String?;

      if (status == 'ended') {
        print('📞 Call ended by other participant');
        _endCall();
      }
    });
  }

  Future<void> _loadContacts() async {
    // Sample contacts - in real app, load from Firebase or API
    _contacts = [
      Contact(
        id: 'user1',
        name: 'John Doe',
        avatar: 'asset/images/profile.jpg',
        isOnline: true,
      ),
      Contact(
        id: 'user2',
        name: 'Jane Smith',
        avatar: 'asset/images/profile.jpg',
        isOnline: false,
      ),
      Contact(
        id: 'user3',
        name: 'Mike Johnson',
        avatar: 'asset/images/profile.jpg',
        isOnline: true,
      ),
    ];

    setState(() {
      _filteredContacts = _contacts;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleScreenShare() async {
    try {
      if (_isScreenSharing) {
        // Stop screen sharing and return to camera
        await _stopScreenShare();
      } else {
        // Start screen sharing
        await _startScreenShare();
      }
    } catch (e) {
      print('Error toggling screen share: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screen sharing error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startScreenShare() async {
    try {
      // Request screen recording permission on Android
      await Permission.systemAlertWindow.request();
      
      // Stop camera capture first
      await _engine?.stopCameraCapture(VideoSourceType.videoSourceCamera);
      
      // Configure screen capture parameters
      const screenCaptureParams = ScreenCaptureParameters2(
        captureAudio: true,
        audioParams: ScreenAudioParameters(
          sampleRate: 48000,
          channels: 2,
          captureSignalVolume: 100,
        ),
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 1920, height: 1080),
          frameRate: 15,
          bitrate: 2000,
        ),
      );

      // Start screen capture
      await _engine?.startScreenCapture(screenCaptureParams);
      
      // Update channel media options to publish screen share
      const options = ChannelMediaOptions(
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        publishScreenTrack: true,
        publishScreenCaptureAudio: true,
        publishScreenCaptureVideo: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      );
      
      await _engine?.updateChannelMediaOptions(options);

      setState(() {
        _isScreenSharing = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screen sharing started'),
          backgroundColor: Colors.green,
        ),
      );

      print('✅ Screen sharing started successfully');
    } catch (e) {
      print('❌ Error starting screen share: $e');
      throw e;
    }
  }

  Future<void> _stopScreenShare() async {
    try {
      // Stop screen capture
      await _engine?.stopScreenCapture();
      
      // Restart camera capture
      await _engine?.startCameraCapture(
        sourceType: VideoSourceType.videoSourceCamera,
        config: const CameraCapturerConfiguration(
          cameraDirection: CameraDirection.cameraFront,
        ),
      );
      
      // Update channel media options to publish camera
      const options = ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        publishScreenTrack: false,
        publishScreenCaptureAudio: false,
        publishScreenCaptureVideo: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      );
      
      await _engine?.updateChannelMediaOptions(options);

      setState(() {
        _isScreenSharing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screen sharing stopped'),
          backgroundColor: Colors.orange,
        ),
      );

      print('✅ Screen sharing stopped successfully');
    } catch (e) {
      print('❌ Error stopping screen share: $e');
      throw e;
    }
  }

  void _showInviteBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildInviteSheet(),
    );
  }

  Widget _buildInviteSheet() {
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
    print('Inviting ${contact.name} to call using GlobalCallService');

    // Use GlobalCallService to create call
    GlobalCallService().createCall(
      recipientId: contact.id,
      peerConnectionConfig: {}, // Not needed for Agora
    ).then((callId) {
      if (callId != null) {
        print('Call initiated successfully with ID: $callId');
      } else {
        print('Failed to initiate call');
      }
    }).catchError((error) {
      print('Error initiating call: $error');
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inviting ${contact.name} to call...')),
    );
  }

  void _toggleMute() async {
    await _agoraService.toggleMute(!_isMuted);
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  void _toggleVideo() async {
    await _agoraService.toggleVideo(_isVideoOff);
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
  }

  void _endCall() async {
    print('📞 Ending call...');

    // Stop the timer
    _callTimer?.cancel();

    // Cancel the status listener
    _callStatusListener?.cancel();

    // Use GlobalCallService to end the call properly
    try {
      await GlobalCallService().endCall(widget.callId);
      print('✅ Call ended via GlobalCallService');
    } catch (e) {
      print('❌ Error ending call via GlobalCallService: $e');
    }

    // Leave Agora channel
    await _agoraService.leaveChannel();

    print('📱 Navigating back from call');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main video view
          if (_remoteUids.isNotEmpty)
            _buildRemoteVideos()
          else
            _buildLocalVideoFullScreen(),

          // Local video (small view when remote exists)
          if (_remoteUids.isNotEmpty)
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
    if (_remoteUids.length == 1) {
      final remoteUid = _remoteUids.first;
      return Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine!,
                canvas: VideoCanvas(uid: remoteUid),
                connection: RtcConnection(channelId: widget.callId),
              ),
            ),
          ),
          // Screen sharing indicator for remote user
          if (_remoteScreenSharing.contains(remoteUid))
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.screen_share, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Remote Screen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      // Grid view for multiple participants
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _remoteUids.length > 4 ? 3 : 2,
        ),
        itemCount: _remoteUids.length,
        itemBuilder: (context, index) {
          final remoteUid = _remoteUids.elementAt(index);
          return Container(
            margin: const EdgeInsets.all(2),
            child: Stack(
              children: [
                AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: remoteUid),
                    connection: RtcConnection(channelId: widget.callId),
                  ),
                ),
                // Screen sharing indicator for remote user in grid
                if (_remoteScreenSharing.contains(remoteUid))
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.screen_share, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'Screen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildLocalVideoFullScreen() {
    if (_engine == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine!,
              canvas: VideoCanvas(
                uid: 0,
                sourceType: _isScreenSharing 
                    ? VideoSourceType.videoSourceScreen 
                    : VideoSourceType.videoSourceCamera,
              ),
            ),
          ),
        ),
        // Screen sharing indicator
        if (_isScreenSharing)
          Positioned(
            top: 60,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.screen_share, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Screen Sharing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocalVideoSmall() {
    if (_engine == null) return const SizedBox.shrink();

    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine!,
                canvas: VideoCanvas(
                  uid: 0,
                  sourceType: _isScreenSharing 
                      ? VideoSourceType.videoSourceScreen 
                      : VideoSourceType.videoSourceCamera,
                ),
              ),
            ),
            // Screen sharing indicator for small view
            if (_isScreenSharing)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.screen_share, color: Colors.white, size: 10),
                      SizedBox(width: 2),
                      Text(
                        'Screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
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
            onPressed: () => _endCall(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _isCallActive ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _callDuration,
                  style: TextStyle(
                    color: _isCallActive ? Colors.green : Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isCallActive ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isCallActive ? 'LIVE' : 'CONNECTING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    print('🗑️ Disposing AgoraChatCallScreen');
    _callTimer?.cancel();
    _callStatusListener?.cancel();
    _agoraService.leaveChannel();
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
