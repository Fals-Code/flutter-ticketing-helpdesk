import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/shared/theme/theme_cubit.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_list_page.dart';
import 'package:uts/shared/widgets/app_button.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/ticket/presentation/pages/staff_dashboard_page.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';

/// Dashboard utama dengan bottom navigation bar dan stat overview.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  void _fetchInitialData() {
    context.read<TicketBloc>().add(const FetchTicketStatsRequested());
    context.read<TicketBloc>().add(const FetchTicketsRequested(page: 0, limit: 5));
    context.read<NotificationBloc>().add(FetchNotificationsRequested());
  }

  static const _navItems = [
    {'label': AppStrings.navDashboard, 'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded},
    {'label': AppStrings.navTickets, 'icon': Icons.confirmation_number_outlined, 'activeIcon': Icons.confirmation_number_rounded},
    {'label': AppStrings.navNotifications, 'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications_rounded},
    {'label': AppStrings.navProfile, 'icon': Icons.person_outline, 'activeIcon': Icons.person_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isStaff = state.status == AuthStatus.authenticated && 
              (state.user.role == UserRole.admin || state.user.role == UserRole.technician);

          return IndexedStack(
            index: _currentIndex,
            children: [
              isStaff ? const StaffDashboardPage() : const _DashboardHomeTab(),
              const TicketListPage(),
              const _NotificationTab(),
              const _ProfileTab(),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppDimensions.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final isActive = _currentIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceLG,
                      vertical: AppDimensions.spaceSM,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isActive
                                ? item['activeIcon'] as IconData
                                : item['icon'] as IconData,
                            key: ValueKey(isActive),
                            size: 24,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isActive ? 16 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createTicket),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createTicket),
            )
          : null,
    );
  }
}

// ── Dashboard Home Tab ─────────────────────────────────────────────────────────

class _DashboardHomeTab extends StatelessWidget {
  const _DashboardHomeTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TicketBloc, TicketState>(
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
                  context.read<TicketBloc>().add(const FetchTicketStatsRequested());
                  context.read<TicketBloc>().add(const FetchTicketsRequested(page: 0, limit: 5));
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<TicketBloc>().add(const FetchTicketStatsRequested());
              context.read<TicketBloc>().add(const FetchTicketsRequested(page: 0, limit: 5));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GreetingBanner(isDark: isDark),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Text('Ringkasan Tiket', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppDimensions.spaceMD),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppDimensions.spaceMD,
                      mainAxisSpacing: AppDimensions.spaceMD,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: stats.length,
                    itemBuilder: (context, i) {
                      final stat = stats[i];
                      return _StatCard(
                        label: stat['label'] as String,
                        value: stat['value'] as String,
                        color: stat['color'] as Color,
                        icon: stat['icon'] as IconData,
                        isDark: isDark,
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiket Terbaru', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          // In a real app, this would switch the tab index
                        },
                        child: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  if (state.tickets.isEmpty && !state.isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text('Belum ada tiket.',
                            style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ),
                    )
                  else
                    ...state.tickets.take(5).map((ticket) => _RecentTicketCard(ticket: ticket, isDark: isDark)),
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

class _GreetingBanner extends StatelessWidget {
  final bool isDark;

  const _GreetingBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.dashboardGreeting},',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.user.fullName ?? 'Pengguna'} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.dashboardSubtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentTicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final bool isDark;

  const _RecentTicketCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = ticket.status.color;
    final priorityColor = ticket.priority.color;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.ticketDetail.replaceAll(':id', ticket.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
        padding: const EdgeInsets.all(AppDimensions.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${ticket.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM HH:mm').format(ticket.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Badge(label: ticket.status.label, color: statusColor),
                      const SizedBox(width: AppDimensions.spaceSM),
                      _Badge(label: ticket.priority.label, color: priorityColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Tab ────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.navProfile),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.spaceXL),
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          user.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      Text(
                        user.fullName ?? 'Pengguna',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _Badge(label: user.role.name.toUpperCase(), color: AppColors.secondary),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),

                // Actions Group
                _ProfileSection(
                  title: 'Aktivitas & Keamanan',
                  children: [
                    _ProfileTile(
                      icon: Icons.history_rounded,
                      title: 'Riwayat Aktivitas',
                      subtitle: 'Lihat log penanganan tiket',
                      onTap: () => context.push(AppRoutes.history),
                      isDark: isDark,
                    ),
                    _ProfileTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ubah Kata Sandi',
                      subtitle: 'Perbarui keamanan akun Anda',
                      onTap: () => context.push(AppRoutes.resetPassword),
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceLG),

                _ProfileSection(
                  title: 'Aplikasi',
                  children: [
                    _ProfileTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Aplikasi',
                      subtitle: 'E-Ticketing Helpdesk v1.0.0',
                      onTap: () {},
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                AppButton(
                  label: AppStrings.logout,
                  backgroundColor: AppColors.statusCritical.withValues(alpha: 0.08),
                  textColor: AppColors.statusCritical,
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        ...children,
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    );
  }
}

// ── Notification Tab ──────────────────────────────────────────────────────────

class _NotificationTab extends StatelessWidget {
  const _NotificationTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.navNotifications)),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('Belum ada notifikasi.', style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(FetchNotificationsRequested());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceMD),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.spaceSM),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return _NotificationCard(notification: notification, isDark: isDark);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification; // Use notification entity
  final bool isDark;

  const _NotificationCard({required this.notification, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<NotificationBloc>().add(MarkReadRequested(notification.id));
        if (notification.ticketId != null) {
          context.push(AppRoutes.ticketDetail.replaceAll(':id', notification.ticketId!));
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        decoration: BoxDecoration(
          color: notification.isRead
              ? (isDark ? AppColors.cardDark : AppColors.cardLight)
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: notification.isRead
                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM, HH:mm').format(notification.createdAt),
                    style: TextStyle(
                      color: isDark 
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.5) 
                        : AppColors.textSecondaryLight.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

