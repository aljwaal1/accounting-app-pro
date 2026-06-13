import 'package:flutter/material.dart';
import '../models/journal.dart';
import '../services/export_service.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class VoucherPreviewScreen extends StatelessWidget {
  final JournalEntry entry;
  const VoucherPreviewScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final settings = Store.instance.settings;
    final color = entry.type == 'سند قبض' ? mint : coral;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('معاينة ${entry.type}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'طباعة / مشاركة PDF',
            onPressed: () => ExportService.shareVoucherPdf(entry),
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: softCard(28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                CircleAvatar(backgroundColor: color.withOpacity(.13), child: Icon(Icons.receipt_long_rounded, color: color)),
                const SizedBox(width: 10),
                Expanded(child: Text(settings.companyName, style: const TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 8),
              Text(entry.type, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              infoTile('رقم السند', entry.number.toString()),
              infoTile('التاريخ', dateText(entry.date)),
              infoTile('طريقة الدفع', entry.method.isEmpty ? '-' : entry.method),
              if (entry.chequeNumber.isNotEmpty) infoTile('رقم الشيك', entry.chequeNumber),
              infoTile('البيان', entry.description),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(border: Border.all(color: line), borderRadius: BorderRadius.circular(18)),
                child: Column(children: [
                  tableRow('الحساب', 'مدين', 'دائن', isHeader: true),
                  ...entry.lines.map((l) => tableRow('${l.accountCode} - ${l.accountName}', money(l.debit), money(l.credit))),
                  tableRow('الإجمالي', money(entry.totalDebit), money(entry.totalCredit), isHeader: true),
                ]),
              ),
              const SizedBox(height: 22),
              Row(children: const [
                Expanded(child: SignatureBox(title: 'المحاسب')),
                SizedBox(width: 10),
                Expanded(child: SignatureBox(title: 'المستلم / الدافع')),
                SizedBox(width: 10),
                Expanded(child: SignatureBox(title: 'المدير')),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ExportService.shareVoucherPdf(entry),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('طباعة / مشاركة PDF'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  Widget infoTile(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(title, style: const TextStyle(color: softText, fontWeight: FontWeight.w800))),
      Expanded(child: Text(value, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900))),
    ]),
  );

  Widget tableRow(String a, String b, String c, {bool isHeader = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    decoration: BoxDecoration(color: isHeader ? primary.withOpacity(.08) : Colors.white, border: const Border(bottom: BorderSide(color: line))),
    child: Row(children: [
      Expanded(flex: 4, child: Text(a, style: TextStyle(color: darkText, fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700))),
      Expanded(child: Text(b, textAlign: TextAlign.center, style: TextStyle(color: darkText, fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700))),
      Expanded(child: Text(c, textAlign: TextAlign.center, style: TextStyle(color: darkText, fontWeight: isHeader ? FontWeight.w900 : FontWeight.w700))),
    ]),
  );
}

class SignatureBox extends StatelessWidget {
  final String title;
  const SignatureBox({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(height: 1, color: softText),
    const SizedBox(height: 6),
    Text(title, textAlign: TextAlign.center, style: const TextStyle(color: softText, fontWeight: FontWeight.w800, fontSize: 11)),
  ]);
}
