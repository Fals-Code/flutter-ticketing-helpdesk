import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/utils/haptic_helper.dart';
import 'package:uts/core/services/toast_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _maintenanceMode = false;
  bool _autoAssign = true;
  double _slaHours = 4.0;
  String _defaultPriority = 'Medium';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Pengaturan Sistem', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                HapticHelper.success();
                ToastService().show(context, message: 'Pengaturan berhasil disimpan', type: ToastType.success);
              },
              child: Text('SIMPAN', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          _buildHeroSection(isDark),
          const SizedBox(height: 32),
          
          _buildSectionHeader('OPERASIONAL SISTEM'),
          _buildSettingsGroup(isDark, [
            _buildToggleTile(
              icon: Icons.construction_rounded,
              title: 'Mode Pemeliharaan',
              subtitle: 'Hanya Admin yang dapat mengakses',
              value: _maintenanceMode,
              onChanged: (v) { HapticHelper.medium(); setState(() => _maintenanceMode = v); },
              color: Colors.orange,
              isDark: isDark,
            ),
            _buildToggleTile(
              icon: Icons.auto_awesome_rounded,
              title: 'Penugasan Otomatis',
              subtitle: 'Distribusi tugas teknisi cerdas',
              value: _autoAssign,
              onChanged: (v) { HapticHelper.medium(); setState(() => _autoAssign = v); },
              color: Colors.purple,
              isDark: isDark,
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionHeader('KONFIGURASI TIKET'),
          _buildSettingsGroup(isDark, [
            _buildSliderTile(
              icon: Icons.timer_outlined,
              title: 'Target SLA Response',
              subtitle: 'Batas respon awal bantuan (jam)',
              value: _slaHours,
              min: 1, max: 24,
              onChanged: (v) => setState(() => _slaHours = v),
              color: Colors.blue,
              isDark: isDark,
            ),
            _buildDropdownTile(
              icon: Icons.flag_outlined,
              title: 'Prioritas Bawaan',
              subtitle: 'Status default untuk tiket baru',
              value: _defaultPriority,
              options: ['Low', 'Medium', 'High', 'Urgent'],
              onChanged: (v) => setState(() => _defaultPriority = v),
              color: Colors.redAccent,
              isDark: isDark,
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionHeader('KEAMANAN & DATA'),
          _buildSettingsGroup(isDark, [
            _buildActionTile(Icons.history_rounded, 'Log Audit Sistem', 'Lihat jejak aktivitas admin', Colors.grey, isDark),
            _buildActionTile(Icons.cloud_download_outlined, 'Cadangkan Database', 'Simpan snapshot data sekarang', Colors.teal, isDark, isLast: true),
          ]),
          
          const SizedBox(height: 48),
          Center(
            child: Opacity(
              opacity: 0.4,
              child: Text(
                'TICKET-Q Engine v1.2.5\nBuild: 2026.04.18',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E), // Dark professional purple-ish
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            'Konfigurasi Global',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Sesuaikan parameter utama untuk mengoptimalkan alur kerja layanan helpdesk Anda.',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildSettingsGroup(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required String subtitle, required bool value, required Function(bool) onChanged, required Color color, required bool isDark}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _IconBox(icon: icon, color: color),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      trailing: Switch.adaptive(
        value: value, 
        onChanged: onChanged, 
        activeTrackColor: AppColors.primary.withValues(alpha: 0.2),
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSliderTile({required IconData icon, required String title, required String subtitle, required double value, required double min, required double max, required Function(double) onChanged, required Color color, required bool isDark}) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _IconBox(icon: icon, color: color),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('${value.toInt()} Jam', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ],
          ),
          subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
        ),
        Slider(
          value: value, min: min, max: max, 
          divisions: (max-min).toInt(),
          activeColor: AppColors.primary,
          inactiveColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          onChanged: (v) { HapticHelper.selection(); onChanged(v); },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDropdownTile({required IconData icon, required String title, required String subtitle, required String value, required List<String> options, required Function(String) onChanged, required Color color, required bool isDark}) {
    return ListTile(
      onTap: () { HapticHelper.medium(); _showSelectionBottomSheet(title, options, value, onChanged, isDark); },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _IconBox(icon: icon, color: color),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  void _showSelectionBottomSheet(String title, List<String> options, String current, Function(String) onChanged, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            ...options.map((opt) => ListTile(
              onTap: () { HapticHelper.selection(); onChanged(opt); Navigator.pop(context); },
              title: Text(opt, style: GoogleFonts.inter(fontWeight: isSelected(opt, current) ? FontWeight.w800 : FontWeight.w500)),
              trailing: isSelected(opt, current) ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )),
          ],
        ),
      ),
    );
  }
  bool isSelected(String o, String c) => o == c;

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color, bool isDark, {bool isLast = false}) {
    return Column(
      children: [
        ListTile(
          onTap: () { HapticHelper.light(); },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: _IconBox(icon: icon, color: color),
          title: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ),
        if (!isLast) Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight, indent: 64),
      ],
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
