import 'package:flutter/material.dart';
import '../widgets/theme.dart';
import '../services/store.dart';
import 'accounts_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'voucher_screen.dart';

enum AppTab { dashboard, accounts, receipts, payments, journal, reports, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab tab = AppTab.dashboard;
  final store = Store.instance;

  void refresh() => setState(() {});

  Widget page() {
    switch (tab) {
      case AppTab.dashboard:
        return DashboardScreen(
          openReceipts: () => setState(() => tab = AppTab.receipts),
          openPayments: () => setState(() => tab = AppTab.payments),
          openAccounts: () => setState(() => tab = AppTab.accounts),
        );
      case AppTab.accounts:
        return AccountsScreen(onChanged: refresh);
      case AppTab.receipts:
        return VoucherScreen(type: 'سند قبض', onSaved: refresh);
      case AppTab.payments:
        return VoucherScreen(type: 'سند صرف', onSaved: refresh);
      case AppTab.journal:
        return JournalScreen(onChanged: refresh);
      case AppTab.reports:
        return ReportsScreen(onChanged: refresh);
      case AppTab.settings:
        return SettingsScreen(onSaved: refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Column(children: [
        top(),
        Expanded(child: page()),
      ])),
      bottomNavigationBar: nav(),
    );
  }

  Widget top() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: softCard(28),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primary, lavender]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.account_balance, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(store.settings.companyName, style: const TextStyle(color: darkText, fontSize: 22, fontWeight: FontWeight.w900)),
          Text('السنة المالية ${store.settings.fiscalYear}', style: const TextStyle(color: softText, fontWeight: FontWeight.w800)),
        ])),
        IconButton(
          onPressed: () => setState(() => tab = AppTab.settings),
          icon: const Icon(Icons.settings, color: primary),
        ),
      ]),
    );
  }

  Widget nav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: softCard(26),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          navItem('الرئيسية', Icons.dashboard_rounded, AppTab.dashboard),
          navItem('الحسابات', Icons.account_tree_rounded, AppTab.accounts),
          navItem('قبض', Icons.south_west_rounded, AppTab.receipts),
          navItem('صرف', Icons.north_east_rounded, AppTab.payments),
          navItem('قيود', Icons.receipt_long_rounded, AppTab.journal),
          navItem('تقارير', Icons.bar_chart_rounded, AppTab.reports),
        ]),
      ),
    );
  }

  Widget navItem(String title, IconData icon, AppTab t) {
    final active = tab == t;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => tab = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: active ? 104 : 82,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? primary.withOpacity(.28) : Colors.transparent),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? primary : softText),
          const SizedBox(height: 3),
          Text(title, style: TextStyle(color: active ? primary : softText, fontWeight: FontWeight.w900, fontSize: 11)),
        ]),
      ),
    );
  }
}
