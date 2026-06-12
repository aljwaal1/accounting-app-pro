import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/app_settings.dart';
import '../models/journal_entry.dart';

class StoreService {
  static final StoreService instance = StoreService._();
  StoreService._();

  AppSettings settings = AppSettings.defaults();
  List<Account> accounts = [];
  List<JournalEntry> entries = [];

  String newId() => '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();

    final s = p.getString('settings_v2');
    settings = s == null ? AppSettings.defaults() : AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(s)));

    final a = p.getString('accounts_v2');
    if (a == null) {
      accounts = seedAccounts();
      await save();
    } else {
      accounts = (jsonDecode(a) as List).map((x) => Account.fromJson(Map<String, dynamic>.from(x))).toList();
    }

    final e = p.getString('entries_v2');
    if (e != null) {
      entries = (jsonDecode(e) as List).map((x) => JournalEntry.fromJson(Map<String, dynamic>.from(x))).toList();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('settings_v2', jsonEncode(settings.toJson()));
    await p.setString('accounts_v2', jsonEncode(accounts.map((e) => e.toJson()).toList()));
    await p.setString('entries_v2', jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Account? accountById(String id) {
    try { return accounts.firstWhere((a) => a.id == id); } catch (_) { return null; }
  }

  List<Account> postingAccounts() => accounts.where((a) => a.level >= 2 && a.active).toList();

  int nextNumber(String type) {
    final year = settings.fiscalYear;
    final same = entries.where((e) => e.type == type && e.fiscalYear == year).map((e) => e.number).toList();
    if (same.isEmpty) {
      if (type == 'سند قبض') return settings.receiptStart;
      if (type == 'سند صرف') return settings.paymentStart;
      return settings.journalStart;
    }
    return same.reduce(max) + 1;
  }

  int nextChequeNumber() {
    final nums = entries.map((e) => int.tryParse(e.chequeNumber) ?? 0).where((n) => n > 0).toList();
    if (nums.isEmpty) return settings.chequeStart;
    return nums.reduce(max) + 1;
  }

  Future<void> addAccount(Account a) async {
    accounts.add(a);
    accounts.sort((a, b) => a.code.compareTo(b.code));
    await save();
  }

  Future<void> addEntry(JournalEntry e) async {
    entries.add(e);
    await save();
  }

  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    await save();
  }

  double debitFor(String accountId) => entries.expand((e) => e.lines).where((l) => l.accountId == accountId).fold(0, (s, l) => s + l.debit);
  double creditFor(String accountId) => entries.expand((e) => e.lines).where((l) => l.accountId == accountId).fold(0, (s, l) => s + l.credit);

  double balanceFor(String accountId) {
    final a = accountById(accountId);
    final d = debitFor(accountId);
    final c = creditFor(accountId);
    if (a == null) return d - c;
    if (a.type == 'التزامات' || a.type == 'رأس المال' || a.type == 'إيرادات') return c - d;
    return d - c;
  }

  double typeBalance(String type) {
    return accounts.where((a) => a.type == type && a.level >= 2).fold(0, (s, a) => s + balanceFor(a.id));
  }

  List<Account> seedAccounts() {
    String id() => newId();
    return [
      Account(id: id(), code: '1', name: 'الأصول', type: 'أصول', parentId: '', level: 1),
      Account(id: id(), code: '101', name: 'الصندوق', type: 'أصول', parentId: '1', level: 2),
      Account(id: id(), code: '102', name: 'البنك', type: 'أصول', parentId: '1', level: 2),
      Account(id: id(), code: '103', name: 'العملاء', type: 'أصول', parentId: '1', level: 2),
      Account(id: id(), code: '104', name: 'المخزون', type: 'أصول', parentId: '1', level: 2),

      Account(id: id(), code: '2', name: 'الالتزامات', type: 'التزامات', parentId: '', level: 1),
      Account(id: id(), code: '201', name: 'الموردون', type: 'التزامات', parentId: '2', level: 2),
      Account(id: id(), code: '202', name: 'أوراق دفع', type: 'التزامات', parentId: '2', level: 2),

      Account(id: id(), code: '3', name: 'حقوق الملكية', type: 'رأس المال', parentId: '', level: 1),
      Account(id: id(), code: '301', name: 'رأس المال', type: 'رأس المال', parentId: '3', level: 2),

      Account(id: id(), code: '4', name: 'الإيرادات', type: 'إيرادات', parentId: '', level: 1),
      Account(id: id(), code: '401', name: 'إيرادات المبيعات', type: 'إيرادات', parentId: '4', level: 2),

      Account(id: id(), code: '5', name: 'المصاريف', type: 'مصاريف', parentId: '', level: 1),
      Account(id: id(), code: '501', name: 'مصاريف عامة', type: 'مصاريف', parentId: '5', level: 2),
      Account(id: id(), code: '502', name: 'مصاريف إدارية', type: 'مصاريف', parentId: '5', level: 2),
    ];
  }
}
