import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart' as stats_state;
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/dashboard/presentation/pages/tabs/widgets/dashboard_widgets.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> with SingleTickerProviderStateMixin {
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

    // Staggered sequence: Greeting (0), Summary Bar (1), Grid (2), Motivation (3)
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

    return BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
      builder: (context, state) {
        final stats = state.stats;

        return Scaffold(
          appBar: AppBar(
            title: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return Text(authState.user.role == UserRole.admin ? 'Dashboard Admin' : 'Panel Teknisi');
              },
            ),
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
                  final authState = context.read<AuthBloc>().state;
                  final user = authState.user;
                  context.read<TicketStatsBloc>().add(stats_event.FetchTicketStatsRequested(
                        assignedToId: user.role == UserRole.technician ? user.id : null,
                      ));
                  context.read<TicketListBloc>().add(list_event.FetchAllTicketsRequested(
                        page: 0,
                        limit: 10,
                        assignedToId: user.role == UserRole.technician ? user.id : null,
                      ));
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final authState = context.read<AuthBloc>().state;
              final user = authState.user;
              context.read<TicketStatsBloc>().add(stats_event.FetchTicketStatsRequested(
                    assignedToId: user.role == UserRole.technician ? user.id : null,
                  ));
              context.read<TicketListBloc>().add(list_event.FetchAllTicketsRequested(
                    page: 0,
                    limit: 10,
                    assignedToId: user.role == UserRole.technician ? user.id : null,
                  ));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnimatedSection(0, GreetingBanner(isDark: isDark)),
                  const SizedBox(height: 32),
                  _buildAnimatedSection(1, _buildSummarySection(isDark, stats.open + stats.inProgress, stats.resolved, stats.total)),
                  const SizedBox(height: 32),
                  _buildAnimatedSection(2, Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATISTIK PENUGASAN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusGrid(context, stats.open, stats.inProgress, stats.resolved, stats.closed),
                    ],
                  )),
                  const SizedBox(height: 32),
                  _buildAnimatedSection(3, _buildMotivationSection(isDark)),
                  const SizedBox(height: 80),
                ],
               ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(bool isDark, int active, int resolved, int total) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          _buildSummaryItem('TOTAL MASUK', total.toString(), Icons.analytics_outlined),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem('PENANGANAN', active.toString(), Icons.engineering_outlined),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildSummaryItem('SELESAI', resolved.toString(), Icons.task_alt_rounded),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: double.tryParse(value) ?? 0.0),
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

  Widget _buildStatusGrid(BuildContext context, int open, int prog, int res, int closed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        StatCard(label: 'Terbuka', value: open.toString(), color: AppColors.statusOpen, icon: Icons.fiber_new_outlined, isDark: isDark),
        StatCard(label: 'Diproses', value: prog.toString(), color: AppColors.statusInProgress, icon: Icons.run_circle_outlined, isDark: isDark),
        StatCard(label: 'Selesai', value: res.toString(), color: AppColors.statusResolved, icon: Icons.check_circle_outline, isDark: isDark),
        StatCard(label: 'Ditutup', value: closed.toString(), color: const Color(0xFF64748B), icon: Icons.cancel_outlined, isDark: isDark),
      ],
    );
  }

  Widget _buildMotivationSection(bool isDark) {
    final quotes = [
      "Pelayanan terbaik lahir dari hati yang tulus.",
      "Setiap masalah yang terpecahkan adalah senyum tambahan.",
      "Kemajuan kecil setiap hari menghasilkan hasil besar.",
      "Fokus pada solusi, bukan pada masalahnya.",
    ];
    final String quote = quotes[DateTime.now().day % quotes.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark2 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded, color: AppColors.primary.withValues(alpha: 0.5), size: 32),
          const SizedBox(height: 8),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
