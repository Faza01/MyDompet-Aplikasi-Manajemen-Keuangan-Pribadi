import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/account.dart';

class AccountWithBalance {
  final Account account;
  final double balance;

  AccountWithBalance({required this.account, required this.balance});
}

class AccountsNotifier extends AsyncNotifier<List<AccountWithBalance>> {
  @override
  FutureOr<List<AccountWithBalance>> build() async {
    final db = DatabaseHelper.instance;
    final accounts = await db.getAllAccounts();
    
    final List<AccountWithBalance> list = [];
    for (final acc in accounts) {
      if (acc.id != null) {
        final bal = await db.getAccountBalance(acc.id!);
        list.add(AccountWithBalance(account: acc, balance: bal));
      } else {
        list.add(AccountWithBalance(account: acc, balance: acc.initialBalance));
      }
    }
    return list;
  }

  Future<void> addAccount(String name, double initialBalance, String? icon, String? color) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.insertAccount(Account(
        name: name,
        initialBalance: initialBalance,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
      ));
      return build();
    });
  }

  Future<void> updateAccount(Account account) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.updateAccount(account);
      return build();
    });
  }

  Future<void> deleteAccount(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.deleteAccount(id);
      return build();
    });
  }

  Future<void> refreshBalances() async {
    ref.invalidateSelf();
  }
}

final accountsNotifierProvider =
    AsyncNotifierProvider.autoDispose<AccountsNotifier, List<AccountWithBalance>>(
  AccountsNotifier.new,
);
