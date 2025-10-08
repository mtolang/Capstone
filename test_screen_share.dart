import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

void main() {
  runApp(ScreenShareTestApp());
}

class ScreenShareTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen Share Test',
      home: ScreenShareTestPage(),
    );
  }
}

class ScreenShareTestPage extends StatefulWidget {
  @override
  _ScreenShareTestPageState createState() => _ScreenShareTestPageState();
}

class _ScreenShareTestPageState extends State<ScreenShareTestPage> {
  RtcEngine? _engine;
  bool _isScreenSharing = false;
  String _statusMessage = 'Ready to test screen sharing';

  @override
  void initState() {
    super.initState();
    _initializeAgora();
  }

  void _initializeAgora() async {
    try {
      // Initialize Agora engine with proper configuration
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(
        appId:
            'a8d7e9e4f1234567890abcdef1234567', // Replace with your actual App ID
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      setState(() {
        _statusMessage = 'Agora engine initialized successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize Agora: $e';
      });
    }
  }

  void _testScreenShare() async {
    if (_engine == null) {
      setState(() {
        _statusMessage = 'Agora engine not initialized';
      });
      return;
    }

    try {
      if (!_isScreenSharing) {
        // Test screen sharing start
        await _engine!.startScreenCapture(const ScreenCaptureParameters2(
          captureAudio: true,
          captureVideo: true,
          videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(width: 1920, height: 1080),
            frameRate: 15,
            bitrate: 2000,
          ),
          audioParams: ScreenAudioParameters(
            sampleRate: 44100,
            channels: 2,
            captureSignalVolume: 100,
          ),
        ));

        await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenTrack: true,
          publishCameraTrack: false,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        setState(() {
          _isScreenSharing = true;
          _statusMessage = 'Screen sharing started successfully';
        });
      } else {
        // Test screen sharing stop
        await _engine!.stopScreenCapture();

        await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenTrack: false,
          publishCameraTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));

        setState(() {
          _isScreenSharing = false;
          _statusMessage = 'Screen sharing stopped successfully';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Screen sharing error: $e';
      });
    }
  }

  @override
  void dispose() {
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Share Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              size: 100,
              color: _isScreenSharing ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 30),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: _testScreenShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScreenSharing ? Colors.red : Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                _isScreenSharing ? 'Stop Screen Share' : 'Start Screen Share',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Test Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('✓ Agora engine initialization'),
                    Text('✓ Screen capture start/stop'),
                    Text('✓ Audio capture configuration'),
                    Text('✓ Video parameters setup'),
                    Text('✓ Channel media options update'),
                    Text('✓ Error handling'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
