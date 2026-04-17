import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AuroraBackground extends StatefulWidget {
  final Widget? child;
  const AuroraBackground({super.key, this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
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
        return Stack(
          children: [
            // Base background
            Container(color: AppColors.auroraIndigo),

            // Moving Blobs
            _PositionedBlob(
              color: AppColors.auroraPurple.withValues(alpha: 0.6),
              size: 500,
              initialOffset: const Offset(-100, -100),
              animationValue: _controller.value,
              radius: 120,
            ),
            _PositionedBlob(
              color: AppColors.auroraCyan.withValues(alpha: 0.4),
              size: 400,
              initialOffset: const Offset(200, 100),
              animationValue: _controller.value,
              radius: 80,
              direction: -1,
            ),
            _PositionedBlob(
              color: AppColors.auroraRose.withValues(alpha: 0.3),
              size: 450,
              initialOffset: const Offset(-50, 400),
              animationValue: _controller.value,
              radius: 100,
              speedScale: 1.2,
            ),

            // Glass/Blur Overlay to blend everything
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),

            if (widget.child != null) widget.child!,
          ],
        );
      },
    );
  }
}

class _PositionedBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset initialOffset;
  final double animationValue;
  final double radius;
  final double direction;
  final double speedScale;

  const _PositionedBlob({
    required this.color,
    required this.size,
    required this.initialOffset,
    required this.animationValue,
    required this.radius,
    this.direction = 1,
    this.speedScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final angle = animationValue * 2 * pi * direction * speedScale;
    final x = initialOffset.dx + cos(angle) * radius;
    final y = initialOffset.dy + sin(angle) * radius;

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
