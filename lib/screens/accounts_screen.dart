import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class AccountsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const AccountsScreen({super.key, required this.onChanged});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final store = Store.instance;
  String query = '';

  @override
  Widget build(BuildContext context) {
    final list = store.accounts.where((a) {
      final q = query.trim();
      return q.isEmpty || a.name.contains(q) || a.code.contains(q) || a.type.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addAccount,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('حساب ذكي'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: fieldDec('بحث في الحسابات', Icons.search_rounded),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
            itemCount: list.length,
            itemBuilder: (_, i) => accountCard(list[i]),
          ),
        ),
      ]),
    );
  }

  Widget accountCard(Account a) {
    final bal = store.balanceFor(a.id);
    final color = a.type == 'أصول' ? primary : a.type == 'مصاريف' ? coral : a.type == 'إيرادات' ? mint : lavender;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onLongPress: () => editAccount(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: EdgeInsetsDirectional.only(start: 12.0 + (a.level - 1) * 16, top: 12, bottom: 12, end: 8),
        decoration: softCard(20),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withOpacity(a.active ? .12 : .05), child: Icon(Icons.account_balance_wallet_rounded, color: a.active ? color : softText, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.display, style: TextStyle(color: a.active ? darkText : softText, fontWeight: FontWeight.w900, fontSize: 15)),
            Text('${a.type} | مستوى ${a.level}${a.active ? '' : ' | موقوف'}', style: const TextStyle(color: softText, fontWeight: FontWeight.w700, fontSize: 12)),
          ])),
          Text(money(bal), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          IconButton(onPressed: () => editAccount(a), icon: const Icon(Icons.more_vert_rounded, color: softText)),
        ]),
      ),
    );
  }

  Future<void> editAccount(Account account) async {
    final name = TextEditingController(text: account.name);
    bool active = account.active;

    await showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(builder: (context, setD) => AlertDialog(
        title: Text('تعديل ${account.code}'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: fieldDec('اسم الحساب', Icons.edit_rounded)),
          const SizedBox(height: 8),
          SwitchListTile(
            value: active,
            onChanged: (v) => setD(() => active = v),
            title: const Text('الحساب فعال'),
            subtitle: const Text('إيقاف الحساب يمنع استخدامه دون حذف حركاته'),
          ),
          const SizedBox(height: 6),
          const Text('الحذف آمن: لن يتم حذف حساب له حركات أو حسابات فرعية.', style: TextStyle(color: softText, fontWeight: FontWeight.w700)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton.icon(
            onPressed: () async {
              final msg = await store.safeDeleteAccount(account);
              if (!mounted) return;
              if (msg != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context);
              setState(() {});
              widget.onChanged();
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('حذف'),
          ),
          FilledButton(onPressed: () async {
            await store.updateAccount(account, name: name.text, active: active);
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {});
            widget.onChanged();
          }, child: const Text('حفظ')),
        ],
      )),
    ));
  }

  Future<void> addAccount() async {
    final name = TextEditingController();
    String type = 'أصول';
    Account? parent;
    String suggested = store.nextAccountCode(type: type);

    await showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(builder: (context, setD) {
        final parents = store.accounts.where((a) => a.type == type && a.level <= 2).toList();
        void refreshCode() {
          suggested = store.nextAccountCode(type: type, parent: parent);
        }

        return AlertDialog(
          title: const Text('فتح حساب ذكي'),
          content: SingleChildScrollView(child: Column(children: [
            DropdownButtonFormField<String>(
              value: type,
              items: ['أصول','التزامات','رأس المال','إيرادات','مصاريف'].map((e)=>DropdownMenuItem(value:e, child:Text(e))).toList(),
              onChanged: (v) => setD(() {
                type = v ?? type;
                parent = null;
                refreshCode();
              }),
              decoration: fieldDec('نوع الحساب', Icons.category_rounded),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<Account?>(
              value: parent,
              items: [
                const DropdownMenuItem<Account?>(value: null, child: Text('بدون حساب أب')),
                ...parents.map((a) => DropdownMenuItem<Account?>(value: a, child: Text(a.display))),
              ],
              onChanged: (v) => setD(() {
                parent = v;
                refreshCode();
              }),
              decoration: fieldDec('الحساب الأب', Icons.account_tree_rounded),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primary.withOpacity(.08), borderRadius: BorderRadius.circular(16)),
              child: Text('الرقم المقترح تلقائيًا: $suggested', style: const TextStyle(color: primaryDark, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            TextField(controller: name, decoration: fieldDec('اسم الحساب', Icons.edit_rounded)),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await store.createAccount(name: name.text.trim(), type: type, parent: parent);
              if (!mounted) return;
              Navigator.pop(context);
              setState(() {});
              widget.onChanged();
            }, child: const Text('حفظ')),
          ],
        );
      }),
    ));
  }
}
