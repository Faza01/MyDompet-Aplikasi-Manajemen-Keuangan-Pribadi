import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../accounts/accounts_provider.dart';
import '../budgeting/categories_provider.dart';
import '../transactions/transactions_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _localAccountId; // null means "Semua Akun"
  String _timeframe = 'month'; // 'week' | 'month'

  final List<Color> _chartColors = [
    const Color(0xFFEF4444), // Coral Red
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF14B8A6), // Teal
    Colors.grey,
  ];

  String _formatRp(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Filters Row
                Row(
                  children: [
                    // Account Dropdown
                    Expanded(
                      child: accountsAsync.when(
                        data: (accounts) {
                          return DropdownButtonFormField<int?>(
                            value: _localAccountId,
                            decoration: InputDecoration(
                              labelText: 'Dompet/Akun',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua Akun', style: TextStyle(fontSize: 12.0)),
                              ),
                              ...accounts.map((acc) {
                                return DropdownMenuItem<int?>(
                                  value: acc.account.id,
                                  child: Text(acc.account.name, style: const TextStyle(fontSize: 12.0)),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _localAccountId = val;
                              });
                            },
                          );
                        },
                        loading: () => const Center(child: LinearProgressIndicator()),
                        error: (err, st) => const Text('Error load akun'),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Timeframe Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _timeframe,
                        decoration: InputDecoration(
                          labelText: 'Periode',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'day',
                            child: Text('Hari Ini', style: TextStyle(fontSize: 12.0)),
                          ),
                          DropdownMenuItem(
                            value: 'week',
                            child: Text('Minggu Ini', style: TextStyle(fontSize: 12.0)),
                          ),
                          DropdownMenuItem(
                            value: 'month',
                            child: Text('Bulan Ini', style: TextStyle(fontSize: 12.0)),
                          ),
                          DropdownMenuItem(
                            value: 'year',
                            child: Text('Tahun Ini', style: TextStyle(fontSize: 12.0)),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _timeframe = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // 2. Data Rendering
                transactionsAsync.when(
                  data: (transactions) {
                    final categories = categoriesAsync.value ?? [];

                    // Apply filters to transactions
                    final now = DateTime.now();
                    final filteredTxs = transactions.where((tx) {
                      final matchesAccount = _localAccountId == null || tx.accountId == _localAccountId;
                      
                      // Filter by Date
                      bool matchesDate = false;
                      if (_timeframe == 'day') {
                        matchesDate = tx.createdAt.year == now.year &&
                            tx.createdAt.month == now.month &&
                            tx.createdAt.day == now.day;
                      } else if (_timeframe == 'week') {
                        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                        matchesDate = tx.createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
                      } else if (_timeframe == 'month') {
                        matchesDate = tx.createdAt.year == now.year && tx.createdAt.month == now.month;
                      } else if (_timeframe == 'year') {
                        matchesDate = tx.createdAt.year == now.year;
                      }

                      // Exclude Transfer transactions from financial reports to avoid distorted stats
                      final category = categories.firstWhere(
                        (c) => c.id == tx.categoryId,
                        orElse: () => Category(name: 'Lain-lain', type: tx.type),
                      );
                      final isNotTransfer = category.name.toLowerCase() != 'transfer';

                      return matchesAccount && matchesDate && isNotTransfer;
                    }).toList();

                    // Calculate Summary Totals
                    final double totalIncome = filteredTxs
                        .where((tx) => tx.type == 'income')
                        .fold(0.0, (sum, tx) => sum + tx.amount);
                    final double totalExpense = filteredTxs
                        .where((tx) => tx.type == 'expense')
                        .fold(0.0, (sum, tx) => sum + tx.amount);

                    // 2a. Pie Chart Calculation (Expense breakdown by category)
                    final Map<int, double> expenseByCategory = {};
                    for (final tx in filteredTxs) {
                      if (tx.type == 'expense' && tx.categoryId != null) {
                        expenseByCategory[tx.categoryId!] = (expenseByCategory[tx.categoryId!] ?? 0.0) + tx.amount;
                      }
                    }

                    // 2b. Line Chart Calculation based on active timeframe
                    List<FlSpot> lineSpots = [];
                    List<String> bottomAxisLabels = [];
                    int totalChartPoints = 0;

                    if (_timeframe == 'day' || _timeframe == 'week') {
                      // Show 7 days (Monday to Sunday) for the current week
                      final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
                      final List<DateTime> weekDays = List.generate(7, (i) {
                        final d = startOfWeek.add(Duration(days: i));
                        return DateTime(d.year, d.month, d.day);
                      });

                      final Map<String, double> dailyExpenses = {};
                      final df = DateFormat('yyyy-MM-dd');
                      for (final day in weekDays) {
                        dailyExpenses[df.format(day)] = 0.0;
                      }

                      for (final tx in filteredTxs) {
                        if (tx.type == 'expense') {
                          final key = df.format(tx.createdAt);
                          if (dailyExpenses.containsKey(key)) {
                            dailyExpenses[key] = dailyExpenses[key]! + tx.amount;
                          }
                        }
                      }

                      totalChartPoints = 7;
                      lineSpots = List.generate(7, (i) {
                        final key = df.format(weekDays[i]);
                        return FlSpot(i.toDouble(), dailyExpenses[key] ?? 0.0);
                      });

                      bottomAxisLabels = weekDays.map((day) {
                        return DateFormat('E', 'id_ID').format(day);
                      }).toList();

                    } else if (_timeframe == 'month') {
                      // Show daily trend for the current month
                      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
                      final List<DateTime> monthDays = List.generate(daysInMonth, (i) {
                        return DateTime(now.year, now.month, i + 1);
                      });

                      final Map<String, double> dailyExpenses = {};
                      final df = DateFormat('yyyy-MM-dd');
                      for (final day in monthDays) {
                        dailyExpenses[df.format(day)] = 0.0;
                      }

                      for (final tx in filteredTxs) {
                        if (tx.type == 'expense') {
                          final key = df.format(tx.createdAt);
                          if (dailyExpenses.containsKey(key)) {
                            dailyExpenses[key] = dailyExpenses[key]! + tx.amount;
                          }
                        }
                      }

                      totalChartPoints = daysInMonth;
                      lineSpots = List.generate(daysInMonth, (i) {
                        final key = df.format(monthDays[i]);
                        return FlSpot(i.toDouble(), dailyExpenses[key] ?? 0.0);
                      });

                      bottomAxisLabels = List.generate(daysInMonth, (i) {
                        final dayNum = i + 1;
                        if (dayNum == 1 || dayNum == 5 || dayNum == 10 || dayNum == 15 || dayNum == 20 || dayNum == 25 || dayNum == daysInMonth) {
                          return dayNum.toString();
                        }
                        return '';
                      });

                    } else if (_timeframe == 'year') {
                      // Show monthly trend for the current year (12 months)
                      final Map<int, double> monthlyExpenses = {};
                      for (int i = 1; i <= 12; i++) {
                        monthlyExpenses[i] = 0.0;
                      }

                      for (final tx in filteredTxs) {
                        if (tx.type == 'expense') {
                          final m = tx.createdAt.month;
                          monthlyExpenses[m] = monthlyExpenses[m]! + tx.amount;
                        }
                      }

                      totalChartPoints = 12;
                      lineSpots = List.generate(12, (i) {
                        final monthNum = i + 1;
                        return FlSpot(i.toDouble(), monthlyExpenses[monthNum] ?? 0.0);
                      });

                      bottomAxisLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Totals summary cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Masuk',
                                amount: totalIncome,
                                color: const Color(0xFF10B981),
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: _buildSummaryCard(
                                title: 'Total Keluar',
                                amount: totalExpense,
                                color: const Color(0xFFEF4444),
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),

                        // Line chart: Daily Trend
                        Card(
                          elevation: 0,
                          color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tren Pengeluaran Harian',
                                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 24.0),
                                SizedBox(
                                  height: 180,
                                  child: Builder(
                                    builder: (context) {
                                      final double maxAmount = lineSpots.isEmpty
                                          ? 1000.0
                                          : lineSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
                                      final double chartMaxY = maxAmount == 0 ? 1000.0 : maxAmount * 1.15;

                                      return BarChart(
                                        BarChartData(
                                          alignment: BarChartAlignment.spaceAround,
                                          maxY: chartMaxY,
                                          barTouchData: BarTouchData(
                                            enabled: true,
                                            touchTooltipData: BarTouchTooltipData(
                                              getTooltipColor: (_) => isDarkMode ? const Color(0xFF131D1D) : const Color(0xFF004D4D),
                                              tooltipBorderRadius: BorderRadius.circular(8),
                                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                                return BarTooltipItem(
                                                  _formatRp(rod.toY),
                                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                                );
                                              },
                                            ),
                                          ),
                                          titlesData: FlTitlesData(
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (val, meta) {
                                                  final index = val.toInt();
                                                  if (index >= 0 && index < totalChartPoints) {
                                                    final label = bottomAxisLabels[index];
                                                    if (label.isEmpty) {
                                                      return const SizedBox();
                                                    }
                                                    return Padding(
                                                      padding: const EdgeInsets.only(top: 6.0),
                                                      child: Text(
                                                        label,
                                                        style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
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
                                          barGroups: List.generate(totalChartPoints, (index) {
                                            final amount = lineSpots[index].y;
                                            return BarChartGroupData(
                                              x: index,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: amount,
                                                  width: _timeframe == 'month' ? 6 : 14,
                                                  borderRadius: BorderRadius.circular(4.0),
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFEF4444), Color(0xFFFF8A80)],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                  ),
                                                  backDrawRodData: BackgroundBarChartRodData(
                                                    show: true,
                                                    toY: chartMaxY,
                                                    color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        // Pie chart: Breakdown
                        Card(
                          elevation: 0,
                          color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(
                              color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alokasi Pengeluaran',
                                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 20.0),
                                if (expenseByCategory.isEmpty)
                                  const SizedBox(
                                    height: 150,
                                    child: Center(
                                      child: Text(
                                        'Tidak ada data pengeluaran.',
                                        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  )
                                else ...[
                                  // Donut Chart
                                  SizedBox(
                                    height: 180,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 4,
                                        centerSpaceRadius: 40,
                                        sections: expenseByCategory.entries.map((entry) {
                                          final catId = entry.key;
                                          final amt = entry.value;
                                          final cat = categories.firstWhere((c) => c.id == catId);
                                          final index = categories.indexOf(cat) % _chartColors.length;

                                          final pct = totalExpense > 0 ? (amt / totalExpense) * 100 : 0.0;

                                          return PieChartSectionData(
                                            value: amt,
                                            title: '${pct.toStringAsFixed(0)}%',
                                            radius: 50,
                                            titleStyle: const TextStyle(
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            color: _chartColors[index],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  // Legend
                                  ...expenseByCategory.entries.map((entry) {
                                    final catId = entry.key;
                                    final amt = entry.value;
                                    final cat = categories.firstWhere((c) => c.id == catId);
                                    final index = categories.indexOf(cat) % _chartColors.length;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: _chartColors[index],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8.0),
                                              Text(
                                                cat.name,
                                                style: const TextStyle(fontSize: 12.0),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            _formatRp(amt),
                                            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Center(child: Text('Error loading report: $err')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.0,
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            _formatRp(amount),
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
