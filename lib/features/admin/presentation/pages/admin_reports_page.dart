import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uts/core/constants/app_colors.dart';
import 'package:uts/core/constants/app_dimensions.dart';
import 'package:uts/core/services/report_export_service.dart';
import 'package:uts/features/admin/presentation/bloc/admin_bloc.dart';
import 'package:uts/features/admin/presentation/bloc/admin_event.dart';
import 'package:uts/features/admin/presentation/bloc/admin_state.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_bloc.dart';
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_event.dart' as stats_event;
import 'package:uts/features/ticket/presentation/bloc/stats/ticket_stats_state.dart' as stats_state;
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

  Future<void> _exportReport(AdminReport report, {required bool asPdf}) async {
    setState(() => _isExporting = true);
    try {
      if (asPdf) {
        await _exportService.exportToPdf(report, startDate: _startDate, endDate: _endDate);
      } else {
        await _exportService.exportToCsv(report, startDate: _startDate, endDate: _endDate);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: AppColors.primary, onPrimary: Colors.white, surface: AppColors.surfaceDark, onSurface: Colors.white)
                : const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black87),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Analitik'),
        actions: [
          BlocBuilder<AdminBloc, AdminState>(
            builder: (context, adminState) {
              final report = adminState.report;
              if (_isExporting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                );
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export Laporan',
                enabled: report != null,
                onSelected: (value) {
                  if (report == null) return;
                  _exportReport(report, asPdf: value == 'pdf');
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20), SizedBox(width: 10), Text('Export PDF')])),
                  PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart_rounded, color: Colors.green, size: 20), SizedBox(width: 10), Text('Export CSV')])),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, adminState) {
          return BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
            builder: (context, statsState) {
              if (adminState.status == AdminStatus.loading && adminState.report == null) {
                return const Center(child: LoadingWidget());
              }

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateFilterHeader(isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Ringkasan Tiket', isDark),
                      const SizedBox(height: 16),
                      _buildStatsGrid(statsState),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Performa Tim (Resolved)', isDark),
                      const SizedBox(height: 16),
                      if (adminState.report != null) 
                         _buildPerformanceList(adminState.report!.teamPerformance, isDark)
                      else
                        const Center(child: Text('Data tidak tersedia')),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Distribusi Kategori', isDark),
                      const SizedBox(height: 16),
                      if (adminState.report != null)
                        _buildCategoryChart(adminState.report!.categoryDistribution, isDark)
                      else
                        const Center(child: Text('Data tidak tersedia')),
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

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildStatsGrid(stats_state.TicketStatsState state) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Tiket', state.stats.total.toString(), Icons.analytics_rounded, AppColors.primary),
        _buildStatCard('Terbuka', state.stats.open.toString(), Icons.hourglass_empty_rounded, Colors.orange),
        _buildStatCard('Selesai', state.stats.resolved.toString(), Icons.check_circle_outline_rounded, Colors.green),
        _buildStatCard('Dalam Proses', state.stats.inProgress.toString(), Icons.running_with_errors_rounded, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ],
          ),
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPerformanceList(List<TeamPerformance> performance, bool isDark) {
    if (performance.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data teknisi.')));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: performance.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
        itemBuilder: (context, index) {
          final item = performance[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : 'T', 
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Teknisi Terverifikasi', style: TextStyle(fontSize: 11)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item.resolvedCount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                const Text('Selesai', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChart(List<CategoryDistribution> distribution, bool isDark) {
    if (distribution.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada data tiket.')));

    final totalValue = distribution.fold<int>(0, (sum, item) => sum + item.count);
    final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.pink, Colors.amber];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  for (int i = 0; i < distribution.length; i++)
                    Expanded(
                      flex: distribution[i].count,
                      child: Container(color: colors[i % colors.length]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (int i = 0; i < distribution.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      '${distribution[i].category} (${(distribution[i].count / totalValue * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterHeader(bool isDark) {
    final hasFilter = _startDate != null || _endDate != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFilter ? AppColors.primary.withValues(alpha: 0.1) : (isDark ? AppColors.surfaceDark : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasFilter ? AppColors.primary : Colors.transparent),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 20, color: hasFilter ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rentang Waktu',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
                ),
                Text(
                  hasFilter 
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                      : 'Semua Waktu',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _refreshData();
              },
            ),
          TextButton(
            onPressed: _selectDateRange,
            child: Text(hasFilter ? 'Ubah' : 'Pilih'),
          ),
        ],
      ),
    );
  }
}
