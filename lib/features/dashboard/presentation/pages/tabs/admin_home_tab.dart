import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/dashboard/presentation/pages/tabs/widgets/dashboard_widgets.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TicketStatsBloc, TicketStatsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Console'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  context.read<TicketStatsBloc>().add(const stats_event.FetchTicketStatsRequested());
                  context.read<TicketListBloc>().add(const list_event.FetchAllTicketsRequested(page: 0, limit: 5));
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TicketStatsBloc>().add(const stats_event.FetchTicketStatsRequested());
              context.read<TicketListBloc>().add(const list_event.FetchAllTicketsRequested(page: 0, limit: 5));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GreetingBanner(isDark: isDark),
                  const SizedBox(height: 32),
                  // Summary Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AdminSummaryItem(label: 'Total', value: state.stats.total, icon: Icons.analytics),
                        _AdminSummaryItem(label: 'Pending', value: state.stats.open + state.stats.inProgress, icon: Icons.hourglass_top),
                        _AdminSummaryItem(label: 'Selesai', value: state.stats.resolved, icon: Icons.task_alt),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Statistik Sistem', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(label: 'Terbuka', value: state.stats.open.toString(), color: AppColors.statusOpen, icon: Icons.folder_open, isDark: isDark),
                      StatCard(label: 'Diproses', value: state.stats.inProgress.toString(), color: AppColors.statusInProgress, icon: Icons.sync, isDark: isDark),
                      StatCard(label: 'Selesai', value: state.stats.resolved.toString(), color: AppColors.statusResolved, icon: Icons.check_circle, isDark: isDark),
                      StatCard(label: 'Ditutup', value: state.stats.closed.toString(), color: Colors.grey, icon: Icons.archive, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Shortcut Navigasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _AdminShortcut(label: 'Kelola Tiket', icon: Icons.confirmation_number, color: Colors.blue, onTap: () => context.push(AppRoutes.ticketManagement)),
                      const SizedBox(width: 12),
                      _AdminShortcut(label: 'Laporan', icon: Icons.bar_chart, color: Colors.purple, onTap: () => context.push(AppRoutes.adminReports)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _AdminShortcut(label: 'Pengguna', icon: Icons.people, color: Colors.orange, onTap: () => context.push(AppRoutes.userManagement)),
                      const SizedBox(width: 12),
                      _AdminShortcut(label: 'Pengaturan', icon: Icons.settings, color: Colors.teal, onTap: () => context.push(AppRoutes.adminSettings)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminSummaryItem extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _AdminSummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(value.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _AdminShortcut extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AdminShortcut({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
