class Budget {
  final int? id;
  final int categoryId;
  final double amountLimit;
  final String period; // 'weekly' | 'monthly'
  final DateTime startDate;

  Budget({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    required this.period,
    required this.startDate,
  });

  Budget copyWith({
    int? id,
    int? categoryId,
    double? amountLimit,
    String? period,
    DateTime? startDate,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'period': period,
      'start_date': startDate.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      amountLimit: (map['amount_limit'] as num).toDouble(),
      period: map['period'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
    );
  }
}
