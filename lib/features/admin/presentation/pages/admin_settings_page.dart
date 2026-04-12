import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _maintenanceMode = false;
  bool _autoAssign = true;
  double _slaHours = 4.0;
  String _priorityLogic = 'Standard';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Sistem'),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pengaturan berhasil disimpan'), backgroundColor: AppColors.statusResolved),
              );
            },
            child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeroSection(isDark),
          const SizedBox(height: 32),
          
          _buildSectionHeader('Operasional Sistem'),
          _buildSettingsCard(isDark, [
            _buildToggleTile(
              Icons.construction_rounded, 
              'Mode Pemeliharaan', 
              'Hanya Admin yang bisa akses aplikasi', 
              _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v),
              Colors.orange,
            ),
            const Divider(height: 1),
            _buildToggleTile(
              Icons.auto_awesome_rounded, 
              'Penugasan Otomatis', 
              'Algoritma penyeimbang beban tugas', 
              _autoAssign,
              (v) => setState(() => _autoAssign = v),
              Colors.purple,
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionHeader('Konfigurasi Tiket & SLA'),
          _buildSettingsCard(isDark, [
            _buildSliderTile(
              Icons.timer_outlined,
              'Target SLA Response',
              'Satuannya dalam jam',
              _slaHours,
              1, 24,
              (v) => setState(() => _slaHours = v),
              Colors.blue,
            ),
            const Divider(height: 1),
            _buildPickerTile(
              Icons.sort_rounded,
              'Logika Prioritas',
              _priorityLogic,
              ['Standard', 'Urgent First', 'FIFO', 'AI Sorted'],
              (v) => setState(() => _priorityLogic = v!),
              Colors.teal,
            ),
          ]),

          const SizedBox(height: 32),
          _buildSectionHeader('Keamanan & Audit'),
          _buildSettingsCard(isDark, [
            _buildActionTile(Icons.history_rounded, 'Audit Log Ekspor', 'Ekspor aktivitas sistem ke CSV/PDF', Colors.grey),
            const Divider(height: 1),
            _buildActionTile(Icons.security_rounded, 'Kebijakan Password', 'Kelola kompleksitas kata sandi', Colors.redAccent),
          ]),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'TICKET-Q v1.0.0-Stable\nEngine Build: 2026.04.12',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 10, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            'Konfigurasi Global',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Kelola parameter sistem dan alur kerja helpdesk di satu tempat terpusat.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile(IconData icon, String title, String subtitle, bool value, Function(bool) onChanged, Color color) {
    return ListTile(
      leading: _IconContainer(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, Color color) {
    return ListTile(
      leading: _IconContainer(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: () {},
    );
  }

  Widget _buildSliderTile(IconData icon, String title, String subtitle, double value, double min, double max, Function(double) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconContainer(icon: icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('${value.toInt()} Jam', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                Text(subtitle, style: const TextStyle(fontSize: 11)),
                Slider(value: value, min: min, max: max, onChanged: onChanged, activeColor: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String title, String value, List<String> options, Function(String?) onChanged, Color color) {
    return ListTile(
      leading: _IconContainer(icon: icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconContainer({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
