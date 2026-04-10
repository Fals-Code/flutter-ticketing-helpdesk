import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/shared/widgets/loading_widget.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        if (state.isLoading && state.allTickets.isEmpty) {
          return const Center(child: LoadingWidget());
        }

        final tickets = state.allTickets;
        final openCount = tickets.where((t) => t.status == TicketStatus.open).length;
        final inProgressCount = tickets.where((t) => t.status == TicketStatus.inProgress).length;
        final resolvedCount = tickets.where((t) => t.status == TicketStatus.resolved).length;
        final closedCount = tickets.where((t) => t.status == TicketStatus.closed).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Staff Dashboard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<TicketBloc>().add(
                      const FetchAllTicketsRequested(page: 0, limit: 100),
                    ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TicketBloc>().add(const FetchAllTicketsRequested(page: 0, limit: 100));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummarySection(isDark, openCount + inProgressCount, resolvedCount),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Text(
                    'Statistik Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  _buildStatusGrid(context, openCount, inProgressCount, resolvedCount, closedCount),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  _buildRecentActivitySection(context, tickets, isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(bool isDark, int active, int resolved) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Aktif', active.toString(), AppColors.primary),
          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
          _buildSummaryItem('Selesai', resolved.toString(), AppColors.statusResolved),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildStatusGrid(BuildContext context, int open, int prog, int res, int closed) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spaceMD,
      crossAxisSpacing: AppDimensions.spaceMD,
      childAspectRatio: 1.5,
      children: [
        _buildStatusCard('Terbuka', open.toString(), AppColors.statusOpen, Icons.fiber_new_outlined),
        _buildStatusCard('Diproses', prog.toString(), AppColors.statusInProgress, Icons.run_circle_outlined),
        _buildStatusCard('Selesai', res.toString(), AppColors.statusResolved, Icons.check_circle_outline),
        _buildStatusCard('Ditutup', closed.toString(), AppColors.textSecondaryLight, Icons.cancel_outlined),
      ],
    );
  }

  Widget _buildStatusCard(String label, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, List<TicketEntity> tickets, bool isDark) {
    final recentTickets = tickets.take(5).toList();
    if (recentTickets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laporan Terbaru',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppDimensions.spaceLG),
        ...recentTickets.map((t) => _buildMiniTicketCard(context, t, isDark)),
      ],
    );
  }

  Widget _buildMiniTicketCard(BuildContext context, TicketEntity ticket, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: ticket.status.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('#${ticket.id.substring(0, 8).toUpperCase()} • ${ticket.category}', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
    );
  }
}
