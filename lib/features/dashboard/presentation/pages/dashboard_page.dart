import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart'
    as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_list_page.dart';
import 'package:uts/features/ticket/presentation/pages/staff_dashboard_page.dart';

// Tab Imports
import 'tabs/dashboard_home_tab.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/notification_tab.dart';

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
    final listBloc = context.read<TicketListBloc>();
    final statsBloc = context.read<TicketStatsBloc>();
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    final isTechnician = user.role == UserRole.technician;

    statsBloc.add(const stats_event.FetchTicketStatsRequested());
    listBloc.add(const list_event.FetchTicketsRequested(page: 0, limit: 5));

    context.read<NotificationBloc>().add(FetchNotificationsRequested());
    context.read<NotificationBloc>().add(StartNotificationSubscription());

    listBloc.add(list_event.StartTicketListSubscription(
      userId: user.id,
      assignedToId: isTechnician ? user.id : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context
              .read<TicketListBloc>()
              .add(list_event.ResetTicketListState());
          context
              .read<TicketStatsBloc>()
              .add(stats_event.ResetTicketStatsState());
          context
              .read<NotificationBloc>()
              .add(ResetNotificationState());
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return IndexedStack(
              index: _currentIndex,
              children: [
                state.user.role == UserRole.admin
                    ? const AdminHomeTab()
                    : (state.user.role == UserRole.technician
                        ? const StaffDashboardPage()
                        : DashboardHomeTab(
                            onSeeAll: () =>
                                setState(() => _currentIndex = 1),
                          )),
                const TicketListPage(),
                const NotificationTab(),
                const ProfileTab(),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(isDark),
        floatingActionButton: _currentIndex == 1
            ? FloatingActionButton(
                heroTag: 'dashboard_fab',
                onPressed: () => context.push(AppRoutes.createTicket),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                child: const Icon(Icons.add_rounded, size: 28),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        final unreadCount =
            notifState.notifications.where((n) => !n.isRead).length;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFEEEEF2),
                width: 1,
              ),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Beranda',
                    isSelected: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.confirmation_number_outlined,
                    activeIcon: Icons.confirmation_number_rounded,
                    label: 'Tiket',
                    isSelected: _currentIndex == 1,
                    onTap: () {
                      setState(() => _currentIndex = 1);
                      final authState = context.read<AuthBloc>().state;
                      if (authState.user.isEmpty) return;
                      final user = authState.user;
                      final isTechnician =
                          user.role == UserRole.technician;
                      context.read<TicketListBloc>().add(
                          const list_event.FetchTicketsRequested(
                              page: 0, limit: 10));
                      if (user.role == UserRole.admin ||
                          user.role == UserRole.technician) {
                        context.read<TicketListBloc>().add(
                            list_event.FetchAllTicketsRequested(
                              page: 0,
                              limit: 10,
                              assignedToId:
                                  isTechnician ? user.id : null,
                            ));
                      }
                    },
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Notifikasi',
                    isSelected: _currentIndex == 2,
                    badge: unreadCount,
                    onTap: () => setState(() => _currentIndex = 2),
                    isDark: isDark,
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profil',
                    isSelected: _currentIndex == 3,
                    onTap: () => setState(() => _currentIndex = 3),
                    isDark: isDark,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
