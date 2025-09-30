import 'package:flutter/material.dart';
import 'package:capstone_2/services/global_call_service.dart';

class CallAwareWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const CallAwareWrapper({
    Key? key,
    required this.child,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  State<CallAwareWrapper> createState() => _CallAwareWrapperState();
}

class _CallAwareWrapperState extends State<CallAwareWrapper> {
  final GlobalCallService _callService = GlobalCallService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCallService();
  }

  void _initializeCallService() {
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _callService.initialize(widget.navigatorKey);
          _isInitialized = true;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Navigator key updates are handled automatically
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
