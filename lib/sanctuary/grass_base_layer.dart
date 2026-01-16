import 'package:flutter/material.dart';

/// Flat grass base layer with subtle curved top edge - pure color, no shadows/gradients
class GrassBaseLayer extends StatelessWidget {
  final double height;
  final Color color;

  const GrassBaseLayer({
    super.key,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: height,
        width: double.infinity,
        color: color, // Pure flat color, rectangular shape
      ),
    );
  }
}
