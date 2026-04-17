import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/features/dashboard/presentation/pages/tabs/widgets/dashboard_widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.navProfile),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.spaceXL),
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      Text(
                        user.fullName ?? 'Pengguna',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                      ),
                      const SizedBox(height: 12),
                      BadgeWidget(
                        label: user.role == UserRole.technician ? 'TEKNISI' : user.role.name.toUpperCase(), 
                        color: user.role == UserRole.technician ? Colors.orange.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1), 
                        textColor: user.role == UserRole.technician ? Colors.orange : AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),

                // Actions Group
                _ProfileSection(
                  title: user.role == UserRole.admin ? 'Manajemen Sistem' : 'Aktivitas & Keamanan',
                  children: [
                    if (user.role == UserRole.admin) ...[
                      _ProfileTile(
                        icon: Icons.bar_chart_rounded,
                        title: 'Laporan & Analitik',
                        subtitle: 'Statistik performa tim',
                        onTap: () => context.push(AppRoutes.adminReports),
                        isDark: isDark,
                      ),
                      _ProfileTile(
                        icon: Icons.people_outline_rounded,
                        title: 'Manajemen Pengguna',
                        subtitle: 'Kelola peran dan akses user',
                        onTap: () => context.push(AppRoutes.userManagement),
                        isDark: isDark,
                      ),
                      _ProfileTile(
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan Sistem',
                        subtitle: 'Konfigurasi SLA dan kategori',
                        onTap: () => context.push(AppRoutes.adminSettings),
                        isDark: isDark,
                      ),
                    ],
                    _ProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Aktivitas',
                      subtitle: user.role == UserRole.admin ? 'Log seluruh sistem' : 'Lihat log penanganan tiket',
                      onTap: () => context.push(AppRoutes.history),
                      isDark: isDark,
                    ),
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ubah Kata Sandi',
                      subtitle: 'Perbarui keamanan akun Anda',
                      onTap: () => context.push(AppRoutes.changePassword),
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                _ProfileSection(
                  title: 'Aplikasi',
                  children: [
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Aplikasi',
                      subtitle: 'E-Ticketing Helpdesk v1.0.0',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                AppButton.danger(
                  label: AppStrings.logout,
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: isDark ? AppColors.textPrimaryDark.withValues(alpha: 0.7) : AppColors.textPrimaryLight.withValues(alpha: 0.8), size: 20),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        trailing: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ),
    );
  }
}
