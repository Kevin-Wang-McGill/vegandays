import 'package:flutter/material.dart';
import 'dart:math';

class SparklesEffect extends StatefulWidget {
  const SparklesEffect({super.key});

  @override
  State<SparklesEffect> createState() => _SparklesEffectState();
}

class _SparklesEffectState extends State<SparklesEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Sparkle> _sparkles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // 生成火花粒子
    for (int i = 0; i < 20; i++) {
      _sparkles.add(_Sparkle(
        angle: _random.nextDouble() * 2 * pi,
        distance: 50 + _random.nextDouble() * 100,
        size: 4 + _random.nextDouble() * 6,
        delay: _random.nextDouble() * 0.3,
      ));
    }

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _SparklesPainter(
            sparkles: _sparkles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _Sparkle {
  final double angle;
  final double distance;
  final double size;
  final double delay;

  _Sparkle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.delay,
  });
}

class _SparklesPainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklesPainter({
    required this.sparkles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final sparkle in sparkles) {
      final adjustedProgress = (progress - sparkle.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final distance = sparkle.distance * adjustedProgress;
      final x = center.dx + cos(sparkle.angle) * distance;
      final y = center.dy + sin(sparkle.angle) * distance;
      final opacity = (1 - adjustedProgress);
      final currentSize = sparkle.size * (1 - adjustedProgress * 0.5);

      final paint = Paint()
        ..color = const Color(0xFFF5C73D).withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), currentSize, paint);

      // 添加星形效果
      final starPaint = Paint()
        ..color = const Color(0xFFED845E).withOpacity(opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      _drawStar(canvas, Offset(x, y), currentSize * 0.7, starPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const n = 5;
    final path = Path();
    for (int i = 0; i < n * 2; i++) {
      final angle = i * pi / n;
      final r = i.isEven ? radius : radius * 0.5;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}




