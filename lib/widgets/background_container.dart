import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:chat_app/services/theme_manager.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;

  const BackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: ThemeManager().currentTheme,
      builder: (context, theme, _) {
        return Stack(
          children: [
            // 1. Theme Image (Cover)
            Positioned.fill(
              child: Image.asset(
                ThemeManager().getBackgroundImage(theme),
                fit: BoxFit.cover,
              ),
            ),

            // 2. Blur Effect
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.2), // Slight tint
                ),
              ),
            ),

            // 3. Noise Overlay
            Positioned.fill(child: CustomPaint(painter: _NoisePainter())),

            // 4. Content
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint();

    // Draw random white dots
    for (int i = 0; i < 10000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.15);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
