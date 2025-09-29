import 'package:flutter/material.dart';
import 'package:capstone_2/services/global_call_service.dart';

class CallAwareWrapper extends StatefulWidget {
  final Widget child;

  const CallAwareWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<CallAwareWrapper> createState() => _CallAwareWrapperState();
}

class _CallAwareWrapperState extends State<CallAwareWrapper> {
  final GlobalCallService _callService = GlobalCallService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callService.initialize(context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _callService.updateContext(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
