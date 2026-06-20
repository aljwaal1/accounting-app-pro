import 'package:flutter/material.dart';

/// ====== هوية التطبيق البصرية (إعادة تصميم) ======
/// لوحة ألوان مالية هادئة وواضحة: زمردي/كحلي أساسي + ذهبي للتمييز،
/// أخضر للمقبوضات/الدائن وأحمر مرجاني للمصروفات/المدين الخطر،
/// مع خلفية رمادية فاتحة هادئة تقلّل إجهاد العين أثناء العمل المحاسبي الطويل.

// الأساسي: زمردي كحلي عميق - يعكس الثقة والاستقرار المالي
const primary = Color(0xFF0E7C66);
const primaryDark = Color(0xFF0B5C4C);
const primaryLight = Color(0xFFE3F3EE);

// الذهبي: للعناصر المميزة (الأرصدة الختامية، التنبيهات الإيجابية)
const gold = Color(0xFFC79A2E);
const goldLight = Color(0xFFFBF1DC);

// دلالات محاسبية: مدين / دائن
const debitColor = Color(0xFFCC4B4B); // مدين / مصروف / صرف
const creditColor = Color(0xFF1E9E6B); // دائن / إيراد / قبض

// ألوان مساعدة لتمييز فئات الحسابات
const mint = Color(0xFF1E9E6B);
const coral = Color(0xFFCC4B4B);
const amber = Color(0xFFCE8A1E);
const lavender = Color(0xFF5B5FCF);

// نصوص وخلفيات
const bg = Color(0xFFF3F6F6);
const cardColor = Color(0xFFFFFFFF);
const darkText = Color(0xFF152722);
const softText = Color(0xFF6B7C78);
const line = Color(0xFFE2E9E7);

/// تنسيق المبالغ مع فاصل الآلاف لسهولة القراءة (مثال: 12,500)
String money(double v) {
  final isWhole = v == v.roundToDouble();
  final fixed = isWhole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final neg = fixed.startsWith('-');
  final clean = neg ? fixed.substring(1) : fixed;
  final parts = clean.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) buf.write(',');
    buf.write(intPart[i]);
  }
  final result = buf.toString() + (parts.length > 1 ? '.${parts[1]}' : '');
  return neg ? '-$result' : result;
}

String dateText(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)}';
}

String dateTimeText(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}/${two(d.month)}/${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

BoxDecoration softCard([double radius = 24]) => BoxDecoration(
  color: cardColor,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: line),
  boxShadow: [
    BoxShadow(
      color: primaryDark.withOpacity(.07),
      blurRadius: 22,
      offset: const Offset(0, 10),
    ),
  ],
);

/// بطاقة بحدّ علوي ملوّن (تُستخدم لتمييز نوع الحساب أو نوع السند بصريًا)
BoxDecoration accentCard(Color accent, [double radius = 24]) => BoxDecoration(
  color: cardColor,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: line),
  boxShadow: [
    BoxShadow(color: accent.withOpacity(.10), blurRadius: 22, offset: const Offset(0, 10)),
  ],
);

LinearGradient brandGradient() => const LinearGradient(
  colors: [primary, primaryDark],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

InputDecoration fieldDec(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon, color: softText),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary, width: 1.4)),
  labelStyle: const TextStyle(color: softText, fontWeight: FontWeight.w700),
);

Widget emptyState(String text, [IconData icon = Icons.inbox_rounded]) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: primaryLight, shape: BoxShape.circle),
        child: Icon(icon, color: primary, size: 34),
      ),
      const SizedBox(height: 14),
      Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: softText, fontWeight: FontWeight.w800, height: 1.8),
      ),
    ]),
  ),
);

/// رقعة صغيرة ملوّنة لعرض نوع الحساب أو حالته
Widget tag(String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
  child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11.5)),
);

/// لون مميّز لكل نوع حساب (يُستخدم في عدة شاشات للحفاظ على التناسق)
Color colorForType(String type) {
  switch (type) {
    case 'أصول':
      return primary;
    case 'مصاريف':
      return coral;
    case 'إيرادات':
      return mint;
    case 'التزامات':
      return amber;
    default:
      return lavender;
  }
}
