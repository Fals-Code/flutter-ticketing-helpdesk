import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() {
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated) {
      context.read<TicketBloc>().add(FetchTicketStatsRequested(assignedToId: authState.user!.id));
      context.read<TicketBloc>().add(const FetchAllTicketsRequested(page: 0, limit: 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState.user;
        final name = user?.fullName ?? 'Teknisi';

        return RefreshIndicator(
          onRefresh: () async => _fetchStats(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreeting(name, isDark),
                const SizedBox(height: 24),
                _buildSummaryBar(context, isDark),
                const SizedBox(height: 24),
                _buildSectionHeader('Statistik Penugasan', isDark),
                const SizedBox(height: 16),
                _buildStatsGrid(context, isDark),
                const SizedBox(height: 32),
                _buildSectionHeader('Tugas Baru Untuk Anda', isDark),
                const SizedBox(height: 16),
                _buildRecentTasks(context, isDark, user?.id),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreeting(String name, bool isDark) {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 11) {
      timeGreeting = 'Selamat Pagi';
    } else if (hour < 15) {
      timeGreeting = 'Selamat Siang';
    } else if (hour < 19) {
      timeGreeting = 'Selamat Sore';
    } else {
      timeGreeting = 'Selamat Malam';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$timeGreeting,',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, bool isDark) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        final stats = state.stats;
        final pending = stats.open + stats.inProgress;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Tugas', stats.total.toString(), Colors.white),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Perlu Penanganan', pending.toString(), Colors.white),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildSummaryItem('Selesai', stats.resolved.toString(), Colors.white),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isDark) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        final stats = state.stats;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard('Terbuka', stats.open.toString(), AppColors.statusOpen, isDark),
            _buildStatCard('Diproses', stats.inProgress.toString(), AppColors.statusInProgress, isDark),
            _buildStatCard('Selesai', stats.resolved.toString(), AppColors.statusResolved, isDark),
            _buildStatCard('Ditutup', stats.closed.toString(), Colors.grey, isDark),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTasks(BuildContext context, bool isDark, String? staffId) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        if (state.isLoading && state.allTickets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final myTasks = state.allTickets.where((t) => t.assignedTo == staffId).take(3).toList();

        if (myTasks.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_turned_in_outlined, size: 40, color: AppColors.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Belum ada tugas khusus untuk Anda.', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: myTasks.map((ticket) => _TaskCard(ticket: ticket, isDark: isDark)).toList(),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final dynamic ticket;
  final bool isDark;

  const _TaskCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: ticket.priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Dari: ${ticket.userName ?? "User"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ticket.status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              ticket.status.label,
              style: TextStyle(
                color: ticket.status.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
