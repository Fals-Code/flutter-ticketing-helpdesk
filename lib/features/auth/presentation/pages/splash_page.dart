import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/router/app_router.dart';
import '../../../../core/constants/enums.dart';
import '../../presentation/bloc/auth_bloc.dart';

/// Splash Page premium dengan animasi FadeIn dan logika navigasi Role-Based.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
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
    // Delay 2 detik agar brand identity terasa profesional
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    
    if (authState.status == AuthStatus.authenticated) {
      final role = authState.user.role;
      // Logika Role: 1=Admin, 2=Staff -> Staff Dashboard
      if (role == UserRole.admin || role == UserRole.technician) {
        context.go(AppRoutes.staffDashboard);
      } else {
        // Role 3=Customer -> Dashboard
        context.go(AppRoutes.dashboard);
      }
    } else {
      // Unauthenticated -> Login
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E40AF), // Royal Blue
              Color(0xFF3B82F6), // Vibrant Blue
              Color(0xFF60A5FA), // Light Sky Blue
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder - Confirmation Icon dengan Glassmorphism effect
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'TICKET-Q',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'MODERN HELPDESK SYSTEM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 80),
              // Minimalist Loading Indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
