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
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
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
    _myTicketsScrollController.addListener(() => _onScroll(_myTicketsScrollController, true));
    _allTicketsScrollController.addListener(() => _onScroll(_allTicketsScrollController, false));
    _fetchInitial();
  }

  void _fetchInitial() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user.isEmpty) return;
    
    final userId = authState.user.id;
    final isStaff = authState.user.role == UserRole.admin || authState.user.role == UserRole.technician;
    final isTechnician = authState.user.role == UserRole.technician;

    context.read<TicketBloc>().add(const FetchTicketsRequested(page: 0, limit: _pageSize));
    context.read<TicketBloc>().add(FetchAllTicketsRequested(
      page: 0, 
      limit: _pageSize,
      assignedToId: isTechnician ? userId : null,
    ));
    
    context.read<TicketBloc>().add(StartTicketSubscription(
      userId: userId, 
      isStaff: isStaff,
      isTechnician: isTechnician,
    ));
  }

  void _onScroll(ScrollController controller, bool isMyTickets) {
    if (controller.position.pixels >= controller.position.maxScrollExtent - 200) {
      final state = context.read<TicketBloc>().state;
      if (state.isLoading) return;

      if (isMyTickets) {
        if (!state.isLastPage) {
          _myTicketsPage++;
          context.read<TicketBloc>().add(FetchTicketsRequested(page: _myTicketsPage, limit: _pageSize));
        }
      } else {
        if (!state.isLastPageAll) {
          _allTicketsPage++;
          context.read<TicketBloc>().add(FetchAllTicketsRequested(page: _allTicketsPage, limit: _pageSize));
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
        final isStaff = user.role == UserRole.admin || user.role == UserRole.technician;
        final isTechnician = user.role == UserRole.technician;
        
        String title;
        if (user.role == UserRole.admin) {
          title = 'Daftar Semua Laporan';
        } else if (user.role == UserRole.technician) {
          title = 'Tugas Perbaikan Saya';
        } else {
          title = 'Laporan Saya';
        }

        return DefaultTabController(
          length: isStaff ? 2 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              bottom: isStaff 
                  ? TabBar(
                      tabs: [
                        const Tab(text: 'Tiket Saya'),
                        Tab(text: isTechnician ? 'Tugas Saya' : 'Semua Tiket'),
                      ],
                    )
                  : null,
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
            body: BlocBuilder<TicketBloc, TicketState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildFilters(context, state, isDark),
                    if (user.role == UserRole.admin) _buildAdminStatsBar(state, isDark),
                    Expanded(
                      child: TabBarView(
                        physics: isStaff ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                        children: [
                          _buildTicketList(state.tickets, state.isLoading, state.errorMessage, _myTicketsScrollController, isDark),
                          if (isStaff) _buildTicketList(state.allTickets, state.isLoading, state.errorMessage, _allTicketsScrollController, isDark),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'ticket_list_fab',
              onPressed: () => context.push(AppRoutes.createTicket),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, TicketState state, bool isDark) {
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
          TextField(
            onChanged: (val) => context.read<TicketBloc>().add(SearchQueryChanged(val)),
            decoration: InputDecoration(
              hintText: 'Cari tiket...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              fillColor: isDark ? const Color(0xFF1E1E22) : const Color(0xFFF5F5F7),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  context,
                  label: 'Semua',
                  isSelected: state.statusFilter == TicketStatusFilter.all,
                  onTap: () => context.read<TicketBloc>().add(const FilterStatusChanged(null)),
                  isDark: isDark,
                ),
                ...TicketStatus.values.map((status) => _buildFilterChip(
                      context,
                      label: status.label,
                      isSelected: state.statusFilter.name == status.name,
                      onTap: () => context.read<TicketBloc>().add(FilterStatusChanged(status)),
                      isDark: isDark,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
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
                : (isDark ? const Color(0xFF2A2A2E) : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
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
      return const Center(child: LoadingWidget());
    }

    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _fetchInitial(),
        child: ListView(
          children: const [
            SizedBox(height: 100),
            EmptyStateWidget(
              title: 'Belum Ada Tiket',
              subtitle: 'Buat tiket baru untuk memulai\nlayanan helpdesk.',
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

  Widget _buildAdminStatsBar(TicketState state, bool isDark) {
    final stats = state.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
      child: Row(
        children: [
          _buildMiniStatCard('Terbuka', stats.open, AppColors.statusOpen, isDark),
          const SizedBox(width: 8),
          _buildMiniStatCard('Diproses', stats.inProgress, AppColors.statusInProgress, isDark),
          const SizedBox(width: 8),
          _buildMiniStatCard('Selesai', stats.resolved, AppColors.statusResolved, isDark),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
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
        onTap: () =>
            context.push('/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
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
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
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
                    color: ticket.priority.color.withValues(alpha: 0.1),
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


