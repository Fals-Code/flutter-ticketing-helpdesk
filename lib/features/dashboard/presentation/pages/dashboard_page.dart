import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:uts/features/ticket/presentation/pages/ticket_list_page.dart';
import 'package:uts/features/ticket/presentation/pages/staff_dashboard_page.dart';

// Tab Imports
import 'tabs/dashboard_home_tab.dart';
import 'tabs/admin_home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/notification_tab.dart';

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

  static const _navItems = [
    {'label': AppStrings.navDashboard, 'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded},
    {'label': AppStrings.navTickets, 'icon': Icons.confirmation_number_outlined, 'activeIcon': Icons.confirmation_number_rounded},
    {'label': AppStrings.navNotifications, 'icon': Icons.notifications_outlined, 'activeIcon': Icons.notifications_rounded},
    {'label': AppStrings.navProfile, 'icon': Icons.person_outline, 'activeIcon': Icons.person_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          // Clear states of other blocs
          context.read<TicketListBloc>().add(list_event.ResetTicketListState());
          context.read<TicketStatsBloc>().add(stats_event.ResetTicketStatsState());
          context.read<NotificationBloc>().add(ResetNotificationState());
          
          // Redirect to login
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
                    : (state.user.role == UserRole.technician ? const StaffDashboardPage() : DashboardHomeTab(
                        onSeeAll: () => setState(() => _currentIndex = 1),
                      )),
                const TicketListPage(),
                const NotificationTab(),
                const ProfileTab(),
              ],
            );
          },
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            setState(() => _currentIndex = i);
            if (i == 1) {
              final authState = context.read<AuthBloc>().state;
              if (authState.user.isEmpty) return;
              final user = authState.user;
              final isStaff = user.role == UserRole.admin || user.role == UserRole.technician;
              final isTechnician = user.role == UserRole.technician;
              
              // Refresh tickets when switching to Tickets tab
              context.read<TicketListBloc>().add(const list_event.FetchTicketsRequested(page: 0, limit: 10));
              
              if (isStaff) {
                context.read<TicketListBloc>().add(list_event.FetchAllTicketsRequested(
                  page: 0, 
                  limit: 10,
                  assignedToId: isTechnician ? user.id : null,
                ));
              }
            }
          },
          destinations: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isNotification = index == 2;
            
            return NavigationDestination(
              icon: isNotification 
                ? BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final unreadCount = state.notifications.where((n) => !n.isRead).length;
                      return Badge(
                        label: Text(unreadCount.toString()),
                        isLabelVisible: unreadCount > 0,
                        child: Icon(item['icon'] as IconData),
                      );
                    },
                  )
                : Icon(item['icon'] as IconData),
              selectedIcon: isNotification
                ? BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final unreadCount = state.notifications.where((n) => !n.isRead).length;
                      return Badge(
                        label: Text(unreadCount.toString()),
                        isLabelVisible: unreadCount > 0,
                        child: Icon(item['activeIcon'] as IconData, color: AppColors.primary),
                      );
                    },
                  )
                : Icon(item['activeIcon'] as IconData, color: AppColors.primary),
              label: item['label'] as String,
            );
          }).toList(),
        ),
        floatingActionButton: _currentIndex == 1
            ? BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state.user.role != UserRole.user) return const SizedBox.shrink();
                  return FloatingActionButton(
                    heroTag: 'dashboard_fab',
                    onPressed: () => context.push(AppRoutes.createTicket),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  );
                },
              )
            : null,
      ),
    );
  }
}
