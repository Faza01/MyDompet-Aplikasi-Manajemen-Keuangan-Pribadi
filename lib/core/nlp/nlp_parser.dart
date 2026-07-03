import '../../data/models/category.dart';
import '../../data/models/keyword.dart';

class ParsedResult {
  final double amount;
  final String type; // 'income' | 'expense'
  final Category? category;
  final String note;
  final String rawInput;

  ParsedResult({
    required this.amount,
    required this.type,
    this.category,
    required this.note,
    required this.rawInput,
  });

  @override
  String toString() {
    return 'ParsedResult(amount: $amount, type: $type, category: ${category?.name}, note: $note)';
  }
}

class NlpParser {
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
    final cleanInput = input.replaceAll(RegExp(r'rp\.?\s*', caseSensitive: false), '').trim();
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
        if (bestKeywordMatch == null || keywordLower.length > bestKeywordMatch.keyword.length) {
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
      final incomeIndicators = ['gaji', 'terima', 'masuk', 'dapat', 'bonus', 'payday', 'angpao', 'sallary', 'untung', 'cashback'];
      final containsIncomeIndicator = incomeIndicators.any((indicator) => lowercaseInput.contains(indicator));
      if (containsIncomeIndicator) {
        type = 'income';
      }
    }

    // Set default category if none matched
    if (matchedCategory == null) {
      matchedCategory = type == 'income' ? defaultIncomeCategory : defaultExpenseCategory;
    }

    // 4. Construct Note
    // The note is the remaining text. If the remaining text is empty, we fall back to the original input.
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
    );
  }

  static _AmountMatch? _extractAmount(String text) {
    // Regex matches numbers, optional decimals/thousands separator, and abbreviations
    // Supports suffix: rb, ribu, k, jt, juta (case insensitive)
    // Matches expressions like: 15k, 15rb, 15.000, 2,5jt, 1.2juta, 15000
    final regExp = RegExp(
      r'\b(\d+(?:[\.,]\d+)*)\s*(rb|ribu|k|jt|juta)?\b',
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
      } else if (commaThreeDigits.hasMatch(normalized) && !normalized.contains('.')) {
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
      if (suffix == 'k' || suffix == 'rb' || suffix == 'ribu') {
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
