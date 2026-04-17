import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
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
        final name = user.fullName ?? 'Pengguna';
        
        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: AppBar(
            title: Text(
              AppStrings.navProfile,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 40, 
                                  fontWeight: FontWeight.w800, 
                                  color: AppColors.primary
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, 
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BadgeWidget(
                        label: user.role == UserRole.technician ? 'Staff Teknisi' : user.role.name.toUpperCase(), 
                        color: user.role == UserRole.technician ? Colors.orange.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1), 
                        textColor: user.role == UserRole.technician ? Colors.orange : AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Management Group
                if (user.role == UserRole.admin) ...[
                  _buildSectionHeader('MANAJEMEN SISTEM', isDark),
                  const SizedBox(height: 12),
                  _buildModule(isDark, [
                    _ProfileTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan & Analitik',
                      subtitle: 'Statistik performa tim secara realtime',
                      onTap: () => context.push(AppRoutes.adminReports),
                      isDark: isDark,
                    ),
                    _ProfileTile(
                      icon: Icons.people_alt_rounded,
                      title: 'Manajemen Pengguna',
                      subtitle: 'Kelola peran dan hak akses user',
                      onTap: () => context.push(AppRoutes.userManagement),
                      isDark: isDark,
                    ),
                    _ProfileTile(
                      icon: Icons.settings_suggest_rounded,
                      title: 'Konfigurasi Sistem',
                      subtitle: 'Pengaturan SLA, kategori, dan dabase',
                      onTap: () => context.push(AppRoutes.adminSettings),
                      isDark: isDark,
                      isLast: true,
                    ),
                  ]),
                  const SizedBox(height: 32),
                ],

                // Security & Privacy
                _buildSectionHeader('KEAMANAN & PRIVASI', isDark),
                const SizedBox(height: 12),
                _buildModule(isDark, [
                  _ProfileTile(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Aktivitas',
                    subtitle: 'Log penggunaan akun dan sistem',
                    onTap: () => context.push(AppRoutes.history),
                    isDark: isDark,
                  ),
                  _ProfileTile(
                    icon: Icons.lock_person_rounded,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Perbarui kredensial keamanan Anda',
                    onTap: () => context.push(AppRoutes.changePassword),
                    isDark: isDark,
                    isLast: true,
                  ),
                ]),
                
                const SizedBox(height: 32),

                // About Group
                _buildSectionHeader('APLIKASI', isDark),
                const SizedBox(height: 12),
                _buildModule(isDark, [
                  _ProfileTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Informasi versi dan pengembangan',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _ProfileTile(
                    icon: Icons.description_rounded,
                    title: 'Syarat & Ketentuan',
                    subtitle: 'Kebijakan layanan helpdesk',
                    onTap: () {},
                    isDark: isDark,
                    isLast: true,
                  ),
                ]),

                const SizedBox(height: 48),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: AppButton.danger(
                    label: 'Keluar dari Akun',
                    icon: Icons.logout_rounded,
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white24 : Colors.black26,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModule(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isLast;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15, 
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12, 
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded, 
                  size: 20, 
                  color: isDark ? Colors.white24 : Colors.black12
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 62),
              child: Divider(
                height: 1, 
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
        ],
      ),
    );
  }
}
