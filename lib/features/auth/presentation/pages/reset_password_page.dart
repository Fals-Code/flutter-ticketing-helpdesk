import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'package:uts/core/constants/enums.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isSuccess = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onReset() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(ResetPasswordRequested(_emailController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.success) {
            setState(() {
              _isSuccess = true;
            });
            // Reset animation to play again for success state
            _animationController.forward(from: 0.0);
          }
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Gagal memproses permintaan'),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _animationController,
                child: _isSuccess ? _buildSuccessState(isDark) : _buildFormState(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space24),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space32),
        Text(
          'Lupa Kata Sandi?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Masukkan email yang terdaftar pada akun Anda\nuntuk menerima instruksi reset kata sandi.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space40),
        Form(
          key: _formKey,
          child: AppTextField(
            label: 'Email',
            hint: 'contoh@email.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onReset(),
            validator: (v) {
              if (v!.isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) return 'Format email tidak valid';
              return null;
            },
          ),
        ),
        const SizedBox(height: AppDimensions.space32),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AppButton.primary(
              label: 'Kirim Instruksi',
              isLoading: state.status == AuthStatus.loading,
              onPressed: _onReset,
              size: AppButtonSize.large,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuccessState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppDimensions.space32),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.space32),
        Text(
          'Email Terkirim!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space8),
        Text(
          'Instruksi untuk mengatur ulang kata sandi telah\ndikirimkan ke ${_emailController.text}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space40),
        AppButton.primary(
          label: 'Kembali ke Login',
          onPressed: () => context.pop(),
          size: AppButtonSize.large,
        ),
      ],
    );
  }
}
