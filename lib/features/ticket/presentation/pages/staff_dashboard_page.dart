import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart' as stats_state;
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/shared/theme/theme_cubit.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
      builder: (context, state) {
        if (state.isLoading && state.stats.total == 0) {
          return const Center(child: LoadingWidget());
        }

        final stats = state.stats;

        return Scaffold(
          appBar: AppBar(
            title: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                return Text(authState.user.role == UserRole.admin ? 'Dashboard Admin' : 'Panel Teknisi');
              },
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => context.read<ThemeCubit>().toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
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
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingBanner(isDark: isDark),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  _buildSummarySection(isDark, stats.open + stats.inProgress, stats.resolved, stats.total),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Text(
                    'Statistik Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  _buildStatusGrid(context, stats.open, stats.inProgress, stats.resolved, stats.closed),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  _buildTotalSection(context, stats.total, isDark),
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
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Masuk', total.toString(), isDark ? Colors.white : Colors.black),
          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.black12),
          _buildSummaryItem('Perlu Penanganan', active.toString(), AppColors.primary),
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTotalSection(BuildContext context, int total, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [AppColors.primary.withValues(alpha: 0.2), AppColors.surfaceDark]
            : [AppColors.primary.withValues(alpha: 0.05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 32),
          const SizedBox(height: 12),
          Text(
            'Total Tiket Masuk: $total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Data statistik dikelola secara terpusat oleh sistem',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(BuildContext context, int open, int prog, int res, int closed) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppDimensions.spaceMD,
      crossAxisSpacing: AppDimensions.spaceMD,
      childAspectRatio: 1.3, // Reduced from 1.5 to prevent overflow
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
}

class _GreetingBanner extends StatelessWidget {
  final bool isDark;

  const _GreetingBanner({required this.isDark});

  Map<String, dynamic> _getGreetingConfig() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return {'text': 'Selamat Pagi', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orangeAccent};
    } else if (hour >= 11 && hour < 15) {
      return {'text': 'Selamat Siang', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orange};
    } else if (hour >= 15 && hour < 18) {
      return {'text': 'Selamat Sore', 'icon': Icons.wb_twilight_rounded, 'color': Colors.deepOrangeAccent};
    } else {
      return {'text': 'Selamat Malam', 'icon': Icons.bedtime_rounded, 'color': Colors.indigoAccent};
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getGreetingConfig();
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final name = state.user.fullName ?? 'Staff';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  config['icon'] as IconData,
                  color: config['color'] as Color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '${config['text']}, $name!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Semoga harimu produktif dalam melayani pengguna",
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ],
        );
      },
    );
  }
}
