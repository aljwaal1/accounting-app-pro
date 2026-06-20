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

/// ====== هوية ملفات PDF (مطابقة لهوية التطبيق الجديدة) ======
final _pdfPrimary = PdfColor.fromHex('#0E7C66');
final _pdfPrimaryDark = PdfColor.fromHex('#0B5C4C');
final _pdfPrimaryLight = PdfColor.fromHex('#E3F3EE');
final _pdfGold = PdfColor.fromHex('#C79A2E');
final _pdfGoldLight = PdfColor.fromHex('#FBF1DC');
final _pdfDebit = PdfColor.fromHex('#CC4B4B');
final _pdfCredit = PdfColor.fromHex('#1E9E6B');
final _pdfLine = PdfColor.fromHex('#E2E9E7');
final _pdfText = PdfColor.fromHex('#152722');
final _pdfSoft = PdfColor.fromHex('#6B7C78');
final _pdfZebra = PdfColor.fromHex('#F6F9F8');

class ExportService {
  static final store = Store.instance;

  static Future<(pw.Font, pw.Font)> _fonts() async {
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    return (font, bold);
  }

  // ===================== سند قبض / صرف =====================
  static Future<void> shareVoucherPdf(JournalEntry entry) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;
    final accent = entry.type == 'سند قبض' ? _pdfCredit : _pdfDebit;

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        header(entry.type, accent: accent),
        pw.SizedBox(height: 14),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: box(),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            infoRow('رقم السند', entry.number.toString(), 'التاريخ', dateText(entry.date), bold),
            pw.SizedBox(height: 6),
            infoRow('طريقة الدفع', entry.method.isEmpty ? '-' : entry.method, 'رقم الشيك', entry.chequeNumber.isEmpty ? '-' : entry.chequeNumber, bold),
            pw.SizedBox(height: 10),
            pw.Container(height: 1, color: _pdfLine),
            pw.SizedBox(height: 10),
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('البيان: ${entry.description}', style: pw.TextStyle(font: bold, fontSize: 12, color: _pdfText))),
          ]),
        ),
        pw.SizedBox(height: 14),
        styledTable(
          headers: const ['الحساب', 'مدين', 'دائن', 'ملاحظة'],
          rows: entry.lines.map((l) => [
            '${l.accountCode} - ${l.accountName}',
            l.debit == 0 ? '-' : money(l.debit),
            l.credit == 0 ? '-' : money(l.credit),
            l.note.isEmpty ? '-' : l.note,
          ]).toList(),
          bold: bold,
        ),
        pw.SizedBox(height: 8),
        totalsBar('الإجمالي', entry.totalDebit, entry.totalCredit, bold),
        pw.SizedBox(height: 30),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          signatureBox('المحاسب'),
          signatureBox('المستلم / الدافع'),
          signatureBox('المدير'),
        ]),
        pw.SizedBox(height: 18),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _pdfLine, width: .7))),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('${store.settings.companyName} — المحاسب الذكي', style: pw.TextStyle(fontSize: 7.5, color: _pdfSoft)),
            pw.Text('تم الإصدار: ${_now()}', style: pw.TextStyle(fontSize: 7.5, color: _pdfSoft)),
          ]),
        ),
      ]),
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: '${entry.type}_${entry.number}.pdf');
  }

  // ===================== ميزان المراجعة =====================
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

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.fromLTRB(26, 26, 26, 26),
      footer: (ctx) => pdfFooter(ctx, bold),
      build: (_) => [
        header('ميزان المراجعة - $level'),
        periodText(from, to),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: const ['رقم الحساب', 'اسم الحساب', 'النوع', 'مدين', 'دائن', 'الفرق'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: pw.BoxDecoration(color: _pdfPrimaryDark, borderRadius: pw.BorderRadius.circular(4)),
          cellStyle: pw.TextStyle(font: font, fontSize: 8, color: _pdfText),
          cellAlignment: pw.Alignment.centerRight,
          oddRowDecoration: pw.BoxDecoration(color: _pdfZebra),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        ),
        pw.SizedBox(height: 10),
        totalsBar('إجمالي الميزان', totalDebit, totalCredit, bold),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'trial_balance.pdf');
  }

  // ===================== كشف حساب (مُعاد تصميمه بالكامل) =====================
  static Future<void> shareAccountStatementPdf(Account a, {DateTime? from, DateTime? to}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;

    final opening = store.openingBalanceFor(a.id, from: from);
    double running = opening;
    final related = store.entriesBetween(from: from, to: to).where((e) => e.lines.any((l) => l.accountId == a.id)).toList();

    final rows = <List<dynamic>>[];
    double totalDebit = 0, totalCredit = 0;
    for (final e in related) {
      for (final l in e.lines.where((x) => x.accountId == a.id)) {
        running += l.debit - l.credit;
        totalDebit += l.debit;
        totalCredit += l.credit;
        rows.add([dateText(e.date), '${e.type} ${e.number}', e.description, l.debit, l.credit, running]);
      }
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.fromLTRB(26, 26, 26, 26),
      footer: (ctx) => pdfFooter(ctx, bold),
      build: (_) => [
        header('كشف حساب'),
        periodText(from, to),
        pw.SizedBox(height: 10),
        // بطاقة معلومات الحساب
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _pdfPrimaryLight,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _pdfPrimary.shade(.15)),
          ),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(a.display, style: pw.TextStyle(font: bold, fontSize: 14, color: _pdfPrimaryDark)),
            pw.Text(a.type, style: pw.TextStyle(font: bold, fontSize: 11, color: _pdfPrimaryDark)),
          ]),
        ),
        pw.SizedBox(height: 10),
        // ملخص الأرصدة
        pw.Row(children: [
          summaryBox('رصيد افتتاحي', opening, PdfColor.fromHex('#5B5FCF'), bold),
          pw.SizedBox(width: 8),
          summaryBox('صافي الحركة', totalDebit - totalCredit, _pdfPrimary, bold),
          pw.SizedBox(width: 8),
          summaryBox('رصيد ختامي', running, _pdfGold, bold),
        ]),
        pw.SizedBox(height: 12),
        statementTable(rows, opening, totalDebit, totalCredit, running, bold, font),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'statement_${a.code}.pdf');
  }

  static pw.Widget summaryBox(String title, double value, PdfColor color, pw.Font bold) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _pdfLine),
          ),
          child: pw.Column(children: [
            pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 8.5, color: _pdfSoft)),
            pw.SizedBox(height: 4),
            pw.Text(money(value), style: pw.TextStyle(font: bold, fontSize: 12, color: color)),
          ]),
        ),
      );

  static pw.Widget statementTable(List<List<dynamic>> rows, double opening, double totalDebit, double totalCredit, double closing, pw.Font bold, pw.Font font) {
    pw.TextStyle h = pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9);
    pw.TextStyle c = pw.TextStyle(font: font, color: _pdfText, fontSize: 8.5);

    pw.Widget cell(String text, {pw.TextStyle? style, pw.Alignment align = pw.Alignment.centerRight}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: pw.Align(alignment: align, child: pw.Text(text, style: style ?? c)),
        );

    final tableRows = <pw.TableRow>[
      pw.TableRow(decoration: pw.BoxDecoration(color: _pdfPrimaryDark), children: [
        cell('التاريخ', style: h, align: pw.Alignment.center),
        cell('المستند', style: h, align: pw.Alignment.center),
        cell('البيان', style: h, align: pw.Alignment.centerRight),
        cell('مدين', style: h, align: pw.Alignment.center),
        cell('دائن', style: h, align: pw.Alignment.center),
        cell('الرصيد', style: h, align: pw.Alignment.center),
      ]),
      pw.TableRow(decoration: pw.BoxDecoration(color: _pdfGoldLight), children: [
        cell('', align: pw.Alignment.center),
        cell('', align: pw.Alignment.center),
        cell('رصيد افتتاحي', style: pw.TextStyle(font: bold, color: _pdfText, fontSize: 8.5)),
        cell('-', align: pw.Alignment.center),
        cell('-', align: pw.Alignment.center),
        cell(money(opening), style: pw.TextStyle(font: bold, color: PdfColor.fromHex('#5B5FCF'), fontSize: 8.5), align: pw.Alignment.center),
      ]),
    ];

    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final debit = r[3] as double;
      final credit = r[4] as double;
      final bg = i % 2 == 1 ? _pdfZebra : PdfColors.white;
      tableRows.add(pw.TableRow(decoration: pw.BoxDecoration(color: bg), children: [
        cell(r[0] as String, align: pw.Alignment.center),
        cell(r[1] as String, align: pw.Alignment.center),
        cell(r[2] as String),
        cell(debit == 0 ? '-' : money(debit), style: pw.TextStyle(font: font, color: debit == 0 ? _pdfSoft : _pdfDebit, fontSize: 8.5), align: pw.Alignment.center),
        cell(credit == 0 ? '-' : money(credit), style: pw.TextStyle(font: font, color: credit == 0 ? _pdfSoft : _pdfCredit, fontSize: 8.5), align: pw.Alignment.center),
        cell(money(r[5] as double), style: pw.TextStyle(font: bold, color: _pdfText, fontSize: 8.5), align: pw.Alignment.center),
      ]));
    }

    tableRows.add(pw.TableRow(decoration: pw.BoxDecoration(color: _pdfGold.shade(.12), border: pw.Border(top: pw.BorderSide(color: _pdfGold, width: 1))), children: [
      cell('', align: pw.Alignment.center),
      cell('', align: pw.Alignment.center),
      cell('الإجمالي / الرصيد الختامي', style: pw.TextStyle(font: bold, color: _pdfPrimaryDark, fontSize: 9)),
      cell(money(totalDebit), style: pw.TextStyle(font: bold, color: _pdfDebit, fontSize: 9), align: pw.Alignment.center),
      cell(money(totalCredit), style: pw.TextStyle(font: bold, color: _pdfCredit, fontSize: 9), align: pw.Alignment.center),
      cell(money(closing), style: pw.TextStyle(font: bold, color: _pdfGold, fontSize: 9.5), align: pw.Alignment.center),
    ]));

    return pw.Table(
      border: pw.TableBorder.all(color: _pdfLine, width: .6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.6),
        1: pw.FlexColumnWidth(1.6),
        2: pw.FlexColumnWidth(3.2),
        3: pw.FlexColumnWidth(1.6),
        4: pw.FlexColumnWidth(1.6),
        5: pw.FlexColumnWidth(1.8),
      },
      children: tableRows,
    );
  }

  // ===================== دفتر اليومية =====================
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
      margin: const pw.EdgeInsets.fromLTRB(26, 26, 26, 26),
      footer: (ctx) => pdfFooter(ctx, bold),
      build: (_) => [
        header('دفتر اليومية'),
        periodText(from, to),
        pw.SizedBox(height: 8),
        ...list.map((e) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: box(),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('${e.type} رقم ${e.number}', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _pdfPrimaryDark)),
                  pw.Text(dateText(e.date), style: pw.TextStyle(font: bold, fontSize: 9.5, color: _pdfSoft)),
                ]),
                if (e.description.isNotEmpty) pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, bottom: 6),
                  child: pw.Text(e.description, style: pw.TextStyle(font: font, fontSize: 9, color: _pdfSoft)),
                ),
                pw.TableHelper.fromTextArray(
                  headers: const ['الحساب', 'مدين', 'دائن'],
                  data: e.lines.map((l) => ['${l.accountCode} - ${l.accountName}', l.debit == 0 ? '-' : money(l.debit), l.credit == 0 ? '-' : money(l.credit)]).toList(),
                  headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 8),
                  headerDecoration: pw.BoxDecoration(color: _pdfPrimary),
                  cellStyle: pw.TextStyle(font: font, fontSize: 7.5, color: _pdfText),
                  cellAlignment: pw.Alignment.centerRight,
                  oddRowDecoration: pw.BoxDecoration(color: _pdfZebra),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                ),
              ]),
            )),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'journal.pdf');
  }

  // ===================== تقرير الصندوق والبنك =====================
  static Future<void> shareCashBankReportPdf({DateTime? from, DateTime? to}) async {
    final doc = pw.Document();
    final fonts = await _fonts();
    final font = fonts.$1;
    final bold = fonts.$2;
    final accounts = store.cashBankAccounts();

    final rows = accounts.map((a) => [
          a.code,
          a.name,
          money(store.debitFor(a.id, from: from, to: to)),
          money(store.creditFor(a.id, from: from, to: to)),
          money(store.balanceFor(a.id, from: from, to: to)),
        ]).toList();
    final totalBalance = accounts.fold<double>(0, (s, a) => s + store.balanceFor(a.id, from: from, to: to));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      theme: pw.ThemeData.withFont(base: font, bold: bold),
      margin: const pw.EdgeInsets.fromLTRB(26, 26, 26, 26),
      footer: (ctx) => pdfFooter(ctx, bold),
      build: (_) => [
        header('تقرير الصندوق والبنك'),
        periodText(from, to),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: const ['رقم الحساب', 'اسم الحساب', 'مدين', 'دائن', 'الرصيد'],
          data: rows,
          headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 9),
          headerDecoration: pw.BoxDecoration(color: _pdfPrimaryDark),
          cellStyle: pw.TextStyle(font: font, fontSize: 8, color: _pdfText),
          cellAlignment: pw.Alignment.centerRight,
          oddRowDecoration: pw.BoxDecoration(color: _pdfZebra),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: _pdfGoldLight, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('إجمالي السيولة (صندوق وبنك)', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _pdfPrimaryDark)),
            pw.Text(money(totalBalance), style: pw.TextStyle(font: bold, fontSize: 12, color: _pdfGold)),
          ]),
        ),
      ],
    ));

    await Printing.sharePdf(bytes: await doc.save(), filename: 'cash_bank_report.pdf');
  }

  // ===================== عناصر مشتركة للتصميم =====================

  static pw.Widget header(String title, {PdfColor? accent}) {
    final s = store.settings;
    final a = accent ?? _pdfPrimary;
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        color: _pdfPrimaryLight,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: _pdfPrimary.shade(.2)),
      ),
      child: pw.Row(children: [
        pw.Container(width: 6, height: 70, decoration: pw.BoxDecoration(color: a, borderRadius: const pw.BorderRadius.horizontal(right: pw.Radius.circular(12)))),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(s.companyName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15, color: _pdfPrimaryDark)),
              pw.SizedBox(height: 2),
              pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20, color: _pdfText)),
              pw.SizedBox(height: 2),
              pw.Text(
                'السنة المالية: ${s.fiscalYear}${(s.phone.isNotEmpty || s.address.isNotEmpty) ? '   |   ${s.phone} ${s.address}'.trim() : ''}',
                style: pw.TextStyle(fontSize: 9, color: _pdfSoft),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  static pw.Widget pdfFooter(pw.Context ctx, pw.Font bold) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _pdfLine, width: .7))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text('${store.settings.companyName} — المحاسب الذكي', style: pw.TextStyle(fontSize: 7.5, color: _pdfSoft)),
          pw.Text('تم الإصدار: ${_now()}', style: pw.TextStyle(fontSize: 7.5, color: _pdfSoft)),
          pw.Text('صفحة ${ctx.pageNumber} من ${ctx.pagesCount}', style: pw.TextStyle(font: bold, fontSize: 7.5, color: _pdfSoft)),
        ]),
      );

  static String _now() {
    final d = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  static pw.Widget periodText(DateTime? from, DateTime? to) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 2),
        child: pw.Text('الفترة: ${from == null ? 'بداية النشاط' : _date(from)} إلى ${to == null ? 'تاريخ اليوم' : _date(to)}', style: pw.TextStyle(fontSize: 9.5, color: _pdfSoft)),
      );

  static String _date(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  static pw.BoxDecoration box() => pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: _pdfLine),
      );

  static pw.Widget infoRow(String a, String av, String b, String bv, pw.Font bold) => pw.Row(children: [
        pw.Expanded(child: pw.Text('$a: $av', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _pdfText))),
        pw.Expanded(child: pw.Text('$b: $bv', style: pw.TextStyle(font: bold, fontSize: 10.5, color: _pdfText))),
      ]);

  static pw.Widget signatureBox(String title) => pw.Column(children: [
        pw.Container(width: 120, height: 1, color: _pdfLine),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(color: _pdfSoft, fontSize: 9)),
      ]);

  static pw.Widget styledTable({required List<String> headers, required List<List<String>> rows, required pw.Font bold}) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(font: bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: pw.BoxDecoration(color: _pdfPrimaryDark, borderRadius: pw.BorderRadius.circular(4)),
      cellStyle: pw.TextStyle(fontSize: 9, color: _pdfText),
      cellAlignment: pw.Alignment.centerRight,
      oddRowDecoration: pw.BoxDecoration(color: _pdfZebra),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
    );
  }

  static pw.Widget totalsBar(String title, double debit, double credit, pw.Font bold) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: pw.BoxDecoration(color: _pdfGoldLight, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 10.5, color: _pdfPrimaryDark)),
          pw.Row(children: [
            pw.Text('مدين ', style: pw.TextStyle(font: bold, fontSize: 10, color: _pdfSoft)),
            pw.Text(money(debit), style: pw.TextStyle(font: bold, fontSize: 11, color: _pdfDebit)),
            pw.SizedBox(width: 14),
            pw.Text('دائن ', style: pw.TextStyle(font: bold, fontSize: 10, color: _pdfSoft)),
            pw.Text(money(credit), style: pw.TextStyle(font: bold, fontSize: 11, color: _pdfCredit)),
          ]),
        ]),
      );

  // ===================== Excel =====================
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
