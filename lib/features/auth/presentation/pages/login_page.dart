import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/domain/value_objects/auth_identifier.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/shared/widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _identifierFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(LoginSubmitted(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    Text(
                      'Masuk ke TICKET-Q',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      'Gunakan email atau username akun Anda.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.space32),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXL),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              label: 'Email atau Username',
                              hint: 'nama@contoh.com atau username',
                              controller: _identifierController,
                              focusNode: _identifierFocus,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.person_outline,
                              validator: AuthIdentifier.validateLogin,
                              onSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                            ),
                            const SizedBox(height: AppDimensions.space20),
                            AppTextField(
                              label: 'Kata Sandi',
                              hint: 'Masukkan kata sandi',
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              isPassword: true,
                              prefixIcon: Icons.lock_outline,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kata sandi wajib diisi';
                                }
                                if (value.length < 6) {
                                  return 'Kata sandi minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () =>
                                    context.push(AppRoutes.resetPassword),
                                child: const Text('Lupa kata sandi?'),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                return AppButton.primary(
                                  label: 'Masuk',
                                  onPressed: _submit,
                                  isLoading:
                                      state.status == AuthStatus.loading,
                                  size: AppButtonSize.large,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun?'),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.register),
                          child: const Text('Daftar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
