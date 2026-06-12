import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class AccountsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const AccountsScreen({super.key, required this.onChanged});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final store = StoreService.instance;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final list = store.accounts.where((a) => a.code.contains(query) || a.name.contains(query) || a.type.contains(query)).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(onPressed: addAccount, icon: const Icon(Icons.add), label: const Text('حساب جديد')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: inputDec('بحث في شجرة الحسابات', Icons.search),
          ),
        ),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final a = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsetsDirectional.only(start: 12.0 + (a.level - 1) * 18, end: 12, top: 12, bottom: 12),
              decoration: panel(18),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: a.level == 1 ? primary : const Color(0xFFE7F7FF), child: Text(a.level.toString(), style: TextStyle(color: a.level == 1 ? Colors.white : primary, fontWeight: FontWeight.w900))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a.code} - ${a.name}', style: const TextStyle(fontWeight: FontWeight.w900, color: darkText, fontSize: 16)),
                  Text('${a.type} | مستوى ${a.level}', style: const TextStyle(color: softText, fontWeight: FontWeight.w700)),
                ])),
                Text(money(store.balanceFor(a.id)), style: const TextStyle(fontWeight: FontWeight.w900, color: primary)),
              ]),
            );
          },
        )),
      ]),
    );
  }

  Future<void> addAccount() async {
    final code = TextEditingController();
    final name = TextEditingController();
    String type = 'أصول';
    int level = 2;
    await showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(builder: (context, setD) => AlertDialog(
        title: const Text('إضافة حساب'),
        content: SingleChildScrollView(child: Column(children: [
          TextField(controller: code, decoration: inputDec('رقم الحساب', Icons.numbers)),
          const SizedBox(height: 10),
          TextField(controller: name, decoration: inputDec('اسم الحساب', Icons.account_balance_wallet)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: type,
            items: ['أصول','التزامات','رأس المال','إيرادات','مصاريف'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
            onChanged: (v)=>setD(()=>type=v??type),
            decoration: inputDec('نوع الحساب', Icons.category),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: level,
            items: [1,2,3].map((e)=>DropdownMenuItem(value:e, child:Text('المستوى $e'))).toList(),
            onChanged: (v)=>setD(()=>level=v??level),
            decoration: inputDec('المستوى', Icons.layers),
          ),
        ])),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            if (code.text.trim().isEmpty || name.text.trim().isEmpty) return;
            await store.addAccount(Account(id: store.newId(), code: code.text.trim(), name: name.text.trim(), type: type, parentId: '', level: level));
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {});
            widget.onChanged();
          }, child: const Text('حفظ')),
        ],
      )),
    ));
  }
}
