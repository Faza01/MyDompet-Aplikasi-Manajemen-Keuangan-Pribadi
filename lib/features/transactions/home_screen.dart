import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/categories_provider.dart';
import 'transactions_provider.dart';
import '../../main.dart';

class DashboardTimeframeNotifier extends Notifier<String> {
  @override
  String build() => 'month';

  void setTimeframe(String value) {
    state = value;
  }
}

final dashboardTimeframeProvider = NotifierProvider.autoDispose<DashboardTimeframeNotifier, String>(
  DashboardTimeframeNotifier.new,
);

// Helper to format currency
String _formatRp(double val) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(val);
}

// Helper to get IconData based on string identifier
IconData _getCategoryIcon(String? iconName) {
  switch (iconName) {
    case 'work': return Icons.work_outline;
    case 'card_giftcard': return Icons.card_giftcard_outlined;
    case 'download': return Icons.download_outlined;
    case 'add_circle': return Icons.add_circle_outline;
    case 'restaurant': return Icons.restaurant_outlined;
    case 'directions_car': return Icons.directions_car_outlined;
    case 'shopping_bag': return Icons.shopping_bag_outlined;
    case 'receipt_long': return Icons.receipt_long_outlined;
    case 'sports_esports': return Icons.sports_esports_outlined;
    case 'swap_horiz': return Icons.swap_horiz;
    default: return Icons.help_outline;
  }
}

// Helper to get Account icon
IconData _getAccountIcon(String? iconName) {
  switch (iconName) {
    case 'wallet': return Icons.account_balance_wallet_outlined;
    case 'account_balance': return Icons.account_balance_outlined;
    case 'payment': return Icons.payment_outlined;
    default: return Icons.credit_card_outlined;
  }
}

Color? _parseCustomColor(String? colorStr) {
  if (colorStr == null || colorStr.isEmpty) return null;
  if (colorStr == 'teal') return const Color(0xFF004D4D);
  if (colorStr == 'orange') return const Color(0xFFFC8A40);
  if (colorStr == 'light_blue') return const Color(0xFF0288D1);
  if (colorStr == 'dark_blue') return const Color(0xFF0A192F);
  if (colorStr == 'red') return const Color(0xFFD32F2F);
  if (colorStr == 'purple') return const Color(0xFF673AB7);
  if (colorStr == 'black') return const Color(0xFF2C2C2C);
  if (colorStr == 'pink') return const Color(0xFFE91E63);

  // Try parsing hex
  try {
    String cleanHex = colorStr.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      return Color(int.parse('FF$cleanHex', radix: 16));
    } else if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
  } catch (_) {}

  // Try parsing RGB (e.g. 255,0,85)
  try {
    if (colorStr.contains(',')) {
      final parts = colorStr.split(',').map((p) => int.parse(p.trim())).toList();
      if (parts.length == 3) {
        return Color.fromARGB(255, parts[0], parts[1], parts[2]);
      }
    }
  } catch (_) {}

  return null;
}

List<Color> _generatePremiumGradient(Color baseColor) {
  final double darkenFactor = 0.5;
  final Color darkColor = Color.fromARGB(
    255,
    (baseColor.red * darkenFactor).round(),
    (baseColor.green * darkenFactor).round(),
    (baseColor.blue * darkenFactor).round(),
  );
  
  final double lightenFactor = 0.55;
  final Color lightColor = Color.fromARGB(
    255,
    (baseColor.red + (255 - baseColor.red) * lightenFactor).round(),
    (baseColor.green + (255 - baseColor.green) * lightenFactor).round(),
    (baseColor.blue + (255 - baseColor.blue) * lightenFactor).round(),
  );
  
  return [darkColor, baseColor, lightColor];
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final selectedAccountId = ref.watch(selectedAccountIdProvider);
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final dashboardTimeframe = ref.watch(dashboardTimeframeProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(accountsNotifierProvider);
            ref.invalidate(transactionsNotifierProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, Selamat Datang!',
                            style: TextStyle(
                              fontSize: 13.0,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const Text(
                            'MyDompet',
                            style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode ? const Color(0xFF1E222B) : Colors.grey[100],
                          ),
                          child: Icon(
                            isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 20,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).setThemeMode(
                              isDarkMode ? ThemeMode.light : ThemeMode.dark);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Account Switcher Horizontal list (Stack Carousel)
              SliverToBoxAdapter(
                child: Container(
                  height: 185.0,
                  margin: const EdgeInsets.symmetric(vertical: 12.0),
                  child: accountsAsync.when(
                    data: (accounts) {
                      final totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);

                      return AccountStackCarousel(
                        accounts: accounts,
                        totalBalance: totalBalance,
                        selectedAccountId: selectedAccountId,
                        ref: ref,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => Center(child: Text('Error loading akun: $err')),
                  ),
                ),
              ),


              // Timeframe selector pills (Capsule style)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      width: 280.0,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF131D1D) : const Color(0xFFECEEEE),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          _buildTimeframePill(context, ref, 'day', 'Hari', dashboardTimeframe),
                          _buildTimeframePill(context, ref, 'week', 'Minggu', dashboardTimeframe),
                          _buildTimeframePill(context, ref, 'month', 'Bulan', dashboardTimeframe),
                          _buildTimeframePill(context, ref, 'year', 'Tahun', dashboardTimeframe),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Monthly Summary Card
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverToBoxAdapter(
                  child: transactionsAsync.when(
                    data: (transactions) {
                      final now = DateTime.now();
                      
                      // Filter transactions of current selected account AND current selected timeframe
                      final filteredTxs = transactions.where((tx) {
                        // If selectedAccountId is null, we sum all accounts
                        final matchesAccount = selectedAccountId == null || tx.accountId == selectedAccountId;
                        
                        // Date filter
                        bool matchesDate = false;
                        if (dashboardTimeframe == 'day') {
                          matchesDate = tx.createdAt.year == now.year &&
                              tx.createdAt.month == now.month &&
                              tx.createdAt.day == now.day;
                        } else if (dashboardTimeframe == 'week') {
                          final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                          matchesDate = tx.createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
                        } else if (dashboardTimeframe == 'month') {
                          matchesDate = tx.createdAt.year == now.year && tx.createdAt.month == now.month;
                        } else if (dashboardTimeframe == 'year') {
                          matchesDate = tx.createdAt.year == now.year;
                        }
                        
                        // Exclude "Transfer" transactions from stats
                        final isNotTransfer = tx.categoryId != null &&
                            categoriesAsync.maybeWhen(
                              data: (cats) {
                                final cat = cats.firstWhere((c) => c.id == tx.categoryId, orElse: () => cats.first);
                                return cat.name.toLowerCase() != 'transfer';
                              },
                              orElse: () => true,
                            );

                        return matchesDate && matchesAccount && isNotTransfer;
                      }).toList();

                      final income = filteredTxs
                          .where((t) => t.type == 'income')
                          .fold(0.0, (sum, t) => sum + t.amount);
                      final expense = filteredTxs
                          .where((t) => t.type == 'expense')
                          .fold(0.0, (sum, t) => sum + t.amount);

                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF131D1D) : Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.015),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: const Icon(
                                      Icons.trending_down_outlined,
                                      color: Color(0xFFEF4444),
                                      size: 22.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    'Pengeluaran',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _formatRp(expense),
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    dashboardTimeframe == 'day'
                                        ? 'Hari ini'
                                        : dashboardTimeframe == 'week'
                                            ? 'Minggu ini'
                                            : dashboardTimeframe == 'month'
                                                ? 'Bulan ini'
                                                : 'Tahun ini',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF131D1D) : Colors.white,
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.015),
                                    blurRadius: 10.0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: const Icon(
                                      Icons.payments_outlined,
                                      color: Color(0xFF10B981),
                                      size: 22.0,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    'Pendapatan',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _formatRp(income),
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    dashboardTimeframe == 'day'
                                        ? 'Hari ini'
                                        : dashboardTimeframe == 'week'
                                            ? 'Minggu ini'
                                            : dashboardTimeframe == 'month'
                                                ? 'Bulan ini'
                                                : 'Tahun ini',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: LinearProgressIndicator()),
                    error: (err, st) => Text('Error loading ringkasan: $err'),
                  ),
                ),
              ),

              // Unified Transaction History Card Container
              transactionsAsync.when(
                data: (allTransactions) {
                  final now = DateTime.now();
                  
                  // Filter by Account and Timeframe
                  final transactions = allTransactions.where((tx) {
                    final matchesAccount = selectedAccountId == null || tx.accountId == selectedAccountId;
                    
                    bool matchesDate = false;
                    if (dashboardTimeframe == 'day') {
                      matchesDate = tx.createdAt.year == now.year &&
                          tx.createdAt.month == now.month &&
                          tx.createdAt.day == now.day;
                    } else if (dashboardTimeframe == 'week') {
                      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                      matchesDate = tx.createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
                    } else if (dashboardTimeframe == 'month') {
                      matchesDate = tx.createdAt.year == now.year && tx.createdAt.month == now.month;
                    } else if (dashboardTimeframe == 'year') {
                      matchesDate = tx.createdAt.year == now.year;
                    }
                    
                    return matchesAccount && matchesDate;
                  }).toList();

                  // Sort transactions by date descending
                  transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (transactions.isEmpty) {
                    return const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: Card(
                          elevation: 0,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    'Belum ada transaksi.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
                        sliver: SliverToBoxAdapter(
                          child: Card(
                            elevation: 0,
                            color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              side: BorderSide(
                                color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isDarkMode ? const Color(0xFF003434) : const Color(0xFFE0F2F1),
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                        child: Icon(
                                          Icons.history_outlined,
                                          color: isDarkMode ? const Color(0xFF94D1D1) : const Color(0xFF004D4D),
                                          size: 22.0,
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      const Text(
                                        'Riwayat Transaksi',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16.0),
                                  
                                  // Transactions list items inside Column
                                  Column(
                                    children: List.generate(transactions.length, (idx) {
                                      final tx = transactions[idx];
                                      final category = categories.firstWhere(
                                        (c) => c.id == tx.categoryId,
                                        orElse: () => Category(name: 'Lain-lain', type: tx.type),
                                      );

                                      // Time subtitle formatting
                                      String timeStr = DateFormat('HH:mm').format(tx.createdAt);
                                      String dateSubtitle;
                                      final txDate = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
                                      final today = DateTime(now.year, now.month, now.day);
                                      final yesterday = today.subtract(const Duration(days: 1));
                                      
                                      if (txDate == today) {
                                        dateSubtitle = 'Hari ini, $timeStr';
                                      } else if (txDate == yesterday) {
                                        dateSubtitle = 'Kemarin, $timeStr';
                                      } else {
                                        dateSubtitle = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt);
                                      }


                                      return Dismissible(
                                        key: Key('tx-${tx.id}'),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: Colors.redAccent,
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20.0),
                                          child: const Icon(Icons.delete_outline, color: Colors.white),
                                        ),
                                        onDismissed: (direction) {
                                          if (tx.id != null) {
                                            ref.read(transactionsNotifierProvider.notifier).deleteTransaction(tx.id!);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                                                backgroundColor: isDarkMode ? const Color(0xFF131D1D) : const Color(0xFF2E3131),
                                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                                duration: const Duration(seconds: 5),
                                                content: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        'Transaksi "${tx.note}" dihapus',
                                                        style: const TextStyle(color: Colors.white, fontSize: 13.0),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        ref.read(transactionsNotifierProvider.notifier).addTransaction(tx);
                                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                      },
                                                      child: const Text(
                                                        'Urungkan',
                                                        style: TextStyle(color: Color(0xFFFC8A40), fontWeight: FontWeight.bold, fontSize: 13.0),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.white70, size: 16.0),
                                                      padding: EdgeInsets.zero,
                                                      constraints: const BoxConstraints(),
                                                      onPressed: () {
                                                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        child: InkWell(
                                          onTap: () {
                                            _showEditDialog(context, ref, tx, categories);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38.0,
                                                  height: 38.0,
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode ? const Color(0xFF131D1D) : const Color(0xFFECEEEE),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _getCategoryIcon(category.icon),
                                                    color: isDarkMode ? Colors.white : Colors.black,
                                                    size: 18.0,
                                                  ),
                                                ),
                                                const SizedBox(width: 12.0),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        (tx.note == null || tx.note!.isEmpty) ? category.name : tx.note!,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 13.0,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2.0),
                                                      Text(
                                                        dateSubtitle,
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Text(
                                                  (tx.type == 'income' ? '+ ' : '- ') + _formatRp(tx.amount),
                                                  style: TextStyle(
                                                    fontSize: 13.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: tx.type == 'income'
                                                        ? const Color(0xFF10B981) // Green for Income!
                                                        : const Color(0xFFEF4444), // Red for Expense!
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                    error: (err, st) => SliverToBoxAdapter(child: Text('Error: $err')),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, st) => SliverToBoxAdapter(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, TransactionModel tx, List<Category> categories) {
    final noteController = TextEditingController(text: tx.note);
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(0));
    Category? selectedCat = categories.firstWhere((c) => c.id == tx.categoryId, orElse: () => categories.first);
    String type = tx.type;
    final accounts = ref.read(accountsNotifierProvider).value ?? [];
    int? selectedAccId = tx.accountId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredCats = categories.where((c) => c.type == type).toList();
            if (!filteredCats.contains(selectedCat)) {
              selectedCat = filteredCats.isNotEmpty ? filteredCats.first : null;
            }

            return AlertDialog(
              title: const Text('Edit Transaksi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pengeluaran')),
                            selected: type == 'expense',
                            onSelected: (val) {
                              if (val) setState(() => type = 'expense');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Pemasukan')),
                            selected: type == 'income',
                            onSelected: (val) {
                              if (val) setState(() => type = 'income');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Category>(
                      value: selectedCat,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: filteredCats.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.name));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedCat = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: selectedAccId,
                      decoration: const InputDecoration(labelText: 'Dompet / Akun'),
                      items: accounts.map((a) {
                        return DropdownMenuItem<int>(
                          value: a.account.id,
                          child: Text(a.account.name),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedAccId = val),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Nominal'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    if (amt > 0) {
                      ref.read(transactionsNotifierProvider.notifier).updateTransaction(
                            tx.copyWith(
                              amount: amt,
                              type: type,
                              accountId: selectedAccId,
                              categoryId: selectedCat?.id,
                              note: noteController.text,
                            ),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeframePill(BuildContext context, WidgetRef ref, String timeframe, String label, String activeTimeframe) {
    final isSelected = activeTimeframe == timeframe;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(dashboardTimeframeProvider.notifier).setTimeframe(timeframe);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2C2C2C) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountStackCarousel extends StatefulWidget {
  final List<AccountWithBalance> accounts;
  final double totalBalance;
  final int? selectedAccountId;
  final WidgetRef ref;

  const AccountStackCarousel({
    super.key,
    required this.accounts,
    required this.totalBalance,
    required this.selectedAccountId,
    required this.ref,
  });

  @override
  State<AccountStackCarousel> createState() => _AccountStackCarouselState();
}

class _AccountStackCarouselState extends State<AccountStackCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    int initialPage = 0;
    if (widget.selectedAccountId != null) {
      final index = widget.accounts.indexWhere((a) => a.account.id == widget.selectedAccountId);
      if (index != -1) {
        initialPage = index + 1;
      }
    }
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.90,
    );
    _currentPage = initialPage.toDouble();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void didUpdateWidget(covariant AccountStackCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAccountId != oldWidget.selectedAccountId) {
      int targetPage = 0;
      if (widget.selectedAccountId != null) {
        final index = widget.accounts.indexWhere((a) => a.account.id == widget.selectedAccountId);
        if (index != -1) {
          targetPage = index + 1;
        }
      }
      if (_pageController.hasClients && _pageController.page?.round() != targetPage) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.accounts.length + 1,
      onPageChanged: (index) {
        final isAllAccounts = index == 0;
        final selectedId = isAllAccounts ? null : widget.accounts[index - 1].account.id;
        widget.ref.read(selectedAccountIdProvider.notifier).select(selectedId);
      },
      itemBuilder: (context, index) {
        final isAllAccounts = index == 0;
        final String title = isAllAccounts ? 'Semua Akun' : widget.accounts[index - 1].account.name;
        final double balance = isAllAccounts ? widget.totalBalance : widget.accounts[index - 1].balance;
        final IconData icon = isAllAccounts
            ? Icons.all_inclusive_rounded
            : _getAccountIcon(widget.accounts[index - 1].account.icon);
        final String? cardColor = isAllAccounts ? 'teal' : widget.accounts[index - 1].account.color;

        final double difference = index - _currentPage;
        final double scale = (1 - (difference.abs() * 0.08)).clamp(0.8, 1.0);
        final double translation = difference * -12.0;

        return Transform(
          transform: Matrix4.identity()
            ..scale(scale)
            ..translate(translation),
          alignment: Alignment.center,
          child: PremiumStackCard(
            title: title,
            balance: balance,
            isSelected: index == _pageController.initialPage || (difference.abs() < 0.5),
            icon: icon,
            isAllAccounts: isAllAccounts,
            color: cardColor,
          ),
        );
      },
    );
  }
}

class PremiumStackCard extends StatefulWidget {
  final String title;
  final double balance;
  final bool isSelected;
  final IconData icon;
  final bool isAllAccounts;
  final String? color;

  const PremiumStackCard({
    super.key,
    required this.title,
    required this.balance,
    required this.isSelected,
    required this.icon,
    required this.isAllAccounts,
    this.color,
  });

  @override
  State<PremiumStackCard> createState() => _PremiumStackCardState();
}

class _PremiumStackCardState extends State<PremiumStackCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant PremiumStackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorId = widget.color ?? 'teal';
    List<Color> gradientColors;

    if (widget.isAllAccounts) {
      gradientColors = [const Color(0xFF111111), const Color(0xFF2C2C2C), const Color(0xFF555555)];
    } else {
      final parsedColor = _parseCustomColor(colorId);
      if (parsedColor != null) {
        gradientColors = _generatePremiumGradient(parsedColor);
      } else {
        gradientColors = [const Color(0xFF002222), const Color(0xFF004D4D), const Color(0xFF4DB6B5)];
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.8),
          radius: 1.2,
          colors: [
            gradientColors[2],
            gradientColors[1],
            gradientColors[0],
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          widget.isAllAccounts ? 'TOTAL SALDO' : 'ACTIVE CARD',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16.0,
                            height: 16.0,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-6.0, 0.0),
                            child: Container(
                              width: 16.0,
                              height: 16.0,
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(widget.balance),
                              style: const TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.wifi_tethering_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                if (!_controller.isAnimating) return const SizedBox();
                return Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: 2.0,
                    alignment: Alignment(_controller.value * 3 - 2, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.35, 0.5, 0.65],
                          begin: const Alignment(-1.0, -0.5),
                          end: const Alignment(1.0, 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
