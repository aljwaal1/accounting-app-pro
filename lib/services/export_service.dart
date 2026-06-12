import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/account.dart';
import 'store_service.dart';
import '../widgets/ui.dart';

class ExportService {
  static final store = StoreService.instance;

  static Future<void> shareTrialBalancePdf() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    final rows = store.accounts.where((a) => a.level >= 2).map((a) {
      return [a.code, a.name, a.type, money(store.debitFor(a.id)), money(store.creditFor(a.id)), money(store.balanceFor(a.id))];
    }).toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _pdfHeader('ميزان المراجعة'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['رقم الحساب', 'اسم الحساب', 'النوع', 'مدين', 'دائن', 'الرصيد'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerRight,
          headerAlignment: pw.Alignment.centerRight,
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'trial_balance.pdf');
  }

  static Future<void> shareAccountStatementPdf(Account a) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    double running = 0;
    final rows = <List<String>>[];

    final related = store.entries.where((e) => e.lines.any((l) => l.accountId == a.id)).toList();
    related.sort((x, y) => x.date.compareTo(y.date));

    for (final e in related) {
      for (final l in e.lines.where((x) => x.accountId == a.id)) {
        running += l.debit - l.credit;
        rows.add([dateText(e.date), e.type, e.number.toString(), e.description, money(l.debit), money(l.credit), money(running)]);
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.all(24),
      build: (_) => [
        _pdfHeader('كشف حساب'),
        pw.Text('${a.code} - ${a.name}', style: pw.TextStyle(font: bold, fontSize: 15)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['التاريخ', 'النوع', 'الرقم', 'البيان', 'مدين', 'دائن', 'الرصيد'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.centerRight,
          headerAlignment: pw.Alignment.centerRight,
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'account_statement_${a.code}.pdf');
  }

  static pw.Widget _pdfHeader(String title) {
    final s = store.settings;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E7F7FF'), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(s.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22, color: PdfColor.fromHex('#063B63'))),
        pw.Text('السنة المالية: ${s.fiscalYear}'),
      ]),
    );
  }

  static Future<void> shareExcel() async {
    final excel = Excel.createExcel();

    final acc = excel['Accounts'];
    acc.appendRow(['Code', 'Name', 'Type', 'Level', 'Debit', 'Credit', 'Balance']);
    for (final a in store.accounts) {
      acc.appendRow([a.code, a.name, a.type, a.level, money(store.debitFor(a.id)), money(store.creditFor(a.id)), money(store.balanceFor(a.id))]);
    }

    final j = excel['Journal'];
    j.appendRow(['No', 'Year', 'Date', 'Type', 'Description', 'Method', 'Cheque', 'Account Code', 'Account Name', 'Debit', 'Credit']);
    for (final e in store.entries) {
      for (final l in e.lines) {
        j.appendRow([e.number, e.fiscalYear, dateText(e.date), e.type, e.description, e.paymentMethod, e.chequeNumber, l.accountCode, l.accountName, money(l.debit), money(l.credit)]);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/accounting_export_v2.xlsx');
    await file.writeAsBytes(Uint8List.fromList(bytes));
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير النظام المحاسبي Excel');
  }
}
