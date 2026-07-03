import 'dart:convert';
import 'import_io_or_html.dart' as io_share;
import '../../core/database/database_helper.dart';

class DatabaseBackupHelper {
  /// Exports all tables to a JSON string.
  static Future<String> exportToJson() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> accounts = await db.query('accounts');
    final List<Map<String, dynamic>> categories = await db.query('categories');
    final List<Map<String, dynamic>> keywords = await db.query('category_keywords');
    final List<Map<String, dynamic>> transactions = await db.query('transactions');
    final List<Map<String, dynamic>> budgets = await db.query('budgets');

    final Map<String, dynamic> backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'accounts': accounts,
      'categories': categories,
      'category_keywords': keywords,
      'transactions': transactions,
      'budgets': budgets,
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Exports the JSON string and shares it as a file using the OS Share sheet.
  static Future<void> exportAndShare() async {
    final jsonStr = await exportToJson();
    final fileName = 'keuangan_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    
    // Delegate to conditional helper to handle sharing in both Web and Native environments
    await io_share.shareBackupFile(jsonStr, fileName);
  }

  /// Imports database tables from a JSON string.
  static Future<bool> importFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);

      // Validate formatting
      if (!data.containsKey('accounts') ||
          !data.containsKey('categories') ||
          !data.containsKey('transactions')) {
        return false;
      }

      final db = await DatabaseHelper.instance.database;

      await db.transaction((txn) async {
        // Clear all tables
        await txn.delete('budgets');
        await txn.delete('transactions');
        await txn.delete('category_keywords');
        await txn.delete('categories');
        await txn.delete('accounts');

        // Restore Accounts
        for (final item in data['accounts']) {
          await txn.insert('accounts', item);
        }

        // Restore Categories
        for (final item in data['categories']) {
          await txn.insert('categories', item);
        }

        // Restore Keywords
        if (data.containsKey('category_keywords')) {
          for (final item in data['category_keywords']) {
            await txn.insert('category_keywords', item);
          }
        }

        // Restore Transactions
        for (final item in data['transactions']) {
          await txn.insert('transactions', item);
        }

        // Restore Budgets
        if (data.containsKey('budgets')) {
          for (final item in data['budgets']) {
            await txn.insert('budgets', item);
          }
        }
      });

      return true;
    } catch (e) {
      return false;
    }
  }
}
