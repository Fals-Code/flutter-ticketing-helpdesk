import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Widget loading dengan 3 titik (pulsing dots)
class LoadingWidget extends StatefulWidget {
  final double size;
  final Color? color;
  const LoadingWidget({super.key, this.size = 8, this.color});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Calculate opacity based on current time and index offset
            double progress = (_controller.value * 3 - index) % 3;
            double opacity = 1.0 - (progress < 1 ? progress : 1.0);
            // ease the opacity
            opacity = Curves.easeInOut.transform(opacity.clamp(0.2, 1.0));
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

/// Shimmer card untuk placeholder loading block/card
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = AppDimensions.radiusMD,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // 1.2s smooth animation
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.5, 1.0],
              colors: isDark
                  ? [
                      AppColors.surfaceDark,
                      AppColors.surfaceDark2,
                      AppColors.surfaceDark,
                    ]
                  : [
                      const Color(0xFFF4F4F5), // Zinc 100
                      const Color(0xFFE4E4E7), // Zinc 200
                      const Color(0xFFF4F4F5),
                    ],
              transform: _SlidingGradientTransform(_animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slideValue);
  final double slideValue;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slideValue, 0.0, 0.0);
  }
}

/// Placeholder untuk text (biasanya didalam list atau detail page)
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonLine({super.key, required this.width, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return ShimmerCard(
      width: width,
      height: height,
      borderRadius: AppDimensions.radiusXS,
    );
  }
}

/// Widget loading satu layar penuh (Centered)
class FullPageLoader extends StatelessWidget {
  const FullPageLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingWidget(size: 10),
          const SizedBox(height: AppDimensions.space24),
          Text(
            'TICKET-Q',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: primaryTextColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
