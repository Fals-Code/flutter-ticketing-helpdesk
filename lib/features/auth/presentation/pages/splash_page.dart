import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/aurora_background.dart';
import 'package:uts/core/router/app_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _idleController;

  late Animation<double> _logoScale;
  late Animation<double> _cardFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Sequence (2 sec)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeIn),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Idle & Shimmer (Repeat)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Branding time
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Failsafe: Re-trigger router refresh to ensure redirect logic fires
    // If the transition happened before the delay, refresh will catch the conclusive state.
    if (mounted) {
      appRouter.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entranceController, _idleController]),
            builder: (context, child) {
              return Opacity(
                opacity: _cardFade.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Floating Logo Container
                            Transform.translate(
                              offset: Offset(0, sin(_idleController.value * 2 * 3.14159) * 8),
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: _buildLogoIcon(),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Branding Info
                            FadeTransition(
                              opacity: _textFade,
                              child: SlideTransition(
                                position: _textSlide,
                                child: Column(
                                  children: [
                                    _buildShimmerText(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'YOUR IT HELPDESK SOLUTION',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withValues(alpha: 0.4),
                                        letterSpacing: 3.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 48),
                            
                            // Footer Loading
                            Opacity(
                              opacity: _textFade.value,
                              child: const LoadingWidget(
                                size: 6,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoIcon() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.confirmation_number_rounded,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildShimmerText() {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Colors.white,
            AppColors.auroraCyan,
            Colors.white,
          ],
          stops: [
            _shimmerAnimation.value - 0.4,
            _shimmerAnimation.value,
            _shimmerAnimation.value + 0.4,
          ],
        ).createShader(bounds);
      },
      child: Text(
        'TICKET-Q',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8.0,
        ),
      ),
    );
  }
}
