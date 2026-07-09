import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/debt.dart';
import 'debts_provider.dart';
import 'add_debt_dialog.dart';
import 'debt_detail_sheet.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  String _statusFilter = 'pending'; // 'pending' (Belum Lunas) or 'paid' (Lunas)
  String _typeFilter = 'all'; // 'all' | 'debt' | 'receivable'

  String _formatRp(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  void _openAddDebtDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddDebtDialog(),
    );
  }

  void _openDebtDetailSheet(DebtModel debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DebtDetailSheet(debt: debt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final debtsAsync = ref.watch(debtsNotifierProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkScaffold : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Hutang & Piutang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDebtDialog,
        backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: debtsAsync.when(
          data: (debts) {
            // Calculations for active/pending debts
            final activeDebts = debts.where((d) => d.status == 'pending').toList();
            final totalReceivables = activeDebts
                .where((d) => d.type == 'receivable')
                .fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
            final totalDebts = activeDebts
                .where((d) => d.type == 'debt')
                .fold(0.0, (sum, d) => sum + (d.amount - d.paidAmount));
            final netBalance = totalReceivables - totalDebts;

            // Filter lists based on UI tab selections
            final filteredDebts = debts.where((d) {
              final matchesStatus = d.status == _statusFilter;
              final matchesType = _typeFilter == 'all' || d.type == _typeFilter;
              return matchesStatus && matchesType;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Summary Cards Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Piutang Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Piutang',
                                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatRp(totalReceivables),
                                    style: const TextStyle(
                                      color: AppColors.accentTeal,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hutang Card
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16.0),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Total Hutang',
                                    style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatRp(totalDebts),
                                    style: const TextStyle(
                                      color: AppColors.semanticRed,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Net Balance Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Saldo Bersih (Net)',
                              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatRp(netBalance),
                              style: TextStyle(
                                color: netBalance >= 0
                                    ? AppColors.accentTeal
                                    : AppColors.semanticRed,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Filter Tabs (Belum Lunas vs Lunas)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColors.darkCard : const Color(0xFFECEEEE),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        // Belum Lunas
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusFilter = 'pending';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: _statusFilter == 'pending'
                                    ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Belum Lunas',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: _statusFilter == 'pending'
                                        ? (isDarkMode ? Colors.white : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Lunas
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusFilter = 'paid';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: _statusFilter == 'paid'
                                    ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Center(
                                child: Text(
                                  'Lunas',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: _statusFilter == 'paid'
                                        ? (isDarkMode ? Colors.white : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Type Filter Chips (Semua, Hutang, Piutang)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('debt', 'Hutang'),
                      const SizedBox(width: 8),
                      _buildFilterChip('receivable', 'Piutang'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 4. List View of Debts
                Expanded(
                  child: filteredDebts.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada catatan ${_statusFilter == 'pending' ? 'aktif' : 'lunas'}.',
                            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 100.0),
                          itemCount: filteredDebts.length,
                          itemBuilder: (context, index) {
                            final debt = filteredDebts[index];
                            final sisa = debt.amount - debt.paidAmount;
                            final double progress = debt.amount > 0 ? (debt.paidAmount / debt.amount) : 0.0;
                            final isOverdue = debt.status == 'pending' && debt.dueDate.isBefore(DateTime.now());
                            final colorType = debt.type == 'debt' ? AppColors.semanticRed : AppColors.accentTeal;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              elevation: 0,
                              color: isDarkMode ? AppColors.darkCard : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: BorderSide(
                                  color: isDarkMode
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => _openDebtDetailSheet(debt),
                                borderRadius: BorderRadius.circular(16.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Row: Contact Name and Type Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            debt.contactName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: colorType.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              debt.type == 'debt' ? 'Hutang' : 'Piutang',
                                              style: TextStyle(
                                                color: colorType,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Middle Row: Sisa Nominal and Original Amount
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Sisa Pembayaran',
                                                style: TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatRp(sisa),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'dari ${_formatRp(debt.amount)}',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Progress Bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: isDarkMode ? Colors.white10 : Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(colorType),
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Bottom Row: Due date and warning if overdue
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_outlined,
                                                size: 12,
                                                color: isOverdue ? AppColors.semanticRed : Colors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Tenggat: ${DateFormat('dd MMM yyyy').format(debt.dueDate)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                                  color: isOverdue ? AppColors.semanticRed : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (debt.note != null && debt.note!.isNotEmpty)
                                            Icon(
                                              Icons.note_alt_outlined,
                                              size: 14,
                                              color: isDarkMode ? Colors.white54 : Colors.black45,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _typeFilter == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _typeFilter = value;
          });
        }
      },
      selectedColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
      backgroundColor: isDarkMode ? AppColors.darkCard : const Color(0xFFECEEEE),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected
            ? (isDarkMode ? Colors.black : Colors.white)
            : (isDarkMode ? Colors.white70 : Colors.black87),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Colors.transparent),
      ),
      showCheckmark: false,
    );
  }
}
