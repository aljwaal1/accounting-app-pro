import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/journal.dart';
import 'store.dart';

class ErpParty {
  final String id;
  String name;
  String type;
  String phone;
  String email;
  String reference;
  String accountId;
  ErpParty({required this.id, required this.name, required this.type, this.phone='', this.email='', this.reference='', this.accountId=''});
  Map<String,dynamic> toJson()=>{'id':id,'name':name,'type':type,'phone':phone,'email':email,'reference':reference,'accountId':accountId};
  factory ErpParty.fromJson(Map<String,dynamic> j)=>ErpParty(id:j['id']??'',name:j['name']??'',type:j['type']??'عميل',phone:j['phone']??'',email:j['email']??'',reference:j['reference']??'',accountId:j['accountId']??'');
}

class ErpProduct {
  final String id;
  String sku;
  String name;
  String category;
  String unit;
  double cost;
  double price;
  double stock;
  double minStock;
  ErpProduct({required this.id,required this.sku,required this.name,this.category='عام',this.unit='قطعة',this.cost=0,this.price=0,this.stock=0,this.minStock=0});
  Map<String,dynamic> toJson()=>{'id':id,'sku':sku,'name':name,'category':category,'unit':unit,'cost':cost,'price':price,'stock':stock,'minStock':minStock};
  factory ErpProduct.fromJson(Map<String,dynamic> j)=>ErpProduct(id:j['id']??'',sku:j['sku']??'',name:j['name']??'',category:j['category']??'عام',unit:j['unit']??'قطعة',cost:(j['cost']??0).toDouble(),price:(j['price']??0).toDouble(),stock:(j['stock']??0).toDouble(),minStock:(j['minStock']??0).toDouble());
}

class ErpLine {
  final String productId;
  final String name;
  final double qty;
  final double price;
  final double cost;
  ErpLine({required this.productId,required this.name,required this.qty,required this.price,required this.cost});
  double get total=>qty*price;
  double get costTotal=>qty*cost;
  Map<String,dynamic> toJson()=>{'productId':productId,'name':name,'qty':qty,'price':price,'cost':cost};
  factory ErpLine.fromJson(Map<String,dynamic> j)=>ErpLine(productId:j['productId']??'',name:j['name']??'',qty:(j['qty']??0).toDouble(),price:(j['price']??0).toDouble(),cost:(j['cost']??0).toDouble());
}

class ErpDocument {
  final String id;
  final int number;
  final int date;
  String type;
  final String partyId;
  String status;
  final List<ErpLine> lines;
  final double discount;
  final double feeRate;
  double paid;
  ErpDocument({required this.id,required this.number,required this.date,required this.type,required this.partyId,required this.status,required this.lines,this.discount=0,this.feeRate=0,this.paid=0});
  double get subtotal=>lines.fold(0,(s,l)=>s+l.total);
  double get fee=>max(0,subtotal-discount)*feeRate/100;
  double get total=>max(0,subtotal-discount)+fee;
  double get due=>max(0,total-paid);
  Map<String,dynamic> toJson()=>{'id':id,'number':number,'date':date,'type':type,'partyId':partyId,'status':status,'lines':lines.map((e)=>e.toJson()).toList(),'discount':discount,'feeRate':feeRate,'paid':paid};
  factory ErpDocument.fromJson(Map<String,dynamic> j)=>ErpDocument(id:j['id']??'',number:j['number']??0,date:j['date']??DateTime.now().millisecondsSinceEpoch,type:j['type']??'فاتورة بيع',partyId:j['partyId']??'',status:j['status']??'مسودة',lines:((j['lines']??[]) as List).map((e)=>ErpLine.fromJson(Map<String,dynamic>.from(e))).toList(),discount:(j['discount']??0).toDouble(),feeRate:(j['feeRate']??0).toDouble(),paid:(j['paid']??0).toDouble());
}

class ErpStore extends ChangeNotifier {
  static final ErpStore instance=ErpStore._();
  ErpStore._();
  final accounting=Store.instance;
  List<ErpParty> parties=[];
  List<ErpProduct> products=[];
  List<ErpDocument> documents=[];
  String inventoryAccountId='';
  String cogsAccountId='';

  String id()=> '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
  List<ErpParty> get customers=>parties.where((e)=>e.type=='عميل').toList();
  List<ErpParty> get suppliers=>parties.where((e)=>e.type=='مورد').toList();
  List<ErpDocument> get sales=>documents.where((e)=>e.type=='فاتورة بيع').toList();
  List<ErpDocument> get purchases=>documents.where((e)=>e.type=='فاتورة شراء').toList();
  List<ErpDocument> get quotes=>documents.where((e)=>e.type=='عرض سعر').toList();
  ErpParty? party(String id){try{return parties.firstWhere((e)=>e.id==id);}catch(_){return null;}}
  ErpProduct? product(String id){try{return products.firstWhere((e)=>e.id==id);}catch(_){return null;}}

  Future<void> load() async {
    final p=await SharedPreferences.getInstance();
    parties=(jsonDecode(p.getString('hesabati_erp_parties')??'[]') as List).map((e)=>ErpParty.fromJson(Map<String,dynamic>.from(e))).toList();
    products=(jsonDecode(p.getString('hesabati_erp_products')??'[]') as List).map((e)=>ErpProduct.fromJson(Map<String,dynamic>.from(e))).toList();
    documents=(jsonDecode(p.getString('hesabati_erp_documents')??'[]') as List).map((e)=>ErpDocument.fromJson(Map<String,dynamic>.from(e))).toList();
    await _ensureCoreAccounts();
    if(parties.isEmpty && products.isEmpty && documents.isEmpty){await _seedDemo();}
  }

  Future<void> _save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('hesabati_erp_parties',jsonEncode(parties.map((e)=>e.toJson()).toList()));
    await p.setString('hesabati_erp_products',jsonEncode(products.map((e)=>e.toJson()).toList()));
    await p.setString('hesabati_erp_documents',jsonEncode(documents.map((e)=>e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> _ensureCoreAccounts() async {
    var inv=accounting.findByName('المخزون');
    inv ??= await accounting.createAccount(name:'المخزون',type:'أصول');
    inventoryAccountId=inv.id;
    var cogs=accounting.findByName('تكلفة البضاعة المباعة');
    cogs ??= await accounting.createAccount(name:'تكلفة البضاعة المباعة',type:'مصاريف');
    cogsAccountId=cogs.id;
  }

  Future<void> _seedDemo() async {
    final c=await addParty(name:'شركة النور',type:'عميل',phone:'',reference:'C-001');
    final s=await addParty(name:'المورد المتحد',type:'مورد',phone:'',reference:'S-001');
    await addProduct(name:'منتج تجريبي',sku:'SKU-001',category:'عام',unit:'قطعة',cost:8,price:12,stock:80,minStock:10,postOpening:true);
    if(c.id.isEmpty||s.id.isEmpty) return;
  }

  Future<ErpParty> addParty({required String name,required String type,String phone='',String email='',String reference=''}) async {
    final parent=accounting.findByCode(type=='عميل'?'103':'201');
    final a=await accounting.createAccount(name:name,type:type=='عميل'?'أصول':'التزامات',parent:parent);
    final e=ErpParty(id:id(),name:name,type:type,phone:phone,email:email,reference:reference,accountId:a.id);
    parties.add(e);await _save();return e;
  }

  Future<ErpProduct> addProduct({required String name,required String sku,String category='عام',String unit='قطعة',double cost=0,double price=0,double stock=0,double minStock=0,bool postOpening=false}) async {
    final e=ErpProduct(id:id(),sku:sku,name:name,category:category,unit:unit,cost:cost,price:price,stock:stock,minStock:minStock);products.add(e);
    if(postOpening && stock>0 && cost>0){
      final inv=accounting.byId(inventoryAccountId)!;final cap=accounting.findByName('رأس المال')!;final amount=stock*cost;
      await _entry('رصيد افتتاحي مخزون','إثبات رصيد افتتاحي للمخزون',[jl(inv,debit:amount),jl(cap,credit:amount)]);
    }
    await _save();return e;
  }

  int nextNumber(String type){final list=documents.where((e)=>e.type==type).map((e)=>e.number).toList();return list.isEmpty?1:list.reduce(max)+1;}

  Future<ErpDocument> createQuote({required String customerId,required List<ErpLine> lines,double discount=0,double feeRate=0}) async {
    final d=ErpDocument(id:id(),number:nextNumber('عرض سعر'),date:DateTime.now().millisecondsSinceEpoch,type:'عرض سعر',partyId:customerId,status:'مفتوح',lines:lines,discount:discount,feeRate:feeRate,paid:0);documents.add(d);await _save();return d;
  }

  Future<ErpDocument?> convertQuoteToSale(String quoteId,{double paid=0,String? cashAccountId}) async {
    final q=documents.where((e)=>e.id==quoteId&&e.type=='عرض سعر').firstOrNull;if(q==null)return null;
    q.status='محوّل';return createSale(customerId:q.partyId,lines:q.lines,discount:q.discount,feeRate:q.feeRate,paid:paid,cashAccountId:cashAccountId);
  }

  Future<ErpDocument> createSale({required String customerId,required List<ErpLine> lines,double discount=0,double feeRate=0,double paid=0,String? cashAccountId}) async {
    for(final l in lines){final p=product(l.productId);if(p==null||p.stock<l.qty)throw StateError('المخزون غير كافٍ للصنف ${l.name}');}
    final d=ErpDocument(id:id(),number:nextNumber('فاتورة بيع'),date:DateTime.now().millisecondsSinceEpoch,type:'فاتورة بيع',partyId:customerId,status:'معتمدة',lines:lines,discount:discount,feeRate:feeRate,paid:paid);
    for(final l in lines){product(l.productId)!.stock-=l.qty;}
    documents.add(d);
    final partyAcc=accounting.byId(party(customerId)!.accountId)!;final salesAcc=accounting.findByName('إيرادات المبيعات')!;final inv=accounting.byId(inventoryAccountId)!;final cogs=accounting.byId(cogsAccountId)!;final cash=accounting.byId(cashAccountId??accounting.settings.defaultCashId)??accounting.findByName('الصندوق الرئيسي')!;
    final revenue=d.total;final received=min(paid,revenue);final due=revenue-received;final cost=lines.fold<double>(0,(s,l)=>s+l.costTotal);
    final rows=<JournalLine>[];if(received>0)rows.add(jl(cash,debit:received));if(due>0)rows.add(jl(partyAcc,debit:due));rows.add(jl(salesAcc,credit:revenue));
    await _entry('فاتورة بيع','فاتورة بيع رقم ${d.number}',rows);
    if(cost>0)await _entry('تكلفة مبيعات','تكلفة فاتورة بيع رقم ${d.number}',[jl(cogs,debit:cost),jl(inv,credit:cost)]);
    await _save();return d;
  }

  Future<ErpDocument> createPurchase({required String supplierId,required List<ErpLine> lines,double discount=0,double feeRate=0,double paid=0,String? cashAccountId}) async {
    final d=ErpDocument(id:id(),number:nextNumber('فاتورة شراء'),date:DateTime.now().millisecondsSinceEpoch,type:'فاتورة شراء',partyId:supplierId,status:'معتمدة',lines:lines,discount:discount,feeRate:feeRate,paid:paid);
    for(final l in lines){final p=product(l.productId);if(p!=null){final oldValue=p.stock*p.cost;final incoming=l.qty*l.price;final newQty=p.stock+l.qty;p.cost=newQty<=0?l.price:(oldValue+incoming)/newQty;p.stock=newQty;}}
    documents.add(d);
    final supplierAcc=accounting.byId(party(supplierId)!.accountId)!;final inv=accounting.byId(inventoryAccountId)!;final cash=accounting.byId(cashAccountId??accounting.settings.defaultCashId)??accounting.findByName('الصندوق الرئيسي')!;final total=d.total;final paidNow=min(paid,total);final due=total-paidNow;
    final rows=<JournalLine>[jl(inv,debit:total)];if(paidNow>0)rows.add(jl(cash,credit:paidNow));if(due>0)rows.add(jl(supplierAcc,credit:due));
    await _entry('فاتورة شراء','فاتورة شراء رقم ${d.number}',rows);await _save();return d;
  }

  Future<void> collectSale(ErpDocument d,double amount,{String? cashAccountId}) async {
    if(amount<=0||amount>d.due+0.001)return;final acc=accounting.byId(party(d.partyId)!.accountId)!;final cash=accounting.byId(cashAccountId??accounting.settings.defaultCashId)??accounting.findByName('الصندوق الرئيسي')!;d.paid+=amount;await _entry('تحصيل عميل','تحصيل فاتورة بيع رقم ${d.number}',[jl(cash,debit:amount),jl(acc,credit:amount)]);await _save();
  }

  Future<void> payPurchase(ErpDocument d,double amount,{String? cashAccountId}) async {
    if(amount<=0||amount>d.due+0.001)return;final acc=accounting.byId(party(d.partyId)!.accountId)!;final cash=accounting.byId(cashAccountId??accounting.settings.defaultCashId)??accounting.findByName('الصندوق الرئيسي')!;d.paid+=amount;await _entry('سداد مورد','سداد فاتورة شراء رقم ${d.number}',[jl(acc,debit:amount),jl(cash,credit:amount)]);await _save();
  }

  Future<void> adjustStock(ErpProduct p,double actual) async {
    final diff=actual-p.stock;if(diff.abs()<0.0001)return;final inv=accounting.byId(inventoryAccountId)!;final cogs=accounting.byId(cogsAccountId)!;final value=diff.abs()*p.cost;p.stock=actual;
    await _entry('تسوية مخزون','تسوية مخزون ${p.name}',diff>0?[jl(inv,debit:value),jl(cogs,credit:value)]:[jl(cogs,debit:value),jl(inv,credit:value)]);await _save();
  }

  Future<void> _entry(String type,String description,List<JournalLine> lines) async {await accounting.addEntry(JournalEntry(id:accounting.id(),number:accounting.nextDocNumber('قيد يومية'),fiscalYear:accounting.settings.fiscalYear,date:DateTime.now().millisecondsSinceEpoch,type:type,description:description,method:'ERP',chequeNumber:'',lines:lines));}
  JournalLine jl(Account a,{double debit=0,double credit=0})=>JournalLine(accountId:a.id,accountCode:a.code,accountName:a.name,debit:debit,credit:credit,note:'حساباتي ERP');

  double get salesTotal=>sales.fold(0,(s,d)=>s+d.total);
  double get purchaseTotal=>purchases.fold(0,(s,d)=>s+d.total);
  double get receivables=>sales.fold(0,(s,d)=>s+d.due);
  double get payables=>purchases.fold(0,(s,d)=>s+d.due);
  double get stockValue=>products.fold(0,(s,p)=>s+p.stock*p.cost);
  double get grossProfit=>sales.fold(0,(s,d)=>s+d.total-d.lines.fold<double>(0,(x,l)=>x+l.costTotal));
  int get lowStock=>products.where((p)=>p.stock<=p.minStock).length;
}

extension _FirstOrNull<E> on Iterable<E>{E? get firstOrNull=>isEmpty?null:first;}
