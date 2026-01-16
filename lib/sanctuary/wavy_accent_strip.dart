import 'package:flutter/material.dart';

/// Wavy accent strip on top of grass base - flat color with smooth terrain waves
class WavyAccentStrip extends StatelessWidget {
  final double height;
  final double grassHeight;
  final Color color;

  const WavyAccentStrip({
    super.key,
    required this.height,
    required this.grassHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: grassHeight - height,
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _WavyStripPainter(color: color, stripHeight: height),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WavyStripPainter extends CustomPainter {
  final Color color;
  final double stripHeight;

  _WavyStripPainter({required this.color, required this.stripHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final amplitude = stripHeight * 0.70; // Wave amplitude (significantly increased)
    final waves = 2; // 2 wave peaks across full width
    final segmentWidth = size.width / waves; // Width per wave segment

    // Start from top-left (horizontal edge as horizon)
    path.moveTo(0, 0);

    // Top edge is horizontal (horizon line)
    path.lineTo(size.width, 0);

    // Bottom edge has smooth waves (connecting to grass base)
    // Use smooth cubic bezier curves for perfectly smooth transitions without sharp corners
    // Two waves with different sizes for natural variation
    final waveY1 = size.height - amplitude * 0.6; // First peak (60%, left side)
    final waveY2 = size.height - amplitude * 0.9; // Second peak (90%, right side)
    final valleyY = size.height - amplitude * 0.2;
    final edgeY = size.height - amplitude * 0.35;

    // Start from right edge with smooth curve
    path.lineTo(size.width, edgeY);

    // Second peak (larger, at 3/4 width) using cubic bezier for smooth connection
    path.cubicTo(
      segmentWidth * 1.875, edgeY, // Control point 1 (smooth entry)
      segmentWidth * 1.625, waveY2, // Control point 2 (smooth peak)
      segmentWidth * 1.5, waveY2, // Second peak position (larger)
    );

    // Smooth valley to center using cubic bezier
    path.cubicTo(
      segmentWidth * 1.375, waveY2, // Control point 1 (smooth from peak)
      segmentWidth * 1.125, valleyY, // Control point 2 (smooth to valley)
      segmentWidth, valleyY, // Valley center
    );

    // Smooth rise to first peak (smaller, at 1/4 width) using cubic bezier
    path.cubicTo(
      segmentWidth * 0.875, valleyY, // Control point 1 (smooth from valley)
      segmentWidth * 0.625, waveY1, // Control point 2 (smooth to peak)
      segmentWidth * 0.5, waveY1, // First peak position (smaller)
    );

    // Smooth valley to left edge using cubic bezier
    path.cubicTo(
      segmentWidth * 0.375, waveY1, // Control point 1 (smooth from peak)
      segmentWidth * 0.125, edgeY, // Control point 2 (smooth to edge)
      0, edgeY, // Left edge
    );

    // Complete the path: back to start
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
