import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/admin_event.dart';
import 'package:uts/features/admin/presentation/bloc/admin_state.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/shared/widgets/loading_widget.dart';

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.priorityHigh),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!), backgroundColor: AppColors.statusResolved),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Pengguna'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<AdminBloc>().add(const FetchAllUsersRequested()),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchHeader(isDark),
            Expanded(
              child: BlocBuilder<AdminBloc, AdminState>(
                builder: (context, state) {
                  if (state.status == AdminStatus.loading && state.users.isEmpty) {
                    return const Center(child: LoadingWidget());
                  }

                  final filteredUsers = state.users.where((u) {
                    final searchLow = _searchQuery.toLowerCase();
                    return (u.fullName?.toLowerCase().contains(searchLow) ?? false) ||
                           u.email.toLowerCase().contains(searchLow);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text('Pengguna tidak ditemukan'),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.spaceMD),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserTile(user, isDark);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Cari nama atau email...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(AuthUser user, bool isDark) {
    final roleInfo = _getRoleInfo(user.role);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            user.fullName?.isNotEmpty == true ? user.fullName![0].toUpperCase() : 'U',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.fullName ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user.email, style: const TextStyle(fontSize: 12)),
        trailing: InkWell(
          onTap: () => _showRoleUpdateDialog(user),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleInfo['color']!.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleInfo['color']!.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  roleInfo['label']!,
                  style: TextStyle(color: roleInfo['color'], fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_rounded, size: 10, color: roleInfo['color']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleUpdateDialog(AuthUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Peran: ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRoleOption(user, 'Administrator', UserRole.admin, Icons.admin_panel_settings_rounded, Colors.red),
            _buildRoleOption(user, 'Teknisi / Agen', UserRole.technician, Icons.engineering_rounded, Colors.orange),
            _buildRoleOption(user, 'Customer / User', UserRole.user, Icons.person_rounded, Colors.green),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ],
      ),
    );
  }

  Widget _buildRoleOption(AuthUser user, String label, UserRole role, IconData icon, Color color) {
    final isSelected = user.role == role;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
      onTap: isSelected ? null : () {
        Navigator.pop(context);
        final roleInt = role == UserRole.admin ? 1 : (role == UserRole.technician ? 2 : 3);
        context.read<AdminBloc>().add(UpdateUserRoleRequested(userId: user.id, newRole: roleInt));
      },
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return {'label': 'Admin', 'color': Colors.red};
      case UserRole.technician:
        return {'label': 'Teknisi', 'color': Colors.blue};
      case UserRole.user:
        return {'label': 'User', 'color': Colors.green};
    }
  }
}
