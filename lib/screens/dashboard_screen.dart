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
    final revenue = s.typeBalance('إيرادات');
    final expenses = s.typeBalance('مصاريف');
    final net = revenue - expenses;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(child: action('سند قبض', Icons.south_west_rounded, mint, openReceipts)),
        const SizedBox(width: 10),
        Expanded(child: action('سند صرف', Icons.north_east_rounded, coral, openPayments)),
      ]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: action('حساب جديد ذكي', Icons.add_business_rounded, primary, openAccounts)),
      const SizedBox(height: 14),
      netProfitCard(net),
      const SizedBox(height: 14),
      Wrap(spacing: 10, runSpacing: 10, children: [
        kpi('الأصول', money(s.typeBalance('أصول')), Icons.account_balance_wallet, primary),
        kpi('الالتزامات', money(s.typeBalance('التزامات')), Icons.warning_amber_rounded, amber),
        kpi('رأس المال', money(s.typeBalance('رأس المال')), Icons.savings_rounded, lavender),
        kpi('الإيرادات', money(revenue), Icons.trending_up_rounded, mint),
        kpi('المصاريف', money(expenses), Icons.trending_down_rounded, coral),
        kpi('عدد القيود', s.entries.length.toString(), Icons.receipt_long_rounded, primaryDark),
      ]),
    ]);
  }

  Widget netProfitCard(double net) {
    final positive = net >= 0;
    final color = positive ? creditColor : debitColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: brandGradient(),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: primary.withOpacity(.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle),
          child: Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('صافي نتيجة النشاط', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('${positive ? '' : '-'}${money(net.abs())}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(12)),
          child: Text(positive ? 'ربح' : 'خسارة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ]),
    );
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
