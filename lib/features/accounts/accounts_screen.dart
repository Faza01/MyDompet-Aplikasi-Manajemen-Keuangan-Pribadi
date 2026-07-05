import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/account.dart';
import '../transactions/transactions_provider.dart';
import 'accounts_provider.dart';

Color? _parseCustomColor(String? colorStr) {
  if (colorStr == null || colorStr.isEmpty) return null;
  if (colorStr == 'teal') return AppColors.accentTeal;
  if (colorStr == 'orange') return AppColors.accentOrange;
  if (colorStr == 'light_blue') return AppColors.accentTeal;
  if (colorStr == 'dark_blue') return AppColors.primaryBlack;
  if (colorStr == 'red') return AppColors.semanticRed;
  if (colorStr == 'purple') return AppColors.neutralGray;
  if (colorStr == 'black') return AppColors.primaryBlack;
  if (colorStr == 'pink') return AppColors.accentOrange;

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
      final parts =
          colorStr.split(',').map((p) => int.parse(p.trim())).toList();
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
  final _formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<Color> _generatePremiumGradient(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final darkColor = hsl.withLightness((hsl.lightness * 0.45).clamp(0.0, 1.0)).toColor();
    final lightColor = hsl.withLightness((hsl.lightness + (1.0 - hsl.lightness) * 0.35).clamp(0.0, 1.0)).toColor();
    return [darkColor, baseColor, lightColor];
  }

  InputDecoration _buildFieldDecoration(String labelText, bool isDarkMode, {String? prefixText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontSize: 13.0,
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      filled: true,
      fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }

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
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'account_balance':
        return Icons.account_balance_outlined;
      case 'payment':
        return Icons.payment_outlined;
      default:
        return Icons.credit_card_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Dompet / Akun',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: accounts.length + 1,
                      itemBuilder: (context, index) {
                        // Card to add new account
                        if (index == accounts.length) {
                          return Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0xFF1E222B)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20.0),
                              onTap: () => _showAddAccountDialog(context),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10.0),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentTeal.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 24.0,
                                      color: AppColors.accentTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Tambah Akun',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final accWithBal = accounts[index];
                        final acc = accWithBal.account;
                        final baseColor = _parseCustomColor(acc.color) ?? (isDarkMode ? const Color(0xFF1E222B) : Colors.white);
                        final bool hasGradient = _parseCustomColor(acc.color) != null;

                        return Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            gradient: hasGradient
                                ? LinearGradient(
                                    colors: _generatePremiumGradient(baseColor),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: hasGradient
                                ? null
                                : (isDarkMode ? const Color(0xFF1E222B) : Colors.white),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: hasGradient
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : (isDarkMode
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.05)),
                              width: 1.0,
                            ),
                            boxShadow: hasGradient
                                ? [
                                    BoxShadow(
                                      color: baseColor.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (hasGradient)
                                Positioned(
                                  right: -10,
                                  bottom: -10,
                                  child: Opacity(
                                    opacity: 0.08,
                                    child: Icon(
                                      _getAccountIcon(acc.icon),
                                      size: 72.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6.0),
                                        decoration: BoxDecoration(
                                          color: hasGradient
                                              ? Colors.white.withValues(alpha: 0.15)
                                              : (isDarkMode
                                                  ? Colors.white.withValues(alpha: 0.06)
                                                  : Colors.black.withValues(alpha: 0.04)),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getAccountIcon(acc.icon),
                                          color: hasGradient
                                              ? Colors.white
                                              : (isDarkMode ? Colors.white : Colors.black87),
                                          size: 16.0,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showEditAccountDialog(context, acc),
                                            child: Container(
                                              padding: const EdgeInsets.all(6.0),
                                              decoration: BoxDecoration(
                                                color: hasGradient
                                                    ? Colors.white.withValues(alpha: 0.12)
                                                    : Colors.transparent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 13.0,
                                                color: hasGradient
                                                    ? Colors.white.withValues(alpha: 0.95)
                                                    : (isDarkMode ? Colors.white70 : Colors.black87),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6.0),
                                          GestureDetector(
                                            onTap: () => _confirmDeleteAccount(context, acc),
                                            child: Container(
                                              padding: const EdgeInsets.all(6.0),
                                              decoration: BoxDecoration(
                                                color: hasGradient
                                                    ? Colors.white.withValues(alpha: 0.12)
                                                    : Colors.transparent,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 13.0,
                                                color: hasGradient
                                                    ? Colors.white.withValues(alpha: 0.95)
                                                    : Colors.redAccent,
                                              ),
                                            ),
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
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: hasGradient ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        _formatter.format(accWithBal.balance),
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.bold,
                                          color: hasGradient ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, st) =>
                      Center(child: Text('Error loading akun: $err')),
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
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: AppColors.accentTeal,
                                size: 18.0,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            const Text(
                              'Pindah Dana / Transfer',
                              style: TextStyle(
                                  fontSize: 14.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        accountsAsync.when(
                          data: (accounts) {
                            return Column(
                              children: [
                                // Source Account selector
                                DropdownButtonFormField<int>(
                                  value: _fromAccountId,
                                  dropdownColor: isDarkMode ? AppColors.darkModal : Colors.white,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20.0),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  decoration: _buildFieldDecoration('Dari Akun / Dompet', isDarkMode),
                                  items: accounts.map((acc) {
                                    return DropdownMenuItem(
                                      value: acc.account.id,
                                      child: Text(
                                        acc.account.name,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
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
                                  dropdownColor: isDarkMode ? AppColors.darkModal : Colors.white,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 20.0),
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                  decoration: _buildFieldDecoration('Ke Akun / Dompet', isDarkMode),
                                  items: accounts.map((acc) {
                                    return DropdownMenuItem(
                                      value: acc.account.id,
                                      child: Text(
                                        acc.account.name,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
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
                          decoration: _buildFieldDecoration('Nominal Transfer', isDarkMode, prefixText: 'Rp '),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        // Note Field
                        TextField(
                          controller: _noteController,
                          decoration: _buildFieldDecoration('Catatan (Opsional)', isDarkMode),
                          style: TextStyle(
                            fontSize: 14.0,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        ElevatedButton(
                          onPressed: _executeTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                            foregroundColor: isDarkMode ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0)),
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
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16.0)
                      : null,
                ),
              );
            }

            return Dialog(
              backgroundColor: isDarkMode ? AppColors.darkModal : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.add_card_outlined,
                              color: AppColors.accentTeal,
                              size: 22.0,
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Text(
                            'Tambah Dompet Baru',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Dompet',
                          hintText: 'cth: GoPay',
                          labelStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        ),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: balanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Saldo Awal',
                          hintText: 'Rp 0',
                          labelStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'PILIH ICON',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          'wallet',
                          'account_balance',
                          'payment'
                        ].map((iconName) {
                          final isSelected = selectedIcon == iconName;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = iconName),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentTeal.withValues(alpha: 0.1)
                                    : (isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.accentTeal : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _getAccountIcon(iconName),
                                color: isSelected
                                    ? AppColors.accentTeal
                                    : (isDarkMode ? Colors.white70 : Colors.black87),
                                size: 24.0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'PILIH WARNA KARTU',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          buildColorDot('teal', AppColors.accentTeal),
                          const SizedBox(width: 12.0),
                          buildColorDot('orange', AppColors.accentOrange),
                          const SizedBox(width: 12.0),
                          if (isCustomActive) ...[
                            GestureDetector(
                              onTap: () => setState(() => isCustomActive = true),
                              child: Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: _parseCustomColor(selectedColor) ??
                                      AppColors.accentTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16.0),
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
                                    : (isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300]),
                                shape: BoxShape.circle,
                                border: _isSelectedCustom(selectedColor)
                                    ? Border.all(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        width: 2.0)
                                    : null,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18.0,
                                color: _isSelectedCustom(selectedColor)
                                    ? (isDarkMode ? Colors.white : Colors.black87)
                                    : (isDarkMode
                                        ? Colors.white70
                                        : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isCustomActive) ...[
                        const SizedBox(height: 16.0),
                        Text(
                          'PILIH PALET KUSTOM',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            {'id': '#1A1A1A', 'color': AppColors.primaryBlack},
                            {'id': '#0D9488', 'color': AppColors.accentTeal},
                            {'id': '#F2994A', 'color': AppColors.accentOrange},
                            {'id': '#6B7280', 'color': AppColors.neutralGray},
                            {'id': '#DC2626', 'color': AppColors.semanticRed},
                            {'id': '#064B45', 'color': const Color(0xFF064B45)},
                          ].map((c) {
                            final isThisSelected = selectedColor.toLowerCase() ==
                                (c['id'] as String).toLowerCase();
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
                                        ? (isDarkMode
                                            ? Colors.white
                                            : Colors.black87)
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                child: isThisSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14.0)
                                    : null,
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
                                decoration: InputDecoration(
                                  labelText: 'Kode Hex / RGB',
                                  hintText: 'cth: #FF5722 atau 255,87,34',
                                  labelStyle: TextStyle(
                                    fontSize: 11.0,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 11.0,
                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 10.0),
                                ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
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
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: _parseCustomColor(selectedColor) ??
                                    Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                                    width: 1.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12.0),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final balance =
                                  double.tryParse(balanceController.text) ?? 0.0;
                              if (name.isNotEmpty) {
                                ref.read(accountsNotifierProvider.notifier).addAccount(
                                    name, balance, selectedIcon, selectedColor);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Dompet "$name" berhasil dibuat')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                              foregroundColor: isDarkMode ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 0,
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
            );
          },
        );
      },
    );
  }

  void _showEditAccountDialog(BuildContext context, Account acc) {
    final nameController = TextEditingController(text: acc.name);
    final balanceController =
        TextEditingController(text: acc.initialBalance.toStringAsFixed(0));
    String selectedIcon = acc.icon ?? 'wallet';
    String selectedColor = acc.color ?? 'teal';

    showDialog(
      context: context,
      builder: (context) {
        final hexController = TextEditingController(
            text: _isSelectedCustom(selectedColor) ? selectedColor : '');
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
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16.0)
                      : null,
                ),
              );
            }

            return Dialog(
              backgroundColor: isDarkMode ? AppColors.darkModal : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Icon(
                              Icons.edit_note_outlined,
                              color: AppColors.accentTeal,
                              size: 22.0,
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Text(
                            'Edit Dompet',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Dompet',
                          labelStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        ),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      TextField(
                        controller: balanceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Saldo Awal',
                          labelStyle: TextStyle(
                            fontSize: 13.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'PILIH ICON',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          'wallet',
                          'account_balance',
                          'payment'
                        ].map((iconName) {
                          final isSelected = selectedIcon == iconName;
                          return GestureDetector(
                            onTap: () => setState(() => selectedIcon = iconName),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.accentTeal.withValues(alpha: 0.1)
                                    : (isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6)),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.accentTeal : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                _getAccountIcon(iconName),
                                color: isSelected
                                    ? AppColors.accentTeal
                                    : (isDarkMode ? Colors.white70 : Colors.black87),
                                size: 24.0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        'PILIH WARNA KARTU',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          buildColorDot('teal', AppColors.accentTeal),
                          const SizedBox(width: 12.0),
                          buildColorDot('orange', AppColors.accentOrange),
                          const SizedBox(width: 12.0),
                          if (isCustomActive) ...[
                            GestureDetector(
                              onTap: () => setState(() => isCustomActive = true),
                              child: Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  color: _parseCustomColor(selectedColor) ??
                                      AppColors.accentTeal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16.0),
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
                                    : (isDarkMode
                                        ? Colors.grey[800]
                                        : Colors.grey[300]),
                                shape: BoxShape.circle,
                                border: _isSelectedCustom(selectedColor)
                                    ? Border.all(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        width: 2.0)
                                    : null,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18.0,
                                color: _isSelectedCustom(selectedColor)
                                    ? (isDarkMode ? Colors.white : Colors.black87)
                                    : (isDarkMode
                                        ? Colors.white70
                                        : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isCustomActive) ...[
                        const SizedBox(height: 16.0),
                        Text(
                          'PILIH PALET KUSTOM',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            {'id': '#1A1A1A', 'color': AppColors.primaryBlack},
                            {'id': '#0D9488', 'color': AppColors.accentTeal},
                            {'id': '#F2994A', 'color': AppColors.accentOrange},
                            {'id': '#6B7280', 'color': AppColors.neutralGray},
                            {'id': '#DC2626', 'color': AppColors.semanticRed},
                            {'id': '#064B45', 'color': const Color(0xFF064B45)},
                          ].map((c) {
                            final isThisSelected = selectedColor.toLowerCase() ==
                                (c['id'] as String).toLowerCase();
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
                                        ? (isDarkMode
                                            ? Colors.white
                                            : Colors.black87)
                                        : Colors.transparent,
                                    width: 2.0,
                                  ),
                                ),
                                child: isThisSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 14.0)
                                    : null,
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
                                decoration: InputDecoration(
                                  labelText: 'Kode Hex / RGB',
                                  hintText: 'cth: #FF5722 atau 255,87,34',
                                  labelStyle: TextStyle(
                                    fontSize: 11.0,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  hintStyle: TextStyle(
                                    fontSize: 11.0,
                                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode ? AppColors.darkElevated : const Color(0xFFF3F4F6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12.0, vertical: 10.0),
                                ),
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
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
                              width: 32.0,
                              height: 32.0,
                              decoration: BoxDecoration(
                                color: _parseCustomColor(selectedColor) ??
                                    Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                                    width: 1.0),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12.0),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final balance =
                                  double.tryParse(balanceController.text) ?? 0.0;
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
                                  SnackBar(
                                      content: Text('Dompet "$name" berhasil diupdate')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                              foregroundColor: isDarkMode ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 0,
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
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, Account acc) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDarkMode ? AppColors.darkModal : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.semanticRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppColors.semanticRed,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Text(
                      'Hapus Dompet',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Apakah Anda yakin ingin menghapus dompet "${acc.name}"? Semua data transaksi yang menggunakan dompet ini juga akan terhapus secara permanen.',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton(
                      onPressed: () {
                        if (acc.id != null) {
                          ref
                              .read(accountsNotifierProvider.notifier)
                              .deleteAccount(acc.id!);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Dompet "${acc.name}" berhasil dihapus'),
                                backgroundColor: AppColors.semanticRed),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.semanticRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
