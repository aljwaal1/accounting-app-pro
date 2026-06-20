import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal.dart';
import '../services/export_service.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class StatementRow {
  final JournalEntry entry;
  final JournalLine line;
  final double running;
  StatementRow({required this.entry, required this.line, required this.running});
}

class StatementPreviewScreen extends StatelessWidget {
  final Account account;
  final DateTime? from;
  final DateTime? to;

  const StatementPreviewScreen({super.key, required this.account, this.from, this.to});

  @override
  Widget build(BuildContext context) {
    final store = Store.instance;
    final settings = store.settings;

    final opening = store.openingBalanceFor(account.id, from: from);
    final related = store
        .entriesBetween(from: from, to: to)
        .where((e) => e.lines.any((l) => l.accountId == account.id))
        .toList();

    double running = opening;
    final rows = <StatementRow>[];
    for (final e in related) {
      for (final l in e.lines.where((x) => x.accountId == account.id)) {
        running += l.debit - l.credit;
        rows.add(StatementRow(entry: e, line: l, running: running));
      }
    }

    final totalDebit = rows.fold<double>(0, (s, r) => s + r.line.debit);
    final totalCredit = rows.fold<double>(0, (s, r) => s + r.line.credit);
    final closing = running;
    final color = colorForType(account.type);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('كشف حساب'),
        actions: [
          IconButton(
            tooltip: 'مشاركة PDF',
            onPressed: () => ExportService.shareAccountStatementPdf(account, from: from, to: to),
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          // بطاقة معلومات الحساب والشركة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: accentCard(color, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(backgroundColor: color.withOpacity(.13), child: Icon(Icons.account_balance_wallet_rounded, color: color)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(account.display, style: const TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(settings.companyName, style: const TextStyle(color: softText, fontWeight: FontWeight.w700, fontSize: 12)),
                ])),
                tag(account.type, color),
              ]),
              const SizedBox(height: 10),
              Text(
                'الفترة: ${from == null ? 'بداية النشاط' : dateOnly(from!)} إلى ${to == null ? 'تاريخ اليوم' : dateOnly(to!)}',
                style: const TextStyle(color: softText, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ملخص الأرصدة: افتتاحي / حركة / ختامي
          Row(children: [
            Expanded(child: balanceChip('افتتاحي', opening, lavender)),
            const SizedBox(width: 8),
            Expanded(child: balanceChip('الحركة', totalDebit - totalCredit, primary)),
            const SizedBox(width: 8),
            Expanded(child: balanceChip('ختامي', closing, gold, filled: true)),
          ]),
          const SizedBox(height: 14),

          if (rows.isEmpty)
            emptyState('لا توجد حركات على هذا الحساب خلال الفترة المحددة', Icons.receipt_long_rounded)
          else
            Container(
              decoration: softCard(20),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                headerRow(),
                openingRow(opening),
                ...rows.map((r) => rowTile(r)),
                totalsRow(totalDebit, totalCredit, closing),
              ]),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: FilledButton.icon(
              onPressed: () => ExportService.shareAccountStatementPdf(account, from: from, to: to),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('مشاركة PDF'),
            )),
          ]),
        ],
      ),
    );
  }

  String dateOnly(DateTime d) => '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  Widget balanceChip(String title, double value, Color color, {bool filled = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: filled ? color.withOpacity(.12) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: filled ? color.withOpacity(.35) : line),
    ),
    child: Column(children: [
      Text(title, style: const TextStyle(color: softText, fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 4),
      FittedBox(child: Text(money(value), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 17))),
    ]),
  );

  Widget headerRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    color: primaryLight,
    child: const Row(children: [
      Expanded(flex: 3, child: Text('البيان', style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12))),
      Expanded(flex: 2, child: Text('مدين', textAlign: TextAlign.center, style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12))),
      Expanded(flex: 2, child: Text('دائن', textAlign: TextAlign.center, style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12))),
      Expanded(flex: 2, child: Text('الرصيد', textAlign: TextAlign.center, style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12))),
    ]),
  );

  Widget openingRow(double opening) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: const BoxDecoration(color: Color(0xFFFAFBFA), border: Border(bottom: BorderSide(color: line))),
    child: Row(children: [
      const Expanded(flex: 3, child: Text('رصيد افتتاحي', style: TextStyle(color: softText, fontWeight: FontWeight.w800, fontSize: 12.5))),
      const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.center, style: TextStyle(color: softText))),
      const Expanded(flex: 2, child: Text('-', textAlign: TextAlign.center, style: TextStyle(color: softText))),
      Expanded(flex: 2, child: Text(money(opening), textAlign: TextAlign.center, style: const TextStyle(color: lavender, fontWeight: FontWeight.w900, fontSize: 12.5))),
    ]),
  );

  Widget rowTile(StatementRow r) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: line))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${r.entry.type} رقم ${r.entry.number}', style: const TextStyle(color: darkText, fontWeight: FontWeight.w800, fontSize: 12.5)),
        Text('${dateText(r.entry.date)} - ${r.entry.description}', style: const TextStyle(color: softText, fontWeight: FontWeight.w600, fontSize: 11)),
      ])),
      Expanded(flex: 2, child: Text(r.line.debit == 0 ? '-' : money(r.line.debit), textAlign: TextAlign.center, style: TextStyle(color: r.line.debit == 0 ? softText : debitColor, fontWeight: FontWeight.w800, fontSize: 12))),
      Expanded(flex: 2, child: Text(r.line.credit == 0 ? '-' : money(r.line.credit), textAlign: TextAlign.center, style: TextStyle(color: r.line.credit == 0 ? softText : creditColor, fontWeight: FontWeight.w800, fontSize: 12))),
      Expanded(flex: 2, child: Text(money(r.running), textAlign: TextAlign.center, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 12))),
    ]),
  );

  Widget totalsRow(double debit, double credit, double closing) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(color: goldLight),
    child: Row(children: [
      const Expanded(flex: 3, child: Text('الإجمالي / الرصيد الختامي', style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12.5))),
      Expanded(flex: 2, child: Text(money(debit), textAlign: TextAlign.center, style: const TextStyle(color: debitColor, fontWeight: FontWeight.w900, fontSize: 12.5))),
      Expanded(flex: 2, child: Text(money(credit), textAlign: TextAlign.center, style: const TextStyle(color: creditColor, fontWeight: FontWeight.w900, fontSize: 12.5))),
      Expanded(flex: 2, child: Text(money(closing), textAlign: TextAlign.center, style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 13))),
    ]),
  );
}
