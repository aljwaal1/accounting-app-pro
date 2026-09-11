import 'package:flutter/material.dart';
import '../services/erp_store.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class ErpDashboardScreen extends StatelessWidget {
  final ErpStore erp;
  final void Function(String) openModule;
  const ErpDashboardScreen({super.key,required this.erp,required this.openModule});

  @override
  Widget build(BuildContext context){
    final accounting=Store.instance;
    final cash=accounting.cashBankAccounts().fold<double>(0,(s,a)=>s+accounting.balanceFor(a.id));
    final net=accounting.typeBalance('إيرادات')-accounting.typeBalance('مصاريف');
    return AnimatedBuilder(
      animation:erp,
      builder:(context,_)=>CustomScrollView(slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(18,18,18,8),sliver:SliverToBoxAdapter(child:_hero(context,net))),
        SliverPadding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:8),sliver:SliverGrid(
          gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:MediaQuery.sizeOf(context).width>900?4:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:MediaQuery.sizeOf(context).width>900?1.6:1.25),
          delegate:SliverChildListDelegate([
            _kpi('المبيعات',erp.salesTotal,Icons.point_of_sale_rounded,creditColor,'إجمالي الفواتير'),
            _kpi('المشتريات',erp.purchaseTotal,Icons.shopping_cart_checkout_rounded,lavender,'إجمالي التوريد'),
            _kpi('مستحقات العملاء',erp.receivables,Icons.account_balance_wallet_outlined,amber,'غير المحصل'),
            _kpi('قيمة المخزون',erp.stockValue,Icons.inventory_2_outlined,primary,'${erp.lowStock} أصناف منخفضة'),
          ]),
        )),
        SliverPadding(padding:const EdgeInsets.all(18),sliver:SliverToBoxAdapter(child:LayoutBuilder(builder:(context,c){
          final wide=c.maxWidth>760;
          final left=_quickActions();
          final right=_overview(cash,net);
          return wide?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:left),const SizedBox(width:14),Expanded(child:right)]):Column(children:[left,const SizedBox(height:14),right]);
        }))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(18,0,18,24),sliver:SliverToBoxAdapter(child:_recentSales())),
      ]),
    );
  }

  Widget _hero(BuildContext context,double net)=>Container(
    padding:const EdgeInsets.all(22),
    decoration:BoxDecoration(gradient:brandGradient(),borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:primaryDark.withOpacity(.22),blurRadius:28,offset:const Offset(0,14))]),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('نظرة تنفيذية',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w800)),
        const SizedBox(height:6),Text(net>=0?'أداء النشاط إيجابي':'راجع المصروفات والهوامش',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:23)),
        const SizedBox(height:8),Text('صافي نتيجة النشاط  ${money(net.abs())}',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:14)),
      ])),
      Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Colors.white.withOpacity(.14),borderRadius:BorderRadius.circular(20)),child:Icon(net>=0?Icons.trending_up_rounded:Icons.trending_down_rounded,color:Colors.white,size:34)),
    ]),
  );

  Widget _kpi(String title,double value,IconData icon,Color color,String note)=>Container(
    padding:const EdgeInsets.all(16),decoration:softCard(22),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Row(children:[Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:color.withOpacity(.10),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color,size:21)),const Spacer(),Icon(Icons.more_horiz_rounded,color:softText.withOpacity(.55))]),
      const SizedBox(height:12),Text(title,style:const TextStyle(color:softText,fontWeight:FontWeight.w800,fontSize:12)),
      FittedBox(child:Text(money(value),style:const TextStyle(color:darkText,fontWeight:FontWeight.w900,fontSize:22))),
      Text(note,style:TextStyle(color:color,fontWeight:FontWeight.w800,fontSize:10.5)),
    ]),
  );

  Widget _quickActions()=>Container(
    padding:const EdgeInsets.all(16),decoration:softCard(24),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('إجراءات سريعة',style:TextStyle(color:darkText,fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:14),
      Wrap(spacing:10,runSpacing:10,children:[
        _action('فاتورة بيع',Icons.receipt_long_rounded,creditColor,()=>openModule('sales')),
        _action('فاتورة شراء',Icons.local_shipping_outlined,lavender,()=>openModule('purchases')),
        _action('عميل جديد',Icons.person_add_alt_1_rounded,primary,()=>openModule('contacts')),
        _action('إدارة المخزون',Icons.inventory_2_outlined,amber,()=>openModule('inventory')),
        _action('سند قبض',Icons.south_west_rounded,creditColor,()=>openModule('receipts')),
        _action('قيد يومية',Icons.account_tree_rounded,primaryDark,()=>openModule('journal')),
      ])
    ]),
  );

  Widget _action(String t,IconData i,Color c,VoidCallback onTap)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Container(width:145,padding:const EdgeInsets.symmetric(horizontal:12,vertical:13),decoration:BoxDecoration(color:c.withOpacity(.07),borderRadius:BorderRadius.circular(16),border:Border.all(color:c.withOpacity(.12))),child:Row(children:[Icon(i,color:c,size:20),const SizedBox(width:8),Expanded(child:Text(t,style:TextStyle(color:c,fontWeight:FontWeight.w900,fontSize:12)))])));

  Widget _overview(double cash,double net)=>Container(
    padding:const EdgeInsets.all(16),decoration:softCard(24),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('المركز التشغيلي',style:TextStyle(color:darkText,fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:12),
      _row('السيولة المتاحة',cash,primary),_row('إجمالي الذمم المدينة',erp.receivables,amber),_row('إجمالي الذمم الدائنة',erp.payables,coral),_row('مجمل ربح المبيعات',erp.grossProfit,creditColor),_row('صافي النشاط',net,net>=0?creditColor:coral),
    ]),
  );
  Widget _row(String t,double v,Color c)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(children:[Container(width:7,height:7,decoration:BoxDecoration(color:c,shape:BoxShape.circle)),const SizedBox(width:9),Expanded(child:Text(t,style:const TextStyle(color:softText,fontWeight:FontWeight.w800,fontSize:12))),Text(money(v),style:TextStyle(color:c,fontWeight:FontWeight.w900))]));

  Widget _recentSales(){
    final list=erp.sales.reversed.take(5).toList();
    return Container(padding:const EdgeInsets.all(16),decoration:softCard(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Text('آخر فواتير البيع',style:TextStyle(color:darkText,fontWeight:FontWeight.w900,fontSize:17))),TextButton(onPressed:()=>openModule('sales'),child:const Text('عرض الكل'))]),
      if(list.isEmpty) emptyState('لا توجد فواتير بيع بعد',Icons.receipt_long_outlined) else ...list.map((d){final p=erp.party(d.partyId);return Container(margin:const EdgeInsets.only(top:8),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(16)),child:Row(children:[CircleAvatar(backgroundColor:primaryLight,child:const Icon(Icons.receipt_long_rounded,color:primary)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p?.name??'عميل',style:const TextStyle(fontWeight:FontWeight.w900)),Text('#${d.number} • ${d.status}',style:const TextStyle(color:softText,fontSize:11))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money(d.total),style:const TextStyle(fontWeight:FontWeight.w900)),if(d.due>0)Text('متبقي ${money(d.due)}',style:const TextStyle(color:amber,fontSize:10,fontWeight:FontWeight.w800))]) ]));})
    ]));
  }
}
