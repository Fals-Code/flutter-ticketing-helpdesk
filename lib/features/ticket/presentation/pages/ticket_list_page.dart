import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/shared/widgets/empty_state_widget.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart'
    as list_event;
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/core/constants/enums.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  static const _pageSize = 10;
  final ScrollController _myTicketsScrollController = ScrollController();
  final ScrollController _allTicketsScrollController = ScrollController();
  int _myTicketsPage = 0;
  int _allTicketsPage = 0;

  @override
  void initState() {
    super.initState();
    _myTicketsScrollController
        .addListener(() => _onScroll(_myTicketsScrollController, true));
    _allTicketsScrollController
        .addListener(() => _onScroll(_allTicketsScrollController, false));
    _fetchInitial();
  }

  void _fetchInitial() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user.isEmpty) return;

    final userId = authState.user.id;
    final isTechnician = authState.user.role == UserRole.technician;

    final listBloc = context.read<TicketListBloc>();
    listBloc.add(
        const list_event.FetchTicketsRequested(page: 0, limit: _pageSize));
    listBloc.add(list_event.FetchAllTicketsRequested(
      page: 0,
      limit: _pageSize,
      assignedToId: isTechnician ? userId : null,
    ));

    listBloc.add(list_event.StartTicketListSubscription(
      userId: userId,
      assignedToId: isTechnician ? userId : null,
    ));
  }

  void _onScroll(ScrollController controller, bool isMyTickets) {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - 200) {
      final listBloc = context.read<TicketListBloc>();
      final state = listBloc.state;
      if (state.isLoading) return;

      if (isMyTickets) {
        if (!state.isLastPage) {
          _myTicketsPage++;
          listBloc.add(list_event.FetchTicketsRequested(
              page: _myTicketsPage, limit: _pageSize));
        }
      } else {
        if (!state.isLastPageAll) {
          _allTicketsPage++;
          listBloc.add(list_event.FetchAllTicketsRequested(
              page: _allTicketsPage, limit: _pageSize));
        }
      }
    }
  }

  @override
  void dispose() {
    _myTicketsScrollController.dispose();
    _allTicketsScrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final bloc = context.read<TicketListBloc>();
    final state = bloc.state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      helpText: 'Pilih Rentang Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Simpan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      // Set end date to end of the day (23:59:59) to include all tickets on that day
      final startOfDay = DateTime(picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
      final endOfDay = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      
      bloc.add(list_event.FilterDateRangeChanged(startOfDay, endOfDay));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.user.isEmpty) return const Scaffold();
        final user = authState.user;
        final isStaff =
            user.role == UserRole.admin || user.role == UserRole.technician;
        final canCreateTicket = user.role == UserRole.user;

        String title;
        if (user.role == UserRole.admin) {
          title = 'Semua Laporan';
        } else if (user.role == UserRole.technician) {
          title = 'Tugas Saya';
        } else {
          title = 'Laporan Saya';
        }

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 20),
            ),
            backgroundColor: isDark
                ? AppColors.backgroundDark
                : const Color(0xFFF7F8FA),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: () {
                  _myTicketsPage = 0;
                  _allTicketsPage = 0;
                  _fetchInitial();
                },
              ),
            ],
          ),
          body: BlocBuilder<TicketListBloc, TicketListState>(
            builder: (context, listState) {
              return Column(
                children: [
                  _buildFilterBar(context, listState, isDark),
                  if (listState.isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: const Text(
                        '📴 Mode offline – data lokal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  if (user.role == UserRole.admin)
                    BlocBuilder<TicketStatsBloc, TicketStatsState>(
                      builder: (context, statsState) {
                        return _buildAdminStatsBar(statsState, isDark);
                      },
                    ),
                  Expanded(
                    child: _buildTicketList(
                        isStaff
                            ? listState.allTickets
                            : listState.tickets,
                        listState.isLoading,
                        listState.errorMessage,
                        isStaff
                            ? _allTicketsScrollController
                            : _myTicketsScrollController,
                        isDark),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: canCreateTicket
              ? FloatingActionButton(
                  heroTag: 'ticket_list_fab',
                  onPressed: () => context.push(AppRoutes.createTicket),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterBar(
      BuildContext context, TicketListState state, bool isDark) {
    final hasDateFilter =
        state.startDate != null || state.endDate != null;

    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          // Search row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF2F2F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    onChanged: (val) => context
                        .read<TicketListBloc>()
                        .add(list_event.SearchTicketsRequested(val)),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari tiket...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildDateFilterButton(
                  context, state, isDark, hasDateFilter),
            ],
          ),
          const SizedBox(height: 10),
          // Date active indicator
          if (hasDateFilter)
            _buildActiveDateChip(context, state, isDark),
          // Status filters
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 2),
              children: [
                _buildStatusChip(
                  context,
                  label: 'Semua',
                  isSelected:
                      state.statusFilter == TicketStatusFilter.all,
                  onTap: () => context.read<TicketListBloc>().add(
                      const list_event.FilterStatusChanged(
                          TicketStatusFilter.all)),
                  isDark: isDark,
                  color: Colors.grey,
                ),
                ...TicketStatus.values.map((status) {
                  final mappedFilter = TicketStatusFilter.values
                      .firstWhere((e) => e.name == status.name);
                  return _buildStatusChip(
                    context,
                    label: status.label,
                    isSelected: state.statusFilter == mappedFilter,
                    onTap: () => context
                        .read<TicketListBloc>()
                        .add(list_event
                            .FilterStatusChanged(mappedFilter)),
                    isDark: isDark,
                    color: status.color,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark
                ? AppColors.borderDark
                : const Color(0xFFEEEEF2),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterButton(BuildContext context, TicketListState state,
      bool isDark, bool hasFilter) {
    return GestureDetector(
      onTap: () => _selectDateRange(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: hasFilter
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : const Color(0xFFF2F2F5)),
          borderRadius: BorderRadius.circular(12),
          border: hasFilter
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4))
              : null,
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          size: 18,
          color: hasFilter
              ? AppColors.primary
              : (isDark ? Colors.white54 : Colors.black45),
        ),
      ),
    );
  }

  Widget _buildActiveDateChip(
      BuildContext context, TicketListState state, bool isDark) {
    final fmt = DateFormat('d MMM');
    final label = state.startDate != null && state.endDate != null
        ? '${fmt.format(state.startDate!)} – ${fmt.format(state.endDate!)}'
        : state.startDate != null
            ? 'Mulai ${fmt.format(state.startDate!)}'
            : 'Hingga ${fmt.format(state.endDate!)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.read<TicketListBloc>().add(
                      const list_event.FilterDateRangeChanged(
                          null, null)),
                  child: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.4)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? color
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList(
    List<TicketEntity> tickets,
    bool isLoading,
    String? error,
    ScrollController controller,
    bool isDark,
  ) {
    if (tickets.isEmpty && isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: ShimmerCard(height: 130),
        ),
      );
    }

    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _fetchInitial(),
        child: ListView(
          children: const [
            SizedBox(height: 80),
            EmptyStateWidget(
              title: 'Belum Ada Tiket',
              subtitle:
                  'Buat tiket baru untuk memulai\nlayanan helpdesk.',
              icon: Icons.confirmation_number_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _myTicketsPage = 0;
        _allTicketsPage = 0;
        _fetchInitial();
      },
      color: AppColors.primary,
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: tickets.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tickets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            );
          }
          return _TicketCard(ticket: tickets[index], isDark: isDark);
        },
      ),
    );
  }

  Widget _buildAdminStatsBar(TicketStatsState state, bool isDark) {
    final stats = state.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Row(
        children: [
          _buildMiniStat(
              'Terbuka', stats.open, AppColors.statusOpen, isDark),
          const SizedBox(width: 8),
          _buildMiniStat('Diproses', stats.inProgress,
              AppColors.statusInProgress, isDark),
          const SizedBox(width: 8),
          _buildMiniStat('Selesai', stats.resolved,
              AppColors.statusResolved, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final TicketEntity ticket;
  final bool isDark;

  const _TicketCard({required this.ticket, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/tickets/${ticket.id}'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : const Color(0xFFEEEEF2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ticket.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '#${ticket.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                    if (ticket.userName != null) ...[
                      const SizedBox(width: 6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white30
                                  : Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        ticket.userName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM').format(ticket.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Badge(
                      label: ticket.category,
                      color:
                          AppColors.primary.withValues(alpha: 0.1),
                      textColor: AppColors.primary,
                    ),

                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ticket.status.color
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ticket.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
