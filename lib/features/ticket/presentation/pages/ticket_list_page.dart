import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/constants/app_strings.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/shared/widgets/loading_widget.dart';
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
      margin: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('${AppRoutes.dashboard}/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ticket.status.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '#${ticket.id.substring(0, 8).toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                ticket.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                ticket.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    ticket.category,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.flag_outlined, size: 14, color: ticket.priority.color),
                  const SizedBox(width: 4),
                  Text(
                    ticket.priority.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ticket.priority.color,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${ticket.createdAt.day}/${ticket.createdAt.month}/${ticket.createdAt.year}',
                    style: Theme.of(context).textTheme.labelSmall,
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


