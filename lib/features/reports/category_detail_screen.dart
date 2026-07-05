import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';

class CategoryDetailScreen extends StatelessWidget {
  final Category category;
  final List<TransactionModel> transactions;
  final String accountName;
  final String dateRangeStr;

  const CategoryDetailScreen({
    super.key,
    required this.category,
    required this.transactions,
    required this.accountName,
    required this.dateRangeStr,
  });

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalAmount = transactions.fold<double>(0.0, (sum, tx) => sum + tx.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
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
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: category.type == 'income'
                            ? const Color(0xFF0D9488).withOpacity(0.12)
                            : const Color(0xFFDC2626).withOpacity(0.12),
                        child: Icon(
                          _getCategoryIcon(category.icon),
                          color: category.type == 'income'
                              ? const Color(0xFF0D9488)
                              : const Color(0xFFDC2626),
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        category.type == 'income' ? 'Total Pemasukan' : 'Total Pengeluaran',
                        style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRp(totalAmount),
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: category.type == 'income'
                              ? const Color(0xFF0D9488)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildInfoRow('Dompet / Akun', accountName, isDarkMode),
                      const SizedBox(height: 6),
                      _buildInfoRow('Periode Laporan', dateRangeStr, isDarkMode),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
              Text(
                'Daftar Transaksi (${transactions.length})',
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada transaksi untuk kategori ini.',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      )
                    : ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              side: BorderSide(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.03),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.04),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(category.icon),
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                  size: 16.0,
                                ),
                              ),
                              title: Text(
                                (tx.note == null || tx.note!.isEmpty) ? category.name : tx.note!,
                                style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.createdAt),
                                style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                              ),
                              trailing: Text(
                                (tx.type == 'income' ? '+ ' : '- ') + _formatRp(tx.amount),
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: tx.type == 'income'
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
