import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/admin_event.dart';
import 'package:uts/features/admin/presentation/bloc/admin_state.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/core/utils/haptic_helper.dart';
import 'package:uts/core/services/toast_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const FetchAllUsersRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ToastService().show(context, message: state.errorMessage!, type: ToastType.error);
        }
        if (state.successMessage != null) {
           ToastService().show(context, message: state.successMessage!, type: ToastType.success);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Data Pengguna', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
          actions: [
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<AdminBloc>().add(const FetchAllUsersRequested())),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            _buildStickySearch(isDark),
            Expanded(
              child: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state.status == AdminStatus.loading && state.users.isEmpty) return const Center(child: LoadingWidget());

                  final filtered = state.users.where((u) {
                    final q = _searchQuery.toLowerCase();
                    return (u.fullName?.toLowerCase().contains(q) ?? false) || u.email.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) return _buildEmptyState(isDark);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildUserCard(filtered[index], isDark),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickySearch(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Cari nama atau email...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildUserCard(AuthUser user, bool isDark) {
    final roleInfo = _getRoleInfo(user.role);
    final avatarColor = _getNameColor(user.fullName ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: avatarColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text((user.fullName ?? 'U')[0].toUpperCase(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: avatarColor, fontSize: 18))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName ?? 'No Name', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildRolePill(user, roleInfo, isDark),
        ],
      ),
    );
  }

  Widget _buildRolePill(AuthUser user, Map<String, dynamic> info, bool isDark) {
    return InkWell(
      onTap: () { HapticHelper.medium(); _showRoleBottomSheet(user); },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: info['color'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Text(info['label'], style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: info['color'])),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more_rounded, size: 12, color: info['color']),
          ],
        ),
      ),
    );
  }

  void _showRoleBottomSheet(AuthUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoleSelectionSheet(user: user, isDark: isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Pengguna tidak ditemukan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getNameColor(String name) {
    final int hash = name.hashCode;
    final List<Color> palette = [const Color(0xFF6366F1), const Color(0xFF8B5CF6), const Color(0xFFEC4899), const Color(0xFF06B6D4), const Color(0xFF10B981)];
    return palette[hash.abs() % palette.length];
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.admin: return {'label': 'ADMIN', 'color': AppColors.danger};
      case UserRole.technician: return {'label': 'TEKNISI', 'color': AppColors.warning};
      case UserRole.user: return {'label': 'PELANGGAN', 'color': AppColors.success};
    }
  }
}

class _RoleSelectionSheet extends StatefulWidget {
  final AuthUser user;
  final bool isDark;
  const _RoleSelectionSheet({required this.user, required this.isDark});
  @override
  State<_RoleSelectionSheet> createState() => _RoleSelectionSheetState();
}

class _RoleSelectionSheetState extends State<_RoleSelectionSheet> {
  UserRole? _selectedRole;
  bool _isUpdating = false;

  @override
  void initState() { super.initState(); _selectedRole = widget.user.role; }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: widget.isDark ? AppColors.surfaceDark : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: widget.isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text('Ubah Peran Pengguna', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Pilih peran baru untuk ${widget.user.fullName}', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          _buildOption(UserRole.admin, 'Administrator', 'Akses penuh ke seluruh sistem', Icons.admin_panel_settings_rounded, AppColors.danger),
          _buildOption(UserRole.technician, 'Teknisi / Staf', 'Menyelesaikan tiket yang masuk', Icons.engineering_rounded, AppColors.warning),
          _buildOption(UserRole.user, 'Pelanggan / User', 'Membuat dan memantau tiket layanan', Icons.person_rounded, AppColors.success),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedRole == widget.user.role || _isUpdating) ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isUpdating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text('SIMPAN PERUBAHAN', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpdate() {
    setState(() => _isUpdating = true);
    HapticHelper.medium();
    context.read<AdminBloc>().add(UpdateUserRoleRequested(userId: widget.user.id, newRole: _selectedRole!.toInt));
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }

  Widget _buildOption(UserRole role, String label, String desc, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () { HapticHelper.selection(); setState(() => _selectedRole = role); },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(desc, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
