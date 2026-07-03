import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/nlp/nlp_parser.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/categories_provider.dart';
import '../transactions/transactions_provider.dart';

class QuickInputDialog extends ConsumerStatefulWidget {
  const QuickInputDialog({super.key});

  @override
  ConsumerState<QuickInputDialog> createState() => _QuickInputDialogState();
}

class _QuickInputDialogState extends ConsumerState<QuickInputDialog> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';

  // Current parsed/edited values
  double _amount = 0.0;
  String _type = 'expense'; // 'income' | 'expense'
  Category? _selectedCategory;
  AccountWithBalance? _selectedAccount;
  String _note = '';

  final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _inputController.addListener(_onTextChanged);
    
    // Select the active account from the home filter as the default account,
    // or fallback to the first available account.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountsAsync = ref.read(accountsNotifierProvider);
      final activeAccountId = ref.read(selectedAccountIdProvider);
      
      accountsAsync.whenData((accounts) {
        if (accounts.isNotEmpty) {
          setState(() {
            _selectedAccount = accounts.firstWhere(
              (a) => a.account.id == activeAccountId,
              orElse: () => accounts.first,
            );
          });
        }
      });
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _noteController.dispose();
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      if (mounted) {
        setState(() {
          _speechAvailable = available;
        });
      }
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _startListening() async {
    if (!_speechAvailable) return;
    
    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    try {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _lastWords = val.recognizedWords;
            if (_lastWords.isNotEmpty) {
              _inputController.text = _lastWords;
              _inputController.selection = TextSelection.fromPosition(
                TextPosition(offset: _inputController.text.length),
              );
            }
          });
        },
        localeId: 'id_ID',
      );
    } catch (e) {
      debugPrint('Speech listen failed: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  // Smart Account Detection based on keywords in text
  AccountWithBalance? _detectAccount(String text, List<AccountWithBalance> accounts) {
    final lowerText = text.toLowerCase();

    // 1. Specific matches: check if text contains "gopay", "shopeepay", "dana", "ovo"
    if (lowerText.contains('gopay')) {
      final found = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('gopay'),
        orElse: () => accounts.firstWhere(
          (a) => a.account.name.toLowerCase().contains('go-pay'),
          orElse: () => accounts.first, // fallback if not found
        ),
      );
      if (found.account.name.toLowerCase().contains('gopay') || found.account.name.toLowerCase().contains('go-pay')) {
        return found;
      }
    }

    if (lowerText.contains('shopeepay') || lowerText.contains('shopee pay')) {
      final found = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('shopeepay') || a.account.name.toLowerCase().contains('shopee pay'),
        orElse: () => accounts.first,
      );
      if (found.account.name.toLowerCase().contains('shopeepay') || found.account.name.toLowerCase().contains('shopee pay')) {
        return found;
      }
    }

    if (lowerText.contains('dana')) {
      final found = accounts.firstWhere(
        (a) => a.account.name.toLowerCase() == 'dana' || a.account.name.toLowerCase().contains('dana'),
        orElse: () => accounts.first,
      );
      if (found.account.name.toLowerCase().contains('dana')) {
        return found;
      }
    }

    if (lowerText.contains('ovo')) {
      final found = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('ovo'),
        orElse: () => accounts.first,
      );
      if (found.account.name.toLowerCase().contains('ovo')) {
        return found;
      }
    }

    // 2. Generic "qris" match:
    // If text contains "qris", try to find a wallet named "E-Wallet", "GoPay", "ShopeePay", "Dana", "Ovo" in order of priority.
    if (lowerText.contains('qris')) {
      // Look for E-Wallet first
      final eWallet = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('e-wallet') || a.account.name.toLowerCase().contains('ewallet'),
        orElse: () => accounts.first,
      );
      if (eWallet.account.name.toLowerCase().contains('e-wallet') || eWallet.account.name.toLowerCase().contains('ewallet')) {
        return eWallet;
      }

      // Fallback to GoPay as the default e-wallet
      final gopay = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('gopay') || a.account.name.toLowerCase().contains('go-pay'),
        orElse: () => accounts.first,
      );
      if (gopay.account.name.toLowerCase().contains('gopay') || gopay.account.name.toLowerCase().contains('go-pay')) {
        return gopay;
      }

      // Fallback to any other e-wallet
      final otherWallet = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('dana') ||
               a.account.name.toLowerCase().contains('ovo') ||
               a.account.name.toLowerCase().contains('shopeepay') ||
               a.account.name.toLowerCase().contains('shopee pay'),
        orElse: () => accounts.first,
      );
      if (otherWallet.account.name.toLowerCase().contains('dana') ||
          otherWallet.account.name.toLowerCase().contains('ovo') ||
          otherWallet.account.name.toLowerCase().contains('shopeepay') ||
          otherWallet.account.name.toLowerCase().contains('shopee pay')) {
        return otherWallet;
      }
    }

    // 3. Regular account detection
    for (final acc in accounts) {
      final nameLower = acc.account.name.toLowerCase();
      if (lowerText.contains(nameLower)) {
        return acc;
      }
      if (nameLower.contains('mandiri') && lowerText.contains('mandiri')) {
        return acc;
      }
      if (nameLower.contains('bca') && lowerText.contains('bca')) {
        return acc;
      }
      if (nameLower == 'tunai' &&
          (lowerText.contains('cash') ||
           lowerText.contains('tunai') ||
           lowerText.contains('dompet') ||
           lowerText.contains('kantong'))) {
        return acc;
      }
    }
    return null;
  }

  void _onTextChanged() {
    try {
      final text = _inputController.text;
      final categoriesAsync = ref.read(categoriesNotifierProvider);
      final keywordsAsync = ref.read(keywordsNotifierProvider);
      final accountsAsync = ref.read(accountsNotifierProvider);

      if (categoriesAsync.hasValue && keywordsAsync.hasValue && accountsAsync.hasValue) {
        final categories = categoriesAsync.value ?? [];
        final keywords = keywordsAsync.value ?? [];
        final accounts = accountsAsync.value ?? [];

        // Safe fallback searches to prevent StateError
        final expenseDefault = categories.firstWhere(
          (c) => c.name.toLowerCase().contains('lain') && c.type == 'expense',
          orElse: () => categories.firstWhere(
            (c) => c.type == 'expense',
            orElse: () => Category(id: 99, name: 'Lain-lain', type: 'expense'),
          ),
        );
        final incomeDefault = categories.firstWhere(
          (c) => c.name.toLowerCase().contains('lain') && c.type == 'income',
          orElse: () => categories.firstWhere(
            (c) => c.type == 'income',
            orElse: () => Category(id: 98, name: 'Lain-lain (Masuk)', type: 'income'),
          ),
        );

        final result = NlpParser.parse(
          text,
          categories: categories,
          keywords: keywords,
          defaultExpenseCategory: expenseDefault,
          defaultIncomeCategory: incomeDefault,
        );

        // Trigger Smart Account Detection
        final detectedAccount = _detectAccount(text, accounts);

        setState(() {
          _amount = result.amount;
          _type = result.type;
          _selectedCategory = result.category;
          _note = result.note;
          if (detectedAccount != null) {
            _selectedAccount = detectedAccount;
          }

          // Safely update sub-controllers without breaking input focus
          _noteController.text = _note;
          _amountController.text = _amount > 0 ? _amount.toStringAsFixed(0) : '';
        });
      }
    } catch (e, st) {
      debugPrint('Error in _onTextChanged: $e\n$st');
    }
  }

  void _saveTransaction() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal transaksi harus lebih dari Rp 0'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan buat akun/dompet terlebih dahulu di pengaturan'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newTx = TransactionModel(
      accountId: _selectedAccount!.account.id!,
      amount: _amount,
      type: _type,
      categoryId: _selectedCategory?.id,
      note: _note.trim().isEmpty ? 'Transaksi Tanpa Catatan' : _note.trim(),
      rawInput: _inputController.text,
      inputMethod: _lastWords.isNotEmpty ? 'voice' : 'text',
      createdAt: DateTime.now(),
    );

    ref.read(transactionsNotifierProvider.notifier).addTransaction(newTx);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final keywordsAsync = ref.watch(keywordsNotifierProvider);
    final accountsAsync = ref.watch(accountsNotifierProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Show loading spinner while Riverpod loads database records
    if (categoriesAsync.isLoading || keywordsAsync.isLoading || accountsAsync.isLoading) {
      return Dialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        child: const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Input',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_outlined, size: 20, color: isDarkMode ? Colors.white : Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 12.0),

              // Input Bar, Mic, and instant checkmark Save button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _saveTransaction(),
                      decoration: InputDecoration(
                        hintText: 'e.g. beli bakso 15rb atau gaji 3jt',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 13.0,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF12161A) : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14.0),
                          borderSide: BorderSide(
                            color: _type == 'income' ? const Color(0xFFFC8A40) : const Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14.0,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (_speechAvailable) ...[
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isListening
                                ? [Colors.redAccent, Colors.red]
                                : [const Color(0xFF004D4D), const Color(0xFF003434)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.red.withOpacity(0.2)
                                  : const Color(0xFF004D4D).withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_off_outlined : Icons.mic_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8.0),
                  // Green instant Save button
                  GestureDetector(
                    onTap: _saveTransaction,
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF004D4D),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF004D4D).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),

              // Live Parsing Preview
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 14.0,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Preview Analisis Teks',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF12161A) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _formatter.format(_amount),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                        color: _type == 'income' ? const Color(0xFFFC8A40) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Divider(height: 1, thickness: 0.5),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Icon(Icons.notes_outlined, size: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _note.isEmpty ? '(Belum ada catatan)' : _note,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontStyle: _note.isEmpty ? FontStyle.italic : FontStyle.normal,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Manual Correction Section
              Text(
                'Sesuaikan Hasil Analisis (Opsional)',
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8.0),

              // Type Switcher
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pengeluaran', style: TextStyle(fontSize: 12.0))),
                      selected: _type == 'expense',
                      selectedColor: const Color(0xFFEF4444).withOpacity(0.15),
                      checkmarkColor: const Color(0xFFEF4444),
                      labelStyle: TextStyle(
                        color: _type == 'expense' ? const Color(0xFFEF4444) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = 'expense';
                            if (_selectedCategory?.type == 'income') {
                              categoriesAsync.whenData((cats) {
                                final expenseCats = cats.where((c) => c.type == 'expense').toList();
                                if (expenseCats.isNotEmpty) {
                                  _selectedCategory = expenseCats.first;
                                }
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Pemasukan', style: TextStyle(fontSize: 12.0))),
                      selected: _type == 'income',
                      selectedColor: const Color(0xFFFC8A40).withOpacity(0.15),
                      checkmarkColor: const Color(0xFFFC8A40),
                      labelStyle: TextStyle(
                        color: _type == 'income' ? const Color(0xFFFC8A40) : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _type = 'income';
                            if (_selectedCategory?.type == 'expense') {
                              categoriesAsync.whenData((cats) {
                                final incomeCats = cats.where((c) => c.type == 'income').toList();
                                if (incomeCats.isNotEmpty) {
                                  _selectedCategory = incomeCats.first;
                                }
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),

              // Stacked Account & Category Dropdowns to prevent horizontal overflows
              accountsAsync.when(
                data: (accounts) {
                  return DropdownButtonFormField<AccountWithBalance>(
                    value: accounts.any((a) => a.account.id == _selectedAccount?.account.id)
                        ? accounts.firstWhere((a) => a.account.id == _selectedAccount?.account.id)
                        : (accounts.isNotEmpty ? accounts.first : null),
                    decoration: InputDecoration(
                      labelText: 'Dompet/Akun',
                      labelStyle: const TextStyle(fontSize: 11.0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<AccountWithBalance>(
                        value: acc,
                        child: Text(acc.account.name, style: const TextStyle(fontSize: 12.0)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAccount = val;
                      });
                    },
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, st) => const Text('Error load akun'),
              ),
              const SizedBox(height: 10.0),
              
              categoriesAsync.when(
                data: (cats) {
                  final filteredCats = cats.where((c) => c.type == _type).toList();
                  final validCategory = filteredCats.any((c) => c.id == _selectedCategory?.id)
                      ? filteredCats.firstWhere((c) => c.id == _selectedCategory?.id)
                      : (filteredCats.isNotEmpty ? filteredCats.first : null);

                  return DropdownButtonFormField<Category>(
                    value: validCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      labelStyle: const TextStyle(fontSize: 11.0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: filteredCats.map((cat) {
                      return DropdownMenuItem<Category>(
                        value: cat,
                        child: Text(cat.name, style: const TextStyle(fontSize: 12.0)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, st) => const Text('Error load kategori'),
              ),
              const SizedBox(height: 10.0),

              // Manual Note & Amount corrections
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Edit Catatan',
                        labelStyle: const TextStyle(fontSize: 11.0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: const TextStyle(fontSize: 12.0),
                      onChanged: (val) {
                        _note = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal',
                        labelStyle: const TextStyle(fontSize: 11.0),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: const TextStyle(fontSize: 12.0),
                      onChanged: (val) {
                        setState(() {
                          _amount = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Save Action Button (Secondary backup)
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Transaksi',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
