class AppSettings {
  String companyName;
  String companyPhone;
  String companyAddress;
  int fiscalYear;
  int receiptStart;
  int paymentStart;
  int journalStart;
  int chequeStart;

  AppSettings({
    required this.companyName,
    required this.companyPhone,
    required this.companyAddress,
    required this.fiscalYear,
    required this.receiptStart,
    required this.paymentStart,
    required this.journalStart,
    required this.chequeStart,
  });

  Map<String, dynamic> toJson() => {
    'companyName': companyName,
    'companyPhone': companyPhone,
    'companyAddress': companyAddress,
    'fiscalYear': fiscalYear,
    'receiptStart': receiptStart,
    'paymentStart': paymentStart,
    'journalStart': journalStart,
    'chequeStart': chequeStart,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    companyName: j['companyName'] ?? 'اسم الشركة',
    companyPhone: j['companyPhone'] ?? '',
    companyAddress: j['companyAddress'] ?? '',
    fiscalYear: j['fiscalYear'] ?? DateTime.now().year,
    receiptStart: j['receiptStart'] ?? 1,
    paymentStart: j['paymentStart'] ?? 1,
    journalStart: j['journalStart'] ?? 1,
    chequeStart: j['chequeStart'] ?? 1,
  );

  factory AppSettings.defaults() => AppSettings(
    companyName: 'اسم الشركة',
    companyPhone: '',
    companyAddress: '',
    fiscalYear: DateTime.now().year,
    receiptStart: 1,
    paymentStart: 1,
    journalStart: 1,
    chequeStart: 1,
  );
}
