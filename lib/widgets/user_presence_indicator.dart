import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/presence_service.dart';

class UserPresenceIndicator extends StatefulWidget {
  final String userId;

  const UserPresenceIndicator({super.key, required this.userId});

  @override
  State<UserPresenceIndicator> createState() => _UserPresenceIndicatorState();
}

class _UserPresenceIndicatorState extends State<UserPresenceIndicator> {
  final PresenceService _presenceService = PresenceService();
  DateTime? _lastSeen;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Check status every second to update UI if user goes offline
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime?>(
      stream: _presenceService.getLastSeen(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _lastSeen = snapshot.data;
        }

        final isOnline =
            _lastSeen != null &&
            DateTime.now().difference(_lastSeen!).inSeconds <= 10;

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
