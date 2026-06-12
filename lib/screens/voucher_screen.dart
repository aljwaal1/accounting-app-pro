import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class VoucherScreen extends StatefulWidget {
  final String type;
  final VoidCallback onSaved;
  const VoucherScreen({super.key, required this.type, required this.onSaved});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final store = StoreService.instance;
  final amount = TextEditingController();
  final desc = TextEditingController();
  final cheque = TextEditingController();
  String method = 'نقدي';
  Account? cashBank;
  Account? other;

  @override
  void initState() {
    super.initState();
    final list = store.postingAccounts();
    cashBank = list.where((a) => a.name == 'الصندوق').isNotEmpty ? list.firstWhere((a) => a.name == 'الصندوق') : (list.isNotEmpty ? list.first : null);
    other = list.length > 1 ? list[1] : cashBank;
  }

  @override
  Widget build(BuildContext context) {
    final accounts = store.postingAccounts();
    final next = store.nextNumber(widget.type);
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(padding: const EdgeInsets.all(16), decoration: panel(26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('${widget.type} رقم $next', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: darkText))),
          Text('السنة ${store.settings.fiscalYear}', style: const TextStyle(color: softText, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 14),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('المبلغ', Icons.payments)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: method,
            items: ['نقدي','بنك'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
            onChanged: (v)=>setState(() {
              method = v ?? method;
              if (method == 'بنك' && cheque.text.isEmpty) cheque.text = store.nextChequeNumber().toString();
            }),
            decoration: inputDec('طريقة الدفع', Icons.payments),
          )),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<Account>(
            value: cashBank,
            items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text('${a.code} - ${a.name}'))).toList(),
            onChanged: (v)=>setState(()=>cashBank=v),
            decoration: inputDec('الصندوق / البنك', Icons.account_balance),
          )),
        ]),
        if (method == 'بنك') ...[
          const SizedBox(height: 10),
          TextField(controller: cheque, keyboardType: TextInputType.number, decoration: inputDec('رقم الشيك', Icons.confirmation_number)),
        ],
        const SizedBox(height: 10),
        DropdownButtonFormField<Account>(
          value: other,
          items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text('${a.code} - ${a.name}'))).toList(),
          onChanged: (v)=>setState(()=>other=v),
          decoration: inputDec(widget.type == 'سند قبض' ? 'الحساب الدائن' : 'الحساب المدين', Icons.account_tree),
        ),
        const SizedBox(height: 10),
        TextField(controller: desc, decoration: inputDec('البيان', Icons.description)),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('حفظ السند'))),
      ])),
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

    await store.addEntry(JournalEntry(
      id: store.newId(),
      number: store.nextNumber(widget.type),
      fiscalYear: store.settings.fiscalYear,
      date: DateTime.now().millisecondsSinceEpoch,
      type: widget.type,
      description: desc.text.trim().isEmpty ? widget.type : desc.text.trim(),
      paymentMethod: method,
      chequeNumber: method == 'بنك' ? cheque.text.trim() : '',
      lines: lines,
    ));

    if (!mounted) return;
    final print = await showDialog<bool>(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('تم حفظ السند'),
      content: const Text('هل تريد فتح قسم التقارير لطباعة أو تصدير المستندات؟'),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context, false), child: const Text('لا')),
        FilledButton(onPressed: ()=>Navigator.pop(context, true), child: const Text('نعم')),
      ],
    )));

    amount.clear(); desc.clear(); cheque.clear();
    widget.onSaved();
    if (print == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('افتح التقارير لتصدير PDF أو Excel')));
    }
  }
}
