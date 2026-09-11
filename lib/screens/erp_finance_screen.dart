import 'package:flutter/material.dart';
import '../services/store.dart';
import '../widgets/theme.dart';

class ErpFinanceScreen extends StatelessWidget{
  final VoidCallback openReceipt;
  final VoidCallback openPayment;
  final VoidCallback openAccounts;
  const ErpFinanceScreen({super.key,required this.openReceipt,required this.openPayment,required this.openAccounts});
  @override Widget build(BuildContext context){
    final s=Store.instance;final accounts=s.cashBankAccounts();final total=accounts.fold<double>(0,(x,a)=>x+s.balanceFor(a.id));final recent=s.entries.reversed.take(12).toList();
    return ListView(padding:const EdgeInsets.all(16),children:[
      Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('الخزائن والبنوك',style:TextStyle(fontWeight:FontWeight.w900,fontSize:24,color:darkText)),Text('السيولة، المقبوضات، المدفوعات وحركة الحسابات',style:TextStyle(color:softText.withOpacity(.9),fontWeight:FontWeight.w700,fontSize:12))])),PopupMenuButton<String>(icon:const Icon(Icons.add_circle_rounded,color:primary,size:30),onSelected:(v){if(v=='r')openReceipt();if(v=='p')openPayment();if(v=='a')openAccounts();},itemBuilder:(_)=>const [PopupMenuItem(value:'r',child:Text('سند قبض')),PopupMenuItem(value:'p',child:Text('سند صرف')),PopupMenuItem(value:'a',child:Text('إدارة الحسابات'))])]),const SizedBox(height:14),
      Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:brandGradient(),borderRadius:BorderRadius.circular(26),boxShadow:[BoxShadow(color:primaryDark.withOpacity(.2),blurRadius:24,offset:const Offset(0,12))]),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('إجمالي السيولة',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(money(total),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:27))])),Container(padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:Colors.white.withOpacity(.15),borderRadius:BorderRadius.circular(18)),child:const Icon(Icons.account_balance_wallet_rounded,color:Colors.white,size:30))])),const SizedBox(height:14),
      Wrap(spacing:10,runSpacing:10,children:accounts.map((a)=>Container(width:MediaQuery.sizeOf(context).width>700?240:(MediaQuery.sizeOf(context).width-42)/2,padding:const EdgeInsets.all(14),decoration:softCard(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(a.name.contains('بنك')?Icons.account_balance_rounded:Icons.payments_outlined,color:primary),const Spacer(),tag(a.name.contains('بنك')?'بنك':'خزينة',a.name.contains('بنك')?lavender:primary)]),const SizedBox(height:12),Text(a.name,style:const TextStyle(fontWeight:FontWeight.w900)),Text(a.code,style:const TextStyle(color:softText,fontSize:10)),const SizedBox(height:8),Text(money(s.balanceFor(a.id)),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20,color:primaryDark))])).toList()),const SizedBox(height:18),
      Row(children:[const Expanded(child:Text('آخر الحركات',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),TextButton(onPressed:openAccounts,child:const Text('دليل الحسابات'))]),const SizedBox(height:8),
      if(recent.isEmpty)emptyState('لا توجد حركات بعد',Icons.swap_vert_rounded) else ...recent.map((e)=>Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:softCard(18),child:Row(children:[CircleAvatar(backgroundColor:(e.totalDebit>0?primary:lavender).withOpacity(.09),child:Icon(Icons.swap_horiz_rounded,color:e.totalDebit>0?primary:lavender)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(e.description,style:const TextStyle(fontWeight:FontWeight.w900)),Text('${e.type} • ${dateText(e.date)}',style:const TextStyle(color:softText,fontSize:10))])),Text(money(e.totalDebit),style:const TextStyle(fontWeight:FontWeight.w900))]))
    ]);
  }
}
