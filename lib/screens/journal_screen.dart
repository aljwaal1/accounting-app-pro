import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal_entry.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const JournalScreen({super.key, required this.onChanged});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final store = StoreService.instance;

  @override
  Widget build(BuildContext context) {
    final list = [...store.entries]..sort((a,b)=>b.date.compareTo(a.date));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: addJournal, icon: const Icon(Icons.add), label: const Text('قيد جديد')),
      body: list.isEmpty ? empty('لا توجد قيود بعد') : ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: panel(22),
            child: ExpansionTile(
              title: Text('${e.type} رقم ${e.number}', style: const TextStyle(fontWeight: FontWeight.w900, color: darkText)),
              subtitle: Text('${dateText(e.date)} | ${e.description}${e.chequeNumber.isNotEmpty ? ' | شيك ${e.chequeNumber}' : ''}'),
              children: [
                ...e.lines.map((l)=>ListTile(
                  title: Text('${l.accountCode} - ${l.accountName}'),
                  trailing: Text('مدين ${money(l.debit)} | دائن ${money(l.credit)}'),
                )),
                TextButton.icon(onPressed: () async {
                  await store.deleteEntry(e.id);
                  setState(() {});
                  widget.onChanged();
                }, icon: const Icon(Icons.delete_outline), label: const Text('حذف القيد')),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> addJournal() async {
    final accounts = store.postingAccounts();
    if (accounts.length < 2) return;
    Account? debit = accounts.first;
    Account? credit = accounts[1];
    final amount = TextEditingController();
    final desc = TextEditingController();

    await showDialog(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (context, setD) => AlertDialog(
      title: Text('قيد يومية رقم ${store.nextNumber('قيد يومية')}'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: desc, decoration: inputDec('البيان', Icons.description)),
        const SizedBox(height: 10),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: inputDec('المبلغ', Icons.payments)),
        const SizedBox(height: 10),
        DropdownButtonFormField<Account>(value: debit, items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text('${a.code} - ${a.name}'))).toList(), onChanged: (v)=>setD(()=>debit=v), decoration: inputDec('الحساب المدين', Icons.add_circle)),
        const SizedBox(height: 10),
        DropdownButtonFormField<Account>(value: credit, items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text('${a.code} - ${a.name}'))).toList(), onChanged: (v)=>setD(()=>credit=v), decoration: inputDec('الحساب الدائن', Icons.remove_circle)),
      ])),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          final v = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
          if (v <= 0 || debit == null || credit == null) return;
          await store.addEntry(JournalEntry(
            id: store.newId(),
            number: store.nextNumber('قيد يومية'),
            fiscalYear: store.settings.fiscalYear,
            date: DateTime.now().millisecondsSinceEpoch,
            type: 'قيد يومية',
            description: desc.text.trim(),
            paymentMethod: '',
            chequeNumber: '',
            lines: [
              JournalLine(accountId: debit!.id, accountCode: debit!.code, accountName: debit!.name, debit: v, credit: 0, note: ''),
              JournalLine(accountId: credit!.id, accountCode: credit!.code, accountName: credit!.name, debit: 0, credit: v, note: ''),
            ],
          ));
          if (!mounted) return;
          Navigator.pop(context);
          setState(() {});
          widget.onChanged();
        }, child: const Text('حفظ')),
      ],
    ))));
  }
}
