import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/export_service.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final store = StoreService.instance;
  Account? selected;

  @override
  void initState() {
    super.initState();
    final list = store.postingAccounts();
    if (list.isNotEmpty) selected = list.first;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = store.postingAccounts();
    return ListView(padding: const EdgeInsets.all(14), children: [
      Wrap(spacing: 10, runSpacing: 10, children: [
        action('ميزان مراجعة PDF', Icons.picture_as_pdf, danger, () => ExportService.shareTrialBalancePdf()),
        action('تصدير Excel كامل', Icons.table_chart, success, () => ExportService.shareExcel()),
      ]),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16), decoration: panel(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('كشف حساب PDF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: darkText)),
        const SizedBox(height: 12),
        DropdownButtonFormField<Account>(
          value: selected,
          items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text('${a.code} - ${a.name}'))).toList(),
          onChanged: (v)=>setState(()=>selected=v),
          decoration: inputDec('اختر الحساب', Icons.account_tree),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: selected == null ? null : () => ExportService.shareAccountStatementPdf(selected!), icon: const Icon(Icons.share), label: const Text('مشاركة كشف الحساب PDF'))),
      ])),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(16), decoration: panel(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ميزان المراجعة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: darkText)),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(columns: const [
          DataColumn(label: Text('رقم الحساب')),
          DataColumn(label: Text('اسم الحساب')),
          DataColumn(label: Text('النوع')),
          DataColumn(label: Text('مدين')),
          DataColumn(label: Text('دائن')),
          DataColumn(label: Text('الرصيد')),
        ], rows: accounts.map((a)=>DataRow(cells: [
          DataCell(Text(a.code)),
          DataCell(Text(a.name)),
          DataCell(Text(a.type)),
          DataCell(Text(money(store.debitFor(a.id)))),
          DataCell(Text(money(store.creditFor(a.id)))),
          DataCell(Text(money(store.balanceFor(a.id)))),
        ])).toList())),
      ])),
    ]);
  }

  Widget action(String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 190,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(text)),
      ),
    );
  }
}
