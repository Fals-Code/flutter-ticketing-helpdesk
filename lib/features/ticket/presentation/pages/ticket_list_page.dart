import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/utils/haptic_helper.dart';
import 'package:uts/shared/widgets/empty_state_widget.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart'
    as list_event;
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/detail/ticket_detail_event.dart'
    as detail_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/core/services/toast_service.dart';
import 'package:collection/collection.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage>
    with TickerProviderStateMixin {
  static const _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isFabExpanded = true;

  // Staff-specific filter: selected assignee (admin only)
  String? _selectedAssigneeId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchInitial();
  }

  void _fetchInitial() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user.isEmpty) return;

    final userId = authState.user.id;
    final isTechnician = authState.user.role == UserRole.technician;
    final isStaff = authState.user.role == UserRole.admin || isTechnician;
    final listBloc = context.read<TicketListBloc>();

    if (isStaff) {
      // Staff: fetch all tickets (optionally filtered by assignee for technician)
      listBloc.add(list_event.FetchAllTicketsRequested(
        page: 0,
        limit: _pageSize,
        assignedToId: isTechnician ? userId : _selectedAssigneeId,
      ));
      // Fetch stats
      context.read<TicketStatsBloc>().add(
            stats_event.FetchTicketStatsRequested(
              assignedToId: isTechnician ? userId : _selectedAssigneeId,
            ),
          );
      context
          .read<TicketStatsBloc>()
          .add(const stats_event.FetchStaffUsersRequested());
    } else {
      // User: fetch own tickets
      listBloc.add(
          const list_event.FetchTicketsRequested(page: 0, limit: _pageSize));
    }

    // Real-time subscription
    listBloc.add(list_event.StartTicketListSubscription(
      userId: isStaff ? null : userId,
      assignedToId: isTechnician ? userId : null,
      isStaff: isStaff,
    ));
  }

  void _onScroll() {
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent > 0 && _scrollController.position.pixels >= maxExtent - 300) {
      final authState = context.read<AuthBloc>().state;
      if (authState.user.isEmpty) return;

      final isStaff = authState.user.role == UserRole.admin ||
          authState.user.role == UserRole.technician;
      final isTechnician = authState.user.role == UserRole.technician;
      final listBloc = context.read<TicketListBloc>();
      final state = listBloc.state;

      if (state.isLoading) return;

      if (!isStaff) {
        if (!state.isLastPage) {
          listBloc.add(list_event.FetchTicketsRequested(
              page: state.currentPage + 1, limit: _pageSize));
        }
      } else {
        if (!state.isLastPageAll) {
          listBloc.add(list_event.FetchAllTicketsRequested(
            page: state.allTicketsPage + 1,
            limit: _pageSize,
            assignedToId:
                isTechnician ? authState.user.id : _selectedAssigneeId,
          ));
        }
      }
    }

    // FAB collapse on scroll down
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabExpanded) setState(() => _isFabExpanded = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabExpanded) setState(() => _isFabExpanded = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.user.isEmpty) return const Scaffold();

        final user = authState.user;
        final isAdmin = user.role == UserRole.admin;
        final isTechnician = user.role == UserRole.technician;
        final isStaff = isAdmin || isTechnician;
        final canCreateTicket = user.role == UserRole.user;

        String title = isAdmin
            ? 'Semua Laporan'
            : (isTechnician ? 'Tugas Saya' : 'Laporan Saya');

        return BlocConsumer<TicketListBloc, TicketListState>(
          listener: (context, state) {
            if (state.successMessage != null) {
              ToastService().show(context,
                  message: state.successMessage!, type: ToastType.success);
            }
            if (state.errorMessage != null) {
              ToastService().show(context,
                  message: state.errorMessage!, type: ToastType.error);
            }
          },
          builder: (context, listState) {
            final tickets = isStaff ? listState.allTickets : listState.tickets;

            return Scaffold(
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              body: NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      title: Text(
                        title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: -0.5),
                      ),
                      backgroundColor: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      floating: true,
                      pinned: true,
                      actions: [
                        if (listState.isOffline) _OfflineBadge(isDark: isDark),
                        if (isStaff) ...[
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: 'Refresh',
                            onPressed: () {
                              HapticHelper.light();
                              _fetchInitial();
                            },
                          ),
                        ],
                        const SizedBox(width: 4),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(108),
                        child: _buildFilterBar(context, listState, isDark,
                            isStaff, isAdmin, isTechnician),
                      ),
                    ),
                  ];
                },
                body: RefreshIndicator(
                  onRefresh: () async => _fetchInitial(),
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      // Stats bar for both admin and technician
                      if (isStaff)
                        BlocBuilder<TicketStatsBloc, TicketStatsState>(
                          builder: (context, statsState) => _buildStaffStatsBar(
                              statsState, isDark, isTechnician),
                        ),
                      // Unassigned tickets warning for admin
                      if (isAdmin)
                        _UnassignedBanner(
                          tickets: tickets,
                          isDark: isDark,
                          onTap: () {
                            // Filter to show only open/unassigned tickets
                            context.read<TicketListBloc>().add(
                                  const list_event.FilterStatusChanged(
                                      TicketStatusFilter.open),
                                );
                          },
                        ),
                      Expanded(
                        child: _buildTicketList(context, tickets, listState,
                            isDark, isStaff, isAdmin),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: canCreateTicket
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      height: 56,
                      child: FloatingActionButton.extended(
                        heroTag: 'ticket_list_fab',
                        onPressed: () => context.push(AppRoutes.createTicket),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        isExtended: _isFabExpanded,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Buat Tiket',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(
    BuildContext context,
    TicketListState state,
    bool isDark,
    bool isStaff,
    bool isAdmin,
    bool isTechnician,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchController,
                  isDark: isDark,
                  onChanged: (val) {
                    context
                        .read<TicketListBloc>()
                        .add(list_event.SearchTicketsRequested(val));
                    setState(() {});
                  },
                  onClear: () {
                    _searchController.clear();
                    context
                        .read<TicketListBloc>()
                        .add(const list_event.SearchTicketsRequested(''));
                    setState(() {});
                  },
                ),
              ),
              if (isStaff && isAdmin) ...[
                const SizedBox(width: 8),
                _AssigneeFilterButton(
                  isDark: isDark,
                  currentAssigneeId: _selectedAssigneeId,
                  staffUsers: context.read<TicketStatsBloc>().state.staffUsers,
                  onChanged: (assigneeId) {
                    setState(() {
                      _selectedAssigneeId = assigneeId;
                    });
                    context.read<TicketListBloc>().add(
                          list_event.FetchAllTicketsRequested(
                            page: 0,
                            limit: _pageSize,
                            assignedToId: assigneeId,
                          ),
                        );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (isTechnician && state.assignedToId != null)
            _ActiveAssigneeChip(
              isDark: isDark,
              onClear: () {
                context.read<TicketListBloc>().add(
                      list_event.FetchAllTicketsRequested(
                        page: 0,
                        limit: _pageSize,
                        assignedToId: null,
                      ),
                    );
                setState(() {
                  _selectedAssigneeId = null;
                });
              },
            ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _StatusChip(
                  label: 'Semua',
                  isSelected: state.statusFilter == TicketStatusFilter.all,
                  color: isDark ? Colors.white70 : Colors.black87,
                  isDark: isDark,
                  onTap: () => context.read<TicketListBloc>().add(
                        const list_event.FilterStatusChanged(
                            TicketStatusFilter.all),
                      ),
                ),
                // For staff, show more relevant statuses first
                if (isStaff) ...[
                  _StatusChip(
                    label: 'Terbuka',
                    isSelected: state.statusFilter == TicketStatusFilter.open,
                    color: AppColors.statusOpen,
                    isDark: isDark,
                    badge: _countByStatus(
                        state.allTickets, TicketStatusFilter.open),
                    onTap: () => context.read<TicketListBloc>().add(
                          const list_event.FilterStatusChanged(
                              TicketStatusFilter.open),
                        ),
                  ),
                  _StatusChip(
                    label: 'Diproses',
                    isSelected:
                        state.statusFilter == TicketStatusFilter.inProgress,
                    color: AppColors.statusInProgress,
                    isDark: isDark,
                    badge: _countByStatus(
                        state.allTickets, TicketStatusFilter.inProgress),
                    onTap: () => context.read<TicketListBloc>().add(
                          const list_event.FilterStatusChanged(
                              TicketStatusFilter.inProgress),
                        ),
                  ),
                  _StatusChip(
                    label: 'Selesai',
                    isSelected:
                        state.statusFilter == TicketStatusFilter.resolved,
                    color: AppColors.statusResolved,
                    isDark: isDark,
                    onTap: () => context.read<TicketListBloc>().add(
                          const list_event.FilterStatusChanged(
                              TicketStatusFilter.resolved),
                        ),
                  ),
                  _StatusChip(
                    label: 'Ditutup',
                    isSelected: state.statusFilter == TicketStatusFilter.closed,
                    color: isDark ? Colors.white38 : Colors.black38,
                    isDark: isDark,
                    onTap: () => context.read<TicketListBloc>().add(
                          const list_event.FilterStatusChanged(
                              TicketStatusFilter.closed),
                        ),
                  ),
                ] else
                  ...TicketStatus.values.map((status) {
                    final mappedFilter = TicketStatusFilter.values
                        .firstWhere((e) => e.name == status.name);
                    return _StatusChip(
                      label: status.label,
                      isSelected: state.statusFilter == mappedFilter,
                      color: status.color,
                      isDark: isDark,
                      onTap: () => context.read<TicketListBloc>().add(
                            list_event.FilterStatusChanged(mappedFilter),
                          ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  int _countByStatus(List<TicketEntity> tickets, TicketStatusFilter filter) {
    return tickets.where((t) {
      if (filter == TicketStatusFilter.open) {
        return t.status == TicketStatus.open;
      }
      if (filter == TicketStatusFilter.inProgress) {
        return t.status == TicketStatus.inProgress;
      }
      return false;
    }).length;
  }

// ── Stats Bar ──────────────────────────────────────────────────────────────

  Widget _buildStaffStatsBar(
      TicketStatsState state, bool isDark, bool isTechnician) {
    if (state.isLoading && state.stats.total == 0) {
      return const SizedBox.shrink();
    }
    final stats = state.stats;
    final bgColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStatItem(
              label: 'Total',
              value: stats.total,
              color: AppColors.primary,
              icon: Icons.confirmation_number_outlined,
              isDark: isDark,
            ),
          ),
          _VerticalDivider(isDark: isDark),
          Expanded(
            child: _MiniStatItem(
              label: 'Terbuka',
              value: stats.open,
              color: AppColors.statusOpen,
              icon: Icons.folder_open_outlined,
              isDark: isDark,
            ),
          ),
          _VerticalDivider(isDark: isDark),
          Expanded(
            child: _MiniStatItem(
              label: 'Diproses',
              value: stats.inProgress,
              color: AppColors.statusInProgress,
              icon: Icons.sync_rounded,
              isDark: isDark,
            ),
          ),
          _VerticalDivider(isDark: isDark),
          Expanded(
            child: _MiniStatItem(
              label: 'Selesai',
              value: stats.resolved,
              color: AppColors.statusResolved,
              icon: Icons.check_circle_outline,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

// ── Ticket List ────────────────────────────────────────────────────────────

  Widget _buildTicketList(BuildContext context, List<TicketEntity> tickets,
      TicketListState state, bool isDark, bool isStaff, bool isAdmin) {
    if (state.isLoading && tickets.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => _TicketSkeletonCard(isDark: isDark),
      );
    }

    if (tickets.isEmpty) {
      if (state.errorMessage != null) {
        return EmptyStateWidget.error(
          subtitle: state.errorMessage!,
          onAction: _fetchInitial,
          actionLabel: 'Coba Lagi',
        );
      }

      if (_searchController.text.isNotEmpty) {
        return EmptyStateWidget.emptySearch(
          actionLabel: 'Hapus Pencarian',
          onAction: () {
            _searchController.clear();
            context
                .read<TicketListBloc>()
                .add(const list_event.SearchTicketsRequested(''));
          },
        );
      }

      if (state.statusFilter != TicketStatusFilter.all ||
          state.startDate != null) {
        return EmptyStateWidget.emptySearch(
          title: 'Filter Kosong',
          subtitle: 'Tidak ada tiket yang sesuai dengan filter yang dipilih.',
          actionLabel: 'Reset Filter',
          onAction: () {
            context.read<TicketListBloc>().add(
                const list_event.FilterStatusChanged(TicketStatusFilter.all));
            context
                .read<TicketListBloc>()
                .add(const list_event.FilterDateRangeChanged(null, null));
          },
        );
      }

      // Role-specific empty state
      if (isStaff) {
        return _StaffEmptyState(isDark: isDark);
      }

      return EmptyStateWidget.emptyTickets(
        actionLabel: 'Buat Tiket Sekarang',
        onAction: () => context.push(AppRoutes.createTicket),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tickets.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == tickets.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _TicketCard(
          ticket: tickets[index],
          isDark: isDark,
          isStaff: isStaff,
          isAdmin: isAdmin,
          staffUsers: context.read<TicketStatsBloc>().state.staffUsers,
          onQuickAction: (ticket, newStatus) =>
              _handleQuickAction(context, ticket, newStatus),
          onRefreshList: _fetchInitial,
        );
      },
    );
  }

  void _handleQuickAction(
      BuildContext context, TicketEntity ticket, TicketStatus newStatus) {
    HapticHelper.medium();
    context.read<TicketDetailBloc>().add(
          detail_event.UpdateTicketStatusRequested(
            ticketId: ticket.id,
            status: newStatus,
          ),
        );
    // Refresh the list after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fetchInitial();
    });
  }
}

class _TicketCard extends StatefulWidget {
  final TicketEntity ticket;
  final bool isDark;
  final bool isStaff;
  final bool isAdmin;
  final List<AuthUser> staffUsers;
  final Function(TicketEntity, TicketStatus) onQuickAction;
  final VoidCallback onRefreshList;

  const _TicketCard({
    required this.ticket,
    required this.isDark,
    required this.isStaff,
    required this.isAdmin,
    required this.staffUsers,
    required this.onQuickAction,
    required this.onRefreshList,
  });

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool get isDark => widget.isDark;
  TicketEntity get ticket => widget.ticket;
  List<AuthUser> get staffUsers => widget.staffUsers;

  void _handleQuickAction(
      BuildContext context, TicketEntity ticket, TicketStatus newStatus) {
    HapticHelper.medium();
    context.read<TicketDetailBloc>().add(
          detail_event.UpdateTicketStatusRequested(
            ticketId: ticket.id,
            status: newStatus,
          ),
        );
    // Refresh the list after a short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onRefreshList();
    });
  }

  void _showAssignTechnicianSheet(
      BuildContext context, TicketEntity ticket, List<AuthUser> staffUsers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Tugaskan Teknisi',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ...staffUsers.map((user) => ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<TicketDetailBloc>().add(
                            detail_event.AssignTicketRequested(
                              ticketId: ticket.id,
                              technicianId: user.id,
                            ),
                          );
                      // Refresh the list after a short delay
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (mounted) widget.onRefreshList();
                      });
                    },
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.fullName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                    title: Text(user.fullName ?? user.email),
                    trailing: ticket.assignedTo == user.id
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTechnician =
        context.read<AuthBloc>().state.user.role == UserRole.technician;
    final isAssignedToMe = isTechnician &&
        ticket.assignedTo == context.read<AuthBloc>().state.user.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.ticketDetail.replaceAll(':id', ticket.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ticket.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: ticket.status.label,
                    color: ticket.status.color,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ticket.category} • ${DateFormat('dd MMM yyyy, HH:mm').format(ticket.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (widget.isStaff)
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 16,
                        color: isDark ? Colors.white54 : Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ticket.assignedTo != null
                            ? (staffUsers
                                    .firstWhereOrNull(
                                        (u) => u.id == ticket.assignedTo)
                                    ?.fullName ??
                                'Tidak Dikenal')
                            : 'Belum Ditugaskan',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isAdmin && ticket.assignedTo == null)
                      _QuickActionButton(
                        isDark: isDark,
                        icon: Icons.assignment_ind_outlined,
                        label: 'Tugaskan',
                        onTap: () => _showAssignTechnicianSheet(
                            context, ticket, staffUsers),
                      ),
                  ],
                ),
              if (widget.isStaff && ticket.status == TicketStatus.open)
                const SizedBox(height: 8),
              if (widget.isStaff && ticket.status == TicketStatus.open)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _QuickActionButton(
                      isDark: isDark,
                      icon: Icons.play_arrow_rounded,
                      label: 'Proses',
                      onTap: () => _handleQuickAction(
                          context, ticket, TicketStatus.inProgress),
                    ),
                  ],
                ),
              if (widget.isStaff && ticket.status == TicketStatus.inProgress)
                const SizedBox(height: 8),
              if (widget.isStaff && ticket.status == TicketStatus.inProgress)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _QuickActionButton(
                      isDark: isDark,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Selesai',
                      onTap: () => _handleQuickAction(
                          context, ticket, TicketStatus.resolved),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssigneeFilterButton extends StatelessWidget {
  final bool isDark;
  final String? currentAssigneeId;
  final List<AuthUser> staffUsers;
  final ValueChanged<String?> onChanged;

  const _AssigneeFilterButton({
    required this.isDark,
    required this.currentAssigneeId,
    required this.staffUsers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFilter = currentAssigneeId != null;

    return GestureDetector(
      onTap: () => _showSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasFilter
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasFilter
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Icon(
          Icons.person_outline_rounded,
          size: 20,
          color: hasFilter
              ? AppColors.primary
              : (isDark ? Colors.white54 : Colors.black54),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Filter Teknisi',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              ListTile(
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null);
                },
                title: const Text('Semua Teknisi'),
                trailing: currentAssigneeId == null
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              ...staffUsers.map((user) => ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      onChanged(user.id);
                    },
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        user.fullName?.substring(0, 1).toUpperCase() ??
                            user.email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                    ),
                    title: Text(user.fullName ?? user.email),
                    trailing: currentAssigneeId == user.id
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Badge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  final bool isDark;
  const _OfflineBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 14, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                color: isDark
                    ? AppColors.warning
                    : AppColors.warning.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
            fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Cari tiket...',
          hintStyle: TextStyle(
              fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: isDark ? Colors.white54 : Colors.black54),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: isDark ? Colors.white54 : Colors.black54,
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _ActiveAssigneeChip extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;

  const _ActiveAssigneeChip({
    required this.isDark,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Ditugaskan ke Saya',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final int badge;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _MiniStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutExpo,
              builder: (context, val, _) => Text(
                val.toInt().toString(),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1),
    );
  }
}

class _UnassignedBanner extends StatelessWidget {
  final List<TicketEntity> tickets;
  final bool isDark;
  final VoidCallback onTap;

  const _UnassignedBanner({
    required this.tickets,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unassigned = tickets
        .where((t) =>
            t.assignedTo == null &&
            (t.status == TicketStatus.open ||
                t.status == TicketStatus.inProgress))
        .length;

    if (unassigned == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.assignment_late_rounded,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$unassigned tiket belum ada teknisi yang ditugaskan',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}

class _StaffEmptyState extends StatelessWidget {
  final bool isDark;
  const _StaffEmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            Text(
              'Semua Tiket Beres!',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada tiket yang perlu ditangani saat ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────

class _TicketSkeletonCard extends StatelessWidget {
  final bool isDark;
  const _TicketSkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: base, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(width: 60, height: 12, color: base),
              const Spacer(),
              Container(width: 50, height: 12, color: base),
            ],
          ),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 16, color: base),
          const SizedBox(height: 8),
          Container(width: 200, height: 12, color: base),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(6))),
              const Spacer(),
              Container(
                  width: 70,
                  height: 24,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(100))),
            ],
          ),
        ],
      ),
    );
  }
}
