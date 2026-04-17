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
import 'package:uts/shared/theme/theme_cubit.dart';

class AdminHomeTab extends StatefulWidget {
  const AdminHomeTab({super.key});

  @override
  State<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends State<AdminHomeTab> with SingleTickerProviderStateMixin {
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

    // Staggered sequence: Greeting (0), Summary Bar (1), Grid (2), Shortcuts (3)
    for (int i = 0; i < 4; i++) {
      final double start = i * 0.15;
      final double end = (start + 0.4).clamp(0.0, 1.0);
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

    return BlocBuilder<TicketStatsBloc, TicketStatsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Console'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedSection(0, GreetingBanner(isDark: isDark)),
                  const SizedBox(height: 32),
                  
                  // Summary Bar
                  _buildAnimatedSection(1, Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AdminSummaryItem(label: 'TOTAL TIKET', value: state.stats.total, icon: Icons.analytics_outlined),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _AdminSummaryItem(label: 'PENDING', value: state.stats.open + state.stats.inProgress, icon: Icons.hourglass_top_rounded),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _AdminSummaryItem(label: 'SELESAI', value: state.stats.resolved, icon: Icons.task_alt_rounded),
                      ],
                    ),
                  )),
                  const SizedBox(height: 32),
                  
                  _buildAnimatedSection(2, Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATISTIK SISTEM', 
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        )
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          StatCard(label: 'Terbuka', value: state.stats.open.toString(), color: AppColors.statusOpen, icon: Icons.folder_open_outlined, isDark: isDark),
                          StatCard(label: 'Diproses', value: state.stats.inProgress.toString(), color: AppColors.statusInProgress, icon: Icons.sync_rounded, isDark: isDark),
                          StatCard(label: 'Selesai', value: state.stats.resolved.toString(), color: AppColors.statusResolved, icon: Icons.check_circle_outline, isDark: isDark),
                          StatCard(label: 'Skala Prioritas', value: state.stats.closed.toString(), color: const Color(0xFF64748B), icon: Icons.flag_outlined, isDark: isDark),
                        ],
                      ),
                    ],
                  )),
                  const SizedBox(height: 32),
                  
                  _buildAnimatedSection(3, Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SHORTCUT NAVIGASI', 
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        )
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _AdminShortcut(label: 'Kelola Tiket', icon: Icons.confirmation_number_outlined, color: AppColors.primary, onTap: () => context.push(AppRoutes.ticketManagement)),
                          const SizedBox(width: 12),
                          _AdminShortcut(label: 'Laporan', icon: Icons.bar_chart_rounded, color: const Color(0xFF8B5CF6), onTap: () => context.push(AppRoutes.adminReports)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _AdminShortcut(label: 'Pengguna', icon: Icons.people_outline, color: const Color(0xFFF59E0B), onTap: () => context.push(AppRoutes.userManagement)),
                          const SizedBox(width: 12),
                          _AdminShortcut(label: 'Pengaturan', icon: Icons.settings_outlined, color: const Color(0xFF10B981), onTap: () => context.push(AppRoutes.adminSettings)),
                        ],
                      ),
                    ],
                  )),
                  const SizedBox(height: 80),
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
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            return Text(
              val.toInt().toString(), 
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1)
            );
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  label, 
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, 
                    fontWeight: FontWeight.w600, 
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
