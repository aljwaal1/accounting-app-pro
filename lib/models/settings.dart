class AppSettings {
  String companyName;
  String phone;
  String address;
  int fiscalYear;
  int receiptStart;
  int paymentStart;
  int journalStart;
  int chequeStart;
  String defaultCashId;
  String defaultBankId;
  String defaultCustomersParentId;
  String defaultSuppliersParentId;

  AppSettings({
    required this.companyName,
    required this.phone,
    required this.address,
    required this.fiscalYear,
    required this.receiptStart,
    required this.paymentStart,
    required this.journalStart,
    required this.chequeStart,
    required this.defaultCashId,
    required this.defaultBankId,
    required this.defaultCustomersParentId,
    required this.defaultSuppliersParentId,
  });

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'phone': phone,
        'address': address,
        'fiscalYear': fiscalYear,
        'receiptStart': receiptStart,
        'paymentStart': paymentStart,
        'journalStart': journalStart,
        'chequeStart': chequeStart,
        'defaultCashId': defaultCashId,
        'defaultBankId': defaultBankId,
        'defaultCustomersParentId': defaultCustomersParentId,
        'defaultSuppliersParentId': defaultSuppliersParentId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        companyName: j['companyName'] ?? 'اسم الشركة',
        phone: j['phone'] ?? '',
        address: j['address'] ?? '',
        fiscalYear: j['fiscalYear'] ?? DateTime.now().year,
        receiptStart: j['receiptStart'] ?? 1,
        paymentStart: j['paymentStart'] ?? 1,
        journalStart: j['journalStart'] ?? 1,
        chequeStart: j['chequeStart'] ?? 1,
        defaultCashId: j['defaultCashId'] ?? '',
        defaultBankId: j['defaultBankId'] ?? '',
        defaultCustomersParentId: j['defaultCustomersParentId'] ?? '',
        defaultSuppliersParentId: j['defaultSuppliersParentId'] ?? '',
      );

  factory AppSettings.defaults() => AppSettings(
        companyName: 'اسم الشركة',
        phone: '',
        address: '',
        fiscalYear: DateTime.now().year,
        receiptStart: 1,
        paymentStart: 1,
        journalStart: 1,
        chequeStart: 1,
        defaultCashId: '',
        defaultBankId: '',
        defaultCustomersParentId: '',
        defaultSuppliersParentId: '',
      );
}
