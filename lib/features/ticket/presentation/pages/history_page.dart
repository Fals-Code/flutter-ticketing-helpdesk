import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_event.dart';
import 'package:uts/features/ticket/presentation/bloc/ticket_state.dart';
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:go_router/go_router.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    final authState = context.read<AuthBloc>().state;
    if (authState.user.role == UserRole.admin) {
      // Admins see everything
      context.read<TicketBloc>().add(const FetchTicketActivitiesRequested());
    } else {
      // Others see their own actions
      context.read<TicketBloc>().add(FetchTicketActivitiesRequested(changedBy: authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _fetchHistory(),
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state.isLoading && state.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Belum ada riwayat aktivitas.'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            itemCount: state.history.length,
            itemBuilder: (context, index) {
              final item = state.history[index];
              final isLast = index == state.history.length - 1;
              
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Axis
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.newStatus),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _getStatusColor(item.newStatus).withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: isDark ? const Color(0xFF2A2A2E) : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Content Card
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.changedByName ?? 'Sistem',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  Text(
                                    DateFormat('dd MMM, HH:mm').format(item.createdAt),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getDescription(item),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => context.push('/dashboard/tickets/${item.ticketId}'),
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TIKET #${item.ticketId.substring(0, 8).toUpperCase()}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'resolved':
        return AppColors.statusResolved;
      case 'closed':
        return Colors.grey;
      default:
        return AppColors.primary;
    }
  }

  String _getDescription(item) {
    if (item.oldStatus == null) return 'Membuat tiket dengan status ${item.newStatus.toUpperCase()}';
    return 'Mengubah status dari ${item.oldStatus!.toUpperCase()} ke ${item.newStatus.toUpperCase()}';
  }
}
