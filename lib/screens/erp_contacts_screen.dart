import 'package:flutter/material.dart';
import '../services/erp_store.dart';
import '../widgets/theme.dart';

class ErpContactsScreen extends StatefulWidget{
  final ErpStore erp;
  const ErpContactsScreen({super.key,required this.erp});
  @override State<ErpContactsScreen> createState()=>_ErpContactsScreenState();
}
class _ErpContactsScreenState extends State<ErpContactsScreen>{
  String type='عميل';String q='';
  @override Widget build(BuildContext context)=>AnimatedBuilder(animation:widget.erp,builder:(context,_){
    final list=widget.erp.parties.where((p)=>p.type==type&&(q.isEmpty||p.name.toLowerCase().contains(q.toLowerCase())||p.reference.toLowerCase().contains(q.toLowerCase()))).toList();
    return Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:Column(children:[Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('العملاء والموردون',style:TextStyle(fontWeight:FontWeight.w900,fontSize:24,color:darkText)),Text('ملفات الأطراف وأرصدة الذمم المرتبطة بالمحاسبة',style:TextStyle(color:softText.withOpacity(.9),fontWeight:FontWeight.w700,fontSize:12))])),FilledButton.icon(onPressed:()=>_add(context),icon:const Icon(Icons.person_add_alt_1_rounded),label:Text(type=='عميل'?'عميل جديد':'مورد جديد'))]),const SizedBox(height:12),SegmentedButton<String>(segments:const [ButtonSegment(value:'عميل',label:Text('العملاء'),icon:Icon(Icons.groups_rounded)),ButtonSegment(value:'مورد',label:Text('الموردون'),icon:Icon(Icons.local_shipping_outlined))],selected:{type},onSelectionChanged:(s)=>setState(()=>type=s.first)),const SizedBox(height:10),TextField(onChanged:(v)=>setState(()=>q=v),decoration:fieldDec('بحث بالاسم أو الرقم المرجعي',Icons.search_rounded))])),
      Expanded(child:list.isEmpty?emptyState(type=='عميل'?'لا يوجد عملاء بعد':'لا يوجد موردون بعد',type=='عميل'?Icons.groups_outlined:Icons.local_shipping_outlined):ListView.separated(padding:const EdgeInsets.fromLTRB(16,0,16,24),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(context,i)=>_card(list[i])))
    ]);
  });

  Widget _card(ErpParty p){
    final docs=p.type=='عميل'?widget.erp.sales.where((d)=>d.partyId==p.id):widget.erp.purchases.where((d)=>d.partyId==p.id);
    final balance=docs.fold<double>(0,(s,d)=>s+d.due);
    final color=p.type=='عميل'?primary:lavender;
    return Container(padding:const EdgeInsets.all(14),decoration:softCard(20),child:Row(children:[CircleAvatar(radius:24,backgroundColor:color.withOpacity(.10),child:Icon(p.type=='عميل'?Icons.person_outline_rounded:Icons.local_shipping_outlined,color:color)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontWeight:FontWeight.w900,color:darkText,fontSize:15)),Text([if(p.reference.isNotEmpty)p.reference,if(p.phone.isNotEmpty)p.phone].join(' • '),style:const TextStyle(color:softText,fontWeight:FontWeight.w700,fontSize:10.5)),Text('${docs.length} مستندات',style:TextStyle(color:softText.withOpacity(.8),fontSize:10))])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[Text(p.type=='عميل'?'الرصيد المستحق':'المبلغ المستحق',style:const TextStyle(color:softText,fontSize:10)),Text(money(balance),style:TextStyle(color:balance>0?(p.type=='عميل'?amber:coral):creditColor,fontWeight:FontWeight.w900,fontSize:17)),tag(p.type,color)])]));
  }

  Future<void> _add(BuildContext context)async{
    final name=TextEditingController(),phone=TextEditingController(),email=TextEditingController(),ref=TextEditingController();
    await showModalBottomSheet(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>Padding(padding:EdgeInsets.fromLTRB(18,8,18,MediaQuery.viewInsetsOf(ctx).bottom+18),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(type=='عميل'?'إضافة عميل':'إضافة مورد',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:21)),const SizedBox(height:14),TextField(controller:name,decoration:fieldDec('الاسم',Icons.badge_outlined)),const SizedBox(height:8),Row(children:[Expanded(child:TextField(controller:phone,keyboardType:TextInputType.phone,decoration:fieldDec('الهاتف',Icons.phone_outlined))),const SizedBox(width:8),Expanded(child:TextField(controller:ref,decoration:fieldDec('رقم مرجعي',Icons.tag_rounded)))]),const SizedBox(height:8),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:fieldDec('البريد الإلكتروني',Icons.email_outlined)),const SizedBox(height:14),FilledButton(onPressed:(){if(name.text.trim().isEmpty)return;widget.erp.addParty(name:name.text.trim(),type:type,phone:phone.text.trim(),email:email.text.trim(),reference:ref.text.trim());Navigator.pop(ctx);},style:FilledButton.styleFrom(minimumSize:const Size.fromHeight(48)),child:Text(type=='عميل'?'حفظ العميل':'حفظ المورد'))]))));
  }
}
