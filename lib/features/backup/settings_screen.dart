import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_backup_helper.dart';
import '../accounts/accounts_provider.dart';
import '../accounts/accounts_screen.dart';
import '../budgeting/categories_provider.dart';
import '../budgeting/budgeting_screen.dart';
import '../transactions/transactions_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Section 1: Accounts Management
            _buildSectionHeader('Akun & Dompet', isDarkMode),
            _buildSettingsItem(
              icon: Icons.account_balance_wallet,
              title: 'Kelola Dompet & Akun',
              subtitle: 'Tambah, edit, hapus dompet, dan transfer dana',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountsScreen()),
                );
              },
              isDarkMode: isDarkMode,
            ),


            // Section 2: Backup & Restore
            _buildSectionHeader('Cadangkan & Pulihkan', isDarkMode),
            _buildSettingsItem(
              icon: Icons.upload_file,
              title: 'Ekspor Data (Backup)',
              subtitle: 'Cadangkan seluruh data ke berkas JSON',
              onTap: () async {
                try {
                  await DatabaseBackupHelper.exportAndShare();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil diekspor!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengekspor data: $e')),
                  );
                }
              },
              isDarkMode: isDarkMode,
            ),
             _buildSettingsItem(
              icon: Icons.file_download,
              title: 'Impor Data (Restore)',
              subtitle: 'Pulihkan data dari teks cadangan JSON',
              onTap: () {
                _showImportDialog(context, ref);
              },
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 20.0),

            // Section 3: Reset
            _buildSectionHeader('Zona Bahaya', isDarkMode),
            _buildSettingsItem(
              icon: Icons.delete_forever,
              title: 'Reset Semua Data',
              subtitle: 'Hapus semua transaksi dan kembalikan ke pengaturan awal',
              iconColor: Colors.redAccent,
              onTap: () {
                _confirmResetData(context, ref);
              },
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? (isDarkMode ? Colors.white : Colors.black)).withOpacity(0.1),
          child: Icon(icon, color: iconColor ?? (isDarkMode ? Colors.white : Colors.black), size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.0, color: isDarkMode ? Colors.grey[500] : Colors.grey[600]),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18.0),
        onTap: onTap,
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Impor Data JSON'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tempelkan seluruh teks JSON backup Anda di bawah ini. Tindakan ini akan menghapus semua data saat ini dan menggantinya dengan isi backup.',
                style: TextStyle(fontSize: 12.0),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: textController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '{\n  "version": 1,\n  "accounts": [...]\n}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: const TextStyle(fontSize: 11.0, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final jsonStr = textController.text.trim();
                if (jsonStr.isEmpty) return;

                final success = await DatabaseBackupHelper.importFromJson(jsonStr);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    // Refresh all providers to reconstruct the local UI state
                    ref.invalidate(transactionsNotifierProvider);
                    ref.invalidate(accountsNotifierProvider);
                    ref.invalidate(categoriesNotifierProvider);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data berhasil dipulihkan (Restore Sukses)!'),
                        backgroundColor: Color(0xFF004D4D),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Format JSON tidak valid atau rusak.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              child: const Text('Impor'),
            ),
          ],
        );
      },
    );
  }

  void _confirmResetData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Data'),
          content: const Text('Apakah Anda yakin ingin menghapus seluruh data? Seluruh transaksi dan anggaran akan hilang. Kategori default akan di-seed ulang.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                ref.read(transactionsNotifierProvider.notifier).resetAllData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua data berhasil direset ke kondisi awal')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}
