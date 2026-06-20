import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/journal.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class JournalScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const JournalScreen({super.key, required this.onChanged});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final store = Store.instance;

  @override
  Widget build(BuildContext context) {
    final list = [...store.entries]..sort((a,b)=>b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addJournal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('قيد يدوي'),
      ),
      body: list.isEmpty ? emptyState('لا توجد قيود بعد', Icons.receipt_long_rounded) : ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: softCard(22),
            child: ExpansionTile(
              title: Text('${e.type} رقم ${e.number}', style: const TextStyle(color: darkText, fontWeight: FontWeight.w900)),
              subtitle: Text('${dateText(e.date)} | ${e.description}${e.chequeNumber.isNotEmpty ? ' | شيك ${e.chequeNumber}' : ''}'),
              children: [
                ...e.lines.map((l)=>ListTile(
                  title: Text('${l.accountCode} - ${l.accountName}'),
                  trailing: Text.rich(TextSpan(children: [
                    TextSpan(text: 'مدين ${money(l.debit)}  ', style: const TextStyle(color: debitColor, fontWeight: FontWeight.w800)),
                    TextSpan(text: 'دائن ${money(l.credit)}', style: const TextStyle(color: creditColor, fontWeight: FontWeight.w800)),
                  ])),
                )),
                TextButton.icon(
                  onPressed: () => confirmDelete(e),
                  style: TextButton.styleFrom(foregroundColor: coral),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('حذف القيد'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> confirmDelete(JournalEntry e) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف ${e.type} رقم ${e.number}؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    ));
    if (ok != true) return;
    await store.deleteEntry(e.id);
    if (!mounted) return;
    setState(() {});
    widget.onChanged();
  }

  Future<void> addJournal() async {
    final accounts = store.postingAccounts();
    if (accounts.length < 2) return;
    Account? debit = accounts.first;
    Account? credit = accounts[1];
    final amount = TextEditingController();
    final desc = TextEditingController();

    await showDialog(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: StatefulBuilder(builder: (context, setD) => AlertDialog(
      title: Text('قيد يومية رقم ${store.nextDocNumber('قيد يومية')}'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: desc, decoration: fieldDec('البيان', Icons.description_rounded)),
        const SizedBox(height: 10),
        TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: fieldDec('المبلغ', Icons.payments_rounded)),
        const SizedBox(height: 10),
        DropdownButtonFormField<Account>(
          value: debit,
          items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text(a.display))).toList(),
          onChanged: (v)=>setD(()=>debit=v),
          decoration: fieldDec('الحساب المدين', Icons.add_circle_rounded),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<Account>(
          value: credit,
          items: accounts.map((a)=>DropdownMenuItem(value:a, child:Text(a.display))).toList(),
          onChanged: (v)=>setD(()=>credit=v),
          decoration: fieldDec('الحساب الدائن', Icons.remove_circle_rounded),
        ),
      ])),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () async {
          final v = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
          if (v <= 0 || debit == null || credit == null) return;

          final e = JournalEntry(
            id: store.id(),
            number: store.nextDocNumber('قيد يومية'),
            fiscalYear: store.settings.fiscalYear,
            date: DateTime.now().millisecondsSinceEpoch,
            type: 'قيد يومية',
            description: desc.text.trim(),
            method: '',
            chequeNumber: '',
            lines: [
              JournalLine(accountId: debit!.id, accountCode: debit!.code, accountName: debit!.name, debit: v, credit: 0, note: ''),
              JournalLine(accountId: credit!.id, accountCode: credit!.code, accountName: credit!.name, debit: 0, credit: v, note: ''),
            ],
          );

          if (!e.balanced) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('القيد غير متوازن')));
            return;
          }

          await store.addEntry(e);
          if (!mounted) return;
          Navigator.pop(context);
          setState(() {});
          widget.onChanged();
        }, child: const Text('حفظ')),
      ],
    ))));
  }
}
