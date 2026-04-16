import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.user.isEmpty) return const Scaffold();
        final user = authState.user;
        final isStaff =
            user.role == UserRole.admin || user.role == UserRole.technician;
        // Only regular users (role == user) get the FAB to create tickets
        final canCreateTicket = user.role == UserRole.user;

        String title;
        if (user.role == UserRole.admin) {
          title = 'Daftar Semua Laporan';
        } else if (user.role == UserRole.technician) {
          title = 'Tugas Perbaikan Saya';
        } else {
          title = 'Laporan Saya';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
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
                  _buildFilters(context, listState, isDark),
                  if (listState.isOffline)
                    Container(
                      width: double.infinity,
                      color: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: const Text(
                        'Sedang offline. Menampilkan data tersimpan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
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
                        isStaff ? listState.allTickets : listState.tickets,
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
          // Only show FAB for regular users (not admin/technician)
          floatingActionButton: canCreateTicket
              ? FloatingActionButton(
                  heroTag: 'ticket_list_fab',
                  onPressed: () => context.push(AppRoutes.createTicket),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilters(
      BuildContext context, TicketListState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => context
                      .read<TicketListBloc>()
                      .add(list_event.SearchTicketsRequested(val)),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket...',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    fillColor: isDark
                        ? const Color(0xFF1E1E22)
                        : const Color(0xFFF5F5F7),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildDateFilterIcon(context, state, isDark),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildQuickDateChips(context, state, isDark),
                VerticalDivider(
                    width: 20,
                    thickness: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight),
                _buildFilterChip(
                  context,
                  label: 'Semua Status',
                  isSelected:
                      state.statusFilter == TicketStatusFilter.all,
                  onTap: () => context.read<TicketListBloc>().add(
                      const list_event
                          .FilterStatusChanged(TicketStatusFilter.all)),
                  isDark: isDark,
                ),
                ...TicketStatus.values.map((status) {
                  final mappedFilter = TicketStatusFilter.values
                      .firstWhere((e) => e.name == status.name);
                  return _buildFilterChip(
                    context,
                    label: status.label,
                    isSelected: state.statusFilter == mappedFilter,
                    onTap: () => context
                        .read<TicketListBloc>()
                        .add(list_event.FilterStatusChanged(mappedFilter)),
                    isDark: isDark,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterIcon(
      BuildContext context, TicketListState state, bool isDark) {
    final hasDateFilter =
        state.startDate != null || state.endDate != null;
    return InkWell(
      onTap: () async {
        final bloc = context.read<TicketListBloc>();
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: state.startDate != null && state.endDate != null
              ? DateTimeRange(start: state.startDate!, end: state.endDate!)
              : null,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.surfaceDark,
                        onSurface: Colors.white)
                    : const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black87),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          bloc.add(
              list_event.FilterDateRangeChanged(picked.start, picked.end));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: hasDateFilter
              ? AppColors.primary.withValues(alpha: 0.1)
              : (isDark
                  ? const Color(0xFF1E1E22)
                  : const Color(0xFFF5F5F7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: hasDateFilter ? AppColors.primary : Colors.transparent),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          color: hasDateFilter
              ? AppColors.primary
              : (isDark ? Colors.white70 : Colors.black54),
        ),
      ),
    );
  }

  Widget _buildQuickDateChips(
      BuildContext context, TicketListState state, bool isDark) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isToday = state.startDate != null &&
        state.startDate == today &&
        state.endDate == null;
    bool isThisWeek = state.startDate != null &&
        state.startDate ==
            today.subtract(const Duration(days: 7)) &&
        state.endDate == null;
    bool isThisMonth = state.startDate != null &&
        state.startDate == DateTime(now.year, now.month, 1) &&
        state.endDate == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterChip(
          context,
          label: 'Hari Ini',
          isSelected: isToday,
          onTap: () => context
              .read<TicketListBloc>()
              .add(list_event.FilterDateRangeChanged(today, null)),
          isDark: isDark,
        ),
        _buildFilterChip(
          context,
          label: 'Minggu Ini',
          isSelected: isThisWeek,
          onTap: () => context.read<TicketListBloc>().add(
              list_event.FilterDateRangeChanged(
                  today.subtract(const Duration(days: 7)), null)),
          isDark: isDark,
        ),
        _buildFilterChip(
          context,
          label: 'Bulan Ini',
          isSelected: isThisMonth,
          onTap: () => context.read<TicketListBloc>().add(
              list_event.FilterDateRangeChanged(
                  DateTime(now.year, now.month, 1), null)),
          isDark: isDark,
        ),
        if (state.startDate != null || state.endDate != null)
          _buildFilterChip(
            context,
            label: 'Hapus Filter Tgl',
            isSelected: false,
            onTap: () => context.read<TicketListBloc>().add(
                const list_event.FilterDateRangeChanged(null, null)),
            isDark: isDark,
            icon: Icons.close_rounded,
          ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                    ? const Color(0xFF2A2A2E)
                    : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
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
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 140),
        ),
      );
    }

    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _fetchInitial(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
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
      child: ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        itemCount: tickets.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tickets.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
      child: Row(
        children: [
          _buildMiniStatCard(
              'Terbuka', stats.open, AppColors.statusOpen, isDark),
          const SizedBox(width: 8),
          _buildMiniStatCard('Diproses', stats.inProgress,
              AppColors.statusInProgress, isDark),
          const SizedBox(width: 8),
          _buildMiniStatCard(
              'Selesai', stats.resolved, AppColors.statusResolved, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(
      String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.black26 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? Colors.white70 : Colors.black54),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
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
                  const SizedBox(width: 8),
                  Text(
                    '#${ticket.id.substring(0, 8).toUpperCase()}',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (ticket.userName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      ticket.userName!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM').format(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Badge(
                    label: ticket.category,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    textColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _Badge(
                    label: ticket.priority.label,
                    color:
                        ticket.priority.color.withValues(alpha: 0.1),
                    textColor: ticket.priority.color,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
