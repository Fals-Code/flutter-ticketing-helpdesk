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

/// Dashboard utama dengan modern floating bottom navigation bar
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isTransitioning = false;
  int _targetIndex = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOutCubic),
    );
    _fetchInitialData();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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

  void _onTabTapped(int index) async {
    if (index == _currentIndex || _isTransitioning) return;
    
    setState(() {
      _isTransitioning = true;
      _targetIndex = index;
    });
    
    await _fadeController.forward();
    
    if (!mounted) return;

    setState(() {
      _currentIndex = _targetIndex;
    });
    
    // Trigger logic fetching data for tickets tab
    if (index == 1) {
      final authState = context.read<AuthBloc>().state;
      if (authState.user.id.isNotEmpty) {
        final user = authState.user;
        final isStaff = user.role == UserRole.admin || user.role == UserRole.technician;
        final isTechnician = user.role == UserRole.technician;
        
        context.read<TicketListBloc>().add(const list_event.FetchTicketsRequested(page: 0, limit: 10));
        if (isStaff) {
          context.read<TicketListBloc>().add(list_event.FetchAllTicketsRequested(
            page: 0, 
            limit: 10,
            assignedToId: isTechnician ? user.id : null,
          ));
        }
      }
    }
    
    await _fadeController.reverse();
    setState(() => _isTransitioning = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          context.read<TicketListBloc>().add(list_event.ResetTicketListState());
          context.read<TicketStatsBloc>().add(stats_event.ResetTicketStatsState());
          context.read<NotificationBloc>().add(ResetNotificationState());
          context.go(AppRoutes.login);
        }
      },
      child: Scaffold(
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                );
              },
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  state.user.role == UserRole.admin 
                      ? const AdminHomeTab() 
                      : (state.user.role == UserRole.technician ? const StaffDashboardPage() : DashboardHomeTab(
                          onSeeAll: () => _onTabTapped(1),
                        )),
                  const TicketListPage(),
                  const NotificationTab(),
                  const ProfileTab(),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  final isActive = _currentIndex == index;
                  final isNotification = index == 2;
                  
                  return GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: isActive ? 64 : 0,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isActive 
                                    ? AppColors.primary.withValues(alpha: 0.15) 
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              Icon(
                                isActive ? item['activeIcon'] as IconData : item['icon'] as IconData,
                                color: isActive 
                                    ? AppColors.primary 
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                size: 24,
                              ),
                              if (isNotification)
                                BlocBuilder<NotificationBloc, NotificationState>(
                                  builder: (context, state) {
                                    final hasUnread = state.notifications.any((n) => !n.isRead);
                                    if (!hasUnread) return const SizedBox.shrink();
                                    return Positioned(
                                      top: 2,
                                      right: 18, // offset relative to icon
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.danger,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: SizedBox(
                              height: isActive ? 18 : 0,
                              child: Opacity(
                                opacity: isActive ? 1.0 : 0.0,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    item['label'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
