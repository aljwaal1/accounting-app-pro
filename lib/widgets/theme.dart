import 'package:flutter/material.dart';

const bg = Color(0xFFF6FAFD);
const cardColor = Color(0xFFFFFFFF);
const primary = Color(0xFF4C8FD7);
const primaryDark = Color(0xFF245C9A);
const mint = Color(0xFF4FBF9F);
const coral = Color(0xFFE77A7A);
const amber = Color(0xFFF2B85B);
const lavender = Color(0xFF8E7BEF);
const darkText = Color(0xFF20364D);
const softText = Color(0xFF72879B);
const line = Color(0xFFE3EEF7);

String money(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

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

BoxDecoration softCard([double radius = 26]) => BoxDecoration(
  color: cardColor,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: line),
  boxShadow: [
    BoxShadow(
      color: const Color(0xFF7AA7CA).withOpacity(.10),
      blurRadius: 26,
      offset: const Offset(0, 12),
    )
  ],
);

InputDecoration fieldDec(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)),
);

Widget emptyState(String text) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: softText, fontWeight: FontWeight.w800, height: 1.8),
    ),
  ),
);
