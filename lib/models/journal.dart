class JournalLine {
  final String accountId;
  final String accountCode;
  final String accountName;
  final double debit;
  final double credit;
  final String note;

  JournalLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.debit,
    required this.credit,
    required this.note,
  });

  Map<String, dynamic> toJson() => {
        'accountId': accountId,
        'accountCode': accountCode,
        'accountName': accountName,
        'debit': debit,
        'credit': credit,
        'note': note,
      };

  factory JournalLine.fromJson(Map<String, dynamic> j) => JournalLine(
        accountId: j['accountId'] ?? '',
        accountCode: j['accountCode'] ?? '',
        accountName: j['accountName'] ?? '',
        debit: (j['debit'] ?? 0).toDouble(),
        credit: (j['credit'] ?? 0).toDouble(),
        note: j['note'] ?? '',
      );
}

class JournalEntry {
  final String id;
  final int number;
  final int fiscalYear;
  final int date;
  final String type;
  final String description;
  final String method;
  final String chequeNumber;
  final List<JournalLine> lines;

  JournalEntry({
    required this.id,
    required this.number,
    required this.fiscalYear,
    required this.date,
    required this.type,
    required this.description,
    required this.method,
    required this.chequeNumber,
    required this.lines,
  });

  double get totalDebit => lines.fold<double>(0, (s, l) => s + l.debit);
  double get totalCredit => lines.fold<double>(0, (s, l) => s + l.credit);
  bool get balanced => (totalDebit - totalCredit).abs() < .001;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'fiscalYear': fiscalYear,
        'date': date,
        'type': type,
        'description': description,
        'method': method,
        'chequeNumber': chequeNumber,
        'lines': lines.map((e) => e.toJson()).toList(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] ?? '',
        number: j['number'] ?? 0,
        fiscalYear: j['fiscalYear'] ?? DateTime.now().year,
        date: j['date'] ?? DateTime.now().millisecondsSinceEpoch,
        type: j['type'] ?? 'قيد يومية',
        description: j['description'] ?? '',
        method: j['method'] ?? '',
        chequeNumber: j['chequeNumber'] ?? '',
        lines: ((j['lines'] ?? []) as List)
            .map((e) => JournalLine.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
