import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/shared/widgets/loading_widget.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh stats when opening report
    context.read<TicketBloc>().add(const FetchTicketStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analitik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TicketBloc>().add(const FetchTicketStatsRequested()),
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state.isLoading && state.stats.total == 0) {
            return const Center(child: LoadingWidget());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Ringkasan Tiket', isDark),
                const SizedBox(height: 16),
                _buildStatsGrid(state),
                const SizedBox(height: 32),
                _buildSectionTitle('Performa Tim', isDark),
                const SizedBox(height: 16),
                _buildPerformanceList(isDark),
                const SizedBox(height: 32),
                _buildSectionTitle('Distribusi Kategori', isDark),
                const SizedBox(height: 16),
                _buildCategoryChart(isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildStatsGrid(TicketState state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Tiket',
          state.stats.total.toString(),
          Icons.analytics_rounded,
          AppColors.primary,
        ),
        _buildStatCard(
          'Tiket Terbuka',
          state.stats.open.toString(),
          Icons.hourglass_empty_rounded,
          Colors.orange,
        ),
        _buildStatCard(
          'Selesai',
          state.stats.resolved.toString(),
          Icons.check_circle_outline_rounded,
          Colors.green,
        ),
        _buildStatCard(
          'Dalam Proses',
          state.stats.inProgress.toString(),
          Icons.running_with_errors_rounded,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceList(bool isDark) {
    // Mock performance data for UTS demo
    final List<Map<String, dynamic>> team = [
      {'name': 'Admin Utama', 'resolved': 12, 'avgTime': '2j 15m', 'rating': 4.8},
      {'name': 'Staff Teknik 1', 'resolved': 8, 'avgTime': '4j 30m', 'rating': 4.5},
      {'name': 'Staff Teknik 2', 'resolved': 5, 'avgTime': '1j 45m', 'rating': 4.9},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: team.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        itemBuilder: (context, index) {
          final member = team[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                member['name'][0],
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member['name'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Rata-rata: ${member['avgTime']}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${member['resolved']} Tiket',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      member['rating'].toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChart(bool isDark) {
    final categories = [
      {'label': 'Hardware', 'percentage': 0.45, 'color': Colors.blue},
      {'label': 'Software', 'percentage': 0.30, 'color': Colors.purple},
      {'label': 'Network', 'percentage': 0.15, 'color': Colors.orange},
      {'label': 'Other', 'percentage': 0.10, 'color': Colors.grey},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final cat in categories)
                    Expanded(
                      flex: ((cat['percentage'] as double) * 100).toInt(),
                      child: Container(color: cat['color'] as Color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final cat in categories)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${cat['label']} (${((cat['percentage'] as double) * 100).toInt()}%)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
