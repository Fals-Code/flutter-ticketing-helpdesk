import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/shared/widgets/empty_state_widget.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/list/ticket_list_event.dart' as list_event;
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

class _TicketListPageState extends State<TicketListPage> with TickerProviderStateMixin {
  static const _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isFabExpanded = true;
  int _currentPage = 0;

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
    final listBloc = context.read<TicketListBloc>();

    listBloc.add(const list_event.FetchTicketsRequested(page: 0, limit: _pageSize));
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

  void _onScroll() {
    if (_scrollController.position.maxScrollExtent > 0 &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final authState = context.read<AuthBloc>().state;
      if (authState.user.isEmpty) return;
      
      final isStaff = authState.user.role == UserRole.admin || authState.user.role == UserRole.technician;
      
      final listBloc = context.read<TicketListBloc>();
      final state = listBloc.state;
      if (state.isLoading) return;

      if (!isStaff) {
        if (!state.isLastPage) {
          listBloc.add(list_event.FetchTicketsRequested(page: state.currentPage + 1, limit: _pageSize));
        }
      } else {
        if (!state.isLastPageAll) {
          listBloc.add(list_event.FetchAllTicketsRequested(page: state.allTicketsPage + 1, limit: _pageSize));
        }
      }
    }

    // Extended FAB logic
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabExpanded) setState(() => _isFabExpanded = false);
    } else {
      if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isFabExpanded) setState(() => _isFabExpanded = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final startOfDay = DateTime(picked.start.year, picked.start.month, picked.start.day);
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
        final isStaff = user.role == UserRole.admin || user.role == UserRole.technician;
        final canCreateTicket = user.role == UserRole.user;

        String title = isStaff ? (user.role == UserRole.admin ? 'Semua Laporan' : 'Tugas Saya') : 'Laporan Saya';

        return Scaffold(
          backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          body: BlocBuilder<TicketListBloc, TicketListState>(
            builder: (context, listState) {
              final tickets = isStaff ? listState.allTickets : listState.tickets;
              
              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.5),
                      ),
                      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      floating: true,
                      pinned: true,
                      actions: [
                        if (listState.isOffline)
                          Center(
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
                                  const Icon(Icons.cloud_off_rounded, size: 14, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: isDark ? AppColors.warning : AppColors.warning.withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      bottom: PreferredSize(
                        preferredSize: Size.fromHeight(listState.startDate != null ? 104 : 76),
                        child: _buildFilterBar(context, listState, isDark),
                      ),
                    ),
                  ];
                },
                body: RefreshIndicator(
                  onRefresh: () async {
                    _fetchInitial();
                  },
                  color: AppColors.primary,
                  child: Column(
                    children: [
                      if (user.role == UserRole.admin)
                        BlocBuilder<TicketStatsBloc, TicketStatsState>(
                          builder: (context, statsState) => _buildAdminStatsBar(statsState, isDark),
                        ),
                      Expanded(
                        child: _buildTicketList(tickets, listState, isDark),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                    label: const Text('Buat Tiket', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, TicketListState state, bool isDark) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      context.read<TicketListBloc>().add(list_event.SearchTicketsRequested(val));
                      setState((){});
                    },
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan subjek atau ID...',
                      hintStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white54 : Colors.black54),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: isDark ? Colors.white54 : Colors.black54,
                              onPressed: () {
                                _searchController.clear();
                                context.read<TicketListBloc>().add(const list_event.SearchTicketsRequested(''));
                                setState((){});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _selectDateRange(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasDateFilter ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hasDateFilter ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: hasDateFilter ? AppColors.primary : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasDateFilter) _buildActiveDateChip(context, state, isDark),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildStatusChip(
                  context,
                  label: 'Semua',
                  isSelected: state.statusFilter == TicketStatusFilter.all,
                  onTap: () => context.read<TicketListBloc>().add(const list_event.FilterStatusChanged(TicketStatusFilter.all)),
                  isDark: isDark,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                ...TicketStatus.values.map((status) {
                  final mappedFilter = TicketStatusFilter.values.firstWhere((e) => e.name == status.name);
                  return _buildStatusChip(
                    context,
                    label: status.label,
                    isSelected: state.statusFilter == mappedFilter,
                    onTap: () => context.read<TicketListBloc>().add(list_event.FilterStatusChanged(mappedFilter)),
                    isDark: isDark,
                    color: status.color,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActiveDateChip(BuildContext context, TicketListState state, bool isDark) {
    final fmt = DateFormat('d MMM yyyy');
    final label = state.startDate != null && state.endDate != null
        ? '${fmt.format(state.startDate!)} - ${fmt.format(state.endDate!)}'
        : 'Rentang Waktu';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => context.read<TicketListBloc>().add(const list_event.FilterDateRangeChanged(null, null)),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
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
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isSelected ? color : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList(List<TicketEntity> tickets, TicketListState state, bool isDark) {
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
          message: state.errorMessage!,
          onAction: () => _fetchInitial(),
          actionLabel: 'Coba Lagi',
        );
      }

      if (_searchController.text.isNotEmpty) {
        return EmptyStateWidget.emptySearch(
          actionLabel: 'Hapus Pencarian',
          onAction: () {
            _searchController.clear();
            context.read<TicketListBloc>().add(const list_event.SearchTicketsRequested(''));
          },
        );
      }

      if (state.statusFilter != TicketStatusFilter.all || state.startDate != null) {
        return EmptyStateWidget.emptySearch(
          title: 'Filter Kosong',
          subtitle: 'Tidak ada tiket yang sesuai dengan filter yang dipilih.',
          actionLabel: 'Reset Filter',
          onAction: () {
            context.read<TicketListBloc>().add(const list_event.FilterStatusChanged(TicketStatusFilter.all));
            context.read<TicketListBloc>().add(const list_event.FilterDateRangeChanged(null, null));
          },
        );
      }

      final isUser = context.read<AuthBloc>().state.user.role == UserRole.user;
      return EmptyStateWidget.emptyTickets(
        actionLabel: isUser ? 'Buat Tiket Sekarang' : null,
        onAction: isUser ? () => context.push(AppRoutes.createTicket) : null,
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
        return _TicketCard(ticket: tickets[index], isDark: isDark);
      },
    );
  }

  Widget _buildAdminStatsBar(TicketStatsState state, bool isDark) {
    if (state.isLoading && state.stats.total == 0) return const SizedBox.shrink();
    final stats = state.stats;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMiniStat('Terbuka', stats.open, AppColors.statusOpen, isDark),
          _buildMiniStat('Diproses', stats.inProgress, AppColors.statusInProgress, isDark),
          _buildMiniStat('Selesai', stats.resolved, AppColors.statusResolved, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int value, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54)),
      ],
    );
  }
}

class _TicketSkeletonCard extends StatelessWidget {
  final bool isDark;
  const _TicketSkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(width: 60, height: 12, color: baseColor),
              const Spacer(),
              Container(width: 50, height: 12, color: baseColor),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Container(width: double.infinity, height: 16, color: baseColor),
          const SizedBox(height: 8),
          // Desc
          Container(width: 200, height: 12, color: baseColor),
          const SizedBox(height: 4),
          Container(width: 150, height: 12, color: baseColor),
          const SizedBox(height: 16),
          // Bottom
          Row(
            children: [
              Container(width: 60, height: 20, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 8),
              Container(width: 60, height: 20, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(6))),
              const Spacer(),
              Container(width: 70, height: 24, decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(100))),
            ],
          )
        ],
      ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final TicketEntity ticket;
  final bool isDark;

  const _TicketCard({required this.ticket, required this.isDark});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(widget.ticket.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          context.push('/tickets/${widget.ticket.id}');
          return false; // Never actually dismiss the widget
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Lihat Detail', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: GestureDetector(
            onTapDown: (_) => _animController.forward(),
            onTapUp: (_) {
              _animController.reverse();
              context.push('/tickets/${widget.ticket.id}');
            },
            onTapCancel: () => _animController.reverse(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.ticket.status.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(
                        '#${widget.ticket.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.firaCode(fontSize: 11, color: widget.isDark ? Colors.white38 : Colors.black38),
                      ),
                      if (widget.ticket.userName != null) ...[
                        const SizedBox(width: 6),
                        Container(width: 3, height: 3, decoration: BoxDecoration(color: widget.isDark ? Colors.white30 : Colors.black26, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(widget.ticket.userName!, style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white60 : Colors.black54)),
                      ],
                      const Spacer(),
                      Text(
                        DateFormat('dd MMM').format(widget.ticket.createdAt),
                        style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white54 : Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.ticket.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.ticket.description,
                    style: TextStyle(fontSize: 13, color: widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Badge(
                        label: widget.ticket.category,
                        color: widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        textColor: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.ticket.status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          widget.ticket.status.label,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.ticket.status.color),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  const _Badge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}
