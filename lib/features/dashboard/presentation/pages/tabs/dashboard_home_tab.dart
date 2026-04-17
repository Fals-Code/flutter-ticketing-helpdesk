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

class DashboardHomeTab extends StatefulWidget {
  final VoidCallback onSeeAll;
  const DashboardHomeTab({super.key, required this.onSeeAll});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimations = [];
    _fadeAnimations = [];

    // Staggered sequence: Greeting (0), Stats (1), Recent Tickets (2)
    for (int i = 0; i < 3; i++) {
      final double start = i * 0.15;
      final double end = (start + 0.5).clamp(0.0, 1.0);
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0.0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
        ),
      );
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _animationController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
        ),
      );
    }
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return SlideTransition(
      position: _slideAnimations[index],
      child: FadeTransition(
        opacity: _fadeAnimations[index],
        child: child,
      ),
    );
  }

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
                  mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedSection(0, GreetingBanner(isDark: isDark)),
              const SizedBox(height: 32),
              
              _buildAnimatedSection(1, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan Aktivitas',
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<TicketStatsBloc, TicketStatsState>(
                    builder: (context, state) {
                      if (state.isLoading && state.stats.total == 0) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, i) => const ShimmerCard(),
                        );
                      }

                      final stats = [
                        {
                          'label': 'Total Tiket',
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
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
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
                ],
              )),
              
              const SizedBox(height: 32),
              
              _buildAnimatedSection(2, Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiket Terbaru', 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onSeeAll,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Lihat Semua', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<TicketListBloc, TicketListState>(
                    builder: (context, state) {
                      if (state.isLoading && state.tickets.isEmpty) {
                        return Column(
                          children: List.generate(
                              3,
                              (index) => const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: ShimmerCard(height: 120),
                                  )),
                        );
                      } else if (state.tickets.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.confirmation_number_outlined,
                                    size: 32, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text('Belum ada tiket.',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              const SizedBox(height: 8),
                              Text(
                                'Bantuan yang Anda minta akan muncul di sini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ],
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
                ],
              )),
              
              const SizedBox(height: 80), // Padding bottom for floating nav
            ],
          ),
        ),
      ),
    );
  }
}
