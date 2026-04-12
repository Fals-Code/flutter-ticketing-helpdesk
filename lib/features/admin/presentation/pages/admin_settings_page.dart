import 'package:flutter/material.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        children: [
          _buildSettingsGroup(
            'Umum',
            [
              _buildSettingTile(
                Icons.language_rounded,
                'Bahasa Aplikasi',
                'Bahasa Indonesia',
                isDark,
              ),
              _buildSettingTile(
                Icons.notifications_active_outlined,
                'Notifikasi Push',
                'Aktif',
                isDark,
                trailing: Switch(value: true, onChanged: (v) {}),
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            'Tiket & Alur Kerja',
            [
              _buildSettingTile(
                Icons.timer_outlined,
                'SLA Response Time',
                '2 Jam',
                isDark,
              ),
              _buildSettingTile(
                Icons.category_outlined,
                'Kelola Kategori',
                '4 Kategori Aktif',
                isDark,
              ),
            ],
            isDark,
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            'Keamanan',
            [
              _buildSettingTile(
                Icons.security_rounded,
                'Dua Faktor Autentikasi',
                'Wajib untuk Admin',
                isDark,
              ),
              _buildSettingTile(
                Icons.api_rounded,
                'API Keys',
                'Kelola akses pihak ketiga',
                isDark,
              ),
            ],
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String subtitle,
    bool isDark, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: trailing == null ? () {} : null,
    );
  }
}
