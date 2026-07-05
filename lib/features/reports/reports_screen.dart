import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/categories_provider.dart';
import '../transactions/transactions_provider.dart';
import 'category_detail_screen.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _localAccountId; // null means "Semua Akun"
  String _timeframe = 'month'; // 'day' | 'week' | 'month' | 'year'
  DateTimeRange? _selectedDateRange; // null means no custom date range
  String _allocationType = 'expense'; // 'income' | 'expense'


  String _formatRp(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work_outline;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'download':
        return Icons.download_outlined;
      case 'add_circle':
        return Icons.add_circle_outline;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'receipt_long':
        return Icons.receipt_long_outlined;
      case 'sports_esports':
        return Icons.sports_esports_outlined;
      case 'swap_horiz':
        return Icons.swap_horiz;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 8.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Filters Row with rounded card selection boxes matching dashboard dialog styles
                accountsAsync.when(
                  data: (accounts) {
                    return Row(
                      children: [
                        // Account select box (inline Dropdown Menu)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white30
                                    : Colors.black,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _localAccountId,
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF1E222B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                icon: Icon(
                                  Icons.unfold_more,
                                  size: 16.0,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return [
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Semua Akun',
                                        style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    ...accounts.map((acc) {
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          acc.account.name,
                                          style: const TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      );
                                    }),
                                  ];
                                },
                                items: [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 16.0,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Text(
                                          'Semua Akun',
                                          style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...accounts.map((acc) {
                                    return DropdownMenuItem<int?>(
                                      value: acc.account.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.credit_card_outlined,
                                            size: 16.0,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            acc.account.name,
                                            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _localAccountId = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        // Timeframe select box (inline Dropdown Menu)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: _selectedDateRange != null
                                  ? (isDarkMode
                                      ? Colors.white.withOpacity(0.04)
                                      : Colors.black.withOpacity(0.03))
                                  : null,
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white30
                                    : Colors.black,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: _selectedDateRange != null ? null : _timeframe,
                                isExpanded: true,
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF1E222B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                icon: Icon(
                                  Icons.unfold_more,
                                  size: 16.0,
                                  color: isDarkMode
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                disabledHint: const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Kustom (Aktif)',
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey),
                                  ),
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return [
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Hari Ini',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Minggu Ini',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Bulan Ini',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('Tahun Ini',
                                          style: TextStyle(
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.w500)),
                                    ),
                                  ];
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: 'day',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.today_outlined,
                                          size: 16.0,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Text('Hari Ini', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'week',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.view_week_outlined,
                                          size: 16.0,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Text('Minggu Ini', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'month',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_view_month_outlined,
                                          size: 16.0,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Text('Bulan Ini', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'year',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16.0,
                                          color: isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Text('Tahun Ini', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: _selectedDateRange != null
                                    ? null
                                    : (val) {
                                        if (val != null) {
                                          setState(() {
                                            _timeframe = val;
                                          });
                                        }
                                      },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4.0),
                        // Calendar icon
                        IconButton(
                          icon: const Icon(Icons.calendar_month_outlined),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            final DateTimeRange? pickedRange =
                                await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              initialDateRange: _selectedDateRange,
                              builder: (context, child) {
                                return Theme(
                                  data: isDarkMode
                                      ? ThemeData.dark()
                                      : ThemeData.light(),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedRange != null) {
                              setState(() {
                                _selectedDateRange = pickedRange;
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (err, st) => const Text('Error loading accounts'),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(height: 10.0),
                  Center(
                    child: InputChip(
                      label: Text(
                        'Rentang: ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                      deleteIcon: const Icon(Icons.close, size: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),

                // 2. Data Rendering
                transactionsAsync.when(
                  data: (transactions) {
                    final categories = categoriesAsync.value ?? [];
                    final accounts = accountsAsync.value ?? [];

                    // Apply filters to transactions
                    final now = DateTime.now();
                    final filteredTxs = transactions.where((tx) {
                      final matchesAccount = _localAccountId == null ||
                          tx.accountId == _localAccountId;

                      // Filter by Date
                      bool matchesDate = false;
                      if (_selectedDateRange != null) {
                        final start = _selectedDateRange!.start;
                        final end = _selectedDateRange!.end;
                        final actualEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
                        matchesDate = tx.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                            tx.createdAt.isBefore(actualEnd);
                      } else {
                        if (_timeframe == 'day') {
                          matchesDate = tx.createdAt.year == now.year &&
                              tx.createdAt.month == now.month &&
                              tx.createdAt.day == now.day;
                        } else if (_timeframe == 'week') {
                          final startOfWeek =
                              DateTime(now.year, now.month, now.day)
                                  .subtract(Duration(days: now.weekday - 1));
                          matchesDate = tx.createdAt.isAfter(
                              startOfWeek.subtract(const Duration(seconds: 1)));
                        } else if (_timeframe == 'month') {
                          matchesDate = tx.createdAt.year == now.year &&
                              tx.createdAt.month == now.month;
                        } else if (_timeframe == 'year') {
                          matchesDate = tx.createdAt.year == now.year;
                        }
                      }

                      // Exclude Transfer transactions from financial reports
                      final category = categories.firstWhere(
                        (c) => c.id == tx.categoryId,
                        orElse: () =>
                            Category(name: 'Lain-lain', type: tx.type),
                      );
                      final isNotTransfer =
                          category.name.toLowerCase() != 'transfer';

                      return matchesAccount && matchesDate && isNotTransfer;
                    }).toList();

                    // Calculate Summary Totals
                    final double totalIncome = filteredTxs
                        .where((tx) => tx.type == 'income')
                        .fold(0.0, (sum, tx) => sum + tx.amount);
                    final double totalExpense = filteredTxs
                        .where((tx) => tx.type == 'expense')
                        .fold(0.0, (sum, tx) => sum + tx.amount);

                    // Check if showing single day comparison
                    final bool isSingleDay = (_selectedDateRange == null && _timeframe == 'day') ||
                        (_selectedDateRange != null &&
                            _selectedDateRange!.start.year == _selectedDateRange!.end.year &&
                            _selectedDateRange!.start.month == _selectedDateRange!.end.month &&
                            _selectedDateRange!.start.day == _selectedDateRange!.end.day);

                    // Trend Line/Bar calculations for multi-day periods
                    List<FlSpot> lineSpotsIncome = [];
                    List<FlSpot> lineSpotsExpense = [];
                    List<String> bottomAxisLabels = [];
                    int totalChartPoints = 0;

                    if (!isSingleDay) {
                      if (_selectedDateRange != null) {
                        final start = _selectedDateRange!.start;
                        final end = _selectedDateRange!.end;
                        final daysInRange = end.difference(start).inDays + 1;

                        final List<DateTime> rangeDays = List.generate(daysInRange, (i) {
                          final d = start.add(Duration(days: i));
                          return DateTime(d.year, d.month, d.day);
                        });

                        final Map<String, double> dailyExpenses = {};
                        final Map<String, double> dailyIncome = {};
                        final df = DateFormat('yyyy-MM-dd');
                        for (final day in rangeDays) {
                          dailyExpenses[df.format(day)] = 0.0;
                          dailyIncome[df.format(day)] = 0.0;
                        }

                        for (final tx in filteredTxs) {
                          final key = df.format(tx.createdAt);
                          if (dailyExpenses.containsKey(key)) {
                            if (tx.type == 'expense') {
                              dailyExpenses[key] = dailyExpenses[key]! + tx.amount;
                            } else if (tx.type == 'income') {
                              dailyIncome[key] = dailyIncome[key]! + tx.amount;
                            }
                          }
                        }

                        totalChartPoints = daysInRange;
                        lineSpotsExpense = List.generate(daysInRange, (i) {
                          final key = df.format(rangeDays[i]);
                          return FlSpot(i.toDouble(), dailyExpenses[key] ?? 0.0);
                        });
                        lineSpotsIncome = List.generate(daysInRange, (i) {
                          final key = df.format(rangeDays[i]);
                          return FlSpot(i.toDouble(), dailyIncome[key] ?? 0.0);
                        });

                        bottomAxisLabels = List.generate(daysInRange, (i) {
                          final day = rangeDays[i];
                          if (daysInRange <= 7) {
                            return DateFormat('dd MMM').format(day);
                          } else {
                            if (i == 0 || i == daysInRange - 1 || i % (daysInRange ~/ 4) == 0) {
                              return DateFormat('dd MMM').format(day);
                            }
                            return '';
                          }
                        });
                      } else if (_timeframe == 'week') {
                        final startOfWeek = DateTime(now.year, now.month, now.day)
                            .subtract(Duration(days: now.weekday - 1));
                        final List<DateTime> weekDays = List.generate(7, (i) {
                          final d = startOfWeek.add(Duration(days: i));
                          return DateTime(d.year, d.month, d.day);
                        });

                        final Map<String, double> dailyExpenses = {};
                        final Map<String, double> dailyIncome = {};
                        final df = DateFormat('yyyy-MM-dd');
                        for (final day in weekDays) {
                          dailyExpenses[df.format(day)] = 0.0;
                          dailyIncome[df.format(day)] = 0.0;
                        }

                        for (final tx in filteredTxs) {
                          final key = df.format(tx.createdAt);
                          if (dailyExpenses.containsKey(key)) {
                            if (tx.type == 'expense') {
                              dailyExpenses[key] = dailyExpenses[key]! + tx.amount;
                            } else if (tx.type == 'income') {
                              dailyIncome[key] = dailyIncome[key]! + tx.amount;
                            }
                          }
                        }

                        totalChartPoints = 7;
                        lineSpotsExpense = List.generate(7, (i) {
                          final key = df.format(weekDays[i]);
                          return FlSpot(i.toDouble(), dailyExpenses[key] ?? 0.0);
                        });
                        lineSpotsIncome = List.generate(7, (i) {
                          final key = df.format(weekDays[i]);
                          return FlSpot(i.toDouble(), dailyIncome[key] ?? 0.0);
                        });

                        bottomAxisLabels = weekDays.map((day) {
                          return DateFormat('E', 'id_ID').format(day);
                        }).toList();
                      } else if (_timeframe == 'month') {
                        final daysInMonth =
                            DateTime(now.year, now.month + 1, 0).day;
                        final List<DateTime> monthDays =
                            List.generate(daysInMonth, (i) {
                          return DateTime(now.year, now.month, i + 1);
                        });

                        final Map<String, double> dailyExpenses = {};
                        final Map<String, double> dailyIncome = {};
                        final df = DateFormat('yyyy-MM-dd');
                        for (final day in monthDays) {
                          dailyExpenses[df.format(day)] = 0.0;
                          dailyIncome[df.format(day)] = 0.0;
                        }

                        for (final tx in filteredTxs) {
                          final key = df.format(tx.createdAt);
                          if (dailyExpenses.containsKey(key)) {
                            if (tx.type == 'expense') {
                              dailyExpenses[key] = dailyExpenses[key]! + tx.amount;
                            } else if (tx.type == 'income') {
                              dailyIncome[key] = dailyIncome[key]! + tx.amount;
                            }
                          }
                        }

                        totalChartPoints = daysInMonth;
                        lineSpotsExpense = List.generate(daysInMonth, (i) {
                          final key = df.format(monthDays[i]);
                          return FlSpot(i.toDouble(), dailyExpenses[key] ?? 0.0);
                        });
                        lineSpotsIncome = List.generate(daysInMonth, (i) {
                          final key = df.format(monthDays[i]);
                          return FlSpot(i.toDouble(), dailyIncome[key] ?? 0.0);
                        });

                        bottomAxisLabels = List.generate(daysInMonth, (i) {
                          final dayNum = i + 1;
                          if (dayNum == 1 ||
                              dayNum == 5 ||
                              dayNum == 10 ||
                              dayNum == 15 ||
                              dayNum == 20 ||
                              dayNum == 25 ||
                              dayNum == daysInMonth) {
                            return dayNum.toString();
                          }
                          return '';
                        });
                      } else if (_timeframe == 'year') {
                        final Map<int, double> monthlyExpenses = {};
                        final Map<int, double> monthlyIncome = {};
                        for (int i = 1; i <= 12; i++) {
                          monthlyExpenses[i] = 0.0;
                          monthlyIncome[i] = 0.0;
                        }

                        for (final tx in filteredTxs) {
                          final m = tx.createdAt.month;
                          if (tx.type == 'expense') {
                            monthlyExpenses[m] = monthlyExpenses[m]! + tx.amount;
                          } else if (tx.type == 'income') {
                            monthlyIncome[m] = monthlyIncome[m]! + tx.amount;
                          }
                        }

                        totalChartPoints = 12;
                        lineSpotsExpense = List.generate(12, (i) {
                          final monthNum = i + 1;
                          return FlSpot(i.toDouble(), monthlyExpenses[monthNum] ?? 0.0);
                        });
                        lineSpotsIncome = List.generate(12, (i) {
                          final monthNum = i + 1;
                          return FlSpot(i.toDouble(), monthlyIncome[monthNum] ?? 0.0);
                        });

                        bottomAxisLabels = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                          'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
                        ];
                      }
                    }

                    // 2a. Allocation Calculations based on active toggle
                    final Map<int, double> allocationByCategory = {};
                    for (final tx in filteredTxs) {
                      if (tx.type == _allocationType && tx.categoryId != null) {
                        allocationByCategory[tx.categoryId!] =
                            (allocationByCategory[tx.categoryId!] ?? 0.0) +
                                tx.amount;
                      }
                    }

                    final double totalForAllocation =
                        _allocationType == 'income' ? totalIncome : totalExpense;

                    final sortedAllocation = allocationByCategory.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    final selectedAccName = _localAccountId == null
                        ? 'Semua Akun'
                        : accounts
                            .firstWhere((a) => a.account.id == _localAccountId,
                                orElse: () => accounts.first)
                            .account
                            .name;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card 1: Tren Pengeluaran
                        Card(
                          elevation: 0,
                          color: isDarkMode
                              ? const Color(0xFF1E222B)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.03),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  isSingleDay ? 'Tren Keuangan Hari Ini' : 'Tren Keuangan',
                                  style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16.0),

                                // Totals side-by-side
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0D9488),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Pemasukan',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatRp(totalIncome),
                                            style: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 30,
                                      width: 1,
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black12,
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFDC2626),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Pengeluaran',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  color: isDarkMode
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatRp(totalExpense),
                                            style: TextStyle(
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14.0),

                                // Net Difference (Selisih)
                                Center(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Selisih ',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: (totalIncome - totalExpense >= 0
                                                  ? '+'
                                                  : '') +
                                              _formatRp(
                                                  totalIncome - totalExpense),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: totalIncome - totalExpense >= 0
                                                ? const Color(0xFF0D9488)
                                                : const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24.0),

                                // Bar chart
                                if (isSingleDay)
                                  SizedBox(
                                    height: 200, // increased scrollview height to allow vertical tooltip float
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0),
                                      child: BarChart(
                                        BarChartData(
                                          alignment: BarChartAlignment.spaceEvenly,
                                          maxY: max(totalIncome, totalExpense) == 0
                                              ? 1000.0
                                              : max(totalIncome, totalExpense) *
                                                  1.15,
                                          barTouchData: BarTouchData(
                                            enabled: true,
                                            touchTooltipData: BarTouchTooltipData(
                                              fitInsideHorizontally: true,
                                              fitInsideVertically: true,
                                              getTooltipColor: (group) =>
                                                  group.x == 0
                                                      ? const Color(0xFF0D9488)
                                                      : const Color(0xFFDC2626), // Green for Pemasukan, Red for Pengeluaran
                                              tooltipBorderRadius:
                                                  BorderRadius.circular(8),
                                              getTooltipItem: (group, groupIndex,
                                                  rod, rodIndex) {
                                                return BarTooltipItem(
                                                  _formatRp(rod.toY),
                                                  const TextStyle(
                                                    color: Colors.white, // white text stands out on green/red bg
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          titlesData: FlTitlesData(
                                            rightTitles: const AxisTitles(
                                                sideTitles:
                                                    SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(
                                                sideTitles:
                                                    SideTitles(showTitles: false)),
                                            leftTitles: const AxisTitles(
                                                sideTitles:
                                                    SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (val, meta) {
                                                  if (val == 0) {
                                                    return const Padding(
                                                      padding:
                                                          EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        'Pemasukan',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  } else if (val == 1) {
                                                    return const Padding(
                                                      padding:
                                                          EdgeInsets.only(top: 8.0),
                                                      child: Text(
                                                        'Pengeluaran',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const SizedBox();
                                                },
                                              ),
                                            ),
                                          ),
                                          gridData: const FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          barGroups: [
                                            BarChartGroupData(
                                              x: 0,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: totalIncome,
                                                  width: 48,
                                                  borderRadius:
                                                      BorderRadius.circular(8.0),
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF059669), Color(0xFF34D399)],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                  ),
                                                  backDrawRodData: BackgroundBarChartRodData(
                                                    show: true,
                                                    toY: max(totalIncome, totalExpense) == 0
                                                        ? 1000.0
                                                        : max(totalIncome, totalExpense) * 1.15,
                                                    color: isDarkMode
                                                        ? Colors.white.withOpacity(0.04)
                                                        : Colors.black.withOpacity(0.04),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            BarChartGroupData(
                                              x: 1,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: totalExpense,
                                                  width: 48,
                                                  borderRadius:
                                                      BorderRadius.circular(8.0),
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFDC2626), Color(0xFFF87171)],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                  ),
                                                  backDrawRodData: BackgroundBarChartRodData(
                                                    show: true,
                                                    toY: max(totalIncome, totalExpense) == 0
                                                        ? 1000.0
                                                        : max(totalIncome, totalExpense) * 1.15,
                                                    color: isDarkMode
                                                        ? Colors.white.withOpacity(0.04)
                                                        : Colors.black.withOpacity(0.04),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  // Scrollable Trend Bar Chart showing both Income and Expense side-by-side
                                  Builder(
                                    builder: (context) {
                                      final double maxAmount = lineSpotsExpense.isEmpty
                                          ? 1000.0
                                          : max(
                                              lineSpotsExpense
                                                  .map((s) => s.y)
                                                  .reduce((a, b) => a > b ? a : b),
                                              lineSpotsIncome.isEmpty
                                                  ? 0.0
                                                  : lineSpotsIncome
                                                      .map((s) => s.y)
                                                      .reduce((a, b) => a > b ? a : b),
                                            );
                                      final double chartMaxY = maxAmount == 0
                                          ? 1000.0
                                          : maxAmount * 1.15; // compact chart headroom

                                      final isMonth = _timeframe == 'month' || totalChartPoints > 15;

                                      return SizedBox(
                                        height: 200, // increased scrollview height to allow vertical tooltip float
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          // clipBehavior remains default hardEdge to prevent horizontal bars bleed outside the card
                                          child: Container(
                                            width: max(MediaQuery.of(context).size.width - 64.0, totalChartPoints * (isMonth ? 36.0 : 52.0)),
                                            padding: const EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0), // top padding keeps tooltip inside scrollview bounds
                                            child: BarChart(
                                              BarChartData(
                                                alignment: BarChartAlignment.spaceAround,
                                                maxY: chartMaxY,
                                                barTouchData: BarTouchData(
                                                  enabled: true,
                                                  touchTooltipData: BarTouchTooltipData(
                                                    fitInsideHorizontally: true,
                                                    fitInsideVertically: true,
                                                    getTooltipColor: (group) {
                                                      // Dynamic tooltip color: Green if Pemasukan is higher, Red if Pengeluaran is higher
                                                      final income = group.barRods[0].toY;
                                                      final expense = group.barRods[1].toY;
                                                      if (income > expense) {
                                                        return const Color(0xFF0D9488);
                                                      } else {
                                                        return const Color(0xFFDC2626);
                                                      }
                                                    },
                                                    tooltipBorderRadius:
                                                        BorderRadius.circular(8),
                                                    getTooltipItem: (group,
                                                        groupIndex, rod, rodIndex) {
                                                      return BarTooltipItem(
                                                        _formatRp(rod.toY),
                                                        const TextStyle(
                                                            color: Colors.white, // white text stands out on green/red bg
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 11),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                titlesData: FlTitlesData(
                                                  rightTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                          showTitles: false)),
                                                  topTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                          showTitles: false)),
                                                  leftTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                          showTitles: false)),
                                                  bottomTitles: AxisTitles(
                                                    sideTitles: SideTitles(
                                                      showTitles: true,
                                                      getTitlesWidget: (val, meta) {
                                                        final index = val.toInt();
                                                        if (index >= 0 &&
                                                            index <
                                                                totalChartPoints) {
                                                          final label =
                                                              bottomAxisLabels[index];
                                                          if (label.isEmpty) {
                                                            return const SizedBox();
                                                          }
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                    top: 6.0),
                                                            child: Text(
                                                              label,
                                                              style: const TextStyle(
                                                                  fontSize: 9,
                                                                  color: Colors.grey,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          );
                                                        }
                                                        return const SizedBox();
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                gridData:
                                                    const FlGridData(show: false),
                                                borderData: FlBorderData(show: false),
                                                barGroups: List.generate(
                                                    totalChartPoints, (index) {
                                                  final incomeAmt = lineSpotsIncome[index].y;
                                                  final expenseAmt = lineSpotsExpense[index].y;
                                                  final rodWidth = isMonth ? 12.0 : 18.0;
                                                  final rRadius = isMonth ? 4.0 : 6.0;

                                                  return BarChartGroupData(
                                                    x: index,
                                                    barRods: [
                                                      // Pemasukan Bar (Green Gradient)
                                                      BarChartRodData(
                                                        toY: incomeAmt,
                                                        width: rodWidth,
                                                        borderRadius:
                                                            BorderRadius.circular(rRadius),
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFF059669), Color(0xFF34D399)],
                                                          begin: Alignment.bottomCenter,
                                                          end: Alignment.topCenter,
                                                        ),
                                                        backDrawRodData: BackgroundBarChartRodData(
                                                          show: true,
                                                          toY: chartMaxY,
                                                          color: isDarkMode
                                                              ? Colors.white.withOpacity(0.04)
                                                              : Colors.black.withOpacity(0.04),
                                                        ),
                                                      ),
                                                      // Pengeluaran Bar (Red Gradient)
                                                      BarChartRodData(
                                                        toY: expenseAmt,
                                                        width: rodWidth,
                                                        borderRadius:
                                                            BorderRadius.circular(rRadius),
                                                        gradient: const LinearGradient(
                                                          colors: [Color(0xFFDC2626), Color(0xFFF87171)],
                                                          begin: Alignment.bottomCenter,
                                                          end: Alignment.topCenter,
                                                        ),
                                                        backDrawRodData: BackgroundBarChartRodData(
                                                          show: true,
                                                          toY: chartMaxY,
                                                          color: isDarkMode
                                                              ? Colors.white.withOpacity(0.04)
                                                              : Colors.black.withOpacity(0.04),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),
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
                        ),
                        const SizedBox(height: 20.0),

                        // Card 2: Alokasi Dana (Flexible toggling income/expense with Donut/Pie Chart kept)
                        Card(
                          elevation: 0,
                          color: isDarkMode
                              ? const Color(0xFF1E222B)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.black.withOpacity(0.03),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Alokasi Dana',
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16.0),

                                // Toggle buttons matching Gambar 2
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _allocationType = 'income'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          decoration: BoxDecoration(
                                            color: _allocationType == 'income'
                                                ? const Color(0xFF0D9488)
                                                    .withOpacity(0.12)
                                                : (isDarkMode
                                                    ? Colors.white
                                                        .withOpacity(0.04)
                                                    : Colors.black
                                                        .withOpacity(0.03)),
                                            borderRadius:
                                                BorderRadius.circular(12.0), // match border radius box/filter boxes
                                            border: Border.all(
                                              color: _allocationType == 'income'
                                                  ? const Color(0xFF0D9488)
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            'Pemasukan',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                              color: _allocationType == 'income'
                                                  ? const Color(0xFF0D9488)
                                                  : (isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _allocationType = 'expense'),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10.0),
                                          decoration: BoxDecoration(
                                            color: _allocationType == 'expense'
                                                ? const Color(0xFFDC2626)
                                                    .withOpacity(0.12)
                                                : (isDarkMode
                                                    ? Colors.white
                                                        .withOpacity(0.04)
                                                    : Colors.black
                                                        .withOpacity(0.03)),
                                            borderRadius:
                                                BorderRadius.circular(12.0), // match border radius box/filter boxes
                                            border: Border.all(
                                              color: _allocationType == 'expense'
                                                  ? const Color(0xFFDC2626)
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            'Pengeluaran',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.bold,
                                              color: _allocationType ==
                                                      'expense'
                                                  ? const Color(0xFFDC2626)
                                                  : (isDarkMode
                                                      ? Colors.white60
                                                      : Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20.0),

                                // Donut/Pie Chart Breakdown (Kept as requested)
                                if (sortedAllocation.isNotEmpty) ...[
                                  SizedBox(
                                    height: 180,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 4,
                                        centerSpaceRadius: 40,
                                        sections: sortedAllocation.map((entry) {
                                          final catId = entry.key;
                                          final amt = entry.value;
                                          final cat = categories.firstWhere(
                                              (c) => c.id == catId,
                                              orElse: () => Category(
                                                  name: 'Lain-lain',
                                                  type: _allocationType));
                                          final catColor = cat.color;

                                          final pct = totalForAllocation > 0
                                              ? (amt / totalForAllocation) * 100
                                              : 0.0;

                                          return PieChartSectionData(
                                            value: amt,
                                            title: '${pct.toStringAsFixed(0)}%',
                                            radius: 50,
                                            titleStyle: const TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            color: catColor,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                ],

                                // Categories list
                                if (sortedAllocation.isEmpty)
                                  SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Text(
                                        'Tidak ada data ${_allocationType == 'income' ? 'pemasukan' : 'pengeluaran'}.',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  )
                                else
                                  ...sortedAllocation.map((entry) {
                                    final catId = entry.key;
                                    final amt = entry.value;
                                    final cat = categories.firstWhere(
                                        (c) => c.id == catId,
                                        orElse: () => Category(
                                            name: 'Lain-lain',
                                            type: _allocationType));
                                    final catColor = cat.color;

                                    final pct = totalForAllocation > 0
                                        ? (amt / totalForAllocation) * 100
                                        : 0.0;

                                    return InkWell(
                                      onTap: () {
                                        final catTxs = filteredTxs
                                            .where((tx) =>
                                                tx.categoryId == cat.id)
                                            .toList();
                                        final dateRangeStr = _selectedDateRange !=
                                                null
                                            ? '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}'
                                            : _timeframe == 'day'
                                                ? 'Hari Ini'
                                                : _timeframe == 'week'
                                                    ? 'Minggu Ini'
                                                    : _timeframe == 'month'
                                                        ? 'Bulan Ini'
                                                        : 'Tahun Ini';

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CategoryDetailScreen(
                                              category: cat,
                                              transactions: catTxs,
                                              accountName: selectedAccName,
                                              dateRangeStr: dateRangeStr,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: Row(
                                          children: [
                                            // Circular Icon Lead
                                            Container(
                                              width: 36.0,
                                              height: 36.0,
                                              decoration: BoxDecoration(
                                                color: catColor
                                                    .withOpacity(0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _getCategoryIcon(cat.icon),
                                                color: catColor,
                                                size: 18.0,
                                              ),
                                            ),
                                            const SizedBox(width: 12.0),

                                            // Category name and Amount subtitle
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cat.name,
                                                    style: const TextStyle(
                                                      fontSize: 13.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2.0),
                                                  Text(
                                                    _formatRp(amt),
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Percentage and Arrow chevron right
                                            Row(
                                              children: [
                                                Text(
                                                  '${pct.toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                const SizedBox(width: 8.0),
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 18.0,
                                                  color: isDarkMode
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, st) =>
                      Center(child: Text('Error loading report: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
