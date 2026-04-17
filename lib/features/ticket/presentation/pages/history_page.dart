import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart' as stats_state;
import 'package:uts/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:go_router/go_router.dart';
import 'package:uts/core/router/app_router.dart';
import 'package:uts/core/utils/haptic_helper.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() {
    final authState = context.read<AuthBloc>().state;
    String? changedBy;
    if (authState.user.role != UserRole.admin) {
      changedBy = authState.user.id;
    }

    context.read<TicketStatsBloc>().add(stats_event.FetchAllHistoryRequested(
      changedBy: changedBy,
      startDate: _startDate,
      endDate: _endDate,
    ));
  }

  Future<void> _selectDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surfaceDark)
                : const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticHelper.medium();
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Riwayat Aktivitas',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month_rounded, color: _startDate != null ? AppColors.primary : null),
            onPressed: _selectDateRange,
          ),
          if (_startDate != null)
            IconButton(
              icon: const Icon(Icons.filter_list_off_rounded),
              onPressed: () {
                HapticHelper.light();
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _fetchHistory();
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
        builder: (context, state) {
          if (state.isLoading && state.history.isEmpty) {
            return _buildSkeleton(isDark);
          }

          if (state.history.isEmpty) {
            return _buildEmptyState(isDark);
          }

          final grouped = _groupHistoryByDate(state.history.cast());

          return RefreshIndicator(
            onRefresh: () async => _fetchHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStickyHeader(group.dateStr, isDark),
                    const SizedBox(height: 16),
                    ...group.items.asMap().entries.map((entry) {
                      final itemIndex = entry.key;
                      final historyItem = entry.value;
                      final isLast = itemIndex == group.items.length - 1;
                      return _buildTimelineItem(historyItem, isLast, isDark);
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white24 : Colors.black26,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTimelineItem(dynamic item, bool isLastGroupItem, bool isDark) {
    final statusColor = _getStatusColor(item.newStatus);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Axis
          Column(
            children: [
              Container(
                width: 12, height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2.5),
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.changedByName ?? 'Sistem',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormat('HH:mm').format(item.createdAt)}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(item),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      HapticHelper.light();
                      context.push(AppRoutes.ticketDetail.replaceAll(':id', item.ticketId));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '#${item.ticketId.substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 12, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.history_toggle_off_rounded, size: 60, color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum Ada Jejak',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Seluruh riwayat aktivitas akan muncul di sini.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<_HistoryGroup> _groupHistoryByDate(List<dynamic> history) {
    final Map<String, List<dynamic>> map = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in history) {
      final date = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      String key;
      if (date == today) {
        key = 'Hari Ini';
      } else if (date == yesterday) {
        key = 'Kemarin';
      } else {
        key = DateFormat('dd MMM yyyy').format(item.createdAt);
      }

      if (!map.containsKey(key)) map[key] = [];
      map[key]!.add(item);
    }

    return map.entries.map((e) => _HistoryGroup(e.key, e.value)).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return AppColors.primary;
      case 'in_progress': return AppColors.statusInProgress;
      case 'resolved': return AppColors.statusResolved;
      case 'closed': return Colors.grey;
      default: return AppColors.primary;
    }
  }

  String _getDescription(item) {
    if (item.oldStatus == null) return 'Membuat tiket baru dengan prioritas ${item.priority?.toUpperCase() ?? 'MEDIUM'}.';
    return 'Mengubah status tiket dari ${item.oldStatus!.toUpperCase()} menjadi ${item.newStatus.toUpperCase()}.';
  }
}

class _HistoryGroup {
  final String dateStr;
  final List<dynamic> items;
  _HistoryGroup(this.dateStr, this.items);
}
