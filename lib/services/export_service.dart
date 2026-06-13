import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/account.dart';
import '../models/journal.dart';
import 'store.dart';
import '../widgets/theme.dart';

class ExportService {
  static final store = Store.instance;

  static Future<(pw.Font, pw.Font)> _fonts() async {
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    return (font, bold);
  }

  static Future<void> shareVoucherPdf(JournalEntry entry) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        header(entry.type),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: box(),
          child: pw.Column(children: [
            infoRow('رقم السند', entry.number.toString(), 'التاريخ', dateText(entry.date), bold),
            infoRow('طريقة الدفع', entry.method.isEmpty ? '-' : entry.method, 'رقم الشيك', entry.chequeNumber.isEmpty ? '-' : entry.chequeNumber, bold),
            pw.SizedBox(height: 8),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('البيان: ${entry.description}', style: pw.TextStyle(font: bold, fontSize: 12))),
          ]),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['الحساب', 'مدين', 'دائن', 'ملاحظة'],
          data: entry.lines.map((l) => ['${l.accountCode} - ${l.accountName}', money(l.debit), money(l.credit), l.note]).toList(),
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignment: pw.Alignment.centerRight,
        ),
        pw.SizedBox(height: 24),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          signatureBox('المحاسب'),
          signatureBox('المستلم / الدافع'),
          signatureBox('المدير'),
        ]),
      ]),
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: '${entry.type}_${entry.number}.pdf');
  }

  static Future<void> shareTrialBalancePdf({DateTime? from, DateTime? to, String level = 'تفصيلي'}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;

    final trialRows = store.trialBalanceRows(level: level, from: from, to: to);
    final rows = trialRows.map((r) => [
          r.account.code,
          r.account.name,
          r.account.type,
          money(r.debit),
          money(r.credit),
          money(r.difference),
        ]).toList();

    final totalDebit = trialRows.fold<double>(0, (s, r) => s + r.debit);
    final totalCredit = trialRows.fold<double>(0, (s, r) => s + r.credit);
    rows.add(['', 'الإجمالي', '', money(totalDebit), money(totalCredit), money(totalDebit - totalCredit)]);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => [
        header('ميزان المراجعة - $level'),
        periodText(from, to),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['رقم الحساب', 'اسم الحساب', 'النوع', 'مدين', 'دائن', 'الفرق'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerRight,
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'trial_balance.pdf');
  }

  static Future<void> shareAccountStatementPdf(Account a, {DateTime? from, DateTime? to}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;

    double running = 0;
    final related = store.entriesBetween(from: from, to: to).where((e) => e.lines.any((l) => l.accountId == a.id)).toList();

    final rows = <List<String>>[];
    for (final e in related) {
      for (final l in e.lines.where((x) => x.accountId == a.id)) {
        running += l.debit - l.credit;
        rows.add([
          dateText(e.date),
          e.type,
          e.number.toString(),
          e.description,
          money(l.debit),
          money(l.credit),
          money(running),
        ]);
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => [
        header('كشف حساب'),
        periodText(from, to),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: box(),
          child: pw.Text(a.display, style: pw.TextStyle(font: bold, fontSize: 15)),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['التاريخ', 'النوع', 'الرقم', 'البيان', 'مدين', 'دائن', 'الرصيد'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellAlignment: pw.Alignment.centerRight,
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'statement_${a.code}.pdf');
  }

  static Future<void> shareJournalPdf({DateTime? from, DateTime? to}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;
    final list = store.entriesBetween(from: from, to: to);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => [
        header('دفتر اليومية'),
        periodText(from, to),
        pw.SizedBox(height: 8),
        ...list.map((e) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: box(),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('${e.type} رقم ${e.number} - ${dateText(e.date)} - ${e.description}', style: pw.TextStyle(font: bold, fontSize: 10)),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  headers: ['الحساب', 'مدين', 'دائن'],
                  data: e.lines.map((l) => ['${l.accountCode} - ${l.accountName}', money(l.debit), money(l.credit)]).toList(),
                  headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 8),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
                  cellStyle: const pw.TextStyle(fontSize: 7),
                  cellAlignment: pw.Alignment.centerRight,
                ),
              ]),
            )),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'journal.pdf');
  }

  static Future<void> shareCashBankReportPdf({DateTime? from, DateTime? to}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;
    final accounts = store.cashBankAccounts();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      build: (_) => [
        header('تقرير الصندوق والبنك'),
        periodText(from, to),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['رقم الحساب', 'اسم الحساب', 'مدين', 'دائن', 'الرصيد'],
          data: accounts.map((a) => [
            a.code,
            a.name,
            money(store.debitFor(a.id, from: from, to: to)),
            money(store.creditFor(a.id, from: from, to: to)),
            money(store.balanceFor(a.id, from: from, to: to)),
          ]).toList(),
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerRight,
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'cash_bank_report.pdf');
  }

  static pw.Widget header(String title) {
    final s = store.settings;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EAF5FF'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColor.fromHex('#CFE4F6')),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(s.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22)),
        pw.Text('السنة المالية: ${s.fiscalYear}'),
        if (s.phone.isNotEmpty || s.address.isNotEmpty) pw.Text('${s.phone} ${s.address}'.trim()),
      ]),
    );
  }

  static pw.Widget periodText(DateTime? from, DateTime? to) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
        child: pw.Text('الفترة: ${from == null ? 'البداية' : _date(from)} إلى ${to == null ? 'النهاية' : _date(to)}'),
      );

  static String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static pw.BoxDecoration box() => pw.BoxDecoration(
        color: PdfColor.fromHex('#FBFDFF'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#DDEAF5')),
      );

  static pw.Widget infoRow(String a, String av, String b, String bv, pw.Font bold) => pw.Row(children: [
        pw.Expanded(child: pw.Text('$a: $av', style: pw.TextStyle(font: bold))),
        pw.Expanded(child: pw.Text('$b: $bv', style: pw.TextStyle(font: bold))),
      ]);

  static pw.Widget signatureBox(String title) => pw.Column(children: [
        pw.Container(width: 120, height: 1, color: PdfColors.grey500),
        pw.SizedBox(height: 4),
        pw.Text(title),
      ]);

  static Future<void> shareExcel() async {
    final excel = Excel.createExcel();

    final acc = excel['Accounts'];
    acc.appendRow(['Code', 'Name', 'Type', 'Level', 'Active', 'Debit', 'Credit', 'Balance']);
    for (final a in store.accounts) {
      acc.appendRow([
        a.code,
        a.name,
        a.type,
        a.level,
        a.active ? 'Yes' : 'No',
        money(store.debitFor(a.id)),
        money(store.creditFor(a.id)),
        money(store.balanceFor(a.id)),
      ]);
    }

    final j = excel['Journal'];
    j.appendRow(['No', 'Year', 'Date', 'Type', 'Description', 'Method', 'Cheque', 'Account', 'Debit', 'Credit']);
    for (final e in store.entries) {
      for (final l in e.lines) {
        j.appendRow([
          e.number,
          e.fiscalYear,
          dateText(e.date),
          e.type,
          e.description,
          e.method,
          e.chequeNumber,
          '${l.accountCode} - ${l.accountName}',
          money(l.debit),
          money(l.credit),
        ]);
      }
    }

    final summary = excel['Summary'];
    summary.appendRow(['Item', 'Value']);
    summary.appendRow(['Assets', money(store.typeBalance('أصول'))]);
    summary.appendRow(['Liabilities', money(store.typeBalance('التزامات'))]);
    summary.appendRow(['Equity', money(store.typeBalance('رأس المال'))]);
    summary.appendRow(['Revenue', money(store.typeBalance('إيرادات'))]);
    summary.appendRow(['Expenses', money(store.typeBalance('مصاريف'))]);

    final bytes = excel.encode();
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/accounting_smart_v3.xlsx');
    await file.writeAsBytes(Uint8List.fromList(bytes));
    await Share.shareXFiles([XFile(file.path)], text: 'تصدير النظام المحاسبي Excel');
  }

  static Future<void> shareBackupJson() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/accounting_smart_v3_backup.json');
    await file.writeAsString(store.backupJson());
    await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية - المحاسب الذكي V3');
  }
}
