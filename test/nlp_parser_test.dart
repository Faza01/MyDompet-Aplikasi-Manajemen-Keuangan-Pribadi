import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_v1/core/nlp/nlp_parser.dart';
import 'package:keuangan_v1/data/models/category.dart';
import 'package:keuangan_v1/data/models/keyword.dart';

void main() {
  group('NLP Parser Tests', () {
    // Set up mock data
    final List<Category> categories = [
      Category(id: 1, name: 'Gaji', type: 'income'),
      Category(id: 2, name: 'Bonus', type: 'income'),
      Category(id: 3, name: 'Makanan', type: 'expense'),
      Category(id: 4, name: 'Transportasi', type: 'expense'),
      Category(id: 5, name: 'Tagihan', type: 'expense'),
      Category(id: 6, name: 'Belanja', type: 'expense'),
      Category(id: 7, name: 'Transfer', type: 'expense'),
    ];

    final List<CategoryKeyword> keywords = [
      CategoryKeyword(id: 1, categoryId: 1, keyword: 'gaji'),
      CategoryKeyword(id: 2, categoryId: 2, keyword: 'bonus'),
      CategoryKeyword(id: 3, categoryId: 3, keyword: 'makan'),
      CategoryKeyword(id: 4, categoryId: 3, keyword: 'minum'),
      CategoryKeyword(id: 5, categoryId: 3, keyword: 'kopi'),
      CategoryKeyword(id: 6, categoryId: 3, keyword: 'bakso'),
      CategoryKeyword(id: 7, categoryId: 4, keyword: 'bensin'),
      CategoryKeyword(id: 8, categoryId: 4, keyword: 'parkir'),
      CategoryKeyword(id: 9, categoryId: 4, keyword: 'tol'),
      CategoryKeyword(id: 10, categoryId: 5, keyword: 'listrik'),
      CategoryKeyword(id: 11, categoryId: 5, keyword: 'wifi'),
      CategoryKeyword(id: 12, categoryId: 5, keyword: 'kos'),
      CategoryKeyword(id: 13, categoryId: 6, keyword: 'beli'),
      CategoryKeyword(id: 14, categoryId: 6, keyword: 'belanja'),
      CategoryKeyword(id: 15, categoryId: 7, keyword: 'transfer ke'),
    ];

    final defaultExpense = Category(id: 99, name: 'Lain-lain', type: 'expense');
    final defaultIncome = Category(id: 98, name: 'Lain-lain (Masuk)', type: 'income');

    test('Should parse "rb" multiplier correctly', () {
      final result = NlpParser.parse(
        'beli makan siang 15rb',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(15000.0));
      expect(result.type, equals('expense'));
      expect(result.category?.name, equals('Makanan'));
      expect(result.note, equals('beli makan siang'));
    });

    test('Should parse "k" multiplier correctly', () {
      final result = NlpParser.parse(
        'kopi susu 18k',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(18000.0));
      expect(result.type, equals('expense'));
      expect(result.category?.name, equals('Makanan'));
      expect(result.note, equals('kopi susu'));
    });

    test('Should parse "jt" multiplier with decimals correctly', () {
      final result = NlpParser.parse(
        'gaji pokok 4.5jt',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(4500000.0));
      expect(result.type, equals('income'));
      expect(result.category?.name, equals('Gaji'));
      expect(result.note, equals('gaji pokok'));
    });

    test('Should parse "juta" multiplier with decimal commas correctly', () {
      final result = NlpParser.parse(
        'bayar kos bulanan 1,2juta',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(1200000.0));
      expect(result.type, equals('expense'));
      expect(result.category?.name, equals('Tagihan'));
      expect(result.note, equals('bayar kos bulanan'));
    });

    test('Should parse raw number with dot separator correctly', () {
      final result = NlpParser.parse(
        'beli bensin 50.000',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(50000.0));
      expect(result.type, equals('expense'));
      expect(result.category?.name, equals('Transportasi'));
      expect(result.note, equals('beli bensin'));
    });

    test('Should choose longest matching keyword to prevent partial matches', () {
      final result = NlpParser.parse(
        'transfer ke bank mandiri 150.000',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(150000.0));
      expect(result.type, equals('expense'));
      expect(result.category?.name, equals('Transfer'));
      expect(result.note, equals('transfer ke bank mandiri'));
    });

    test('Should handle unknown categories and fallback to general type indicators', () {
      final result = NlpParser.parse(
        'dapat untung lotere 100k',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(100000.0));
      expect(result.type, equals('income')); // 'dapat' is an income indicator
      expect(result.category?.name, equals('Lain-lain (Masuk)'));
      expect(result.note, equals('dapat untung lotere'));
    });

    test('Additional Income Parsing Tests', () {
      final r1 = NlpParser.parse(
        'gaji 5jt',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r1.amount, equals(5000000.0));
      expect(r1.type, equals('income'));

      final r2 = NlpParser.parse(
        'masuk 50.000',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r2.amount, equals(50000.0));
      expect(r2.type, equals('income'));

      final r3 = NlpParser.parse(
        'pemasukan 100k',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r3.amount, equals(100000.0));
      expect(r3.type, equals('income'));

      final r4 = NlpParser.parse(
        'gaji masuk mandiri 5jt',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r4.amount, equals(5000000.0));
      expect(r4.type, equals('income'));
    });

    test('Should parse "Rp" prefix correctly', () {
      final r1 = NlpParser.parse(
        'beli bakso Rp5.000',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r1.amount, equals(5000.0));

      final r2 = NlpParser.parse(
        'beli bakso Rp 5.000',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );
      expect(r2.amount, equals(5000.0));
    });

    test('Should split statements with multiple transactions correctly', () {
      final inputSpace = 'beli makan 5 rebu beli ayam 20 rebu beli sotong 5k';
      final statementsSpace = NlpParser.splitStatements(inputSpace);
      expect(statementsSpace.length, equals(3));
      expect(statementsSpace[0], equals('beli makan 5 rebu'));
      expect(statementsSpace[1], equals('beli ayam 20 rebu'));
      expect(statementsSpace[2], equals('beli sotong 5k'));

      final inputNewline = 'beli makan 5 rebu\nbeli ayam 20 rebu\nbeli sotong 5k';
      final statementsNewline = NlpParser.splitStatements(inputNewline);
      expect(statementsNewline.length, equals(3));
      expect(statementsNewline[0], equals('beli makan 5 rebu'));
      expect(statementsNewline[1], equals('beli ayam 20 rebu'));
      expect(statementsNewline[2], equals('beli sotong 5k'));
    });

    test('Should parse multiple transactions correctly using parseMultiple', () {
      final input = 'beli makan 5 rebu makan ayam 20 rebu gaji bulanan 5jt';
      final results = NlpParser.parseMultiple(
        input,
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(results.length, equals(3));

      expect(results[0].amount, equals(5000.0));
      expect(results[0].type, equals('expense'));
      expect(results[0].category?.name, equals('Makanan'));
      expect(results[0].note, equals('beli makan'));

      expect(results[1].amount, equals(20000.0));
      expect(results[1].type, equals('expense'));
      expect(results[1].category?.name, equals('Makanan'));
      expect(results[1].note, equals('makan ayam'));

      expect(results[2].amount, equals(5000000.0));
      expect(results[2].type, equals('income'));
      expect(results[2].category?.name, equals('Gaji'));
      expect(results[2].note, equals('gaji bulanan'));
    });

    test('Should parse debt transaction "hutang ke Budi 50rb deadline 12 juli" correctly', () {
      final result = NlpParser.parse(
        'hutang ke Budi 50rb deadline 12 juli',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(50000.0));
      expect(result.type, equals('income')); // Uang masuk
      expect(result.debtType, equals('debt'));
      expect(result.contactName, equals('Budi'));
      expect(result.dueDate, isNotNull);
      expect(result.dueDate?.day, equals(12));
      expect(result.dueDate?.month, equals(7));
    });

    test('Should parse receivable transaction "pinjamkan ke Andi 100rb" with null deadline correctly', () {
      final result = NlpParser.parse(
        'pinjamkan ke Andi 100rb',
        categories: categories,
        keywords: keywords,
        defaultExpenseCategory: defaultExpense,
        defaultIncomeCategory: defaultIncome,
      );

      expect(result.amount, equals(100000.0));
      expect(result.type, equals('expense')); // Uang keluar
      expect(result.debtType, equals('receivable'));
      expect(result.contactName, equals('Andi'));
      expect(result.dueDate, isNull);
    });
  });
}
