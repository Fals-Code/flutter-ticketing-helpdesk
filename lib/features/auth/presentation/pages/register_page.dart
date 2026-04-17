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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;

  late AnimationController _pageAnimationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _pageAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    // Staggered animations
    _slideAnimations = [];
    _fadeAnimations = [];
    for (int i = 0; i < 6; i++) {
      final double start = i * 0.1;
      final double end = (start + 0.4).clamp(0.0, 1.0);
      _slideAnimations.add(Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero)
          .animate(CurvedAnimation(
              parent: _pageAnimationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic))));
      _fadeAnimations.add(Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(
              parent: _pageAnimationController,
              curve: Interval(start, end, curve: Curves.easeOutCubic))));
    }
    _pageAnimationController.forward();

    // Setup inline validation
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        setState(() => _isNameValid = _nameController.text.trim().isNotEmpty);
      }
    });

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        final val = _emailController.text.trim();
        setState(() => _isEmailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(val));
      }
    });

    _passwordController.addListener(() {
      setState(() {
        _isPasswordValid = _passwordController.text.length >= 6;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  double get _progressValue {
    int score = 0;
    if (_isNameValid) score++;
    if (_isEmailValid) score++;
    if (_isPasswordValid) score++;
    return score / 3.0; // 3 implicit steps
  }

  bool get _isFormReady {
    return _isNameValid &&
        _isEmailValid &&
        _isPasswordValid &&
        _confirmPasswordController.text == _passwordController.text;
  }

  void _onRegister() {
    if (_formKey.currentState!.validate() && _isFormReady) {
      context.read<AuthBloc>().add(RegisterSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
          ));
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

  Widget _buildStaggeredItem(int index, Widget child) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: child,
      ),
    );
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _progressValue),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: isDark ? AppColors.surfaceDark2 : AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              );
            },
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Registrasi gagal'),
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStaggeredItem(
                    0,
                    Text(
                      'Buat Akun Baru',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  _buildStaggeredItem(
                    0,
                    Text(
                      'Lengkapi data di bawah untuk bergabung dengan TICKET-Q.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space32),
                  
                  _buildStaggeredItem(
                    1,
                    AppTextField(
                      label: 'Nama Lengkap',
                      hint: 'Masukan Nama Anda',
                      controller: _nameController,
                      focusNode: _nameFocus,
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                      validator: (v) => v!.isEmpty ? 'Nama tidak valid' : null,
                      isSuccess: _isNameValid,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  
                  _buildStaggeredItem(
                    2,
                    AppTextField(
                      label: 'Email',
                      hint: 'Masukan Email Anda',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      validator: (v) {
                        if (v!.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) return 'Email tidak valid';
                        return null;
                      },
                      isSuccess: _isEmailValid,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  
                  _buildStaggeredItem(
                    3,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Kata Sandi',
                          hint: 'Minimal 6 karakter',
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _confirmFocus.requestFocus(),
                          validator: (v) => v!.length < 6 ? 'Terlalu pendek' : null,
                          isSuccess: _isPasswordValid,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(4, (index) {
                            final score = _calculatePasswordStrength(_passwordController.text);
                            final color = index < score ? _getPasswordStrengthColor(score) : (isDark ? AppColors.borderDark : AppColors.borderLight);
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                  
                  _buildStaggeredItem(
                    4,
                    AppTextField(
                      label: 'Konfirmasi Kata Sandi',
                      hint: 'Ulangi kata sandi di atas',
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocus,
                      isPassword: true,
                      prefixIcon: Icons.lock_reset_outlined,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onRegister(),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Tidak cocok';
                        return null;
                      },
                      isSuccess: _confirmPasswordController.text.isNotEmpty && _confirmPasswordController.text == _passwordController.text,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space40),
                  
                  _buildStaggeredItem(
                    5,
                    Column(
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return AppButton.primary(
                              label: 'Daftar Sekarang',
                              isLoading: state.status == AuthStatus.loading,
                              onPressed: _isFormReady ? _onRegister : null,
                              size: AppButtonSize.large,
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.space20),
                        Text(
                          'Dengan mendaftar, Anda menyetujui Ketentuan Layanan\ndan Kebijakan Privasi kami.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
