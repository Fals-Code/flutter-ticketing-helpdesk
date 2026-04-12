import 'package:flutter/material.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, String>> mockUsers = [
      {'name': 'Admin Utama', 'email': 'admin@uts.com', 'role': 'Admin'},
      {'name': 'Budiman Tech', 'email': 'staff1@uts.com', 'role': 'Staff'},
      {'name': 'Siti Network', 'email': 'staff2@uts.com', 'role': 'Staff'},
      {'name': 'Budi Santoso', 'email': 'customer@uts.com', 'role': 'Customer'},
      {'name': 'Ani Wijaya', 'email': 'customer2@uts.com', 'role': 'Customer'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchHeader(isDark),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              itemCount: mockUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = mockUsers[index];
                return _buildUserTile(user, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari pengguna...',
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

  Widget _buildUserTile(Map<String, String> user, bool isDark) {
    final Color roleColor = user['role'] == 'Admin' 
        ? Colors.red 
        : (user['role'] == 'Staff' ? Colors.blue : Colors.green);

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
            user['name']![0],
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(user['email']!, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user['role']!,
            style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        onTap: () {},
      ),
    );
  }
}
