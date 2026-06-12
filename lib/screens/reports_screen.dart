import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/export_service.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class ReportsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const ReportsScreen({super.key, required this.onChanged});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final store = Store.instance;
  Account? selected;
  DateTime? from;
  DateTime? to;

  @override
  void initState() {
    super.initState();
    final list = store.postingAccounts();
    if (list.isNotEmpty) selected = list.first;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = store.postingAccounts();

    return ListView(padding: const EdgeInsets.all(12), children: [
      filterCard(),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: reportAction('ميزان PDF', Icons.picture_as_pdf_rounded, coral, () => ExportService.shareTrialBalancePdf(from: from, to: to))),
        const SizedBox(width: 10),
        Expanded(child: reportAction('Excel', Icons.table_chart_rounded, mint, () => ExportService.shareExcel())),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: reportAction('دفتر اليومية', Icons.menu_book_rounded, primary, () => ExportService.shareJournalPdf(from: from, to: to))),
        const SizedBox(width: 10),
        Expanded(child: reportAction('صندوق وبنك', Icons.account_balance_rounded, lavender, () => ExportService.shareCashBankReportPdf(from: from, to: to))),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('كشف حساب PDF', style: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<Account>(
            value: selected,
            items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text(a.display))).toList(),
            onChanged: (v)=>setState(()=>selected=v),
            decoration: fieldDec('اختر الحساب', Icons.account_tree_rounded),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: selected == null ? null : () => ExportService.shareAccountStatementPdf(selected!, from: from, to: to),
            icon: const Icon(Icons.share_rounded),
            label: const Text('مشاركة كشف الحساب PDF'),
          )),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ميزان المراجعة', style: TextStyle(color: darkText, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: const [
              DataColumn(label: Text('الحساب')),
              DataColumn(label: Text('مدين')),
              DataColumn(label: Text('دائن')),
              DataColumn(label: Text('الرصيد')),
            ], rows: accounts.map((a)=>DataRow(cells: [
              DataCell(Text(a.display)),
              DataCell(Text(money(store.debitFor(a.id, from: from, to: to)))),
              DataCell(Text(money(store.creditFor(a.id, from: from, to: to)))),
              DataCell(Text(money(store.balanceFor(a.id, from: from, to: to)))),
            ])).toList()),
          ),
        ]),
      ),
    ]);
  }

  Widget filterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: softCard(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('فلاتر التقارير', style: TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: dateButton('من تاريخ', from, () => pickDate(true))),
          const SizedBox(width: 8),
          Expanded(child: dateButton('إلى تاريخ', to, () => pickDate(false))),
        ]),
        if (from != null || to != null) Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => setState(() { from = null; to = null; }), icon: const Icon(Icons.clear_rounded), label: const Text('مسح الفلتر')),
        ),
      ]),
    );
  }

  Widget dateButton(String label, DateTime? value, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.date_range_rounded),
      label: Text(value == null ? label : '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}'),
    );
  }

  Future<void> pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (from ?? now) : (to ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        from = picked;
      } else {
        to = picked;
      }
    });
  }

  Widget reportAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(22),
        child: Column(children: [
          CircleAvatar(backgroundColor: color.withOpacity(.13), child: Icon(icon, color: color)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
