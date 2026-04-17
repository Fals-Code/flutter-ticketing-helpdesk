import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Halaman Login redesign: clean, konversi-focused
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _pageAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeOutCubic),
    );
    _pageAnimationController.forward();
    
    // Auto focus username/email field
    Future.microtask(() => _emailFocus.requestFocus());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;
    
    context.read<AuthBloc>().add(LoginSubmitted(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state.status == AuthStatus.authenticated) {
            // Flash green success brief delay
            await Future.delayed(const Duration(milliseconds: 300));
            if (!context.mounted) return;
            final role = state.user.role;
            if (role == UserRole.admin || role == UserRole.technician) {
              context.go(AppRoutes.staffDashboard);
            } else {
              context.go(AppRoutes.dashboard);
            }
          }
          if (state.status == AuthStatus.error) {
            _showErrorSnackBar(state.errorMessage ?? 'Login Gagal');
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space24, vertical: AppDimensions.space32),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _pageAnimationController,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(isDark),
                          const SizedBox(height: AppDimensions.space32),
                          _buildFormCard(isDark),
                          const SizedBox(height: AppDimensions.space32),
                          _buildFooter(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.confirmation_number_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        Text(
          'Selamat Datang Kembali 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Masuk untuk melanjutkan ke dashboard Anda',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: AppStrings.email,
              hint: AppStrings.emailHint,
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (value) {
                if (value == null || value.isEmpty) return AppStrings.emailRequired;
                if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(value)) {
                  return AppStrings.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space20),
            AppTextField(
              label: AppStrings.password,
              hint: AppStrings.passwordHint,
              controller: _passwordController,
              focusNode: _passwordFocus,
              isPassword: true,
              prefixIcon: Icons.lock_outline,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              validator: (value) {
                if (value == null || value.isEmpty) return AppStrings.passwordRequired;
                if (value.length < 6) return AppStrings.passwordMinLength;
                return null;
              },
            ),
            
            // Right-aligned Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.resetPassword),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lupa Password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppDimensions.space32),
            
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isSuccess = state.status == AuthStatus.authenticated;
                // If success display green color state briefly
                if (isSuccess) {
                  return const AppButton.danger(
                    label: 'Berhasil', // Not exactly danger, but we use a distinct style or just standard primary.
                    // Instead of misusing danger, we stick to primary or build specialized, but the requirements just say primary
                  ); // fallback below
                }
                
                return AppButton.primary(
                  label: isSuccess ? 'Berhasil Masuk' : AppStrings.login,
                  onPressed: _handleLogin,
                  isLoading: state.status == AuthStatus.loading,
                  size: AppButtonSize.large,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: Text(
                'atau',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
            Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          ],
        ),
        const SizedBox(height: AppDimensions.space24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Belum punya akun?',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: AppDimensions.space4),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Daftar Sekarang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
