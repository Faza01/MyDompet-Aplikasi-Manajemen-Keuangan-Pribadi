import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/debt.dart';
import '../accounts/accounts_provider.dart';
import 'debts_provider.dart';

class AddDebtDialog extends ConsumerStatefulWidget {
  const AddDebtDialog({super.key});

  @override
  ConsumerState<AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends ConsumerState<AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'receivable'; // 'debt' (Hutang) or 'receivable' (Piutang)
  DateTime? _dueDate;
  int? _selectedAccountId;

  @override
  void dispose() {
    _contactController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)), // 5 years max
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.white,
                    onPrimary: Colors.black,
                    surface: AppColors.darkModal,
                    onSurface: Colors.white70,
                  )
                : const ColorScheme.light(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tenggat waktu pembayaran')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih rekening/dompet asal')),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim().replaceAll('.', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak valid')),
      );
      return;
    }

    final newDebt = DebtModel(
      contactName: _contactController.text.trim(),
      amount: amount,
      type: _type,
      dueDate: _dueDate!,
      status: 'pending',
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      accountId: _selectedAccountId!,
      createdAt: DateTime.now(),
    );

    ref.read(debtsNotifierProvider.notifier).addDebt(newDebt);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Dialog(
      backgroundColor: isDarkMode ? AppColors.darkModal : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                Row(
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tambah Hutang / Piutang',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Selector Tipe: Hutang atau Piutang
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkCard : const Color(0xFFECEEEE),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      // Piutang Button (Orang lain pinjam ke kita)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = 'receivable';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: _type == 'receivable'
                                  ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: _type == 'receivable' && !isDarkMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4.0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Piutang',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'receivable'
                                      ? (isDarkMode ? Colors.white : Colors.black87)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Hutang Button (Kita pinjam ke orang lain)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = 'debt';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: _type == 'debt'
                                  ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: _type == 'debt' && !isDarkMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4.0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Hutang',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: _type == 'debt'
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
                const SizedBox(height: 20.0),

                // TextField Nama Kontak
                TextFormField(
                  controller: _contactController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Nama Orang / Kontak',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    hintText: 'Masukkan nama',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_outline, size: 20, color: Colors.grey),
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
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // TextField Nominal
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Nominal (Rp)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    hintText: '100000',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.money_outlined, size: 20, color: Colors.grey),
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
                      return 'Nominal tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Dompet Asal / Penerima
                accountsAsync.when(
                  data: (accounts) {
                    if (_selectedAccountId == null && accounts.isNotEmpty) {
                      // auto select first wallet
                      _selectedAccountId = accounts.first.account.id;
                    }
                    return DropdownButtonFormField<int>(
                      value: _selectedAccountId,
                      dropdownColor: isDarkMode ? AppColors.darkModal : Colors.white,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        labelText: _type == 'debt' ? 'Dompet Penerima Saldo' : 'Dompet Asal Saldo',
                        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.wallet_outlined, size: 20, color: Colors.grey),
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
                const SizedBox(height: 16.0),

                // Deadline / Due date picker
                InkWell(
                  onTap: () => _selectDueDate(context),
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isDarkMode ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              _dueDate == null
                                  ? 'Tenggat Waktu / Due Date'
                                  : DateFormat('dd MMM yyyy').format(_dueDate!),
                              style: TextStyle(
                                fontSize: 13.0,
                                color: _dueDate == null
                                    ? Colors.grey
                                    : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Catatan (Opsional)
                TextFormField(
                  controller: _noteController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    hintText: 'Keterangan tambahan',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.note_alt_outlined, size: 20, color: Colors.grey),
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
                ),
                const SizedBox(height: 28.0),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                        foregroundColor: isDarkMode ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
