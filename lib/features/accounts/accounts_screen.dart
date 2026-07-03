import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/account.dart';
import '../transactions/transactions_provider.dart';
import 'accounts_provider.dart';

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

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Transfer Form State
  int? _fromAccountId;
  int? _toAccountId;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _executeTransfer() {
    if (_fromAccountId == null || _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih akun asal dan tujuan')),
      );
      return;
    }

    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Akun asal dan tujuan tidak boleh sama')),
      );
      return;
    }

    final amt = double.tryParse(_amountController.text) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transfer harus lebih dari 0')),
      );
      return;
    }

    ref.read(transactionsNotifierProvider.notifier).addTransfer(
          fromAccountId: _fromAccountId!,
          toAccountId: _toAccountId!,
          amount: amt,
          note: _noteController.text,
        );

    _amountController.clear();
    _noteController.clear();
    setState(() {
      _fromAccountId = null;
      _toAccountId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer dana berhasil dicatat!')),
    );
  }

  IconData _getAccountIcon(String? iconName) {
    switch (iconName) {
      case 'wallet': return Icons.account_balance_wallet_outlined;
      case 'account_balance': return Icons.account_balance_outlined;
      case 'payment': return Icons.payment_outlined;
      default: return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dompet / Akun', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // 1. Account List Grid
                const Text(
                  'Daftar Dompet & Akun Anda',
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                accountsAsync.when(
                  data: (accounts) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: accounts.length + 1,
                      itemBuilder: (context, index) {
                        // Card to add new account
                        if (index == accounts.length) {
                          return Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.0),
                              onTap: () => _showAddAccountDialog(context),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 28.0, color: const Color(0xFF004D4D)),
                                  SizedBox(height: 6.0),
                                  Text(
                                    'Tambah Akun',
                                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final accWithBal = accounts[index];
                        final acc = accWithBal.account;

                        return Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(_getAccountIcon(acc.icon), color: isDarkMode ? Colors.white : Colors.black, size: 20),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 14, color: isDarkMode ? Colors.white70 : Colors.black87),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditAccountDialog(context, acc),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _confirmDeleteAccount(context, acc),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    _formatter.format(accWithBal.balance),
                                    style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, st) => Center(child: Text('Error loading akun: $err')),
                ),
                const SizedBox(height: 24.0),
                const Divider(),
                const SizedBox(height: 20.0),

                // 2. Transfer Form Card
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.swap_horiz, color: const Color(0xFF004D4D)),
                            SizedBox(width: 8),
                            Text(
                              'Pindah Dana / Transfer',
                              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        accountsAsync.when(
                          data: (accounts) {
                            return Column(
                              children: [
                                // Source Account selector
                                DropdownButtonFormField<int>(
                                  value: _fromAccountId,
                                  decoration: InputDecoration(
                                    labelText: 'Dari Akun / Dompet',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: accounts.map((acc) {
                                    return DropdownMenuItem(
                                      value: acc.account.id,
                                      child: Text(acc.account.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _fromAccountId = val;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12.0),
                                // Destination Account selector
                                DropdownButtonFormField<int>(
                                  value: _toAccountId,
                                  decoration: InputDecoration(
                                    labelText: 'Ke Akun / Dompet',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: accounts.map((acc) {
                                    return DropdownMenuItem(
                                      value: acc.account.id,
                                      child: Text(acc.account.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _toAccountId = val;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox(),
                          error: (err, st) => const SizedBox(),
                        ),
                        const SizedBox(height: 12.0),
                        // Amount Field
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Nominal Transfer',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixText: 'Rp ',
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        // Note Field
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: _executeTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Kirim Transfer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelectedCustom(String color) {
    return color != 'teal' && color != 'orange';
  }

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedIcon = 'wallet';
    String selectedColor = 'teal';

    showDialog(
      context: context,
      builder: (context) {
        final hexController = TextEditingController();
        bool isCustomActive = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            Widget buildColorDot(String id, Color color) {
              final isSelected = selectedColor == id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = id;
                    isCustomActive = false;
                  });
                },
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16.0) : null,
                ),
              );
            }

            return AlertDialog(
              title: const Text('Tambah Dompet Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Dompet (cth: GoPay)'),
                    ),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Pilih Icon:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(Icons.account_balance_wallet,
                              color: selectedIcon == 'wallet' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'wallet'),
                        ),
                        IconButton(
                          icon: Icon(Icons.account_balance,
                              color: selectedIcon == 'account_balance' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'account_balance'),
                        ),
                        IconButton(
                          icon: Icon(Icons.payment,
                              color: selectedIcon == 'payment' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'payment'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Pilih Warna Kartu:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        buildColorDot('teal', const Color(0xFF004D4D)),
                        const SizedBox(width: 12.0),
                        buildColorDot('orange', const Color(0xFFFC8A40)),
                        const SizedBox(width: 12.0),
                        if (isCustomActive) ...[
                          GestureDetector(
                            onTap: () => setState(() => isCustomActive = true),
                            child: Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: _parseCustomColor(selectedColor) ?? const Color(0xFF0288D1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16.0),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                        ],
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isCustomActive = true;
                              selectedColor = '#0288D1';
                              hexController.text = '#0288D1';
                            });
                          },
                          child: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              color: _isSelectedCustom(selectedColor)
                                  ? Colors.transparent
                                  : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                              shape: BoxShape.circle,
                              border: _isSelectedCustom(selectedColor)
                                  ? Border.all(color: isDarkMode ? Colors.white : Colors.black87, width: 2.0)
                                  : null,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18.0,
                              color: _isSelectedCustom(selectedColor)
                                  ? (isDarkMode ? Colors.white : Colors.black87)
                                  : (isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isCustomActive) ...[
                      const SizedBox(height: 16.0),
                      const Text('Pilih Palet Kustom:', style: TextStyle(fontSize: 11.0, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: [
                          {'id': '#0288D1', 'color': const Color(0xFF0288D1)},
                          {'id': '#0A192F', 'color': const Color(0xFF0A192F)},
                          {'id': '#D32F2F', 'color': const Color(0xFFD32F2F)},
                          {'id': '#673AB7', 'color': const Color(0xFF673AB7)},
                          {'id': '#2C2C2C', 'color': const Color(0xFF2C2C2C)},
                          {'id': '#E91E63', 'color': const Color(0xFFE91E63)},
                        ].map((c) {
                          final isThisSelected = selectedColor.toLowerCase() == (c['id'] as String).toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = c['id'] as String;
                                hexController.text = c['id'] as String;
                              });
                            },
                            child: Container(
                              width: 28.0,
                              height: 28.0,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isThisSelected
                                      ? (isDarkMode ? Colors.white : Colors.black87)
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: isThisSelected ? const Icon(Icons.check, color: Colors.white, size: 14.0) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hexController,
                              decoration: const InputDecoration(
                                labelText: 'Kode Hex atau RGB (cth: #FF5722 atau 255,87,34)',
                                labelStyle: TextStyle(fontSize: 10.0),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                              ),
                              style: const TextStyle(fontSize: 11.0),
                              onChanged: (val) {
                                final parsed = _parseCustomColor(val);
                                if (parsed != null) {
                                  setState(() {
                                    selectedColor = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: _parseCustomColor(selectedColor) ?? Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400, width: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text) ?? 0.0;
                    if (name.isNotEmpty) {
                      ref.read(accountsNotifierProvider.notifier).addAccount(name, balance, selectedIcon, selectedColor);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dompet "$name" berhasil dibuat')),
                      );
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

  void _showEditAccountDialog(BuildContext context, Account acc) {
    final nameController = TextEditingController(text: acc.name);
    final balanceController = TextEditingController(text: acc.initialBalance.toStringAsFixed(0));
    String selectedIcon = acc.icon ?? 'wallet';
    String selectedColor = acc.color ?? 'teal';

    showDialog(
      context: context,
      builder: (context) {
        final hexController = TextEditingController(
          text: _isSelectedCustom(selectedColor) ? selectedColor : ''
        );
        bool isCustomActive = _isSelectedCustom(selectedColor);

        return StatefulBuilder(
          builder: (context, setState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            Widget buildColorDot(String id, Color color) {
              final isSelected = selectedColor == id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = id;
                    isCustomActive = false;
                  });
                },
                child: Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDarkMode ? Colors.white : Colors.black87)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16.0) : null,
                ),
              );
            }

            return AlertDialog(
              title: const Text('Edit Dompet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Dompet'),
                    ),
                    TextField(
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)'),
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Pilih Icon:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: Icon(Icons.account_balance_wallet,
                              color: selectedIcon == 'wallet' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'wallet'),
                        ),
                        IconButton(
                          icon: Icon(Icons.account_balance,
                              color: selectedIcon == 'account_balance' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'account_balance'),
                        ),
                        IconButton(
                          icon: Icon(Icons.payment,
                              color: selectedIcon == 'payment' ? const Color(0xFF004D4D) : Colors.grey),
                          onPressed: () => setState(() => selectedIcon = 'payment'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    const Text('Pilih Warna Kartu:', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        buildColorDot('teal', const Color(0xFF004D4D)),
                        const SizedBox(width: 12.0),
                        buildColorDot('orange', const Color(0xFFFC8A40)),
                        const SizedBox(width: 12.0),
                        if (isCustomActive) ...[
                          GestureDetector(
                            onTap: () => setState(() => isCustomActive = true),
                            child: Container(
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: _parseCustomColor(selectedColor) ?? const Color(0xFF0288D1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  width: 2.5,
                                ),
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16.0),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                        ],
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isCustomActive = true;
                              selectedColor = '#0288D1';
                              hexController.text = '#0288D1';
                            });
                          },
                          child: Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              color: _isSelectedCustom(selectedColor)
                                  ? Colors.transparent
                                  : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                              shape: BoxShape.circle,
                              border: _isSelectedCustom(selectedColor)
                                  ? Border.all(color: isDarkMode ? Colors.white : Colors.black87, width: 2.0)
                                  : null,
                            ),
                            child: Icon(
                              Icons.add,
                              size: 18.0,
                              color: _isSelectedCustom(selectedColor)
                                  ? (isDarkMode ? Colors.white : Colors.black87)
                                  : (isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isCustomActive) ...[
                      const SizedBox(height: 16.0),
                      const Text('Pilih Palet Kustom:', style: TextStyle(fontSize: 11.0, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: [
                          {'id': '#0288D1', 'color': const Color(0xFF0288D1)},
                          {'id': '#0A192F', 'color': const Color(0xFF0A192F)},
                          {'id': '#D32F2F', 'color': const Color(0xFFD32F2F)},
                          {'id': '#673AB7', 'color': const Color(0xFF673AB7)},
                          {'id': '#2C2C2C', 'color': const Color(0xFF2C2C2C)},
                          {'id': '#E91E63', 'color': const Color(0xFFE91E63)},
                        ].map((c) {
                          final isThisSelected = selectedColor.toLowerCase() == (c['id'] as String).toLowerCase();
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = c['id'] as String;
                                hexController.text = c['id'] as String;
                              });
                            },
                            child: Container(
                              width: 28.0,
                              height: 28.0,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isThisSelected
                                      ? (isDarkMode ? Colors.white : Colors.black87)
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: isThisSelected ? const Icon(Icons.check, color: Colors.white, size: 14.0) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: hexController,
                              decoration: const InputDecoration(
                                labelText: 'Kode Hex atau RGB (cth: #FF5722 atau 255,87,34)',
                                labelStyle: TextStyle(fontSize: 10.0),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                              ),
                              style: const TextStyle(fontSize: 11.0),
                              onChanged: (val) {
                                final parsed = _parseCustomColor(val);
                                if (parsed != null) {
                                  setState(() {
                                    selectedColor = val;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Container(
                            width: 28.0,
                            height: 28.0,
                            decoration: BoxDecoration(
                              color: _parseCustomColor(selectedColor) ?? Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400, width: 1.0),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                    final name = nameController.text.trim();
                    final balance = double.tryParse(balanceController.text) ?? 0.0;
                    if (name.isNotEmpty) {
                      ref.read(accountsNotifierProvider.notifier).updateAccount(
                            acc.copyWith(
                              name: name,
                              initialBalance: balance,
                              icon: selectedIcon,
                              color: selectedColor,
                            ),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dompet "$name" berhasil diupdate')),
                      );
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

  void _confirmDeleteAccount(BuildContext context, Account acc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Dompet'),
          content: Text('Apakah Anda yakin ingin menghapus dompet "${acc.name}"? Semua data transaksi yang menggunakan dompet ini juga akan terhapus.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (acc.id != null) {
                  ref.read(accountsNotifierProvider.notifier).deleteAccount(acc.id!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dompet "${acc.name}" berhasil dihapus')),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
