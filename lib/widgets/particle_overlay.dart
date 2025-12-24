import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late double opacity;

  Particle({required double screenWidth, required double screenHeight}) {
    final random = Random();
    x = random.nextDouble() * screenWidth;
    y = random.nextDouble() * screenHeight;
    vx = (random.nextDouble() - 0.5) * 0.3; // velocity x: -1 to 1
    vy = (random.nextDouble() - 0.5) * 0.3; // velocity y: -1 to 1
    size = random.nextDouble() * 4 + 2; // size: 2 to 6
    opacity = random.nextDouble() * 0.3 + 0.2; // opacity: 0.2 to 0.8
  }

  void update(double screenWidth, double screenHeight) {
    x += vx;
    y += vy;

    // wrap around edges
    if (x < 0) x = screenWidth;
    if (x > screenWidth) x = 0;
    if (y < 0) y = screenHeight;
    if (y > screenHeight) y = 0;
  }
}

class ParticleOverlay extends StatefulWidget {
  final int particleCount;

  const ParticleOverlay({Key? key, this.particleCount = 20})
      : super(key: key);

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with TickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    particles = [];
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _initializeParticles(size.width, size.height);
    });

    _animationController.addListener(() {
      setState(() {
        final size = MediaQuery.of(context).size;
        for (var particle in particles) {
          particle.update(size.width, size.height);
        }
      });
    });
  }

  void _initializeParticles(double screenWidth, double screenHeight) {
    particles = List.generate(
      widget.particleCount,
      (index) => Particle(screenWidth: screenWidth, screenHeight: screenHeight),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlePainter(particles: particles),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw semi-transparent black background
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.8);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );

    // Draw particles with blur effect
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

    for (final particle in particles) {
      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
