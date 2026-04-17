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
import 'package:uts/core/utils/haptic_helper.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Color _getNameColor(String name) {
    final int hash = name.hashCode;
    final List<Color> palette = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF43F5E), // Rose
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Emerald
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF3B82F6), // Blue
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        final name = user.fullName ?? 'Pengguna';
        final avatarColor = _getNameColor(name);

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              AppStrings.navProfile,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
            child: Column(
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    boxShadow: [
                      if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: avatarColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: avatarColor.withValues(alpha: 0.2), width: 2),
                            ),
                            child: Center(
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32, 
                                  fontWeight: FontWeight.w800, 
                                  color: avatarColor
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark2 : Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Icon(Icons.camera_alt_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      _buildRoleBadge(user.role),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Section: AKUN
                _buildSectionLabel('AKUN'),
                _buildProfileModule(isDark, [
                  _ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Perbarui kredensial keamanan Anda',
                    onTap: () => context.push(AppRoutes.changePassword),
                    isDark: isDark,
                    color: Colors.blue,
                  ),
                ]),

                const SizedBox(height: 24),
                // Section: AKTIVITAS
                _buildSectionLabel('AKTIVITAS'),
                _buildProfileModule(isDark, [
                  _ProfileTile(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Aktivitas',
                    subtitle: 'Lihat seluruh log tindakan Anda',
                    onTap: () => context.push(AppRoutes.history),
                    isDark: isDark,
                    color: Colors.indigo,
                    isLast: true,
                  ),
                ]),

                if (user.role == UserRole.admin) ...[
                  const SizedBox(height: 24),
                  _buildSectionLabel('ADMIN / MANAJEMEN'),
                  _buildProfileModule(isDark, [
                    _ProfileTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Laporan & Analitik',
                      subtitle: 'Pantau statistik tiket dan SLA',
                      onTap: () => context.push(AppRoutes.adminReports),
                      isDark: isDark,
                      color: Colors.teal,
                    ),
                    _ProfileTile(
                      icon: Icons.people_outline_rounded,
                      title: 'Manajemen Pengguna',
                      subtitle: 'Kelola peran dan hak akses staf',
                      onTap: () => context.push(AppRoutes.userManagement),
                      isDark: isDark,
                      color: Colors.orange,
                    ),
                    _ProfileTile(
                      icon: Icons.settings_suggest_outlined,
                      title: 'Pengaturan Sistem',
                      subtitle: 'Konfigurasi parameter global',
                      onTap: () => context.push(AppRoutes.adminSettings),
                      isDark: isDark,
                      color: Colors.deepPurple,
                      isLast: true,
                    ),
                  ]),
                ],

                const SizedBox(height: 24),
                // Section: APLIKASI
                _buildSectionLabel('APLIKASI'),
                _buildProfileModule(isDark, [
                  _ProfileTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang TICKET-Q',
                    subtitle: 'Informasi pengembang dan lisensi',
                    onTap: () {},
                    isDark: isDark,
                    color: Colors.grey,
                  ),
                  _buildVersionTile(isDark),
                ]),

                const SizedBox(height: 40),
                // Logout Button
                _buildLogoutButton(context, isDark),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color;
    String label;
    switch (role) {
      case UserRole.admin: color = AppColors.danger; label = 'ADMINISTRATOR'; break;
      case UserRole.technician: color = AppColors.warning; label = 'TEKNISI'; break;
      case UserRole.user: color = AppColors.success; label = 'PELANGGAN'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5),
        ),
      ),
    );
  }

  Widget _buildProfileModule(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildVersionTile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.code_rounded, size: 18, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Versi Aplikasi',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '1.2.0-stable',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return TextButton.icon(
      onPressed: () => _showLogoutDialog(context, isDark),
      icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
      label: Text('Keluar dari Akun', style: GoogleFonts.plusJakartaSans(color: AppColors.danger, fontWeight: FontWeight.w800, fontSize: 15)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Konfirmasi Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: Text('Apakah Anda yakin ingin mengakhiri sesi aktif Anda?', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text('Keluar', style: GoogleFonts.inter(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      transitionBuilder: (context, anim1, anim2, child) => FadeTransition(opacity: anim1, child: child),
    );
  }
}

class _ProfileTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;
  final bool isLast;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.color,
    this.isLast = false,
  });

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTapDown: (_) {
         HapticHelper.light();
         setState(() => _isPressed = true);
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(widget.icon, size: 18, color: widget.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ),
            if (!widget.isLast)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(height: 1, color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
          ],
        ),
      ),
    );
  }
}
