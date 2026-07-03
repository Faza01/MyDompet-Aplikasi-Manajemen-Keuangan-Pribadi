import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/keyword.dart';
import '../../data/models/transaction.dart';
import '../../data/models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keuangan_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE accounts ADD COLUMN color TEXT');
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        initial_balance REAL NOT NULL DEFAULT 0,
        icon TEXT,
        color TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income','expense')),
        icon TEXT,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // 3. Category Keywords Table
    await db.execute('''
      CREATE TABLE category_keywords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        keyword TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // 4. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income','expense')),
        category_id INTEGER,
        note TEXT,
        raw_input TEXT,
        input_method TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    // 5. Budgets Table
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount_limit REAL NOT NULL,
        period TEXT NOT NULL CHECK(period IN ('weekly','monthly')),
        start_date TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // Create Indexes for Query Optimization
    await db.execute('CREATE INDEX idx_transactions_created_at ON transactions(created_at)');
    await db.execute('CREATE INDEX idx_transactions_category_id ON transactions(category_id)');
    await db.execute('CREATE INDEX idx_transactions_account_id ON transactions(account_id)');
    await db.execute('CREATE INDEX idx_keywords_keyword ON category_keywords(keyword)');

    // Seed Initial Data
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    final nowStr = DateTime.now().toIso8601String();

    // Seed Accounts
    await db.insert('accounts', {'name': 'Tunai', 'initial_balance': 100000.0, 'icon': 'wallet', 'created_at': nowStr});
    await db.insert('accounts', {'name': 'Bank Mandiri', 'initial_balance': 1000000.0, 'icon': 'account_balance', 'created_at': nowStr});
    await db.insert('accounts', {'name': 'GoPay', 'initial_balance': 50000.0, 'icon': 'payment', 'created_at': nowStr});

    // Seed Categories
    // Income
    final idGaji = await db.insert('categories', {'name': 'Gaji', 'type': 'income', 'icon': 'work', 'is_default': 1});
    final idBonus = await db.insert('categories', {'name': 'Bonus', 'type': 'income', 'icon': 'card_giftcard', 'is_default': 1});
    final idTransferMasuk = await db.insert('categories', {'name': 'Terima Transfer', 'type': 'income', 'icon': 'download', 'is_default': 1});
    final idIncomeLain = await db.insert('categories', {'name': 'Lain-lain (Masuk)', 'type': 'income', 'icon': 'add_circle', 'is_default': 1});

    // Expense
    final idMakanan = await db.insert('categories', {'name': 'Makanan', 'type': 'expense', 'icon': 'restaurant', 'is_default': 1});
    final idTransportasi = await db.insert('categories', {'name': 'Transportasi', 'type': 'expense', 'icon': 'directions_car', 'is_default': 1});
    final idBelanja = await db.insert('categories', {'name': 'Belanja', 'type': 'expense', 'icon': 'shopping_bag', 'is_default': 1});
    final idTagihan = await db.insert('categories', {'name': 'Tagihan', 'type': 'expense', 'icon': 'receipt_long', 'is_default': 1});
    final idHiburan = await db.insert('categories', {'name': 'Hiburan', 'type': 'expense', 'icon': 'sports_esports', 'is_default': 1});
    final idTransfer = await db.insert('categories', {'name': 'Transfer', 'type': 'expense', 'icon': 'swap_horiz', 'is_default': 1});
    final idExpenseLain = await db.insert('categories', {'name': 'Lain-lain (Keluar)', 'type': 'expense', 'icon': 'remove_circle', 'is_default': 1});

    // Seed Category Keywords
    final Map<int, List<String>> keywordMap = {
      idGaji: ['gaji', 'payday', 'sallary', 'honor'],
      idBonus: ['bonus', 'hadiah', 'angpao', 'thr', 'reward'],
      idTransferMasuk: ['transfer masuk', 'terima', 'dapat transfer', 'masuk'],
      idIncomeLain: ['jual', 'cashback', 'kembalian'],
      idMakanan: [
        'makan', 'minum', 'kopi', 'warteg', 'bakso', 'gojek', 'grabfood', 'shopeefood', 
        'cafe', 'restoran', 'kuliner', 'sate', 'nasi', 'mie', 'snack', 'roti', 'jajan', 
        'susu', 'teh', 'dinner', 'lunch', 'breakfast'
      ],
      idTransportasi: [
        'bensin', 'parkir', 'tol', 'busway', 'kereta', 'ojek', 'mrt', 'lrt', 'driver', 
        'transport', 'gojek', 'grab', 'taxi', 'taksi', 'ban', 'service'
      ],
      idBelanja: [
        'beli', 'indomaret', 'alfamart', 'belanja', 'baju', 'sepatu', 'tas', 'supermarket', 
        'mall', 'tokopedia', 'shopee', 'lazada', 'celana', 'kaos', 'jaket', 'skincare', 'sabun'
      ],
      idTagihan: [
        'listrik', 'air', 'wifi', 'kos', 'pulsa', 'paket data', 'internet', 'token', 
        'langganan', 'pajak', 'bpjs', 'netflix', 'spotify', 'kontrakan', 'cicilan'
      ],
      idHiburan: [
        'nonton', 'bioskop', 'tiket', 'game', 'hiburan', 'jalanjalan', 'liburan', 'travel', 
        'holiday', 'cinema', 'karaoke', 'topup game', 'steam'
      ],
      idTransfer: ['transfer ke', 'pindah ke', 'kirim ke', 'tf ke', 'mutasi']
    };

    for (final entry in keywordMap.entries) {
      for (final keyword in entry.value) {
        await db.insert('category_keywords', {
          'category_id': entry.key,
          'keyword': keyword,
        });
      }
    }
  }

  // --- CRUD Accounts ---
  Future<int> insertAccount(Account account) async {
    final db = await instance.database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final maps = await db.query('accounts', orderBy: 'name ASC');
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Categories ---
  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final maps = await db.query('categories', orderBy: 'is_default DESC, name ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Category Keywords ---
  Future<int> insertKeyword(CategoryKeyword keyword) async {
    final db = await instance.database;
    return await db.insert('category_keywords', keyword.toMap());
  }

  Future<List<CategoryKeyword>> getKeywordsForCategory(int categoryId) async {
    final db = await instance.database;
    final maps = await db.query(
      'category_keywords',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'keyword ASC',
    );
    return maps.map((m) => CategoryKeyword.fromMap(m)).toList();
  }

  Future<List<CategoryKeyword>> getAllKeywords() async {
    final db = await instance.database;
    final maps = await db.query('category_keywords');
    return maps.map((m) => CategoryKeyword.fromMap(m)).toList();
  }

  Future<int> deleteKeyword(int id) async {
    final db = await instance.database;
    return await db.delete(
      'category_keywords',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Transactions ---
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final maps = await db.query('transactions', orderBy: 'created_at DESC');
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<List<TransactionModel>> getTransactionsForAccount(int accountId) async {
    final db = await instance.database;
    final maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => TransactionModel.fromMap(m)).toList();
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- CRUD Budgets ---
  Future<int> insertBudget(Budget budget) async {
    final db = await instance.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await instance.database;
    final maps = await db.query('budgets');
    return maps.map((m) => Budget.fromMap(m)).toList();
  }

  Future<Budget?> getBudgetForCategory(int categoryId) async {
    final db = await instance.database;
    final maps = await db.query(
      'budgets',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<int> updateBudget(Budget budget) async {
    final db = await instance.database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await instance.database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Database Stats Helper ---
  // Calculates dynamic account balances: initial_balance + sum(income) - sum(expense)
  Future<double> getAccountBalance(int accountId) async {
    final db = await instance.database;
    
    // Get initial balance
    final accountMap = await db.query(
      'accounts',
      columns: ['initial_balance'],
      where: 'id = ?',
      whereArgs: [accountId],
    );
    if (accountMap.isEmpty) return 0.0;
    final initialBalance = (accountMap.first['initial_balance'] as num).toDouble();

    // Get total income
    final incomeResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE account_id = ? AND type = 'income'
    ''', [accountId]);
    final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // Get total expense
    final expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions 
      WHERE account_id = ? AND type = 'expense'
    ''', [accountId]);
    final expense = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

    return initialBalance + income - expense;
  }

  // Clear all tables (Reset database)
  Future<void> resetDatabase() async {
    final db = await instance.database;
    await db.delete('budgets');
    await db.delete('transactions');
    await db.delete('category_keywords');
    await db.delete('categories');
    await db.delete('accounts');
    await _seedData(db);
  }
}
