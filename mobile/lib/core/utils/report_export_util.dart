import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Rapor Export & Print Yardımcı Sınıfı
class ReportExportUtil {
  /// PDF oluştur ve paylaş/yazdır
  static Future<void> exportAndPrint({
    required BuildContext context,
    required String title,
    required String companyName,
    required List<Map<String, String>> columns,
    required List<Map<String, String>> data,
    Map<String, String>? summary,
    bool print = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('TornaDefter', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A5F'))),
            pw.Text(companyName, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text('$title - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            pw.Divider(color: PdfColor.fromHex('#1E3A5F'), thickness: 2),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'TornaDefter Cari Hesap Yönetim Sistemi - Sayfa ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
        ),
        build: (context) => [
          if (summary != null)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              margin: const pw.EdgeInsets.only(bottom: 15),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#f0f4f8'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: summary.entries.map((e) => pw.Column(
                  children: [
                    pw.Text(e.key, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    pw.SizedBox(height: 3),
                    pw.Text(e.value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A5F'))),
                  ],
                )).toList(),
              ),
            ),
          pw.TableHelper.fromTextArray(
            context: context,
            headers: columns.map((c) => c['header'] ?? '').toList(),
            data: data.map((row) => columns.map((c) => row[c['key']] ?? '').toList()).toList(),
            headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A5F')),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(5),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            oddCellStyle: const pw.TextStyle(fontSize: 9),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    if (print) {
      await Printing.layoutPdf(onLayout: (_) => pdf.save());
    } else {
      await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
    }
  }
}

