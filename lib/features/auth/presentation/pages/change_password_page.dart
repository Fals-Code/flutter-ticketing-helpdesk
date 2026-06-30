import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/shared/widgets/app_text_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(
          AuthPasswordUpdateRequested(_passwordController.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state.status == AuthStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          return;
        }

        if (state.status == AuthStatus.success &&
            state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (!context.mounted) return;
          if (state.user.isEmpty) {
            context.go(AppRoutes.login);
          } else if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.dashboard);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ubah Kata Sandi')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.password_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      Text(
                        'Atur Kata Sandi Baru',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppDimensions.space32),
                      AppTextField(
                        label: 'Kata Sandi Baru',
                        hint: 'Minimal 8 karakter',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if ((value ?? '').length < 8) {
                            return 'Kata sandi minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.space20),
                      AppTextField(
                        label: 'Konfirmasi Kata Sandi',
                        hint: 'Ulangi kata sandi baru',
                        controller: _confirmController,
                        prefixIcon: Icons.lock_reset_rounded,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Konfirmasi kata sandi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.space32),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) => AppButton.primary(
                          label: 'Simpan Kata Sandi',
                          onPressed: _submit,
                          isLoading: state.status == AuthStatus.loading,
                          size: AppButtonSize.large,
                        ),
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
