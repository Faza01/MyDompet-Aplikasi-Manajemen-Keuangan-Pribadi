class Account {
  final int? id;
  final String name;
  final double initialBalance;
  final String? icon;
  final String? color;
  final DateTime createdAt;

  Account({
    this.id,
    required this.name,
    required this.initialBalance,
    this.icon,
    this.color,
    required this.createdAt,
  });

  Account copyWith({
    int? id,
    String? name,
    double? initialBalance,
    String? icon,
    String? color,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'icon': icon,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      initialBalance: (map['initial_balance'] as num).toDouble(),
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
