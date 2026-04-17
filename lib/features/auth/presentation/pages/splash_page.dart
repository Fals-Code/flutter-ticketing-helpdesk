import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/enums.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../presentation/bloc/auth_bloc.dart';

/// Splash Page premium dengan sequence animasi dan logika navigasi Role-Based.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<double> _loaderFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 1. Logo scale dari 0.7 ke 1.0 dengan elastic curve (800ms)
    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.533, curve: Curves.elasticOut), // 800/1500
      ),
    );

    // 2. Teks fade in dari bawah (600ms, delay 200ms)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.133, 0.533, curve: Curves.easeOutCubic), // 200-800ms
      ),
    );
    _titleSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.133, 0.533, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Tagline fade in (400ms, delay 500ms)
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.333, 0.6, curve: Curves.easeIn), // 500-900ms
      ),
    );

    // 4. Dots loader muncul (delay 800ms)
    _loaderFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.533, 1.0, curve: Curves.easeIn), // 800-1500ms
      ),
    );

    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    // Splash durasi: 2.5 detik sebelum navigate
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    
    if (authState.status == AuthStatus.authenticated) {
      final role = authState.user.role;
      if (role == UserRole.admin || role == UserRole.technician) {
        context.go(AppRoutes.staffDashboard);
      } else {
        context.go(AppRoutes.dashboard);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // Background: dark gradient dari #0A0A0F ke #111118
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF111118),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedBuilder(
              animation: _logoScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(AppDimensions.space24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDimensions.space32),
            
            // Title
            SlideTransition(
              position: _titleSlideAnimation,
              child: FadeTransition(
                opacity: _titleFadeAnimation,
                child: const Text(
                  'TICKET-Q',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 6.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            
            // Tagline
            FadeTransition(
              opacity: _taglineFadeAnimation,
              child: Text(
                'YOUR IT HELPDESK SOLUTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 3.0,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space64),
            
            // Loader
            FadeTransition(
              opacity: _loaderFadeAnimation,
              child: const LoadingWidget(
                size: 8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
