import 'package:flutter/material.dart';
import '../../theme/design_constants.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;

  const CustomBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: DesignConstants.appBackgroundGradient,
          ),
        ),
        // Decorative Shapes
        Positioned.fill(
          child: CustomPaint(
            painter: BackgroundPainter(),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Left Middle Primary Blue Circle
    paint.color = DesignConstants.primaryBlue.withOpacity(0.6);
    canvas.drawCircle(
      Offset(size.width * -0.1, size.height * 0.4),
      size.width * 0.6,
      paint,
    );

    // Bottom Right Primary Blue Circle
    paint.color = DesignConstants.primaryBlue.withOpacity(0.5);
    canvas.drawCircle(
      Offset(size.width * 1.1, size.height * 0.9),
      size.width * 0.8,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
