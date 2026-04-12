import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
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
    context.read<TicketBloc>().add(const FetchTicketsRequested(page: 0, limit: _pageSize));
    context.read<TicketBloc>().add(const FetchAllTicketsRequested(page: 0, limit: _pageSize));
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
        final isStaff = authState.status == AuthStatus.authenticated && 
            (authState.user.role == UserRole.admin || authState.user.role == UserRole.technician);

        return DefaultTabController(
          length: isStaff ? 2 : 1,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(AppStrings.myTickets),
              bottom: isStaff 
                  ? const TabBar(
                      tabs: [
                        Tab(text: 'Tiket Saya'),
                        Tab(text: 'Semua Tiket'),
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
                return TabBarView(
                  physics: isStaff ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  children: [
                    _buildTicketList(state.tickets, state.isLoading, state.errorMessage, _myTicketsScrollController, isDark),
                    if (isStaff) _buildTicketList(state.allTickets, state.isLoading, state.errorMessage, _allTicketsScrollController, isDark),
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
            context.push('${AppRoutes.dashboard}/tickets/${ticket.id}'),
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



