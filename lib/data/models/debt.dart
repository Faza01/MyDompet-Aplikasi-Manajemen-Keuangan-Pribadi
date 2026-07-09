class DebtModel {
  final int? id;
  final String contactName;
  final double amount;
  final double paidAmount; // Track total paid amount
  final String type; // 'debt' | 'receivable'
  final DateTime dueDate;
  final String status; // 'pending' | 'paid'
  final String? note;
  final int accountId;
  final int? transactionId;
  final DateTime createdAt;

  DebtModel({
    this.id,
    required this.contactName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.type,
    required this.dueDate,
    required this.status,
    this.note,
    required this.accountId,
    this.transactionId,
    required this.createdAt,
  });

  DebtModel copyWith({
    int? id,
    String? contactName,
    double? amount,
    double? paidAmount,
    String? type,
    DateTime? dueDate,
    String? status,
    String? note,
    int? accountId,
    int? transactionId,
    DateTime? createdAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
      accountId: accountId ?? this.accountId,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'contact_name': contactName,
      'amount': amount,
      'type': type,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'note': note,
      'account_id': accountId,
      'transaction_id': transactionId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      contactName: map['contact_name'] as String,
      amount: (map['amount'] as num).toDouble(),
      paidAmount: ((map['paid_amount'] as num?)?.toDouble()) ?? 0.0,
      type: map['type'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      status: map['status'] as String,
      note: map['note'] as String?,
      accountId: map['account_id'] as int,
      transactionId: map['transaction_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
