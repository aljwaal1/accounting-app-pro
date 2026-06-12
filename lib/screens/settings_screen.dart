import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onSaved;
  const SettingsScreen({super.key, required this.onSaved});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final store = StoreService.instance;
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
    phone = TextEditingController(text: s.companyPhone);
    address = TextEditingController(text: s.companyAddress);
    year = TextEditingController(text: s.fiscalYear.toString());
    receipt = TextEditingController(text: s.receiptStart.toString());
    payment = TextEditingController(text: s.paymentStart.toString());
    journal = TextEditingController(text: s.journalStart.toString());
    cheque = TextEditingController(text: s.chequeStart.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(14), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: panel(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('إعدادات الشركة والنظام', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkText)),
          const SizedBox(height: 14),
          field(company, 'اسم الشركة', Icons.business),
          const SizedBox(height: 10),
          field(phone, 'هاتف الشركة', Icons.phone),
          const SizedBox(height: 10),
          field(address, 'عنوان الشركة', Icons.location_on),
          const SizedBox(height: 18),
          const Text('الترقيم والسنة المالية', style: TextStyle(fontWeight: FontWeight.w900, color: darkText)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: field(year, 'السنة المالية', Icons.date_range, number: true)),
            const SizedBox(width: 10),
            Expanded(child: field(receipt, 'بداية سند القبض', Icons.call_received, number: true)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: field(payment, 'بداية سند الصرف', Icons.call_made, number: true)),
            const SizedBox(width: 10),
            Expanded(child: field(journal, 'بداية القيود', Icons.edit_note, number: true)),
          ]),
          const SizedBox(height: 10),
          field(cheque, 'بداية رقم الشيك', Icons.confirmation_number, number: true),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('حفظ الإعدادات'))),
        ]),
      )
    ]);
  }

  TextField field(TextEditingController c, String label, IconData icon, {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: inputDec(label, icon),
    );
  }

  Future<void> save() async {
    final s = store.settings;
    s.companyName = company.text.trim().isEmpty ? 'اسم الشركة' : company.text.trim();
    s.companyPhone = phone.text.trim();
    s.companyAddress = address.text.trim();
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
