import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/nlp/nlp_parser.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/categories_provider.dart';
import '../transactions/transactions_provider.dart';

class EditableParsedTransaction {
  final String rawInput;
  final TextEditingController noteController;
  final TextEditingController amountController;
  String type; // 'income' | 'expense'
  Category? category;
  AccountWithBalance? account;
  double amount;
  String note;

  EditableParsedTransaction({
    required this.rawInput,
    required this.note,
    required this.amount,
    required this.type,
    this.category,
    this.account,
  })  : noteController = TextEditingController(text: note),
        amountController = TextEditingController(
            text: amount > 0 ? amount.toStringAsFixed(0) : '');

  void dispose() {
    noteController.dispose();
    amountController.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  List<EditableParsedTransaction>? parsedTransactions;
  bool isSaved;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.parsedTransactions,
    this.isSaved = false,
  });

  void dispose() {
    if (parsedTransactions != null) {
      for (final tx in parsedTransactions!) {
        tx.dispose();
      }
    }
  }
}

class QuickInputDialog extends ConsumerStatefulWidget {
  final bool startListeningImmediately;
  const QuickInputDialog({super.key, this.startListeningImmediately = false});

  @override
  ConsumerState<QuickInputDialog> createState() => _QuickInputDialogState();
}

class _QuickInputDialogState extends ConsumerState<QuickInputDialog> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';

  // Chat message history
  final List<ChatMessage> _messages = [];

  // Edit message variables
  int? _editingMessageIndex;
  TextEditingController? _editMessageController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    // Initial greeting message from bot
    _messages.add(
      ChatMessage(
        text: 'Halo! Saya asisten pencatatan keuangan Anda. Silakan tulis atau ucapkan transaksi Anda (misal: "beli makan 5 rebu beli ayam 20 rebu beli sotong 5k"), dan saya akan bantu mengelompokkannya secara otomatis.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    _inputFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _editMessageController?.dispose();
    for (final msg in _messages) {
      msg.dispose();
    }
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
        if (available && widget.startListeningImmediately) {
          _startListening();
        }
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
          });
          if (val.finalResult) {
            _stopListening();
          }
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
    try {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      if (_lastWords.trim().isNotEmpty) {
        _handleUserMessage(_lastWords);
        _lastWords = '';
      }
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _handleUserMessage(text);
  }

  void _handleUserMessage(String text) {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
    });

    _scrollToBottom();

    // 2. Parse Text using NlpParser.parseMultiple
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    final keywords = ref.read(keywordsNotifierProvider).value ?? [];
    final accounts = ref.read(accountsNotifierProvider).value ?? [];

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

    final parsedResults = NlpParser.parseMultiple(
      text,
      categories: categories,
      keywords: keywords,
      defaultExpenseCategory: expenseDefault,
      defaultIncomeCategory: incomeDefault,
    );

    // 3. Convert parsed results to EditableParsedTransaction
    final List<EditableParsedTransaction> editableTxs = [];
    final activeAccountId = ref.read(selectedAccountIdProvider);
    AccountWithBalance? defaultAccount;
    final activeAccountList = accounts.where((a) => a.account.id == activeAccountId).toList();
    if (activeAccountList.isNotEmpty) {
      defaultAccount = activeAccountList.first;
    } else if (accounts.isNotEmpty) {
      defaultAccount = accounts.first;
    }

    for (final res in parsedResults) {
      final detectedAccount = _detectAccount(res.rawInput, accounts) ?? defaultAccount;
      editableTxs.add(
        EditableParsedTransaction(
          rawInput: res.rawInput,
          note: res.note,
          amount: res.amount,
          type: res.type,
          category: res.category,
          account: detectedAccount,
        ),
      );
    }

    // 4. Generate Bot Response
    String botResponseText;
    if (editableTxs.isEmpty || (editableTxs.length == 1 && editableTxs.first.amountController.text.isEmpty)) {
      botResponseText = 'Maaf, saya tidak menemukan angka transaksi yang jelas dalam pesan Anda. Silakan tulis nominal transaksi secara jelas seperti: "beli makan 15rb" atau "gaji 3jt".';
    } else {
      botResponseText = 'Berikut adalah transaksi yang berhasil saya analisis. Silakan periksa kembali detailnya di bawah ini sebelum menyimpan:';
    }

    final botMsg = ChatMessage(
      text: botResponseText,
      isUser: false,
      timestamp: DateTime.now(),
      parsedTransactions: (editableTxs.isEmpty || (editableTxs.length == 1 && editableTxs.first.amountController.text.isEmpty)) ? null : editableTxs,
    );

    setState(() {
      _messages.add(botMsg);
    });

    _scrollToBottom();
  }

  void _saveMessageTransactions(ChatMessage message) {
    if (message.parsedTransactions == null || message.isSaved) return;

    final notifier = ref.read(transactionsNotifierProvider.notifier);
    int savedCount = 0;

    for (final tx in message.parsedTransactions!) {
      if (tx.amount <= 0) continue;
      if (tx.account == null) continue;

      final newTx = TransactionModel(
        accountId: tx.account!.account.id!,
        amount: tx.amount,
        type: tx.type,
        categoryId: tx.category?.id,
        note: tx.note.trim().isEmpty ? 'Transaksi Tanpa Catatan' : tx.note.trim(),
        rawInput: tx.rawInput,
        inputMethod: 'chat',
        createdAt: DateTime.now(),
      );

      notifier.addTransaction(newTx);
      savedCount++;
    }

    if (savedCount > 0) {
      setState(() {
        message.isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$savedCount transaksi berhasil disimpan ke dompet!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _toggleType(EditableParsedTransaction tx, String newType, List<Category> categories) {
    if (tx.type == newType) return;
    tx.type = newType;

    final filteredCats = categories.where((c) => c.type == newType).toList();
    final defaultCat = filteredCats.firstWhere(
      (c) => c.name.toLowerCase().contains('lain'),
      orElse: () => filteredCats.isNotEmpty ? filteredCats.first : categories.first,
    );
    tx.category = defaultCat;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  int _getLastUserMessageIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return i;
    }
    return -1;
  }

  bool _canEditLastMessage() {
    final lastUserIdx = _getLastUserMessageIndex();
    if (lastUserIdx == -1) return false;
    
    // Find the next message after lastUserIdx (which should be the bot response)
    if (lastUserIdx + 1 < _messages.length) {
      final nextMsg = _messages[lastUserIdx + 1];
      if (!nextMsg.isUser && nextMsg.isSaved) {
        return false; // Already saved, cannot edit anymore
      }
    }
    return true;
  }

  void _saveEditedMessage(int index) {
    final newText = _editMessageController?.text.trim() ?? '';
    if (newText.isEmpty) return;

    setState(() {
      // 1. Update the user message text
      _messages[index] = ChatMessage(
        text: newText,
        isUser: true,
        timestamp: DateTime.now(),
      );

      // 2. Remove the subsequent bot message if it exists
      if (index + 1 < _messages.length) {
        final nextMsg = _messages[index + 1];
        if (!nextMsg.isUser) {
          nextMsg.dispose(); // clean up controllers!
          _messages.removeAt(index + 1);
        }
      }

      _editingMessageIndex = null;
      _editMessageController?.dispose();
      _editMessageController = null;
    });

    // 3. Re-parse and generate a new bot message response
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    final keywords = ref.read(keywordsNotifierProvider).value ?? [];
    final accounts = ref.read(accountsNotifierProvider).value ?? [];

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

    final parsedResults = NlpParser.parseMultiple(
      newText,
      categories: categories,
      keywords: keywords,
      defaultExpenseCategory: expenseDefault,
      defaultIncomeCategory: incomeDefault,
    );

    final List<EditableParsedTransaction> editableTxs = [];
    final activeAccountId = ref.read(selectedAccountIdProvider);
    AccountWithBalance? defaultAccount;
    final activeAccountList = accounts.where((a) => a.account.id == activeAccountId).toList();
    if (activeAccountList.isNotEmpty) {
      defaultAccount = activeAccountList.first;
    } else if (accounts.isNotEmpty) {
      defaultAccount = accounts.first;
    }

    for (final res in parsedResults) {
      final detectedAccount = _detectAccount(res.rawInput, accounts) ?? defaultAccount;
      editableTxs.add(
        EditableParsedTransaction(
          rawInput: res.rawInput,
          note: res.note,
          amount: res.amount,
          type: res.type,
          category: res.category,
          account: detectedAccount,
        ),
      );
    }

    String botResponseText;
    if (editableTxs.isEmpty || (editableTxs.length == 1 && editableTxs.first.amountController.text.isEmpty)) {
      botResponseText = 'Maaf, saya tidak menemukan angka transaksi yang jelas dalam pesan Anda. Silakan tulis nominal transaksi secara jelas seperti: "beli makan 15rb" atau "gaji 3jt".';
    } else {
      botResponseText = 'Berikut adalah transaksi yang berhasil saya analisis. Silakan periksa kembali detailnya di bawah ini sebelum menyimpan:';
    }

    final botMsg = ChatMessage(
      text: botResponseText,
      isUser: false,
      timestamp: DateTime.now(),
      parsedTransactions: (editableTxs.isEmpty || (editableTxs.length == 1 && editableTxs.first.amountController.text.isEmpty)) ? null : editableTxs,
    );

    setState(() {
      // Insert the new bot response right after the edited user message
      _messages.insert(index + 1, botMsg);
    });

    _scrollToBottom();
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
          orElse: () => accounts.first,
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
    if (lowerText.contains('qris')) {
      final eWallet = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('e-wallet') || a.account.name.toLowerCase().contains('ewallet'),
        orElse: () => accounts.first,
      );
      if (eWallet.account.name.toLowerCase().contains('e-wallet') || eWallet.account.name.toLowerCase().contains('ewallet')) {
        return eWallet;
      }

      final gopay = accounts.firstWhere(
        (a) => a.account.name.toLowerCase().contains('gopay') || a.account.name.toLowerCase().contains('go-pay'),
        orElse: () => accounts.first,
      );
      if (gopay.account.name.toLowerCase().contains('gopay') || gopay.account.name.toLowerCase().contains('go-pay')) {
        return gopay;
      }

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

  Widget _buildTypeToggleChip({
    required String title,
    required bool isActive,
    required Color activeColor,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isActive ? activeColor : (isDarkMode ? Colors.white30 : Colors.black26),
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeColor : (isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final keywordsAsync = ref.watch(keywordsNotifierProvider);
    final accountsAsync = ref.watch(accountsNotifierProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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

    final categories = categoriesAsync.value ?? [];
    final accounts = accountsAsync.value ?? [];

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
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Chat Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined,
                      size: 20,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'Asisten Finansial',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_outlined, size: 20, color: isDarkMode ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
            ),
            Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.black12),

            // Message Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isEditingThis = _editingMessageIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.isUser) ...[
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isDarkMode ? const Color(0xFF2C313E) : Colors.grey.shade200,
                            child: Icon(Icons.smart_toy_outlined, size: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? (isDarkMode ? const Color(0xFF2A2E3D) : const Color(0xFF1E222B))
                                  : (isDarkMode ? const Color(0xFF232732) : Colors.grey.shade50),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16.0),
                                topRight: const Radius.circular(16.0),
                                bottomLeft: message.isUser ? const Radius.circular(16.0) : const Radius.circular(4.0),
                                bottomRight: message.isUser ? const Radius.circular(4.0) : const Radius.circular(16.0),
                              ),
                              border: Border.all(
                                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: isEditingThis
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: _editMessageController,
                                        maxLines: null,
                                        style: const TextStyle(fontSize: 13.0, color: Colors.white),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                      const Divider(color: Colors.white24, height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _editingMessageIndex = null;
                                                _editMessageController?.dispose();
                                                _editMessageController = null;
                                              });
                                            },
                                            child: const Text('Batal', style: TextStyle(color: Colors.white70, fontSize: 12.0)),
                                          ),
                                          const SizedBox(width: 8.0),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                              minimumSize: const Size(60, 28),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                            ),
                                            onPressed: () => _saveEditedMessage(index),
                                            child: const Text('Simpan', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              message.text,
                                              style: TextStyle(
                                                fontSize: 13.0,
                                                color: message.isUser
                                                    ? Colors.white
                                                    : (isDarkMode ? Colors.white : Colors.black87),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          if (message.isUser && index == _getLastUserMessageIndex() && _canEditLastMessage()) ...[
                                            const SizedBox(width: 8.0),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _editingMessageIndex = index;
                                                  _editMessageController = TextEditingController(text: message.text);
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.only(bottom: 2.0),
                                                child: Icon(
                                                  Icons.edit_outlined,
                                                  size: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (message.parsedTransactions != null) ...[
                                        ...message.parsedTransactions!.asMap().entries.map((entry) {
                                          final idx = entry.key;
                                          final tx = entry.value;
                                          return Container(
                                            margin: const EdgeInsets.only(top: 10.0),
                                            padding: const EdgeInsets.all(12.0),
                                            decoration: BoxDecoration(
                                              color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(
                                                color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.08),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Transaksi #${idx + 1}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12.0,
                                                        color: isDarkMode ? Colors.white70 : Colors.black87,
                                                      ),
                                                    ),
                                                    if (!message.isSaved)
                                                      IconButton(
                                                        icon: const Icon(Icons.delete_outline_outlined, size: 16, color: Colors.redAccent),
                                                        onPressed: () {
                                                          setState(() {
                                                            message.parsedTransactions!.removeAt(idx);
                                                            if (message.parsedTransactions!.isEmpty) {
                                                              message.parsedTransactions = null;
                                                            }
                                                          });
                                                        },
                                                        constraints: const BoxConstraints(),
                                                        padding: EdgeInsets.zero,
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8.0),
                                                Row(
                                                  children: [
                                                    _buildTypeToggleChip(
                                                      title: 'Pengeluaran',
                                                      isActive: tx.type == 'expense',
                                                      activeColor: Colors.redAccent,
                                                      onTap: message.isSaved
                                                          ? null
                                                          : () => setState(() => _toggleType(tx, 'expense', categories)),
                                                      isDarkMode: isDarkMode,
                                                    ),
                                                    const SizedBox(width: 8.0),
                                                    _buildTypeToggleChip(
                                                      title: 'Pemasukan',
                                                      isActive: tx.type == 'income',
                                                      activeColor: const Color(0xFF10B981),
                                                      onTap: message.isSaved
                                                          ? null
                                                          : () => setState(() => _toggleType(tx, 'income', categories)),
                                                      isDarkMode: isDarkMode,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10.0),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: TextField(
                                                        controller: tx.noteController,
                                                        enabled: !message.isSaved,
                                                        style: TextStyle(fontSize: 11.5, color: isDarkMode ? Colors.white : Colors.black87),
                                                        decoration: InputDecoration(
                                                          labelText: 'Catatan',
                                                          labelStyle: const TextStyle(fontSize: 10.0),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6.0),
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextField(
                                                        controller: tx.amountController,
                                                        enabled: !message.isSaved,
                                                        keyboardType: TextInputType.number,
                                                        style: TextStyle(fontSize: 11.5, color: isDarkMode ? Colors.white : Colors.black87),
                                                        decoration: InputDecoration(
                                                          labelText: 'Nominal',
                                                          labelStyle: const TextStyle(fontSize: 10.0),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8.0),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: DropdownButtonFormField<Category>(
                                                        value: tx.category,
                                                        disabledHint: tx.category != null ? Text(tx.category!.name, style: const TextStyle(fontSize: 11.0)) : null,
                                                        items: categories
                                                            .where((c) => c.type == tx.type)
                                                            .map((c) => DropdownMenuItem(
                                                                  value: c,
                                                                  child: Text(c.name, style: const TextStyle(fontSize: 11.0)),
                                                                ))
                                                            .toList(),
                                                        onChanged: message.isSaved
                                                            ? null
                                                            : (val) => setState(() => tx.category = val),
                                                        decoration: InputDecoration(
                                                          labelText: 'Kategori',
                                                          labelStyle: const TextStyle(fontSize: 9.5),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6.0),
                                                    Expanded(
                                                      child: DropdownButtonFormField<AccountWithBalance>(
                                                        value: accounts.any((a) => a.account.id == tx.account?.account.id)
                                                            ? accounts.firstWhere((a) => a.account.id == tx.account?.account.id)
                                                            : null,
                                                        disabledHint: tx.account != null ? Text(tx.account!.account.name, style: const TextStyle(fontSize: 11.0)) : null,
                                                        items: accounts
                                                            .map((a) => DropdownMenuItem(
                                                                  value: a,
                                                                  child: Text(a.account.name, style: const TextStyle(fontSize: 11.0)),
                                                                ))
                                                            .toList(),
                                                        onChanged: message.isSaved
                                                            ? null
                                                            : (val) => setState(() => tx.account = val),
                                                        decoration: InputDecoration(
                                                          labelText: 'Dompet',
                                                          labelStyle: const TextStyle(fontSize: 9.5),
                                                          isDense: true,
                                                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 12.0),
                                        if (!message.isSaved)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isDarkMode ? Colors.white : const Color(0xFF1E222B),
                                              foregroundColor: isDarkMode ? Colors.black : Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              minimumSize: const Size(double.infinity, 32),
                                            ),
                                            icon: const Icon(Icons.check_circle_outline_outlined, size: 14),
                                            label: const Text('Simpan ke Dompet', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            onPressed: () {
                                              for (final tx in message.parsedTransactions!) {
                                                final amtText = tx.amountController.text.trim();
                                                tx.amount = double.tryParse(amtText) ?? 0.0;
                                                tx.note = tx.noteController.text.trim();
                                              }
                                              _saveMessageTransactions(message);
                                            },
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10.0),
                                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.check_circle_outlined, color: Color(0xFF10B981), size: 14),
                                                SizedBox(width: 6.0),
                                                Text(
                                                  'Tersimpan ke Dompet',
                                                  style: TextStyle(
                                                    color: Color(0xFF10B981),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                      ]
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: isDarkMode ? Colors.white10 : Colors.black12),

            // Input Panel
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 8.0, bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF232732) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.08),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: TextField(
                              controller: _inputController,
                              focusNode: _inputFocusNode,
                              onSubmitted: (_) => _sendMessage(),
                              style: TextStyle(
                                fontSize: 13.0,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening ? 'Mendengarkan...' : 'Ketik pesan transaksi...',
                                hintStyle: TextStyle(
                                  fontSize: 13.0,
                                  color: isDarkMode ? Colors.white30 : Colors.black38,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none_outlined,
                              color: _isListening ? Colors.redAccent : (isDarkMode ? Colors.white70 : Colors.black54),
                              size: 20,
                            ),
                            onPressed: _isListening ? _stopListening : _startListening,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E222B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
