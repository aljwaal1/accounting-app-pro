import 'package:flutter/material.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback openReceipts;
  final VoidCallback openPayments;
  final VoidCallback openAccounts;

  const DashboardScreen({
    super.key,
    required this.openReceipts,
    required this.openPayments,
    required this.openAccounts,
  });

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(child: action('سند قبض', Icons.south_west_rounded, mint, openReceipts)),
        const SizedBox(width: 10),
        Expanded(child: action('سند صرف', Icons.north_east_rounded, coral, openPayments)),
      ]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: action('حساب جديد ذكي', Icons.add_business_rounded, primary, openAccounts)),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        kpi('الأصول', money(s.typeBalance('أصول')), Icons.account_balance_wallet, primary),
        kpi('الالتزامات', money(s.typeBalance('التزامات')), Icons.warning_amber_rounded, coral),
        kpi('رأس المال', money(s.typeBalance('رأس المال')), Icons.savings_rounded, lavender),
        kpi('الإيرادات', money(s.typeBalance('إيرادات')), Icons.trending_up_rounded, mint),
        kpi('المصاريف', money(s.typeBalance('مصاريف')), Icons.trending_down_rounded, amber),
        kpi('عدد القيود', s.entries.length.toString(), Icons.receipt_long_rounded, primaryDark),
      ]),
    ]);
  }

  Widget action(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(24),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withOpacity(.14), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: darkText, fontWeight: FontWeight.w900, fontSize: 16))),
          const Icon(Icons.arrow_back_ios_new_rounded, color: softText, size: 16),
        ]),
      ),
    );
  }

  Widget kpi(String title, String value, IconData icon, Color color) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(15),
      decoration: softCard(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: softText, fontWeight: FontWeight.w900, fontSize: 13)),
        FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 23, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
