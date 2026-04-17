import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
      duration: const Duration(milliseconds: 1000),
    );

    _slideAnimations = [];
    _fadeAnimations = [];

    // Staggered sequence: Greeting (0), Summary Bar (1), Grid (2), Motivation (3)
    for (int i = 0; i < 4; i++) {
      final double start = i * 0.12;
      final double end = (start + 0.6).clamp(0.0, 1.0);
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
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
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          appBar: AppBar(
            title: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return Text(
                  authState.user.role == UserRole.admin ? 'Dashboard Admin' : 'Panel Teknisi',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
                );
              },
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) {
                  return IconButton(
                    icon: Icon(
                      mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      size: 20,
                    ),
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
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
              const SizedBox(width: 8),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                      _buildSectionLabel('STATISTIK PENUGASAN', isDark),
                      const SizedBox(height: 16),
                      _buildStatusGrid(context, stats.open, stats.inProgress, stats.resolved, stats.closed),
                    ],
                  )),
                  const SizedBox(height: 36),
                  _buildAnimatedSection(3, _buildMotivationSection(isDark)),
                ],
               ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label, 
      style: GoogleFonts.inter(
        fontSize: 11, 
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white38 : Colors.black45,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSummarySection(bool isDark, int active, int resolved, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('TOTAL MASUK', total, Icons.analytics_rounded),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
          _buildSummaryItem('PENANGANAN', active, Icons.engineering_rounded),
          Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.2)),
          _buildSummaryItem('SELESAI', resolved, Icons.verified_rounded),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, val, child) {
            return Text(
              val.toInt().toString(), 
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1)
            );
          },
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatusGrid(BuildContext context, int open, int prog, int res, int closed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        StatCard(label: 'Terbuka', value: open.toString(), color: AppColors.statusOpen, icon: Icons.fiber_new_rounded, isDark: isDark),
        StatCard(label: 'Diproses', value: prog.toString(), color: AppColors.statusInProgress, icon: Icons.sync_rounded, isDark: isDark),
        StatCard(label: 'Selesai', value: res.toString(), color: AppColors.statusResolved, icon: Icons.check_circle_rounded, isDark: isDark),
        StatCard(label: 'Ditutup', value: closed.toString(), color: const Color(0xFF94A3B8), icon: Icons.archive_rounded, isDark: isDark),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.format_quote_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15, 
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
