import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_password_field.dart';
import '../../../../shared/widgets/primary_action_button.dart';
import '../../domain/value_objects/auth_identifier.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_form_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_status_banner.dart';

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
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (context.read<AuthBloc>().state.status == AuthStatus.loading) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<AuthBloc>().add(
          LoginSubmitted(
            identifier: _identifierController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        final errorMessage =
            state.status == AuthStatus.error ? state.errorMessage : null;

        return AuthScreenShell(
          header: const AuthHeader(
            title: 'Masuk',
            subtitle: 'Masuk untuk mengelola dan memantau tiket layanan.',
          ),
          form: AuthFormCard(
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LoginStaggerItem(
                      order: 0,
                      child: Text(
                        'Gunakan kredensial yang aktif untuk melanjutkan ke ruang kerja tiket Anda.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: AppDimensions.motionFastMs,
                      ),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: errorMessage == null
                          ? const SizedBox(height: AppDimensions.space20)
                          : Padding(
                              key: const ValueKey('login-error-banner'),
                              padding: const EdgeInsets.only(
                                top: AppDimensions.space20,
                              ),
                              child: AuthStatusBanner(
                                message: errorMessage,
                              ),
                            ),
                    ),
                    _LoginStaggerItem(
                      order: 1,
                      child: AppTextField(
                        label: 'Email atau Username',
                        hint: 'Masukkan email atau username',
                        controller: _identifierController,
                        focusNode: _identifierFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: AuthIdentifier.validateLogin,
                        enabled: !isLoading,
                        semanticLabel: 'Email atau username',
                        autofillHints: const [
                          AutofillHints.username,
                          AutofillHints.email,
                        ],
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                    _LoginStaggerItem(
                      order: 2,
                      child: AppPasswordField(
                        label: 'Kata Sandi',
                        hint: 'Masukkan kata sandi Anda',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        enabled: !isLoading,
                        semanticLabel: 'Kata sandi',
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
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    _LoginStaggerItem(
                      order: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.resetPassword),
                          child: const Text('Lupa Kata Sandi?'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    _LoginStaggerItem(
                      order: 4,
                      child: PrimaryActionButton(
                        label: AppStrings.login,
                        onPressed: _submit,
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    Text(
                      'Butuh bantuan masuk? Hubungi helpdesk internal atau gunakan reset kata sandi.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          footer: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppDimensions.space4,
            runSpacing: AppDimensions.space4,
            children: [
              Text(
                'Belum punya akun?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: state.status == AuthStatus.loading
                    ? null
                    : () => context.push(AppRoutes.register),
                child: const Text('Daftar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoginStaggerItem extends StatelessWidget {
  const _LoginStaggerItem({
    required this.order,
    required this.child,
  });

  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: disableAnimations
          ? Duration.zero
          : Duration(milliseconds: 320 + (order * 80)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
