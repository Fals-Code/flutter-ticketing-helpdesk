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
import '../../../../core/constants/enums.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _newPasswordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isPasswordValid = false;

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

    _newPasswordController.addListener(() {
      setState(() {
        _isPasswordValid = _newPasswordController.text.length >= 6;
      });
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isFormReady {
    return _isPasswordValid &&
        _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text == _newPasswordController.text;
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_isFormReady) {
        context.read<AuthBloc>().add(
              AuthPasswordUpdateRequested(_newPasswordController.text),
            );
      }
    }
  }

  Color _getPasswordStrengthColor(int score) {
    if (score <= 1) return AppColors.danger;
    if (score == 2) return AppColors.warning;
    return AppColors.success;
  }

  int _calculatePasswordStrength(String pass) {
    if (pass.isEmpty) return 0;
    int score = 0;
    if (pass.length > 5) score++;
    if (pass.length > 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(pass)) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.success && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.successMessage!)),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 1500));
          if (context.mounted) context.pop();
        } else if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Ubah Kata Sandi',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _animationController,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppDimensions.space16),
                      Text(
                        'Perbarui Keamanan Akun',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Pastikan kata sandi baru Anda kuat dan sulit ditebak oleh orang lain.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              height: 1.5,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.space40),
                      AppTextField(
                        label: 'Kata Sandi Baru',
                        hint: 'Minimal 6 karakter',
                        controller: _newPasswordController,
                        focusNode: _newPasswordFocus,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kata sandi tidak boleh kosong';
                          }
                          if (value.length < 6) {
                            return 'Minimal 6 karakter';
                          }
                          return null;
                        },
                        isSuccess: _isPasswordValid,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Row(
                        children: List.generate(4, (index) {
                          final score = _calculatePasswordStrength(_newPasswordController.text);
                          final color = index < score 
                              ? _getPasswordStrengthColor(score) 
                              : (isDark ? AppColors.borderDark : AppColors.borderLight);
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 4,
                              margin: EdgeInsets.only(right: index == 3 ? 0 : 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      AppTextField(
                        label: 'Konfirmasi Kata Sandi Baru',
                        hint: 'Ulangi kata sandi baru',
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        isPassword: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onSave(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi tidak boleh kosong';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Kata sandi tidak cocok';
                          }
                          return null;
                        },
                        isSuccess: _confirmPasswordController.text.isNotEmpty && 
                                   _confirmPasswordController.text == _newPasswordController.text,
                      ),
                      const SizedBox(height: AppDimensions.space40),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          return AppButton.primary(
                            label: 'Simpan Perubahan',
                            onPressed: _isFormReady ? _onSave : null,
                            isLoading: state.status == AuthStatus.loading,
                            size: AppButtonSize.large,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
