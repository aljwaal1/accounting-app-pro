import 'package:flutter/material.dart';
import '../services/erp_store.dart';
import '../widgets/theme.dart';

class ErpPurchasesScreen extends StatelessWidget {
  final ErpStore erp;
  const ErpPurchasesScreen({super.key, required this.erp});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: erp,
      builder: (context, _) {
        final docs = erp.purchases.reversed.toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المشتريات',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: darkText),
                        ),
                        Text(
                          'التوريد، فواتير الموردين، والسداد',
                          style: TextStyle(color: softText.withOpacity(.9), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _editor(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('فاتورة شراء'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? emptyState('لا توجد فواتير شراء بعد', Icons.local_shipping_outlined)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _card(context, docs[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, ErpDocument d) {
    final party = erp.party(d.partyId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: softCard(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: lavender.withOpacity(.10), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.local_shipping_outlined, color: lavender),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فاتورة شراء #${d.number}', style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(party?.name ?? 'مورد', style: const TextStyle(color: softText, fontWeight: FontWeight.w700)),
                Text(
                  '${d.lines.length} أصناف • ${dateText(d.date)}',
                  style: const TextStyle(color: softText, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(d.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              if (d.due > 0)
                Text(
                  'متبقي ${money(d.due)}',
                  style: const TextStyle(color: coral, fontWeight: FontWeight.w800, fontSize: 10),
                ),
              if (d.due > 0)
                TextButton(
                  onPressed: () => _pay(context, d),
                  child: const Text('سداد'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pay(BuildContext context, ErpDocument d) async {
    final controller = TextEditingController(text: d.due.toStringAsFixed(2));
    final value = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سداد للمورد', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: fieldDec('المبلغ', Icons.payments_outlined),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text) ?? 0),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('تسجيل السداد'),
            ),
          ],
        ),
      ),
    );
    if (value != null && value > 0) await erp.payPurchase(d, value);
  }

  Future<void> _editor(BuildContext context) async {
    if (erp.suppliers.isEmpty || erp.products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف موردًا ومنتجًا أولًا')));
      return;
    }

    String supplierId = erp.suppliers.first.id;
    final qty = <String, double>{};
    final cost = <String, double>{for (final p in erp.products) p.id: p.cost};
    final discount = TextEditingController(text: '0');
    final fee = TextEditingController(text: '0');
    final paid = TextEditingController(text: '0');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final selected = erp.products.where((p) => (qty[p.id] ?? 0) > 0).toList();
          final subtotal = selected.fold<double>(0, (s, p) => s + (qty[p.id] ?? 0) * (cost[p.id] ?? p.cost));
          final discountValue = double.tryParse(discount.text) ?? 0;
          final feeRate = double.tryParse(fee.text) ?? 0;
          final taxable = (subtotal - discountValue).clamp(0.0, double.infinity).toDouble();
          final total = taxable * (1 + feeRate / 100);

          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('فاتورة شراء', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: supplierId,
                      decoration: fieldDec('المورد', Icons.local_shipping_outlined),
                      items: erp.suppliers
                          .map((e) => DropdownMenuItem<String>(value: e.id, child: Text(e.name)))
                          .toList(),
                      onChanged: (v) => supplierId = v ?? supplierId,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: erp.products.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                                      Text('${p.sku} • رصيد ${money(p.stock)}', style: const TextStyle(color: softText, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: TextFormField(
                                    initialValue: '0',
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setLocal(() => qty[p.id] = double.tryParse(v) ?? 0),
                                    decoration: const InputDecoration(labelText: 'كمية', isDense: true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 92,
                                  child: TextFormField(
                                    initialValue: p.cost.toStringAsFixed(2),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) => setLocal(() => cost[p.id] = double.tryParse(v) ?? p.cost),
                                    decoration: const InputDecoration(labelText: 'التكلفة', isDense: true),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: discount,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setLocal(() {}),
                            decoration: const InputDecoration(labelText: 'خصم', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: fee,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setLocal(() {}),
                            decoration: const InputDecoration(labelText: 'رسوم اختيارية %', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: paid,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'المدفوع الآن', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: goldLight, borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Text(money(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final lines = selected.map((p) {
                          final unitCost = cost[p.id] ?? p.cost;
                          return ErpLine(
                            productId: p.id,
                            name: p.name,
                            qty: qty[p.id] ?? 0,
                            price: unitCost,
                            cost: unitCost,
                          );
                        }).toList();
                        if (lines.isEmpty) return;
                        await erp.createPurchase(
                          supplierId: supplierId,
                          lines: lines,
                          discount: discountValue,
                          feeRate: feeRate,
                          paid: double.tryParse(paid.text) ?? 0,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('اعتماد فاتورة الشراء'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
