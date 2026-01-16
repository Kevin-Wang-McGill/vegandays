import 'package:flutter/material.dart';
import 'dart:math';
import '../models/sanctuary_animal.dart';
import '../services/app_state_service.dart';

class SanctuaryScene extends StatefulWidget {
  const SanctuaryScene({super.key});

  @override
  State<SanctuaryScene> createState() => _SanctuarySceneState();
}

class _SanctuarySceneState extends State<SanctuaryScene>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _sunController;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _sunController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateService.instance.state;
    final animals = state.sanctuaryAnimals;

    return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 背景天空渐变
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE4EDF1),
                        Color(0xFFCDE4DD),
                      ],
                    ),
                  ),
                ),
            // 太阳
            AnimatedBuilder(
              animation: _sunController,
              builder: (context, child) {
                return Positioned(
                  left: 20 + sin(_sunController.value * 2 * pi) * 10,
                  top: 20 + cos(_sunController.value * 2 * pi) * 5,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF9DC86),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF9DC86).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // 云朵
            AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return Stack(
                  children: [
                    Positioned(
                      left: 50 + (_cloudController.value * 100),
                      top: 30,
                      child: _buildCloud(60, 30),
                    ),
                    Positioned(
                      right: 80 - (_cloudController.value * 80),
                      top: 50,
                      child: _buildCloud(50, 25),
                    ),
                  ],
                );
              },
            ),
            // 草地/丘陵
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: _GrassPainter(),
                ),
              ),
            ),
            // 树 - 调整位置以适应新的草地高度
            Positioned(
              left: 40,
              bottom: constraints.maxHeight * 0.15,
              child: _buildTree(),
            ),
            Positioned(
              right: 50,
              bottom: constraints.maxHeight * 0.12,
              child: _buildTree(),
            ),
            // 动物
            ...animals.asMap().entries.map((entry) {
              final animal = entry.value;
              final index = entry.key;
              return Positioned(
                left: animal.x / 100 * constraints.maxWidth,
                top: animal.y / 100 * constraints.maxHeight,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 500 + index * 100),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Text(
                        animal.type.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
              ],
            );
          },
        );
  }

  Widget _buildCloud(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTree() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFCDE4DD),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: 40,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF6B8E5A),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _GrassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCDE4DD)
      ..style = PaintingStyle.fill;

    // 调整草地高度，占据底部约 35-40% 的区域
    final grassStartY = size.height * 0.6;
    final path = Path();
    path.moveTo(0, grassStartY);
    path.quadraticBezierTo(
      size.width * 0.3,
      grassStartY - size.height * 0.05,
      size.width * 0.5,
      grassStartY,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      grassStartY + size.height * 0.05,
      size.width,
      grassStartY - size.height * 0.03,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // 草细节
    final grassPaint = Paint()
      ..color = const Color(0xFF8FAE7F)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += 30) {
      final y = grassStartY + sin(i / 50) * 8;
      canvas.drawLine(
        Offset(i, y),
        Offset(i, size.height),
        grassPaint..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

