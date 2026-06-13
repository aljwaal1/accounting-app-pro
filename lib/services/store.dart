import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/journal.dart';
import '../models/settings.dart';


class TrialBalanceRow {
  final Account account;
  final double debit;
  final double credit;

  TrialBalanceRow({required this.account, required this.debit, required this.credit});

  double get difference => debit - credit;
}

class Store {
  static final Store instance = Store._();
  Store._();

  AppSettings settings = AppSettings.defaults();
  List<Account> accounts = [];
  List<JournalEntry> entries = [];

  String id() => '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();

    final rawSettings = p.getString('smart_settings_v3');
    settings = rawSettings == null
        ? AppSettings.defaults()
        : AppSettings.fromJson(Map<String, dynamic>.from(jsonDecode(rawSettings)));

    final rawAccounts = p.getString('smart_accounts_v3');
    if (rawAccounts == null) {
      accounts = seedAccounts();
      settings.defaultCashId = findByName('الصندوق الرئيسي')?.id ?? '';
      settings.defaultBankId = findByName('البنك الرئيسي')?.id ?? '';
      settings.defaultCustomersParentId = findByCode('103')?.id ?? '';
      settings.defaultSuppliersParentId = findByCode('201')?.id ?? '';
      await save();
    } else {
      accounts = (jsonDecode(rawAccounts) as List)
          .map((e) => Account.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawEntries = p.getString('smart_entries_v3');
    if (rawEntries != null) {
      entries = (jsonDecode(rawEntries) as List)
          .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('smart_settings_v3', jsonEncode(settings.toJson()));
    await p.setString('smart_accounts_v3', jsonEncode(accounts.map((e) => e.toJson()).toList()));
    await p.setString('smart_entries_v3', jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Map<String, dynamic> backupMap() => {
        'app': 'المحاسب الذكي V3',
        'version': 3,
        'createdAt': DateTime.now().toIso8601String(),
        'settings': settings.toJson(),
        'accounts': accounts.map((e) => e.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  String backupJson() => const JsonEncoder.withIndent('  ').convert(backupMap());

  Future<void> importBackupJson(String raw) async {
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    final importedAccounts = ((data['accounts'] ?? []) as List)
        .map((e) => Account.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final importedEntries = ((data['entries'] ?? []) as List)
        .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    if (importedAccounts.isEmpty) {
      throw const FormatException('ملف النسخة الاحتياطية لا يحتوي على حسابات.');
    }
    settings = AppSettings.fromJson(Map<String, dynamic>.from(data['settings'] ?? {}));
    accounts = importedAccounts;
    entries = importedEntries;
    await save();
  }

  Account? findByName(String name) {
    try {
      return accounts.firstWhere((a) => a.name == name);
    } catch (_) {
      return null;
    }
  }

  Account? findByCode(String code) {
    try {
      return accounts.firstWhere((a) => a.code == code);
    } catch (_) {
      return null;
    }
  }

  Account? byId(String id) {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Account> postingAccounts() => accounts.where((a) => a.active && !accountHasChildren(a.id)).toList();
  List<Account> cashBankAccounts() => accounts.where((a) => a.active && (a.name.contains('صندوق') || a.name.contains('بنك') || a.code.startsWith('101'))).toList();

  int nextDocNumber(String type) {
    final year = settings.fiscalYear;
    final nums = entries.where((e) => e.fiscalYear == year && e.type == type).map((e) => e.number).toList();
    if (nums.isNotEmpty) return nums.reduce(max) + 1;
    if (type == 'سند قبض') return settings.receiptStart;
    if (type == 'سند صرف') return settings.paymentStart;
    return settings.journalStart;
  }

  int nextChequeNumber() {
    final nums = entries.map((e) => int.tryParse(e.chequeNumber) ?? 0).where((n) => n > 0).toList();
    if (nums.isEmpty) return settings.chequeStart;
    return nums.reduce(max) + 1;
  }

  String nextAccountCode({required String type, Account? parent}) {
    if (parent != null) {
      final children = accounts.where((a) => a.parentId == parent.id).toList();
      final nums = children
          .map((a) => int.tryParse(a.code.replaceFirst(parent.code, '')) ?? 0)
          .where((n) => n > 0)
          .toList();
      final next = nums.isEmpty ? 1 : nums.reduce(max) + 1;
      return '${parent.code}${next.toString().padLeft(3, '0')}';
    }

    final prefix = switch (type) {
      'أصول' => '1',
      'التزامات' => '2',
      'رأس المال' => '3',
      'إيرادات' => '4',
      'مصاريف' => '5',
      _ => '9',
    };

    final same = accounts.where((a) => a.code.startsWith(prefix) && a.level == 2).toList();
    final nums = same.map((a) => int.tryParse(a.code) ?? 0).toList();
    final next = nums.isEmpty ? int.parse('${prefix}01') : nums.reduce(max) + 1;
    return next.toString();
  }

  Future<Account> createAccount({
    required String name,
    required String type,
    Account? parent,
  }) async {
    final code = nextAccountCode(type: type, parent: parent);
    final a = Account(
      id: id(),
      code: code,
      name: name,
      type: parent?.type ?? type,
      parentId: parent?.id ?? '',
      level: parent == null ? 2 : parent.level + 1,
    );
    accounts.add(a);
    accounts.sort((a, b) => a.code.compareTo(b.code));
    await save();
    return a;
  }

  bool accountHasChildren(String accountId) => accounts.any((a) => a.parentId == accountId);
  bool accountHasMovement(String accountId) => entries.any((e) => e.lines.any((l) => l.accountId == accountId));

  Future<void> updateAccount(Account account, {required String name, bool? active}) async {
    account.name = name.trim().isEmpty ? account.name : name.trim();
    if (active != null) account.active = active;
    await save();
  }

  Future<String?> safeDeleteAccount(Account account) async {
    if (account.level == 1) return 'لا يمكن حذف حساب رئيسي من المستوى الأول.';
    if (accountHasChildren(account.id)) return 'لا يمكن حذف الحساب لأنه يحتوي على حسابات فرعية.';
    if (accountHasMovement(account.id)) return 'لا يمكن حذف الحساب لأنه مرتبط بقيود. يمكنك إيقافه بدل الحذف.';
    accounts.removeWhere((a) => a.id == account.id);
    await save();
    return null;
  }

  Future<void> addEntry(JournalEntry e) async {
    entries.add(e);
    await save();
  }

  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    await save();
  }

  List<JournalEntry> entriesBetween({DateTime? from, DateTime? to}) {
    final start = from == null ? null : DateTime(from.year, from.month, from.day).millisecondsSinceEpoch;
    final end = to == null ? null : DateTime(to.year, to.month, to.day, 23, 59, 59).millisecondsSinceEpoch;
    return entries.where((e) {
      if (start != null && e.date < start) return false;
      if (end != null && e.date > end) return false;
      return true;
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  List<String> descendantIds(String accountId) {
    final ids = <String>{accountId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final a in accounts) {
        if (a.parentId.isNotEmpty && ids.contains(a.parentId) && ids.add(a.id)) {
          changed = true;
        }
      }
    }
    return ids.toList();
  }

  double debitFor(String accountId, {DateTime? from, DateTime? to, bool includeChildren = false}) {
    final ids = includeChildren ? descendantIds(accountId).toSet() : <String>{accountId};
    return entriesBetween(from: from, to: to)
        .expand((e) => e.lines)
        .where((l) => ids.contains(l.accountId))
        .fold<double>(0, (s, l) => s + l.debit);
  }

  double creditFor(String accountId, {DateTime? from, DateTime? to, bool includeChildren = false}) {
    final ids = includeChildren ? descendantIds(accountId).toSet() : <String>{accountId};
    return entriesBetween(from: from, to: to)
        .expand((e) => e.lines)
        .where((l) => ids.contains(l.accountId))
        .fold<double>(0, (s, l) => s + l.credit);
  }

  double balanceFor(String accountId, {DateTime? from, DateTime? to, bool includeChildren = false}) {
    final a = byId(accountId);
    final d = debitFor(accountId, from: from, to: to, includeChildren: includeChildren);
    final c = creditFor(accountId, from: from, to: to, includeChildren: includeChildren);
    if (a == null) return d - c;
    if (a.type == 'التزامات' || a.type == 'رأس المال' || a.type == 'إيرادات') return c - d;
    return d - c;
  }

  List<TrialBalanceRow> trialBalanceRows({required String level, DateTime? from, DateTime? to}) {
    final List<Account> list;
    if (level == 'مستوى أول') {
      list = accounts.where((a) => a.active && a.level == 1).toList();
    } else if (level == 'مستوى ثاني') {
      list = accounts.where((a) => a.active && a.level == 2).toList();
    } else {
      list = postingAccounts();
    }
    list.sort((a, b) => a.code.compareTo(b.code));

    final aggregate = level != 'تفصيلي';
    return list.map((a) => TrialBalanceRow(
      account: a,
      debit: debitFor(a.id, from: from, to: to, includeChildren: aggregate),
      credit: creditFor(a.id, from: from, to: to, includeChildren: aggregate),
    )).where((r) => r.debit != 0 || r.credit != 0 || level != 'تفصيلي').toList();
  }

  double typeBalance(String type) {
    return postingAccounts().where((a) => a.type == type).fold<double>(0, (s, a) => s + balanceFor(a.id));
  }

  List<Account> seedAccounts() {
    String nid() => id();

    final assets = nid();
    final cashBanks = nid();
    final cash = nid();
    final bank = nid();
    final customers = nid();

    final liabilities = nid();
    final suppliers = nid();

    final equity = nid();
    final capital = nid();

    final revenue = nid();
    final sales = nid();

    final expenses = nid();
    final generalExp = nid();

    return [
      Account(id: assets, code: '1', name: 'الأصول', type: 'أصول', parentId: '', level: 1),
      Account(id: cashBanks, code: '101', name: 'النقدية والبنوك', type: 'أصول', parentId: assets, level: 2),
      Account(id: cash, code: '101001', name: 'الصندوق الرئيسي', type: 'أصول', parentId: cashBanks, level: 3),
      Account(id: bank, code: '101002', name: 'البنك الرئيسي', type: 'أصول', parentId: cashBanks, level: 3),
      Account(id: customers, code: '103', name: 'العملاء', type: 'أصول', parentId: assets, level: 2),

      Account(id: liabilities, code: '2', name: 'الالتزامات', type: 'التزامات', parentId: '', level: 1),
      Account(id: suppliers, code: '201', name: 'الموردون', type: 'التزامات', parentId: liabilities, level: 2),

      Account(id: equity, code: '3', name: 'حقوق الملكية', type: 'رأس المال', parentId: '', level: 1),
      Account(id: capital, code: '301', name: 'رأس المال', type: 'رأس المال', parentId: equity, level: 2),

      Account(id: revenue, code: '4', name: 'الإيرادات', type: 'إيرادات', parentId: '', level: 1),
      Account(id: sales, code: '401', name: 'إيرادات المبيعات', type: 'إيرادات', parentId: revenue, level: 2),

      Account(id: expenses, code: '5', name: 'المصاريف', type: 'مصاريف', parentId: '', level: 1),
      Account(id: generalExp, code: '501', name: 'مصاريف عامة', type: 'مصاريف', parentId: expenses, level: 2),
    ];
  }
}
