import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capstone_2/services/agora_config.dart';
import 'package:capstone_2/services/call_utility.dart';

/// Agora Call Service - Handles WebRTC replacement with Agora
class AgoraCallService {
  static final AgoraCallService _instance = AgoraCallService._internal();
  factory AgoraCallService() => _instance;
  AgoraCallService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;
  String? _currentChannelId;
  bool _isInChannel = false;

  /// Initialize Agora Engine with optimizations
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      CallUtility.log(
          'AgoraCallService', '🚀 Initializing Agora Engine (optimized)');
      CallUtility.log(
          'AgoraCallService', '🔑 Using App ID: ${AgoraConfig.getAppId()}');

      // Request permissions in parallel
      final permissionFuture = _requestPermissions();

      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.getAppId(),
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set optimized audio profile for better quality
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQuality,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      // Enable dual stream mode for better performance
      await _engine!.enableDualStreamMode(enabled: true);

      // Wait for permissions
      await permissionFuture;

      CallUtility.log(
          'AgoraCallService', '✅ Agora Engine initialized successfully');
      _isInitialized = true;
      return true;
    } catch (e) {
      CallUtility.log('AgoraCallService', '❌ Failed to initialize Agora: $e');
      return false;
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    CallUtility.log('AgoraCallService', '🔐 Requesting permissions');

    Map<Permission, PermissionStatus> permissions = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    permissions.forEach((permission, status) {
      CallUtility.log(
          'AgoraCallService', '${permission.toString()}: ${status.toString()}');
    });
  }

  /// Join a voice call channel
  Future<bool> joinVoiceCall(String channelId, {int uid = 0}) async {
    if (!_isInitialized || _engine == null) {
      CallUtility.log('AgoraCallService', '❌ Engine not initialized');
      return false;
    }

    try {
      CallUtility.log('AgoraCallService', '🎤 Joining voice call: $channelId');

      // Disable video for voice call
      await _engine!.disableVideo();
      await _engine!.enableAudio();

      // Join channel
      await _engine!.joinChannel(
        token: "", // Use empty string for no token authentication
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      CallUtility.log('AgoraCallService', '✅ Successfully joined voice call');
      return true;
    } catch (e) {
      CallUtility.log('AgoraCallService', '❌ Failed to join voice call: $e');
      return false;
    }
  }

  /// Join a video call channel with proper cleanup
  Future<bool> joinVideoCall(String channelId, {int uid = 0}) async {
    if (!_isInitialized || _engine == null) {
      CallUtility.log('AgoraCallService', '❌ Engine not initialized');
      return false;
    }

    try {
      // Leave current channel if already in one
      if (_isInChannel && _currentChannelId != null) {
        CallUtility.log('AgoraCallService',
            '� Leaving current channel: $_currentChannelId');
        await _engine!.leaveChannel();
        await Future.delayed(Duration(milliseconds: 500)); // Wait for cleanup
      }

      CallUtility.log('AgoraCallService', '�📹 Joining video call: $channelId');

      // Enable video and audio
      await _engine!.enableVideo();
      await _engine!.enableAudio();

      // Start camera capture for local preview
      await _engine!.startPreview();

      // Join channel with optimized settings
      await _engine!.joinChannel(
        token: "", // Use empty string for no token authentication
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );

      // Update state
      _currentChannelId = channelId;
      _isInChannel = true;

      CallUtility.log('AgoraCallService', '✅ Successfully joined video call');
      return true;
    } catch (e) {
      CallUtility.log('AgoraCallService', '❌ Failed to join video call: $e');
      return false;
    }
  }

  /// Leave current channel
  Future<void> leaveChannel() async {
    if (_engine != null && _isInChannel) {
      CallUtility.log(
          'AgoraCallService', '👋 Leaving channel: $_currentChannelId');
      await _engine!.leaveChannel();
      _isInChannel = false;
      _currentChannelId = null;
    }
  }

  /// Mute/unmute local audio
  Future<void> toggleMute(bool mute) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(mute);
      CallUtility.log(
          'AgoraCallService', '🔇 Audio ${mute ? 'muted' : 'unmuted'}');
    }
  }

  /// Enable/disable local video
  Future<void> toggleVideo(bool enable) async {
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(!enable);
      CallUtility.log(
          'AgoraCallService', '📹 Video ${enable ? 'enabled' : 'disabled'}');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
      CallUtility.log('AgoraCallService', '🔄 Camera switched');
    }
  }

  /// Get the RTC engine instance
  RtcEngine? get engine => _engine;

  /// Check if engine is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose the engine
  Future<void> dispose() async {
    if (_engine != null) {
      CallUtility.log('AgoraCallService', '🗑️ Disposing Agora engine');
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    }
  }
}
