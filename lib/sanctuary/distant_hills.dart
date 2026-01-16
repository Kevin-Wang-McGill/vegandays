import 'package:flutter/material.dart';

/// Distant hills layer - drawn with dark green color, no shadows/gradients
class DistantHills extends StatelessWidget {
  final double height;
  final double bottom;
  final Color color;

  const DistantHills({
    super.key,
    required this.height,
    required this.bottom,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      height: height,
      child: CustomPaint(
        painter: _DistantHillsPainter(color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _DistantHillsPainter extends CustomPainter {
  final Color color;

  _DistantHillsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from bottom-left (fill screen edge)
    path.moveTo(0, size.height);
    
    // Define edge Y position
    final edgeY = size.height * 0.78;
    path.lineTo(0, edgeY);
    
    // Define 5 key points for the ridge line
    final points = [
      Offset(0, edgeY), // P0: Left edge entry point
      Offset(size.width * 0.30, size.height * 0.52), // P1: Left peak
      Offset(size.width * 0.55, size.height * 0.64), // P2: Valley
      Offset(size.width * 0.85, size.height * 0.44), // P3: Right peak
      Offset(size.width, edgeY), // P4: Right edge exit point
    ];
    
    // Generate smooth curves using Catmull-Rom spline
    final tension = 1.0;
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[0] + (points[0] - points[1]); // Extrapolate for first segment
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[points.length - 1] + (points[points.length - 1] - points[points.length - 2]); // Extrapolate for last segment
      
      // Catmull-Rom to Bézier conversion
      var c1 = p1 + (p2 - p0) * (tension / 6.0);
      var c2 = p2 - (p3 - p1) * (tension / 6.0);
      
      // Force horizontal tangent at edges
      if (i == 0) {
        // First segment: C1 y must be edgeY for horizontal entry
        c1 = Offset(c1.dx, edgeY);
      }
      if (i == points.length - 2) {
        // Last segment: C2 y must be edgeY for horizontal exit
        c2 = Offset(c2.dx, edgeY);
      }
      
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    
    // Complete the path: right edge -> bottom edge -> back to start
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  /// Convert Catmull-Rom spline points to cubic Bézier control points
  /// Returns (C1, C2) control points for segment from P1 to P2
  static (Offset, Offset) _catmullRomToBezier(
    Offset p0, // Previous point (or extrapolated)
    Offset p1, // Start point
    Offset p2, // End point
    Offset p3, // Next point (or extrapolated)
    double tension,
  ) {
    final c1 = p1 + (p2 - p0) * (tension / 6.0);
    final c2 = p2 - (p3 - p1) * (tension / 6.0);
    return (c1, c2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

