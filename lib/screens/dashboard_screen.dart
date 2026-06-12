import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreService.instance;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            kpi('عدد الحسابات', s.accounts.length.toString(), Icons.account_tree, primary),
            kpi('عدد القيود', s.entries.length.toString(), Icons.edit_note, purple),
            kpi('الصندوق', balanceByName('الصندوق'), Icons.wallet, success),
            kpi('البنك', balanceByName('البنك'), Icons.account_balance, primary),
            kpi('المصاريف', money(s.typeBalance('مصاريف')), Icons.trending_down, danger),
            kpi('رأس المال', money(s.typeBalance('رأس المال')), Icons.savings, purple),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: panel(24),
          child: const Text(
            'واجهة V2 محسّنة بطابع برنامج كمبيوتر: شريط جانبي، إعدادات شركة، سنة مالية، ترقيم سندات، رقم شيك، تقارير PDF وExcel، وأقسام واضحة.',
            style: TextStyle(color: darkText, height: 1.8, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  String balanceByName(String name) {
    final s = StoreService.instance;
    final list = s.accounts.where((a) => a.name == name);
    if (list.isEmpty) return '0';
    return money(s.balanceFor(list.first.id));
  }

  Widget kpi(String title, String value, IconData icon, Color color) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: panel(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: softText, fontWeight: FontWeight.w900)),
        FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 25, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
