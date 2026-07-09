import '../../data/models/category.dart';
import '../../data/models/keyword.dart';

class ParsedResult {
  final double amount;
  final String type; // 'income' | 'expense'
  final Category? category;
  final String note;
  final String rawInput;
  
  // Debt-specific parsed metadata
  final String? contactName;
  final String? debtType; // 'debt' | 'receivable' | null
  final DateTime? dueDate;

  ParsedResult({
    required this.amount,
    required this.type,
    this.category,
    required this.note,
    required this.rawInput,
    this.contactName,
    this.debtType,
    this.dueDate,
  });

  @override
  String toString() {
    return 'ParsedResult(amount: $amount, type: $type, category: ${category?.name}, note: $note, contactName: $contactName, debtType: $debtType)';
  }
}

class NlpParser {
  /// Splits a single input string containing potential multiple transaction clauses.
  /// First, splits by newlines. If a line contains multiple numeric/amount patterns,
  /// it splits the line into segments ending at the end of each amount phrase.
  static List<String> splitStatements(String input) {
    final lines = input.split('\n');
    final List<String> statements = [];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Matches numbers optionally followed by suffixes like rb, ribu, rebu, k, jt, juta
      final regExp = RegExp(
        r'\b(\d+(?:[\.,]\d+)*)\s*(rb|ribu|rebu|k|jt|juta)?\b',
        caseSensitive: false,
      );
      final matches = regExp.allMatches(trimmedLine).toList();

      if (matches.length <= 1) {
        statements.add(trimmedLine);
      } else {
        int lastIndex = 0;
        for (int i = 0; i < matches.length; i++) {
          final end = matches[i].end;
          // For the last segment, consume until the end of the line
          final segmentEnd = (i == matches.length - 1) ? trimmedLine.length : end;
          final segment = trimmedLine.substring(lastIndex, segmentEnd).trim();
          if (segment.isNotEmpty) {
            statements.add(segment);
          }
          lastIndex = end;
        }
      }
    }
    return statements;
  }

  /// Parses a text that might contain multiple transaction clauses.
  static List<ParsedResult> parseMultiple(
    String input, {
    required List<Category> categories,
    required List<CategoryKeyword> keywords,
    Category? defaultExpenseCategory,
    Category? defaultIncomeCategory,
  }) {
    final statements = splitStatements(input);
    final List<ParsedResult> results = [];
    for (final stmt in statements) {
      results.add(
        parse(
          stmt,
          categories: categories,
          keywords: keywords,
          defaultExpenseCategory: defaultExpenseCategory,
          defaultIncomeCategory: defaultIncomeCategory,
        ),
      );
    }
    return results;
  }

  /// Parses a raw input text into a structured [ParsedResult].
  /// [categories] is the list of all available categories.
  /// [keywords] is the list of all keywords mapped to their category IDs.
  static ParsedResult parse(
    String input, {
    required List<Category> categories,
    required List<CategoryKeyword> keywords,
    Category? defaultExpenseCategory,
    Category? defaultIncomeCategory,
  }) {
    if (input.trim().isEmpty) {
      return ParsedResult(
        amount: 0.0,
        type: 'expense',
        category: defaultExpenseCategory,
        note: '',
        rawInput: input,
      );
    }

    // Clean up "Rp" or "rp" prefix (with optional dot and spaces) to prevent word boundary issues (e.g. "Rp5.000" -> "5.000")
    final cleanInput =
        input.replaceAll(RegExp(r'rp\.?\s*', caseSensitive: false), '').trim();
    final lowercaseInput = cleanInput.toLowerCase();

    // 1. Extract Amount
    final amountMatch = _extractAmount(cleanInput);
    final double amount = amountMatch?.amount ?? 0.0;
    final String matchedText = amountMatch?.matchedText ?? '';

    // Remove the matched amount from the input text to clean up the note and categorizer target
    String remainingText = cleanInput;
    if (matchedText.isNotEmpty) {
      remainingText = cleanInput.replaceFirst(matchedText, '');
    }

    // Clean up extra spaces in the remaining text
    remainingText = remainingText.replaceAll(RegExp(r'\s+'), ' ').trim();
    final remainingLowercase = remainingText.toLowerCase();

    // 2. Identify Category via Keywords
    Category? matchedCategory;
    CategoryKeyword? bestKeywordMatch;

    // We look for keyword matches in remaining text.
    // If multiple keywords match, we choose the longest keyword to avoid partial matches (e.g. "transfer masuk" beats "transfer")
    for (final kw in keywords) {
      final keywordLower = kw.keyword.toLowerCase();
      // Match keyword as word boundary or substring if appropriate.
      // For general parsing, a simple substring check or regex check is used.
      // E.g., check if the lowercase text contains the keyword.
      if (remainingLowercase.contains(keywordLower)) {
        if (bestKeywordMatch == null ||
            keywordLower.length > bestKeywordMatch.keyword.length) {
          bestKeywordMatch = kw;
        }
      }
    }

    if (bestKeywordMatch != null) {
      matchedCategory = categories.firstWhere(
        (c) => c.id == bestKeywordMatch!.categoryId,
        orElse: () => defaultExpenseCategory ?? categories.first,
      );
    }

    // 3. Determine Type (Income vs Expense)
    String type = 'expense';
    if (matchedCategory != null) {
      type = matchedCategory.type;
    } else {
      // If no category matched, guess type from general income/expense indicators in the text
      final incomeIndicators = [
        'gaji',
        'terima',
        'masuk',
        'dapat',
        'bonus',
        'payday',
        'angpao',
        'sallary',
        'untung',
        'cashback'
      ];
      final containsIncomeIndicator = incomeIndicators
          .any((indicator) => lowercaseInput.contains(indicator));
      if (containsIncomeIndicator) {
        type = 'income';
      }
    }

    // Set default category if none matched
    matchedCategory ??=
        type == 'income' ? defaultIncomeCategory : defaultExpenseCategory;

    // 4. Extract Debt Specific Info (Hutang & Piutang)
    String? contactName;
    String? debtType;
    DateTime? dueDate;

    // Detect if this is a debt or receivable transaction
    String? matchedKeyword;
    for (final kw in debtKeywords) {
      if (lowercaseInput.contains(kw)) {
        debtType = 'debt';
        matchedKeyword = kw;
        type = 'income'; // Kita berhutang = uang masuk
        break;
      }
    }
    if (debtType == null) {
      for (final kw in receivableKeywords) {
        if (lowercaseInput.contains(kw)) {
          debtType = 'receivable';
          matchedKeyword = kw;
          type = 'expense'; // Kita meminjamkan = uang keluar
          break;
        }
      }
    }

    if (debtType != null && matchedKeyword != null) {
      // Extract contact name (next word after the keyword)
      final escapedKeyword = RegExp.escape(matchedKeyword);
      final nameReg = RegExp(
        '$escapedKeyword\\s+([a-zA-Z0-9_]+)',
        caseSensitive: false,
      );
      final match = nameReg.firstMatch(lowercaseInput);
      if (match != null) {
        final startIndex = match.start + matchedKeyword.length;
        final nameSnippet = cleanInput.substring(startIndex).trim();
        final rawName = nameSnippet.split(' ').first;
        contactName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      }

      // Extract optional due date
      final dateKeywords = ['deadline', 'tenggat', 'jatuh tempo', 'sampai', 'tgl', 'tanggal'];
      for (final dk in dateKeywords) {
        if (lowercaseInput.contains(dk)) {
          final escapedDk = RegExp.escape(dk);
          final dateReg = RegExp(
            '$escapedDk\\s+([^\\s]+(?:\\s+[^\\s]+)?)',
            caseSensitive: false,
          );
          final dMatch = dateReg.firstMatch(lowercaseInput);
          if (dMatch != null) {
            final dateStr = dMatch.group(1)?.trim();
            if (dateStr != null) {
              dueDate = _parseNlpDate(dateStr);
            }
          }
          break;
        }
      }
    }

    // 5. Construct Note
    String note = remainingText;
    if (note.isEmpty) {
      note = cleanInput;
    }

    return ParsedResult(
      amount: amount,
      type: type,
      category: matchedCategory,
      note: note,
      rawInput: cleanInput,
      contactName: contactName,
      debtType: debtType,
      dueDate: dueDate,
    );
  }

  // --- NLP Debt/Receivable Configurable Triggers ---
  static List<String> debtKeywords = [
    'hutang ke',
    'utang ke',
    'hutang dari',
    'utang dari',
    'pinjam dari',
    'pinjem dari',
    'pinjam uang dari',
    'pinjem uang dari',
  ];

  static List<String> receivableKeywords = [
    'pinjamkan ke',
    'pinjemin ke',
    'piutang ke',
    'piutang dari',
    'pinjamkan uang ke',
    'utangin ke',
    'piutang',
    'kasih pinjam ke',
    'kasih pinjem ke',
  ];

  static DateTime? _parseNlpDate(String text) {
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9/\-]'), ' ').trim();
    final parts = cleanText.split(RegExp(r'\s+'));
    if (parts.isEmpty) return null;

    final now = DateTime.now();
    int day = now.day;
    int month = now.month;
    int year = now.year;

    // 1. Try parsing direct dd/mm/yyyy or dd/mm
    final slashReg = RegExp(r'(\d{1,2})[\/\-](\d{1,2})(?:[\/\-](\d{2,4}))?');
    final match = slashReg.firstMatch(cleanText);
    if (match != null) {
      day = int.tryParse(match.group(1) ?? '') ?? day;
      month = int.tryParse(match.group(2) ?? '') ?? month;
      final yrStr = match.group(3);
      if (yrStr != null) {
        int yr = int.tryParse(yrStr) ?? year;
        if (yr < 100) yr += 2000;
        year = yr;
      }
      return DateTime(year, month, day);
    }

    // 2. Try parsing word-based month (Indonesian)
    final indonesianMonths = {
      'jan': 1, 'januari': 1,
      'feb': 2, 'februari': 2,
      'mar': 3, 'maret': 3,
      'apr': 4, 'april': 4,
      'mei': 5,
      'jun': 6, 'juni': 6,
      'jul': 7, 'juli': 7,
      'agu': 8, 'agustus': 8,
      'sep': 9, 'september': 9,
      'okt': 10, 'oktober': 10,
      'nov': 11, 'november': 11,
      'des': 12, 'desember': 12,
    };

    if (parts.length >= 2) {
      final parsedDay = int.tryParse(parts[0]);
      if (parsedDay != null) {
        day = parsedDay;
        final monthStr = parts[1];
        if (indonesianMonths.containsKey(monthStr)) {
          month = indonesianMonths[monthStr]!;
          if (parts.length >= 3) {
            final parsedYear = int.tryParse(parts[2]);
            if (parsedYear != null) {
              year = parsedYear;
              if (year < 100) year += 2000;
            }
          }
          return DateTime(year, month, day);
        }
      }
    }

    final parsedDay = int.tryParse(parts[0]);
    if (parsedDay != null && parsedDay >= 1 && parsedDay <= 31) {
      if (parsedDay < now.day) {
        month = now.month == 12 ? 1 : now.month + 1;
        year = now.month == 12 ? now.year + 1 : now.year;
      }
      return DateTime(year, month, parsedDay);
    }

    return null;
  }

  static _AmountMatch? _extractAmount(String text) {
    // Regex matches numbers, optional decimals/thousands separator, and abbreviations
    // Supports suffix: rb, ribu, rebu, k, jt, juta (case insensitive)
    // Matches expressions like: 15k, 15rb, 15rebu, 15.000, 2,5jt, 1.2juta, 15000
    final regExp = RegExp(
      r'\b(\d+(?:[\.,]\d+)*)\s*(rb|ribu|rebu|k|jt|juta)?\b',
      caseSensitive: false,
    );

    final matches = regExp.allMatches(text);
    if (matches.isEmpty) return null;

    _AmountMatch? bestMatch;

    for (final match in matches) {
      final matchedText = match.group(0) ?? '';
      final numberStr = match.group(1) ?? '';
      final suffix = match.group(2)?.toLowerCase();

      double parsedVal = _parseNumberString(numberStr, suffix);

      // We select the best match:
      // - Prioritize matches that have a currency suffix (e.g. "30k" over "2")
      // - Otherwise, select the one with the larger value to avoid selecting counts like "2 nasi goreng" (amount = 30000)
      if (bestMatch == null) {
        bestMatch = _AmountMatch(parsedVal, matchedText, suffix != null);
      } else {
        final currentHasSuffix = suffix != null;
        if (currentHasSuffix && !bestMatch.hasSuffix) {
          bestMatch = _AmountMatch(parsedVal, matchedText, true);
        } else if (currentHasSuffix == bestMatch.hasSuffix) {
          if (parsedVal > bestMatch.amount) {
            bestMatch = _AmountMatch(parsedVal, matchedText, currentHasSuffix);
          }
        }
      }
    }

    return bestMatch;
  }

  static double _parseNumberString(String numberStr, String? suffix) {
    // Normalize decimal and thousands separators
    String normalized = numberStr;

    if (suffix != null) {
      // If we have a suffix like "jt" or "k", the dot or comma is a decimal separator (e.g. 1.5jt = 1.5 million)
      normalized = normalized.replaceAll(',', '.');
    } else {
      // If no suffix, determine if dot/comma is thousands or decimal
      // E.g. "15.000" -> thousands, "12,5" -> decimal

      // If dot is followed by exactly 3 digits, and there are other digits, or it is standard thousands
      // Let's check: if there is a dot followed by exactly three digits at the end:
      final dotThreeDigits = RegExp(r'\.(\d{3})$');
      final commaThreeDigits = RegExp(r',(\d{3})$');

      if (dotThreeDigits.hasMatch(normalized) && !normalized.contains(',')) {
        // Dot is thousands separator. E.g. 15.000 -> 15000, 1.500.000 -> 1500000
        normalized = normalized.replaceAll('.', '');
      } else if (commaThreeDigits.hasMatch(normalized) &&
          !normalized.contains('.')) {
        // Comma is thousands separator. E.g. 15,000 -> 15000
        normalized = normalized.replaceAll(',', '');
      } else {
        // Mixed or single separator. E.g. 12,5 -> 12.5 or 12.5 -> 12.5
        normalized = normalized.replaceAll(',', '.');
      }
    }

    double value = double.tryParse(normalized) ?? 0.0;

    // Apply multiplier based on suffix
    if (suffix != null) {
      if (suffix == 'k' ||
          suffix == 'rb' ||
          suffix == 'ribu' ||
          suffix == 'rebu') {
        value *= 1000;
      } else if (suffix == 'jt' || suffix == 'juta') {
        value *= 1000000;
      }
    }

    return value;
  }
}

class _AmountMatch {
  final double amount;
  final String matchedText;
  final bool hasSuffix;

  _AmountMatch(this.amount, this.matchedText, this.hasSuffix);
}
