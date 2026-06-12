import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';
import 'accounts_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'voucher_screen.dart';

enum AppTab { dashboard, accounts, receipt, payment, journal, reports, settings }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab tab = AppTab.dashboard;
  final store = StoreService.instance;

  void refresh() => setState(() {});

  Widget currentPage() {
    switch (tab) {
      case AppTab.dashboard:
        return const DashboardScreen();
      case AppTab.accounts:
        return AccountsScreen(onChanged: refresh);
      case AppTab.receipt:
        return VoucherScreen(type: 'سند قبض', onSaved: refresh);
      case AppTab.payment:
        return VoucherScreen(type: 'سند صرف', onSaved: refresh);
      case AppTab.journal:
        return JournalScreen(onChanged: refresh);
      case AppTab.reports:
        return const ReportsScreen();
      case AppTab.settings:
        return SettingsScreen(onSaved: refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Row(
        children: [
          sideBar(),
          Expanded(child: Column(
            children: [
              topBar(),
              Expanded(child: currentPage()),
            ],
          )),
        ],
      )),
    );
  }

  Widget sideBar() {
    return Container(
      width: 112,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(8),
      decoration: panel(28),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00A8FF), primary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.account_balance, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          item('الرئيسية', Icons.dashboard, AppTab.dashboard),
          item('الحسابات', Icons.account_tree, AppTab.accounts),
          item('قبض', Icons.call_received, AppTab.receipt),
          item('صرف', Icons.call_made, AppTab.payment),
          item('قيود', Icons.edit_note, AppTab.journal),
          item('تقارير', Icons.bar_chart, AppTab.reports),
          const Spacer(),
          item('إعدادات', Icons.settings, AppTab.settings),
        ],
      ),
    );
  }

  Widget item(String title, IconData icon, AppTab t) {
    final active = tab == t;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => tab = t),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : softText, size: 22),
            Text(title, style: TextStyle(color: active ? Colors.white : softText, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget topBar() {
    return Container(
      height: 88,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: panel(26),
      child: Row(
        children: [
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store.settings.companyName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkText)),
              Text('السنة المالية ${store.settings.fiscalYear} | برنامج محاسبي محلي', style: const TextStyle(color: softText, fontWeight: FontWeight.w800)),
            ],
          )),
          summary('الأصول', money(store.typeBalance('أصول')), primary),
          summary('الالتزامات', money(store.typeBalance('التزامات')), danger),
          summary('الإيرادات', money(store.typeBalance('إيرادات')), success),
        ],
      ),
    );
  }

  Widget summary(String label, String value, Color color) {
    return Container(
      width: 115,
      margin: const EdgeInsetsDirectional.only(start: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: const TextStyle(color: softText, fontSize: 12, fontWeight: FontWeight.w900)),
        FittedBox(child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
