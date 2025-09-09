import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstone_2/services/call_service.dart';

class CallAwareWidget extends StatefulWidget {
  final Widget child;

  const CallAwareWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<CallAwareWidget> createState() => _CallAwareWidgetState();
}

class _CallAwareWidgetState extends State<CallAwareWidget> {
  final CallService _callService = CallService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeCallService();
  }

  Future<void> _initializeCallService() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get user ID from different sources
      String? userId = prefs.getString('user_id'); // For parents
      if (userId == null) {
        userId = prefs.getString('clinic_id'); // For clinics
      }

      print('CallAwareWidget: Initializing with user ID: $userId');

      if (userId != null && mounted) {
        setState(() {
          _currentUserId = userId;
        });
        _callService.initialize(userId, context);
      } else {
        print('CallAwareWidget: No user ID found in SharedPreferences');
      }
    } catch (e) {
      print('Error initializing call service: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUserId != null) {
      _callService.updateContext(context);
    }
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
