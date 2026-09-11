import 'package:flutter/material.dart';
import '../services/erp_store.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class ErpSalesScreen extends StatefulWidget{
  final ErpStore erp;
  const ErpSalesScreen({super.key,required this.erp});
  @override State<ErpSalesScreen> createState()=>_ErpSalesScreenState();
}
class _ErpSalesScreenState extends State<ErpSalesScreen>{
  bool quotes=false;
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.erp,builder:(context,_){
    final docs=(quotes?widget.erp.quotes:widget.erp.sales).reversed.toList();
    return Column(children:[
      _header(context),
      Expanded(child:docs.isEmpty?emptyState(quotes?'لا توجد عروض أسعار بعد':'لا توجد فواتير بيع بعد',Icons.receipt_long_outlined):ListView.separated(padding:const EdgeInsets.fromLTRB(16,0,16,22),itemCount:docs.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i)=>_docCard(context,docs[i])))
    ]);
  });

  Widget _header(BuildContext context)=>Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('المبيعات',style:TextStyle(fontWeight:FontWeight.w900,fontSize:24,color:darkText)),Text('إدارة دورة البيع من العرض حتى التحصيل',style:TextStyle(color:softText.withOpacity(.9),fontWeight:FontWeight.w700,fontSize:12))])),
      FilledButton.icon(onPressed:()=>_editor(context,quotes?'عرض سعر':'فاتورة بيع'),icon:const Icon(Icons.add_rounded),label:Text(quotes?'عرض جديد':'فاتورة جديدة'))
    ]),const SizedBox(height:12),
    SegmentedButton<bool>(segments:const [ButtonSegment(value:false,label:Text('الفواتير'),icon:Icon(Icons.receipt_long_rounded)),ButtonSegment(value:true,label:Text('عروض الأسعار'),icon:Icon(Icons.request_quote_outlined))],selected:{quotes},onSelectionChanged:(s)=>setState(()=>quotes=s.first),style:ButtonStyle(visualDensity:VisualDensity.compact,minimumSize:WidgetStateProperty.all(const Size(0,42))))
  ]));

  Widget _docCard(BuildContext context,ErpDocument d){
    final p=widget.erp.party(d.partyId);final due=d.due;
    final color=d.type=='عرض سعر'?lavender:due>0?amber:creditColor;
    return Container(padding:const EdgeInsets.all(14),decoration:softCard(20),child:Row(children:[
      Container(width:48,height:48,decoration:BoxDecoration(color:color.withOpacity(.10),borderRadius:BorderRadius.circular(15)),child:Icon(d.type=='عرض سعر'?Icons.request_quote_outlined:Icons.receipt_long_rounded,color:color)),const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Text('${d.type} #${d.number}',style:const TextStyle(fontWeight:FontWeight.w900,color:darkText)),const SizedBox(width:8),tag(d.status,color)]),const SizedBox(height:4),Text(p?.name??'بدون عميل',style:const TextStyle(color:softText,fontWeight:FontWeight.w700)),Text('${d.lines.length} أصناف • ${dateText(d.date)}',style:TextStyle(color:softText.withOpacity(.8),fontSize:10.5))])),
      Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(money(d.total),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17,color:darkText)),if(due>0&&d.type=='فاتورة بيع')Text('متبقي ${money(due)}',style:const TextStyle(color:amber,fontWeight:FontWeight.w800,fontSize:10)),PopupMenuButton<String>(padding:EdgeInsets.zero,icon:const Icon(Icons.more_horiz_rounded,color:softText),onSelected:(v){if(v=='collect')_collect(context,d);if(v=='convert')_convert(context,d);},itemBuilder:(_)=>[if(d.type=='فاتورة بيع'&&d.due>0)const PopupMenuItem(value:'collect',child:Text('تحصيل دفعة')),if(d.type=='عرض سعر'&&d.status!='محوّل')const PopupMenuItem(value:'convert',child:Text('تحويل إلى فاتورة'))])])
    ]));
  }

  Future<void> _collect(BuildContext context,ErpDocument d)async{
    final c=TextEditingController(text:d.due.toStringAsFixed(2));
    final result=await showModalBottomSheet<double>(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(18,8,18,MediaQuery.viewInsetsOf(ctx).bottom+20),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('تحصيل من العميل',style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)),const SizedBox(height:12),TextField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:fieldDec('المبلغ',Icons.payments_outlined)),const SizedBox(height:14),FilledButton(onPressed:()=>Navigator.pop(ctx,double.tryParse(c.text)??0),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(48)),child:const Text('تسجيل التحصيل'))])));
    if(result!=null&&result>0)await widget.erp.collectSale(d,result);
  }

  Future<void> _convert(BuildContext context,ErpDocument d)async{
    await widget.erp.convertQuoteToSale(d.id,paid:0);if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تحويل عرض السعر إلى فاتورة بيع')));
  }

  Future<void> _editor(BuildContext context,String type)async{
    if(widget.erp.customers.isEmpty||widget.erp.products.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف عميلًا ومنتجًا أولًا')));return;}
    String customerId=widget.erp.customers.first.id;
    final qty=<String,double>{};final price=<String,double>{};
    for(final p in widget.erp.products){price[p.id]=p.price;}
    final discount=TextEditingController(text:'0'),fee=TextEditingController(text:'0'),paid=TextEditingController(text:'0');
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal){
      final selected=widget.erp.products.where((p)=>(qty[p.id]??0)>0).toList();
      final sub=selected.fold<double>(0,(s,p)=>s+(qty[p.id]??0)*(price[p.id]??p.price));
      final total=(sub-(double.tryParse(discount.text)??0)).clamp(0,double.infinity)*(1+(double.tryParse(fee.text)??0)/100);
      return Dialog(insetPadding:const EdgeInsets.all(12),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:760,maxHeight:760),child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
        Row(children:[Expanded(child:Text(type,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:21))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close))]),const SizedBox(height:8),
        DropdownButtonFormField<String>(initialValue:customerId,decoration:fieldDec('العميل',Icons.person_outline),items:widget.erp.customers.map((e)=>DropdownMenuItem(value:e.id,child:Text(e.name))).toList(),onChanged:(v)=>customerId=v??customerId),const SizedBox(height:10),
        Expanded(child:ListView(children:widget.erp.products.map((p)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(15)),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text('${p.sku} • متاح ${money(p.stock)}',style:const TextStyle(color:softText,fontSize:10))])),SizedBox(width:70,child:TextFormField(initialValue:(qty[p.id]??0).toStringAsFixed(0),keyboardType:TextInputType.number,onChanged:(v)=>setLocal(()=>qty[p.id]=double.tryParse(v)??0),decoration:const InputDecoration(labelText:'كمية',isDense:true))),const SizedBox(width:8),SizedBox(width:90,child:TextFormField(initialValue:(price[p.id]??p.price).toStringAsFixed(2),keyboardType:TextInputType.number,onChanged:(v)=>setLocal(()=>price[p.id]=double.tryParse(v)??p.price),decoration:const InputDecoration(labelText:'السعر',isDense:true))) ]))).toList())),
        const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:discount,keyboardType:TextInputType.number,onChanged:(_)=>setLocal((){}),decoration:const InputDecoration(labelText:'خصم',isDense:true))),const SizedBox(width:8),Expanded(child:TextField(controller:fee,keyboardType:TextInputType.number,onChanged:(_)=>setLocal((){}),decoration:const InputDecoration(labelText:'رسوم/ضريبة اختيارية %',isDense:true))),if(type=='فاتورة بيع')...[const SizedBox(width:8),Expanded(child:TextField(controller:paid,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'المدفوع الآن',isDense:true)))]]),
        const SizedBox(height:12),Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:primaryLight,borderRadius:BorderRadius.circular(15)),child:Row(children:[const Text('الإجمالي',style:TextStyle(fontWeight:FontWeight.w900)),const Spacer(),Text(money(total),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20,color:primaryDark))])),const SizedBox(height:12),
        FilledButton.icon(onPressed:(){final lines=selected.map((p)=>ErpLine(productId:p.id,name:p.name,qty:qty[p.id]??0,price:price[p.id]??p.price,cost:p.cost)).toList();if(lines.isEmpty)return;if(type=='عرض سعر'){widget.erp.createQuote(customerId:customerId,lines:lines,discount:double.tryParse(discount.text)??0,feeRate:double.tryParse(fee.text)??0);}else{widget.erp.createSale(customerId:customerId,lines:lines,discount:double.tryParse(discount.text)??0,feeRate:double.tryParse(fee.text)??0,paid:double.tryParse(paid.text)??0);}Navigator.pop(ctx);},icon:const Icon(Icons.check_rounded),label:Text(type=='عرض سعر'?'حفظ العرض':'اعتماد الفاتورة'),style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(48)))
      ])))));
    }));
  }
}
