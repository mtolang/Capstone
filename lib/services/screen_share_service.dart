import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enhanced Screen Share Service for Mobile and Desktop
///
/// PURPOSE: Provide reliable screen sharing across platforms
/// FEATURES:
/// - Android MediaProjection API support
/// - Desktop getDisplayMedia support
/// - Automatic fallback options
/// - Permission handling
/// - Stream management

class ScreenShareService {
  static final ScreenShareService _instance = ScreenShareService._internal();
  factory ScreenShareService() => _instance;
  ScreenShareService._internal();

  MediaStream? _screenStream;
  bool _isScreenSharing = false;
  StreamController<bool>? _screenShareStateController;

  Stream<bool> get screenShareState =>
      _screenShareStateController?.stream ?? Stream.value(false);
  bool get isScreenSharing => _isScreenSharing;
  MediaStream? get screenStream => _screenStream;

  void initialize() {
    _screenShareStateController = StreamController<bool>.broadcast();
  }

  void dispose() {
    _screenShareStateController?.close();
    _screenShareStateController = null;
  }

  /// Start screen sharing with platform-specific implementation
  Future<MediaStream?> startScreenShare() async {
    try {
      if (Platform.isAndroid) {
        return await _startAndroidScreenShare();
      } else if (Platform.isIOS) {
        return await _startIOSScreenShare();
      } else {
        return await _startDesktopScreenShare();
      }
    } catch (e) {
      print('ScreenShareService: Error starting screen share: $e');
      return null;
    }
  }

  /// Android-specific screen sharing using MediaProjection
  Future<MediaStream?> _startAndroidScreenShare() async {
    try {
      // Check for required permissions
      final permissions = [
        Permission.systemAlertWindow,
        Permission.camera,
        Permission.microphone,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      if (statuses.values.any((status) => !status.isGranted)) {
        print('ScreenShareService: Some permissions denied');
        return null;
      }

      // For Android, use display capture via WebRTC
      // This works better than getDisplayMedia on mobile

      // Try to get display media first
      try {
        _screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': {
            'width': {'max': 1280},
            'height': {'max': 720},
            'frameRate': {'max': 15}
          },
          'audio': false
        });

        if (_screenStream != null) {
          _isScreenSharing = true;
          _screenShareStateController?.add(true);
          _setupScreenShareEndListener();
          return _screenStream;
        }
      } catch (e) {
        print('ScreenShareService: getDisplayMedia failed on Android: $e');
      }

      // Fallback: Use getUserMedia with screen capture hint
      try {
        _screenStream = await navigator.mediaDevices.getUserMedia({
          'video': {
            'mandatory': {
              'chromeMediaSource': 'screen',
              'maxWidth': 1280,
              'maxHeight': 720,
              'maxFrameRate': 15,
            }
          },
          'audio': false
        });

        if (_screenStream != null) {
          _isScreenSharing = true;
          _screenShareStateController?.add(true);
          _setupScreenShareEndListener();
          return _screenStream;
        }
      } catch (e) {
        print('ScreenShareService: getUserMedia screen capture failed: $e');
      }

      return null;
    } catch (e) {
      print('ScreenShareService: Android screen share failed: $e');
      return null;
    }
  }

  /// iOS-specific screen sharing (limited support)
  Future<MediaStream?> _startIOSScreenShare() async {
    try {
      // iOS has very limited screen sharing support
      // Attempt ReplayKit integration through WebRTC
      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'width': {'max': 1280},
          'height': {'max': 720},
          'frameRate': {'max': 15}
        },
        'audio': false
      });

      if (_screenStream != null) {
        _isScreenSharing = true;
        _screenShareStateController?.add(true);
        _setupScreenShareEndListener();
      }

      return _screenStream;
    } catch (e) {
      print('ScreenShareService: iOS screen share failed: $e');
      return null;
    }
  }

  /// Desktop screen sharing using getDisplayMedia
  Future<MediaStream?> _startDesktopScreenShare() async {
    try {
      _screenStream = await navigator.mediaDevices.getDisplayMedia({
        'video': {
          'displaySurface': 'monitor',
          'width': {'max': 1920},
          'height': {'max': 1080},
          'frameRate': {'max': 30}
        },
        'audio': true
      });

      if (_screenStream != null) {
        _isScreenSharing = true;
        _screenShareStateController?.add(true);
        _setupScreenShareEndListener();
      }

      return _screenStream;
    } catch (e) {
      print('ScreenShareService: Desktop screen share failed: $e');
      return null;
    }
  }

  /// Stop screen sharing
  Future<void> stopScreenShare() async {
    try {
      if (_screenStream != null) {
        _screenStream!.getTracks().forEach((track) {
          track.stop();
        });
        await _screenStream!.dispose();
        _screenStream = null;
      }

      _isScreenSharing = false;
      _screenShareStateController?.add(false);
    } catch (e) {
      print('ScreenShareService: Error stopping screen share: $e');
    }
  }

  /// Setup listener for when screen sharing ends naturally
  void _setupScreenShareEndListener() {
    if (_screenStream != null) {
      final videoTracks = _screenStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        // Listen for track ending
        videoTracks.first.onEnded = () {
          print('ScreenShareService: Screen share ended by user');
          _isScreenSharing = false;
          _screenShareStateController?.add(false);
          _screenStream = null;
        };
      }
    }
  }

  /// Request necessary permissions for screen sharing
  Future<bool> requestScreenSharePermissions() async {
    try {
      if (Platform.isAndroid) {
        final permissions = [
          Permission.systemAlertWindow,
          Permission.camera,
          Permission.microphone,
        ];

        Map<Permission, PermissionStatus> statuses =
            await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      } else if (Platform.isIOS) {
        final permissions = [
          Permission.camera,
          Permission.microphone,
        ];

        Map<Permission, PermissionStatus> statuses =
            await permissions.request();
        return statuses.values.every((status) => status.isGranted);
      }

      return true; // Desktop doesn't need special permissions
    } catch (e) {
      print('ScreenShareService: Permission request failed: $e');
      return false;
    }
  }

  /// Show platform-specific guidance for screen sharing
  void showScreenShareGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.screen_share, color: Colors.blue),
            SizedBox(width: 8),
            Text('Screen Share Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (Platform.isAndroid) ...[
                _buildGuideSection(
                  '📱 Android Instructions:',
                  [
                    '1. When prompted, allow screen recording',
                    '2. Select "Start now" in the system dialog',
                    '3. Choose what to share (entire screen/app)',
                    '4. Your screen will be visible to others',
                  ],
                ),
              ] else if (Platform.isIOS) ...[
                _buildGuideSection(
                  '📱 iOS Instructions:',
                  [
                    '1. Open Control Center',
                    '2. Press and hold the screen recording button',
                    '3. Select this app for broadcasting',
                    '4. Start recording to share screen',
                  ],
                ),
              ] else ...[
                _buildGuideSection(
                  '🖥️ Desktop Instructions:',
                  [
                    '1. Choose what to share (screen/window/tab)',
                    '2. Select the content you want to share',
                    '3. Click "Share" to start sharing',
                    '4. Click "Stop sharing" when done',
                  ],
                ),
              ],
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber.shade700),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Screen sharing is only visible during video calls and is not recorded.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              startScreenShare();
            },
            child: Text('Try Screen Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, List<String> steps) {
    return Container(
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
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          SizedBox(height: 8),
          ...steps.map((step) => Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  step,
                  style: TextStyle(fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }
}
