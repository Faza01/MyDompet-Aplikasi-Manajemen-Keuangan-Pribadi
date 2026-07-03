import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/budget.dart';
import '../../data/models/transaction.dart';
import 'categories_provider.dart';
import '../transactions/transactions_provider.dart';

class CategoryBudgetProgress {
  final Category category;
  final Budget? budget;
  final double spentAmount;
  final double limitAmount;
  final bool isExceeded;
  final double percentage; // 0.0 to 1.0+

  CategoryBudgetProgress({
    required this.category,
    this.budget,
    required this.spentAmount,
    required this.limitAmount,
    required this.isExceeded,
    required this.percentage,
  });
}

class BudgetNotifier extends AsyncNotifier<List<Budget>> {
  @override
  FutureOr<List<Budget>> build() async {
    return DatabaseHelper.instance.getAllBudgets();
  }

  Future<void> setBudget({
    required int categoryId,
    required double limit,
    required String period, // 'weekly' | 'monthly'
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      final existing = await db.getBudgetForCategory(categoryId);
      
      if (existing != null) {
        await db.updateBudget(existing.copyWith(
          amountLimit: limit,
          period: period,
          startDate: DateTime.now(),
        ));
      } else {
        await db.insertBudget(Budget(
          categoryId: categoryId,
          amountLimit: limit,
          period: period,
          startDate: DateTime.now(),
        ));
      }
      return db.getAllBudgets();
    });
  }

  Future<void> removeBudget(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.deleteBudget(id);
      return db.getAllBudgets();
    });
  }
}

final budgetNotifierProvider =
    AsyncNotifierProvider.autoDispose<BudgetNotifier, List<Budget>>(
  BudgetNotifier.new,
);

/// Combined provider that calculates budget progress for all expense categories.
final categoryBudgetProgressProvider =
    Provider.autoDispose<AsyncValue<List<CategoryBudgetProgress>>>((ref) {
  final categoriesAsync = ref.watch(categoriesNotifierProvider);
  final budgetsAsync = ref.watch(budgetNotifierProvider);
  final transactionsAsync = ref.watch(transactionsNotifierProvider);

  // If any source provider is loading or error, propagate that state
  if (categoriesAsync.isLoading || budgetsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (categoriesAsync.hasError) {
    return AsyncValue.error(categoriesAsync.error!, categoriesAsync.stackTrace!);
  }
  if (budgetsAsync.hasError) {
    return AsyncValue.error(budgetsAsync.error!, budgetsAsync.stackTrace!);
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace!);
  }

  final categories = categoriesAsync.value ?? [];
  final budgets = budgetsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  final now = DateTime.now();

  // Helper to determine if a transaction date is within the current week
  bool _isThisWeek(DateTime date) {
    // Start of week: Monday
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    return date.isAfter(startOfWeek) || date.isAtSameMomentAs(startOfWeek);
  }

  // Helper to determine if a transaction date is within the current month
  bool _isThisMonth(DateTime date) {
    return date.year == now.year && date.month == now.month;
  }

  final List<CategoryBudgetProgress> progressList = [];

  // Calculate progress for each expense category
  for (final cat in categories) {
    if (cat.type != 'expense' || cat.name.toLowerCase() == 'transfer') {
      continue; // budgets apply to expense categories only, excluding transfer
    }

    final budget = budgets.firstWhere(
      (b) => b.categoryId == cat.id,
      orElse: () => Budget(id: -1, categoryId: cat.id!, amountLimit: 0, period: 'monthly', startDate: now),
    );

    final hasBudget = budget.id != -1;
    final limit = budget.amountLimit;

    double spent = 0.0;
    if (hasBudget) {
      final periodTransactions = transactions.where((tx) {
        if (tx.categoryId != cat.id || tx.type != 'expense') return false;
        
        if (budget.period == 'weekly') {
          return _isThisWeek(tx.createdAt);
        } else {
          return _isThisMonth(tx.createdAt);
        }
      });

      spent = periodTransactions.fold(0.0, (sum, tx) => sum + tx.amount);
    }

    final percentage = limit > 0 ? (spent / limit) : 0.0;

    progressList.add(CategoryBudgetProgress(
      category: cat,
      budget: hasBudget ? budget : null,
      spentAmount: spent,
      limitAmount: limit,
      isExceeded: hasBudget && spent > limit,
      percentage: percentage,
    ));
  }

  return AsyncValue.data(progressList);
});
