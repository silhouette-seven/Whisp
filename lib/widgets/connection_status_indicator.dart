import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectionStatusIndicator extends StatefulWidget {
  const ConnectionStatusIndicator({Key? key}) : super(key: key);

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isConnected = false;
  bool _isChecking = true;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _checkConnection();

    // Check connection every 10 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    if (!mounted) return;

    // Start checking animation
    setState(() {
      _isChecking = true;
    });
    _controller.repeat(reverse: true);

    // Simulate a brief delay for the animation to be visible
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isConnected = true;
            _isChecking = false;
          });
          _controller.stop();
        }
      }
    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
        _controller.stop();
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: _controller,
              curve: Interval(index * 0.2, 1.0, curve: Curves.easeInOut),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      );
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green : Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.red).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
