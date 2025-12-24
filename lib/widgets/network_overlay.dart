import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Node {
  late double x;
  late double y;
  late double vx;
  late double vy;
  final String id;

  Node({required double screenWidth, required double screenHeight})
    : id = UniqueKey().toString() {
    final random = Random();
    x = random.nextDouble() * screenWidth;
    y = random.nextDouble() * screenHeight;
    vx = (random.nextDouble() - 0.5) * 0.5; // Slow velocity
    vy = (random.nextDouble() - 0.5) * 0.5;
  }

  void update(double screenWidth, double screenHeight) {
    x += vx;
    y += vy;

    // Bounce off edges
    if (x < 0 || x > screenWidth) vx *= -1;
    if (y < 0 || y > screenHeight) vy *= -1;
  }
}

class Packet {
  final Node start;
  final Node end;
  double progress = 0.0;
  final double speed;

  Packet({required this.start, required this.end})
    : speed = 0.005 + Random().nextDouble() * 0.01; // Random slow speed

  bool update() {
    progress += speed;
    return progress >= 1.0;
  }
}

class NetworkOverlay extends StatefulWidget {
  final int nodeCount;
  final double connectionDistance;

  const NetworkOverlay({
    Key? key,
    this.nodeCount = 40,
    this.connectionDistance = 150.0,
  }) : super(key: key);

  @override
  State<NetworkOverlay> createState() => _NetworkOverlayState();
}

class _NetworkOverlayState extends State<NetworkOverlay>
    with SingleTickerProviderStateMixin {
  late List<Node> nodes;
  late List<Packet> packets;
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    nodes = [];
    packets = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _initializeNodes(size.width, size.height);
    });

    _controller.addListener(_update);
  }

  void _initializeNodes(double width, double height) {
    nodes = List.generate(
      widget.nodeCount,
      (_) => Node(screenWidth: width, screenHeight: height),
    );
  }

  void _update() {
    if (!mounted) return;
    setState(() {
      final size = MediaQuery.of(context).size;

      // Update nodes
      for (var node in nodes) {
        node.update(size.width, size.height);
      }

      // Update packets
      packets.removeWhere((packet) => packet.update());

      // Spawn new packets randomly
      if (_random.nextDouble() < 0.05) {
        // 5% chance per frame
        _spawnPacket();
      }
    });
  }

  void _spawnPacket() {
    if (nodes.isEmpty) return;

    // Find two connected nodes
    final startNode = nodes[_random.nextInt(nodes.length)];
    final nearbyNodes =
        nodes.where((n) {
          if (n == startNode) return false;
          final dx = n.x - startNode.x;
          final dy = n.y - startNode.y;
          return sqrt(dx * dx + dy * dy) < widget.connectionDistance;
        }).toList();

    if (nearbyNodes.isNotEmpty) {
      final endNode = nearbyNodes[_random.nextInt(nearbyNodes.length)];
      packets.add(Packet(start: startNode, end: endNode));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NetworkPainter(
        nodes: nodes,
        packets: packets,
        connectionDistance: widget.connectionDistance,
      ),
      size: Size.infinite,
    );
  }
}

class NetworkPainter extends CustomPainter {
  final List<Node> nodes;
  final List<Packet> packets;
  final double connectionDistance;

  NetworkPainter({
    required this.nodes,
    required this.packets,
    required this.connectionDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withOpacity(0.85),
    );

    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..strokeWidth = 1.0;

    final nodePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..style = PaintingStyle.fill;

    // Draw connections and nodes
    for (int i = 0; i < nodes.length; i++) {
      final nodeA = nodes[i];

      // Draw Node
      canvas.drawCircle(Offset(nodeA.x, nodeA.y), 2.0, nodePaint);

      // Draw Connections
      for (int j = i + 1; j < nodes.length; j++) {
        final nodeB = nodes[j];
        final dx = nodeA.x - nodeB.x;
        final dy = nodeA.y - nodeB.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < connectionDistance) {
          final opacity = 1.0 - (dist / connectionDistance);
          linePaint.color = Colors.white.withOpacity(opacity * 0.15);
          canvas.drawLine(
            Offset(nodeA.x, nodeA.y),
            Offset(nodeB.x, nodeB.y),
            linePaint,
          );
        }
      }
    }

    // Draw Packets (Glowing Lights)
    final packetPaint =
        Paint()
          ..color = Colors.cyanAccent
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (var packet in packets) {
      final x =
          packet.start.x + (packet.end.x - packet.start.x) * packet.progress;
      final y =
          packet.start.y + (packet.end.y - packet.start.y) * packet.progress;

      canvas.drawCircle(Offset(x, y), 3.0, packetPaint);

      // Draw core for extra brightness
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(NetworkPainter oldDelegate) => true;
}
