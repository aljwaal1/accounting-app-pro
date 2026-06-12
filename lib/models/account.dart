class Account {
  final String id;
  String code;
  String name;
  String type;
  String parentId;
  int level;
  bool active;

  Account({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.parentId,
    required this.level,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type,
    'parentId': parentId,
    'level': level,
    'active': active,
  };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: j['id'] ?? '',
    code: j['code'] ?? '',
    name: j['name'] ?? '',
    type: j['type'] ?? 'أصول',
    parentId: j['parentId'] ?? '',
    level: j['level'] ?? 1,
    active: j['active'] ?? true,
  );
}
