import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uts/core/constants/app_colors.dart';
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
import 'package:uts/core/utils/haptic_helper.dart';

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
    HapticHelper.medium();
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
          SnackBar(content: Text('Gagal export: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showExportBottomSheet(AdminReport report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Ekspor Laporan', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildExportCard(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'Format PDF',
                    color: Colors.red,
                    isDark: isDark,
                    onTap: () { Navigator.pop(context); _exportReport(report, asPdf: true); },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExportCard(
                    icon: Icons.table_chart_rounded,
                    label: 'Format CSV',
                    color: Colors.green,
                    isDark: isDark,
                    onTap: () { Navigator.pop(context); _exportReport(report, asPdf: false); },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({required IconData icon, required String label, required Color color, required bool isDark, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
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
      // Validate range (max 1 year)
      if (picked.end.difference(picked.start).inDays > 366) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maksimal rentang waktu adalah 1 tahun.'), backgroundColor: AppColors.danger),
          );
        }
        return;
      }

      HapticHelper.medium();
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _refreshData();
    }
  }

  bool _isDataStale(AdminState state) {
    if (state.report == null) return true;
    // Simple check: do the report parameters match our current filter?
    // In a real app, the report entity might have a 'generatedAt' or 'period' property.
    // For now, if we are loading, it's definitely stale or about to be.
    return state.status == AdminStatus.loading;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Laporan & Analitik', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _refreshData),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, adminState) {
          return BlocBuilder<TicketStatsBloc, stats_state.TicketStatsState>(
            builder: (context, statsState) {
              if (adminState.status == AdminStatus.loading && adminState.report == null) return const Center(child: LoadingWidget());

              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterCard(isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('RINGKASAN TIKET'),
                      const SizedBox(height: 16),
                      _buildStatsGrid(statsState, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('PERFORMA TIM'),
                      const SizedBox(height: 16),
                      if (adminState.report != null) _buildPerformanceList(adminState.report!.teamPerformance, isDark),
                      const SizedBox(height: 32),
                      _buildSectionTitle('DISTRIBUSI KATEGORI'),
                      const SizedBox(height: 16),
                      if (adminState.report != null) _buildCategoryDistribution(adminState.report!.categoryDistribution, isDark),
                      const SizedBox(height: 48),
                      if (adminState.report != null) _buildDownloadButton(adminState.report!, isDark),
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

  Widget _buildFilterCard(bool isDark) {
    final hasFilter = _startDate != null;
    return GestureDetector(
      onTap: _selectDateRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFilter ? AppColors.primary.withValues(alpha: 0.05) : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasFilter ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rentang Waktu', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
                  Text(
                    hasFilter ? '${DateFormat('d MMM').format(_startDate!)} - ${DateFormat('d MMM yyyy').format(_endDate!)}' : 'Seluruh Waktu',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (hasFilter)
              IconButton(
                onPressed: () { setState(() { _startDate = null; _endDate = null; }); _refreshData(); },
                icon: const Icon(Icons.clear_rounded, size: 18),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.5));
  }

  Widget _buildStatsGrid(stats_state.TicketStatsState state, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Total', state.stats.total, Icons.analytics_rounded, Colors.indigo, isDark),
        _buildStatCard('Terbuka', state.stats.open, Icons.folder_open_rounded, Colors.orange, isDark),
        _buildStatCard('Diproses', state.stats.inProgress, Icons.loop_rounded, Colors.blue, isDark),
        _buildStatCard('Selesai', state.stats.resolved, Icons.check_circle_rounded, Colors.green, isDark),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedCounter(value: value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800)),
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceList(List<TeamPerformance> performance, bool isDark) {
    final max = performance.isNotEmpty ? performance.first.resolvedCount : 1;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: performance.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight, indent: 60),
        itemBuilder: (context, index) {
          final item = performance[index];
          final progress = item.resolvedCount / (max == 0 ? 1 : max);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('#${index + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.fullName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation(progress > 0.8 ? Colors.green : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(item.resolvedCount.toString(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.green)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryDistribution(List<CategoryDistribution> distribution, bool isDark) {
    final total = distribution.fold<int>(0, (s, e) => s + e.count);
    final colors = [AppColors.primary, Colors.orange, Colors.teal, Colors.purple, Colors.pink, Colors.amber];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        children: distribution.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final progress = item.count / (total == 0 ? 1 : total);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.category, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                    Text('${item.count} (${(progress * 100).toInt()}%)', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4))),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(height: 8, decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(4))),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadButton(AdminReport report, bool isDark) {
    final state = context.watch<AdminBloc>().state;
    final isStale = _isDataStale(state);
    final isLoadingReport = state.status == AdminStatus.loading;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isStale ? [Colors.grey, Colors.grey.shade600] : [AppColors.primary, const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          if (!isStale) BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isStale || _isExporting) ? null : () => _showExportBottomSheet(report),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isExporting || isLoadingReport)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  _isExporting
                      ? 'MENYIAPKAN LAPORAN...'
                      : (isLoadingReport ? 'MEMUAT DATA...' : 'UNDUH LAPORAN'),
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;
  const _AnimatedCounter({required this.value, required this.style});
  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animation = IntTween(begin: 0, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = IntTween(begin: oldWidget.value, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
      _controller.reset(); _controller.forward();
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Text(_animation.value.toString(), style: widget.style),
    );
  }
}
