class TransactionModel {
  final int? id;
  final int accountId;
  final double amount;
  final String type; // 'income' | 'expense'
  final int? categoryId;
  final String? note;
  final String? rawInput;
  final String inputMethod; // 'text' | 'voice' | 'manual'
  final DateTime createdAt;

  TransactionModel({
    this.id,
    required this.accountId,
    required this.amount,
    required this.type,
    this.categoryId,
    this.note,
    this.rawInput,
    required this.inputMethod,
    required this.createdAt,
  });

  TransactionModel copyWith({
    int? id,
    int? accountId,
    double? amount,
    String? type,
    int? categoryId,
    String? note,
    String? rawInput,
    String? inputMethod,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      rawInput: rawInput ?? this.rawInput,
      inputMethod: inputMethod ?? this.inputMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'note': note,
      'raw_input': rawInput,
      'input_method': inputMethod,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      categoryId: map['category_id'] as int?,
      note: map['note'] as String?,
      rawInput: map['raw_input'] as String?,
      inputMethod: map['input_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
