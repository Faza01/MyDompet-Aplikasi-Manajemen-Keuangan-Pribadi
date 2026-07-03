import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/transaction.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/budget_provider.dart';

// Modern Notifier representing the selected account filter
class SelectedAccountIdNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) {
    state = id;
  }
}

final selectedAccountIdProvider =
    NotifierProvider.autoDispose<SelectedAccountIdNotifier, int?>(
  SelectedAccountIdNotifier.new,
);

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  FutureOr<List<TransactionModel>> build() async {
    final db = DatabaseHelper.instance;
    return db.getAllTransactions();
  }

  Future<List<TransactionModel>> _fetch() async {
    final db = DatabaseHelper.instance;
    return db.getAllTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.insertTransaction(transaction);
      
      // Invalidate related providers to trigger rebuilds
      ref.invalidate(accountsNotifierProvider);
      ref.invalidate(budgetNotifierProvider);
      
      return _fetch();
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.updateTransaction(transaction);
      
      ref.invalidate(accountsNotifierProvider);
      ref.invalidate(budgetNotifierProvider);
      
      return _fetch();
    });
  }

  Future<void> deleteTransaction(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.deleteTransaction(id);
      
      ref.invalidate(accountsNotifierProvider);
      ref.invalidate(budgetNotifierProvider);
      
      return _fetch();
    });
  }

  Future<void> addTransfer({
    required int fromAccountId,
    required int toAccountId,
    required double amount,
    required String note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      final now = DateTime.now();

      // Retrieve all accounts to find names
      final accounts = await db.getAllAccounts();
      final fromAcc = accounts.firstWhere((a) => a.id == fromAccountId);
      final toAcc = accounts.firstWhere((a) => a.id == toAccountId);

      // Find system category 'Transfer'
      final categories = await db.getAllCategories();
      final transferCat = categories.firstWhere(
        (c) => c.name.toLowerCase() == 'transfer',
        orElse: () => categories.firstWhere((c) => c.type == 'expense'),
      );

      final cleanNote = note.trim().isEmpty ? 'Transfer Dana' : note.trim();

      // 1. Expense transaction from source account
      await db.insertTransaction(TransactionModel(
        accountId: fromAccountId,
        amount: amount,
        type: 'expense',
        categoryId: transferCat.id,
        note: '$cleanNote (Ke ${toAcc.name})',
        inputMethod: 'manual',
        createdAt: now,
      ));

      // 2. Income transaction to destination account
      await db.insertTransaction(TransactionModel(
        accountId: toAccountId,
        amount: amount,
        type: 'income',
        categoryId: transferCat.id,
        note: '$cleanNote (Dari ${fromAcc.name})',
        inputMethod: 'manual',
        createdAt: now,
      ));

      ref.invalidate(accountsNotifierProvider);
      ref.invalidate(budgetNotifierProvider);

      return _fetch();
    });
  }

  Future<void> resetAllData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await DatabaseHelper.instance.resetDatabase();
      ref.invalidate(accountsNotifierProvider);
      ref.invalidate(budgetNotifierProvider);
      return _fetch();
    });
  }
}

final transactionsNotifierProvider =
    AsyncNotifierProvider.autoDispose<TransactionsNotifier, List<TransactionModel>>(
  TransactionsNotifier.new,
);
