import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/debt.dart';
import '../../data/models/debt_repayment.dart';
import '../accounts/accounts_provider.dart';
import 'debts_provider.dart';

class DebtDetailSheet extends ConsumerStatefulWidget {
  final DebtModel debt;

  const DebtDetailSheet({super.key, required this.debt});

  @override
  ConsumerState<DebtDetailSheet> createState() => _DebtDetailSheetState();
}

class _DebtDetailSheetState extends ConsumerState<DebtDetailSheet> {
  late Future<List<DebtRepaymentModel>> _repaymentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRepayments();
  }

  void _refreshRepayments() {
    setState(() {
      _repaymentsFuture = ref
          .read(debtsNotifierProvider.notifier)
          .getRepayments(widget.debt.id!);
    });
  }

  String _formatRp(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkModal : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Hapus Catatan',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus catatan ini? Seluruh saldo dompet terhubung juga akan ikut disesuaikan kembali.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                ref.read(debtsNotifierProvider.notifier).deleteDebt(widget.debt.id!);
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(); // pop sheet
              },
              child: const Text('Hapus', style: TextStyle(color: AppColors.semanticRed)),
            ),
          ],
        );
      },
    );
  }

  void _openRepayDialog() {
    showDialog(
      context: context,
      builder: (context) => RepayDialog(
        debt: widget.debt,
        onSuccess: () {
          _refreshRepayments();
          // We also trigger a reload in debts screen by forcing a rebuild or Riverpod update
          ref.invalidate(debtsNotifierProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorType = widget.debt.type == 'debt' ? AppColors.semanticRed : AppColors.accentTeal;
    final sisa = widget.debt.amount - widget.debt.paidAmount;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkModal : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.debt.contactName,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorType.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.debt.type == 'debt' ? 'Hutang' : 'Piutang',
                      style: TextStyle(
                        color: colorType,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info Row: Nominal Awal, Sisa, Tanggal Jatuh Tempo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pinjaman', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(_formatRp(widget.debt.amount), style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Sisa Belum Bayar', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        _formatRp(sisa),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sisa > 0 ? colorType : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note (if any)
              if (widget.debt.note != null && widget.debt.note!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkCard : const Color(0xFFF5F6F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.debt.note!,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Repayment History Section
              Text(
                'Riwayat Cicilan / Pelunasan',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: FutureBuilder<List<DebtRepaymentModel>>(
                  future: _repaymentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final reps = snapshot.data ?? [];
                    if (reps.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            'Belum ada pembayaran cicilan.',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: reps.length,
                      itemBuilder: (context, index) {
                        final rep = reps[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 16, color: colorType),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(rep.createdAt),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              Text(
                                _formatRp(rep.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Action Buttons
              Row(
                children: [
                  // Hapus Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline, color: AppColors.semanticRed),
                      label: const Text('Hapus', style: TextStyle(color: AppColors.semanticRed)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.semanticRed),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Cicil / Lunasi Button (disabled if already paid)
                  if (widget.debt.status == 'pending')
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _openRepayDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Bayar Cicilan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                          foregroundColor: isDarkMode ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RepayDialog extends ConsumerStatefulWidget {
  final DebtModel debt;
  final VoidCallback onSuccess;

  const RepayDialog({
    super.key,
    required this.debt,
    required this.onSuccess,
  });

  @override
  ConsumerState<RepayDialog> createState() => _RepayDialogState();
}

class _RepayDialogState extends ConsumerState<RepayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    // Default input is the remaining balance
    final remaining = widget.debt.amount - widget.debt.paidAmount;
    _amountController.text = remaining.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitRepayment() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih rekening/dompet pembayaran')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    final remaining = widget.debt.amount - widget.debt.paidAmount;

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal cicilan tidak valid')),
      );
      return;
    }

    if (amount > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nominal cicilan melebihi sisa pinjaman (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remaining)})')),
      );
      return;
    }

    ref.read(debtsNotifierProvider.notifier).repayDebt(
          debtId: widget.debt.id!,
          amount: amount,
          accountId: _selectedAccountId!,
          contactName: widget.debt.contactName,
          type: widget.debt.type,
        );

    widget.onSuccess();
    Navigator.of(context).pop(); // pop RepayDialog
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Dialog(
      backgroundColor: isDarkMode ? AppColors.darkModal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pembayaran Cicilan',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16.0),

              // Repayment Amount Form Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nominal Cicilan (Rp)',
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(
                      color: isDarkMode ? Colors.white54 : Colors.black87,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal cicilan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Wallet Account Selection
              accountsAsync.when(
                data: (accounts) {
                  if (_selectedAccountId == null && accounts.isNotEmpty) {
                    _selectedAccountId = accounts.first.account.id;
                  }
                  return DropdownButtonFormField<int>(
                    value: _selectedAccountId,
                    dropdownColor: isDarkMode ? AppColors.darkModal : Colors.white,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Pilih Dompet / Rekening',
                      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white10 : Colors.black12,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white54 : Colors.black87,
                        ),
                      ),
                    ),
                    items: accounts.map((acc) {
                      return DropdownMenuItem<int>(
                        value: acc.account.id,
                        child: Text(acc.account.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedAccountId = val;
                      });
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error: $e'),
              ),
              const SizedBox(height: 24.0),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitRepayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
