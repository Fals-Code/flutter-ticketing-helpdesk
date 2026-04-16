import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:uts/features/admin/domain/entities/admin_report_entity.dart';

class ReportExportService {
  /// Exports the admin report as a PDF file and opens the share dialog.
  Future<void> exportToPdf(
    AdminReport report, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd MMM yyyy');
    final now = dateFormatter.format(DateTime.now());

    final String periodLabel = startDate != null && endDate != null
        ? '${dateFormatter.format(startDate)} – ${dateFormatter.format(endDate)}'
        : 'Semua Waktu';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Laporan E-Ticketing Helpdesk',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Periode: $periodLabel  |  Dicetak: $now',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (_) => [
          // ── Team Performance ──────────────────────────────────────────
          pw.Text('Performa Tim (Tiket Selesai)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (report.teamPerformance.isEmpty)
            pw.Text('Belum ada data teknisi.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                  children: [
                    _cell('No', isHeader: true),
                    _cell('Nama Teknisi', isHeader: true),
                    _cell('Tiket Selesai', isHeader: true),
                  ],
                ),
                // data rows
                ...report.teamPerformance.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: i.isEven ? PdfColors.white : PdfColors.grey50),
                    children: [
                      _cell('${i + 1}'),
                      _cell(item.fullName),
                      _cell('${item.resolvedCount}'),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),

          // ── Category Distribution ────────────────────────────────────
          pw.Text('Distribusi Kategori Tiket',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (report.categoryDistribution.isEmpty)
            pw.Text('Belum ada data tiket.',
                style: const pw.TextStyle(color: PdfColors.grey600))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                  children: [
                    _cell('Kategori', isHeader: true),
                    _cell('Jumlah Tiket', isHeader: true),
                    _cell('Persentase', isHeader: true),
                  ],
                ),
                ...() {
                  final total = report.categoryDistribution
                      .fold<int>(0, (s, c) => s + c.count);
                  return report.categoryDistribution.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    final pct = total > 0
                        ? (item.count / total * 100).toStringAsFixed(1)
                        : '0.0';
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                          color: i.isEven ? PdfColors.white : PdfColors.grey50),
                      children: [
                        _cell(item.category),
                        _cell('${item.count}'),
                        _cell('$pct%'),
                      ],
                    );
                  });
                }(),
              ],
            ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_helpdesk_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan E-Ticketing Helpdesk',
    );
  }

  /// Exports the admin report as a CSV file and opens the share dialog.
  Future<void> exportToCsv(
    AdminReport report, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rows = <List<dynamic>>[];

    // ── Team Performance section ──────────────────────────────────────
    rows.add(['=== PERFORMA TIM ===']);
    rows.add(['No', 'Nama Teknisi', 'Tiket Selesai']);
    for (var i = 0; i < report.teamPerformance.length; i++) {
      final item = report.teamPerformance[i];
      rows.add([i + 1, item.fullName, item.resolvedCount]);
    }

    rows.add([]); // blank separator

    // ── Category Distribution section ─────────────────────────────────
    rows.add(['=== DISTRIBUSI KATEGORI ===']);
    rows.add(['Kategori', 'Jumlah Tiket', 'Persentase (%)']);
    final total =
        report.categoryDistribution.fold<int>(0, (s, c) => s + c.count);
    for (final item in report.categoryDistribution) {
      final pct =
          total > 0 ? (item.count / total * 100).toStringAsFixed(1) : '0.0';
      rows.add([item.category, item.count, pct]);
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/laporan_helpdesk_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Laporan E-Ticketing Helpdesk',
    );
  }

  // ── helpers ─────────────────────────────────────────────────────────
  pw.Widget _cell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
