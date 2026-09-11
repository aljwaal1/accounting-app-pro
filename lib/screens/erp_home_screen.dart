import 'package:flutter/material.dart';
import '../services/erp_store.dart';
import '../services/store.dart';
import '../widgets/theme.dart';
import 'erp_dashboard_screen.dart';
import 'erp_sales_screen.dart';
import 'erp_purchases_screen.dart';
import 'erp_inventory_screen.dart';
import 'erp_contacts_screen.dart';
import 'erp_pos_screen.dart';
import 'erp_finance_screen.dart';
import 'accounts_screen.dart';
import 'journal_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'voucher_screen.dart';

class _NavItem {
  final String id,title,group;
  final IconData icon;
  const _NavItem(this.id,this.title,this.icon,this.group);
}

const _navItems=< _NavItem>[
  _NavItem('dashboard','لوحة التحكم',Icons.space_dashboard_rounded,'الرئيسية'),
  _NavItem('sales','المبيعات',Icons.receipt_long_rounded,'العمليات'),
  _NavItem('purchases','المشتريات',Icons.local_shipping_outlined,'العمليات'),
  _NavItem('contacts','العملاء والموردون',Icons.groups_2_outlined,'العمليات'),
  _NavItem('inventory','المنتجات والمخزون',Icons.inventory_2_outlined,'العمليات'),
  _NavItem('pos','نقطة البيع POS',Icons.point_of_sale_rounded,'العمليات'),
  _NavItem('finance','الخزائن والبنوك',Icons.account_balance_wallet_outlined,'المالية'),
  _NavItem('receipts','سندات القبض',Icons.south_west_rounded,'المالية'),
  _NavItem('payments','سندات الصرف',Icons.north_east_rounded,'المالية'),
  _NavItem('accounts','دليل الحسابات',Icons.account_tree_rounded,'المحاسبة'),
  _NavItem('journal','القيود اليومية',Icons.menu_book_rounded,'المحاسبة'),
  _NavItem('reports','التقارير',Icons.query_stats_rounded,'المحاسبة'),
  _NavItem('settings','الإعدادات',Icons.settings_outlined,'النظام'),
];

class ErpHomeScreen extends StatefulWidget{
  const ErpHomeScreen({super.key});
  @override State<ErpHomeScreen> createState()=>_ErpHomeScreenState();
}
class _ErpHomeScreenState extends State<ErpHomeScreen>{
  String current='dashboard';
  final erp=ErpStore.instance;
  final accounting=Store.instance;
  void open(String id){setState(()=>current=id);Navigator.maybePop(context);}
  void refresh()=>setState((){});

  String get title=>_navItems.firstWhere((e)=>e.id==current).title;
  Widget page(){switch(current){
    case 'dashboard':return ErpDashboardScreen(erp:erp,openModule:open);
    case 'sales':return ErpSalesScreen(erp:erp);
    case 'purchases':return ErpPurchasesScreen(erp:erp);
    case 'contacts':return ErpContactsScreen(erp:erp);
    case 'inventory':return ErpInventoryScreen(erp:erp);
    case 'pos':return ErpPosScreen(erp:erp);
    case 'finance':return ErpFinanceScreen(openReceipt:()=>open('receipts'),openPayment:()=>open('payments'),openAccounts:()=>open('accounts'));
    case 'receipts':return VoucherScreen(type:'سند قبض',onSaved:refresh);
    case 'payments':return VoucherScreen(type:'سند صرف',onSaved:refresh);
    case 'accounts':return AccountsScreen(onChanged:refresh);
    case 'journal':return JournalScreen(onChanged:refresh);
    case 'reports':return ReportsScreen(onChanged:refresh);
    case 'settings':return SettingsScreen(onSaved:refresh);
    default:return ErpDashboardScreen(erp:erp,openModule:open);
  }}

  @override Widget build(BuildContext context){
    final width=MediaQuery.sizeOf(context).width;final desktop=width>=920;
    return Scaffold(
      drawer:desktop?null:Drawer(width:min(330.0,width*.88),child:SafeArea(child:_sideBar(compact:false))),
      appBar:desktop?null:AppBar(
        titleSpacing:0,
        title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),Text(accounting.settings.companyName,style:const TextStyle(fontSize:10,color:softText,fontWeight:FontWeight.w700))]),
        actions:[IconButton(onPressed:()=>open('settings'),icon:const Icon(Icons.tune_rounded)),const SizedBox(width:4)],
      ),
      body:SafeArea(child:Row(children:[if(desktop)SizedBox(width:270,child:_sideBar(compact:false)),Expanded(child:Column(children:[if(desktop)_desktopTop(),Expanded(child:page())]))])),
      bottomNavigationBar:desktop?null:_bottomNav(),
    );
  }

  Widget _desktopTop()=>Container(height:72,padding:const EdgeInsets.symmetric(horizontal:22),decoration:const BoxDecoration(color:Colors.white,border:Border(bottom:BorderSide(color:line))),child:Row(children:[Expanded(child:Column(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20,color:darkText)),Text('حساباتي ERP • ${accounting.settings.companyName}',style:const TextStyle(color:softText,fontWeight:FontWeight.w700,fontSize:11))])),Container(width:280,height:42,decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(14)),child:const TextField(decoration:InputDecoration(prefixIcon:Icon(Icons.search_rounded,size:20),hintText:'بحث سريع...',border:InputBorder.none,contentPadding:EdgeInsets.symmetric(vertical:10),hintStyle:TextStyle(fontSize:12)))),const SizedBox(width:12),CircleAvatar(backgroundColor:primaryLight,child:IconButton(onPressed:()=>open('settings'),icon:const Icon(Icons.person_outline_rounded,color:primary,size:19))) ]));

  Widget _sideBar({required bool compact}){
    final groups=<String,List<_NavItem>>{};for(final item in _navItems){groups.putIfAbsent(item.group,()=>[]).add(item);}
    return Container(color:const Color(0xFF0C2F2A),child:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(18,22,18,16),child:Row(children:[Container(width:46,height:46,decoration:BoxDecoration(gradient:brandGradient(),borderRadius:BorderRadius.circular(15),border:Border.all(color:Colors.white.withOpacity(.16))),child:const Icon(Icons.account_balance_rounded,color:Colors.white,size:25)),const SizedBox(width:11),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('حساباتي',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:20)),Text('ERP لإدارة الأعمال',style:TextStyle(color:Colors.white60,fontWeight:FontWeight.w700,fontSize:10))]))])),
      Container(margin:const EdgeInsets.symmetric(horizontal:14),padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white.withOpacity(.06),borderRadius:BorderRadius.circular(14),border:Border.all(color:Colors.white.withOpacity(.08))),child:Row(children:[const Icon(Icons.business_rounded,color:Colors.white70,size:18),const SizedBox(width:8),Expanded(child:Text(accounting.settings.companyName,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))),Text(accounting.settings.fiscalYear.toString(),style:const TextStyle(color:Colors.white54,fontWeight:FontWeight.w800,fontSize:10))])),const SizedBox(height:8),
      Expanded(child:ListView(padding:const EdgeInsets.fromLTRB(10,4,10,18),children:[for(final entry in groups.entries)...[Padding(padding:const EdgeInsets.fromLTRB(11,13,11,6),child:Text(entry.key,style:const TextStyle(color:Colors.white38,fontWeight:FontWeight.w900,fontSize:9,letterSpacing:.5))),...entry.value.map(_navTile)]])),
      Padding(padding:const EdgeInsets.all(14),child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white.withOpacity(.05),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.cloud_done_outlined,color:Color(0xFF78D9C3),size:18),SizedBox(width:8),Expanded(child:Text('البيانات محفوظة محليًا',style:TextStyle(color:Colors.white60,fontSize:9.5,fontWeight:FontWeight.w700)))])))
    ]));
  }

  Widget _navTile(_NavItem item){final active=current==item.id;return Container(margin:const EdgeInsets.symmetric(vertical:2),decoration:BoxDecoration(color:active?Colors.white.withOpacity(.12):Colors.transparent,borderRadius:BorderRadius.circular(13),border:active?Border.all(color:Colors.white.withOpacity(.08)):null),child:ListTile(dense:true,minLeadingWidth:24,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(13)),leading:Icon(item.icon,color:active?const Color(0xFF79E1C9):Colors.white54,size:20),title:Text(item.title,style:TextStyle(color:active?Colors.white:Colors.white70,fontWeight:active?FontWeight.w900:FontWeight.w700,fontSize:12)),trailing:active?Container(width:4,height:20,decoration:BoxDecoration(color:const Color(0xFF79E1C9),borderRadius:BorderRadius.circular(5))):null,onTap:()=>open(item.id)));}

  Widget _bottomNav(){
    final main=['dashboard','sales','inventory','reports'];final selected=main.contains(current)?main.indexOf(current):0;
    return NavigationBar(height:68,selectedIndex:selected,onDestinationSelected:(i)=>open(main[i]),destinations:const [NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard_rounded),label:'الرئيسية'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long_rounded),label:'المبيعات'),NavigationDestination(icon:Icon(Icons.inventory_2_outlined),selectedIcon:Icon(Icons.inventory_2_rounded),label:'المخزون'),NavigationDestination(icon:Icon(Icons.query_stats_outlined),selectedIcon:Icon(Icons.query_stats_rounded),label:'التقارير')]);
  }
}

double min(double a,double b)=>a<b?a:b;
