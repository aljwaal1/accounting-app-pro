import 'package:flutter/material.dart';
import '../services/store.dart';
import '../services/export_service.dart';
import '../widgets/theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const SettingsScreen({super.key, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final store = Store.instance;
  late TextEditingController company;
  late TextEditingController phone;
  late TextEditingController address;
  late TextEditingController year;
  late TextEditingController receipt;
  late TextEditingController payment;
  late TextEditingController journal;
  late TextEditingController cheque;

  @override
  void initState() {
    super.initState();
    final s = store.settings;
    company = TextEditingController(text: s.companyName);
    phone = TextEditingController(text: s.phone);
    address = TextEditingController(text: s.address);
    year = TextEditingController(text: s.fiscalYear.toString());
    receipt = TextEditingController(text: s.receiptStart.toString());
    payment = TextEditingController(text: s.paymentStart.toString());
    journal = TextEditingController(text: s.journalStart.toString());
    cheque = TextEditingController(text: s.chequeStart.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إعدادات الشركة', style: TextStyle(color: darkText, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: company, decoration: fieldDec('اسم الشركة', Icons.business_rounded)),
          const SizedBox(height: 10),
          TextField(controller: phone, decoration: fieldDec('الهاتف', Icons.phone_rounded)),
          const SizedBox(height: 10),
          TextField(controller: address, decoration: fieldDec('العنوان', Icons.location_on_rounded)),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('الترقيم والسنة المالية', style: TextStyle(color: darkText, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: year, keyboardType: TextInputType.number, decoration: fieldDec('السنة المالية', Icons.date_range_rounded)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: receipt, keyboardType: TextInputType.number, decoration: fieldDec('بداية القبض', Icons.south_west_rounded))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: payment, keyboardType: TextInputType.number, decoration: fieldDec('بداية الصرف', Icons.north_east_rounded))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: journal, keyboardType: TextInputType.number, decoration: fieldDec('بداية القيود', Icons.receipt_long_rounded))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: cheque, keyboardType: TextInputType.number, decoration: fieldDec('بداية الشيك', Icons.confirmation_number_rounded))),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_rounded), label: const Text('حفظ الإعدادات'))),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: softCard(26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('النسخ الاحتياطي والاستيراد', style: TextStyle(color: darkText, fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('التصدير يحفظ ملف JSON تستطيع مشاركته أو الاحتفاظ به. الاستيراد يتم بلصق محتوى ملف النسخة الاحتياطية.', style: TextStyle(color: softText, fontWeight: FontWeight.w700, height: 1.5)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FilledButton.icon(onPressed: ExportService.shareBackupJson, icon: const Icon(Icons.backup_rounded), label: const Text('تصدير'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: importBackup, icon: const Icon(Icons.restore_rounded), label: const Text('استيراد'))),
          ]),
        ]),
      ),
    ]);
  }

  Future<void> importBackup() async {
    final raw = TextEditingController();
    await showDialog(context: context, builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('استيراد نسخة احتياطية'),
        content: TextField(
          controller: raw,
          minLines: 6,
          maxLines: 10,
          decoration: fieldDec('الصق محتوى ملف JSON هنا', Icons.data_object_rounded),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () async {
            try {
              await store.importBackupJson(raw.text.trim());
              if (!mounted) return;
              Navigator.pop(context);
              widget.onSaved();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استيراد النسخة الاحتياطية')));
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر الاستيراد. تأكد أن النص من ملف النسخة الاحتياطية الصحيح.')));
            }
          }, child: const Text('استيراد')),
        ],
      ),
    ));
  }

  Future<void> save() async {
    final s = store.settings;
    s.companyName = company.text.trim().isEmpty ? 'اسم الشركة' : company.text.trim();
    s.phone = phone.text.trim();
    s.address = address.text.trim();
    s.fiscalYear = int.tryParse(year.text) ?? DateTime.now().year;
    s.receiptStart = int.tryParse(receipt.text) ?? 1;
    s.paymentStart = int.tryParse(payment.text) ?? 1;
    s.journalStart = int.tryParse(journal.text) ?? 1;
    s.chequeStart = int.tryParse(cheque.text) ?? 1;
    await store.save();
    widget.onSaved();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
  }
}
