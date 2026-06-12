import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal.dart';
import '../services/store.dart';
import '../services/export_service.dart';
import '../widgets/theme.dart';

class VoucherScreen extends StatefulWidget {
  final String type;
  final VoidCallback onSaved;
  const VoucherScreen({super.key, required this.type, required this.onSaved});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final store = Store.instance;
  final amount = TextEditingController();
  final desc = TextEditingController();
  final cheque = TextEditingController();
  String method = 'نقدي';
  Account? cashBank;
  Account? other;

  @override
  void initState() {
    super.initState();
    final accounts = store.postingAccounts();
    cashBank = store.byId(store.settings.defaultCashId) ?? (accounts.isNotEmpty ? accounts.first : null);
    other = accounts.length > 1 ? accounts[1] : cashBank;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = store.postingAccounts();
    final no = store.nextDocNumber(widget.type);
    final color = widget.type == 'سند قبض' ? mint : coral;

    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundColor: color.withOpacity(.13), child: Icon(widget.type == 'سند قبض' ? Icons.south_west_rounded : Icons.north_east_rounded, color: color)),
            const SizedBox(width: 10),
            Expanded(child: Text('${widget.type} رقم $no', style: const TextStyle(color: darkText, fontSize: 22, fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 14),
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fieldDec('المبلغ', Icons.payments_rounded)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: method,
            items: ['نقدي', 'بنك'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
            onChanged: (v) => setState(() {
              method = v ?? method;
              if (method == 'بنك' && cheque.text.isEmpty) cheque.text = store.nextChequeNumber().toString();
            }),
            decoration: fieldDec('طريقة الدفع', Icons.tune_rounded),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Account>(
            value: cashBank,
            items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text(a.display))).toList(),
            onChanged: (v)=>setState(()=>cashBank=v),
            decoration: fieldDec('الصندوق / البنك', Icons.account_balance_rounded),
          ),
          if (method == 'بنك') ...[
            const SizedBox(height: 10),
            TextField(controller: cheque, keyboardType: TextInputType.number, decoration: fieldDec('رقم الشيك التلقائي', Icons.confirmation_number_rounded)),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<Account>(
            value: other,
            items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text(a.display))).toList(),
            onChanged: (v)=>setState(()=>other=v),
            decoration: fieldDec(widget.type == 'سند قبض' ? 'قبض من حساب' : 'صرف إلى حساب', Icons.account_tree_rounded),
          ),
          const SizedBox(height: 10),
          TextField(controller: desc, decoration: fieldDec('البيان', Icons.description_rounded)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ وتوليد القيد تلقائيًا'))),
        ]),
      ),
    ]);
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
    if (value <= 0 || cashBank == null || other == null) return;

    final lines = widget.type == 'سند قبض'
        ? [
            JournalLine(accountId: cashBank!.id, accountCode: cashBank!.code, accountName: cashBank!.name, debit: value, credit: 0, note: ''),
            JournalLine(accountId: other!.id, accountCode: other!.code, accountName: other!.name, debit: 0, credit: value, note: ''),
          ]
        : [
            JournalLine(accountId: other!.id, accountCode: other!.code, accountName: other!.name, debit: value, credit: 0, note: ''),
            JournalLine(accountId: cashBank!.id, accountCode: cashBank!.code, accountName: cashBank!.name, debit: 0, credit: value, note: ''),
          ];

    final entry = JournalEntry(
      id: store.id(),
      number: store.nextDocNumber(widget.type),
      fiscalYear: store.settings.fiscalYear,
      date: DateTime.now().millisecondsSinceEpoch,
      type: widget.type,
      description: desc.text.trim().isEmpty ? widget.type : desc.text.trim(),
      method: method,
      chequeNumber: method == 'بنك' ? cheque.text.trim() : '',
      lines: lines,
    );

    if (!entry.balanced) return;
    await store.addEntry(entry);

    if (!mounted) return;
    await showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تم الحفظ'),
        content: Text('تم حفظ ${widget.type} رقم ${entry.number} وتوليد القيد المحاسبي تلقائيًا.'),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إغلاق')),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ExportService.shareVoucherPdf(entry);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: const Text('طباعة PDF'),
          ),
        ],
      ),
    ));

    amount.clear();
    desc.clear();
    cheque.clear();
    setState(() {});
    widget.onSaved();
  }
}
