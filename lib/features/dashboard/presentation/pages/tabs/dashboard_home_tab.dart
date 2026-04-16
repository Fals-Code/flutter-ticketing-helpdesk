import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/dashboard/presentation/pages/tabs/widgets/dashboard_widgets.dart';
import 'package:uts/shared/widgets/loading_widget.dart';

class DashboardHomeTab extends StatelessWidget {
  final VoidCallback onSeeAll;
  const DashboardHomeTab({super.key, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                tooltip: mode == ThemeMode.dark ? 'Mode Terang' : 'Mode Gelap',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<TicketStatsBloc>().add(const stats_event.FetchTicketStatsRequested());
              context.read<TicketListBloc>().add(const list_event.FetchTicketsRequested(page: 0, limit: 5));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<TicketStatsBloc>().add(const stats_event.FetchTicketStatsRequested());
          context.read<TicketListBloc>().add(const list_event.FetchTicketsRequested(page: 0, limit: 5));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingBanner(isDark: isDark),
              const SizedBox(height: 32),
              const Text(
                'Ringkasan Tiket',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              BlocBuilder<TicketStatsBloc, TicketStatsState>(
                builder: (context, state) {
                  final stats = [
                    {
                      'label': AppStrings.totalTickets,
                      'value': state.stats.total.toString(),
                      'color': AppColors.primary,
                      'icon': Icons.confirmation_number_outlined
                    },
                    {
                      'label': AppStrings.openTickets,
                      'value': state.stats.open.toString(),
                      'color': AppColors.statusOpen,
                      'icon': Icons.folder_open_outlined
                    },
                    {
                      'label': AppStrings.inProgressTickets,
                      'value': state.stats.inProgress.toString(),
                      'color': AppColors.statusInProgress,
                      'icon': Icons.pending_outlined
                    },
                    {
                      'label': AppStrings.resolvedTickets,
                      'value': state.stats.resolved.toString(),
                      'color': AppColors.statusResolved,
                      'icon': Icons.check_circle_outline
                    },
                  ];

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppDimensions.spaceMD,
                      mainAxisSpacing: AppDimensions.spaceMD,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, i) {
                      final stat = stats[i];
                      return StatCard(
                        label: stat['label'] as String,
                        value: stat['value'] as String,
                        color: stat['color'] as Color,
                        icon: stat['icon'] as IconData,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tiket Terbaru', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spaceMD),
              BlocBuilder<TicketListBloc, TicketListState>(
                builder: (context, state) {
                  if (state.isLoading && state.tickets.isEmpty) {
                    return Column(
                      children: List.generate(
                          3,
                          (index) => const Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: ShimmerCard(height: 100),
                              )),
                    );
                  } else if (state.tickets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 48, color: isDark ? Colors.white24 : Colors.black12),
                            const SizedBox(height: 16),
                            Text('Belum ada tiket bantuan.',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                            const SizedBox(height: 8),
                            const Text(
                              'Tiket yang Anda buat akan muncul di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: state.tickets
                        .take(5)
                        .map((ticket) => RecentTicketCard(ticket: ticket, isDark: isDark))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
