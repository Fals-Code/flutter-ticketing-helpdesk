import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/services/report_export_service.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/admin_event.dart';
import 'package:uts/features/admin/presentation/bloc/admin_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart'
    as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart'
    as stats_state;
import 'package:uts/shared/widgets/loading_widget.dart';
import 'package:uts/features/admin/domain/entities/admin_report_entity.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;
  final _exportService = ReportExportService();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<TicketStatsBloc>().add(stats_event.FetchTicketStatsRequested(
          startDate: _startDate,
          endDate: _endDate,
        ));
    context.read<AdminBloc>().add(FetchAdminReportsRequested(
          startDate: _startDate,
          endDate: _endDate,
        ));
  }

  Future<void> _exportReport(AdminReport report,
      {required bool asPdf}) async {
    setState(() => _isExporting = true);
    try {
      if (asPdf) {
        await _exportService.exportToPdf(report,
            startDate: _startDate, endDate: _endDate);
      } else {
        await _exportService.exportToCsv(report,
            startDate: _startDate, endDate: _endDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
      helpText: 'Pilih Rentang Laporan',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
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
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Laporan & Analitik',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        backgroundColor:
            isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocBuilder<AdminBloc, AdminState>(
            builder: (context, adminState) {
              final report = adminState.report;
              if (_isExporting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary)),
                  ),
                );
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.download_rounded, size: 20),
                tooltip: 'Export Laporan',
                enabled: report != null,
                onSelected: (value) {
                  if (report == null) return;
                  _exportReport(report, asPdf: value == 'pdf');
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(children: [
                      Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text('Export PDF', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(children: [
                      Icon(Icons.table_chart_rounded,
                          color: Colors.green, size: 18),
                      SizedBox(width: 10),
                      Text('Export CSV', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, adminState) {
          return BlocBuilder<TicketStatsBloc,
              stats_state.TicketStatsState>(
            builder: (context, statsState) {
              if (adminState.status == AdminStatus.loading &&
                  adminState.report == null) {
                return const Center(child: LoadingWidget());
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                color: AppColors.primary,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Filter Card
                      _buildDateFilterCard(isDark),
                      const SizedBox(height: 24),

                      // Stats Grid
                      _buildSectionTitle(
                          'Ringkasan Tiket', isDark),
                      const SizedBox(height: 14),
                      _buildStatsGrid(statsState),
                      const SizedBox(height: 28),

                      // Team Performance
                      _buildSectionTitle(
                          'Performa Tim', isDark),
                      const SizedBox(height: 14),
                      if (adminState.report != null)
                        _buildPerformanceList(
                            adminState.report!.teamPerformance,
                            isDark)
                      else
                        _buildEmptyCard(
                            'Data tidak tersedia', isDark),
                      const SizedBox(height: 28),

                      // Category Distribution
                      _buildSectionTitle(
                          'Distribusi Kategori', isDark),
                      const SizedBox(height: 14),
                      if (adminState.report != null)
                        _buildCategoryChart(
                            adminState
                                .report!.categoryDistribution,
                            isDark)
                      else
                        _buildEmptyCard(
                            'Data tidak tersedia', isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateFilterCard(bool isDark) {
    final hasFilter = _startDate != null || _endDate != null;
    final fmt = DateFormat('d MMM yyyy');

    return GestureDetector(
      onTap: _selectDateRange,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFilter
              ? AppColors.primary.withValues(alpha: 0.08)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFilter
                ? AppColors.primary.withValues(alpha: 0.3)
                : (isDark
                    ? AppColors.borderDark
                    : const Color(0xFFEEEEF2)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasFilter
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF2F2F5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: hasFilter
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white54
                        : Colors.black45),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rentang Waktu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white38
                          : Colors.black38,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFilter
                        ? '${fmt.format(_startDate!)}  →  ${fmt.format(_endDate!)}'
                        : 'Semua Waktu (Ketuk untuk filter)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasFilter
                          ? AppColors.primary
                          : (isDark
                              ? Colors.white
                              : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            if (hasFilter)
              GestureDetector(
                onTap: _clearDateFilter,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildStatsGrid(stats_state.TicketStatsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      {
        'label': 'Total',
        'value': state.stats.total,
        'icon': Icons.analytics_outlined,
        'color': AppColors.primary,
      },
      {
        'label': 'Terbuka',
        'value': state.stats.open,
        'icon': Icons.folder_open_rounded,
        'color': Colors.orange,
      },
      {
        'label': 'Selesai',
        'value': state.stats.resolved,
        'icon': Icons.check_circle_outline_rounded,
        'color': Colors.green,
      },
      {
        'label': 'Diproses',
        'value': state.stats.inProgress,
        'icon': Icons.sync_rounded,
        'color': Colors.blue,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((item) {
        final color = item['color'] as Color;
        final value = item['value'] as int;
        return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item['icon'] as IconData,
                        size: 16, color: color),
                  ),
                  Text(
                    '$value',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceList(
      List<TeamPerformance> performance, bool isDark) {
    if (performance.isEmpty) {
      return _buildEmptyCard('Belum ada data teknisi.', isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFEEEEF2),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: performance.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFEEEEF2),
        ),
        itemBuilder: (context, index) {
          final item = performance[index];
          final initials = item.fullName.isNotEmpty
              ? item.fullName[0].toUpperCase()
              : 'T';
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              item.fullName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: const Text(
              'Teknisi',
              style: TextStyle(fontSize: 11),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.resolvedCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Selesai',
                  style: TextStyle(fontSize: 10, color: Colors.green),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChart(
      List<CategoryDistribution> distribution, bool isDark) {
    if (distribution.isEmpty) {
      return _buildEmptyCard('Belum ada data tiket.', isDark);
    }

    final total =
        distribution.fold<int>(0, (sum, item) => sum + item.count);
    final List<Color> colors = [
      AppColors.primary,
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.pink,
      Colors.amber,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          // Bar chart
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (int i = 0; i < distribution.length; i++)
                    Expanded(
                      flex: distribution[i].count,
                      child: Container(
                          color: colors[i % colors.length]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...distribution.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final pct = total > 0
                ? (item.count / total * 100).toStringAsFixed(0)
                : '0';
            final color = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.white70 : Colors.black70,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFEEEEF2),
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
