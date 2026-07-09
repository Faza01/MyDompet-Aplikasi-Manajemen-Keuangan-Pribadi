import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/nlp_debt_keyword.dart';
import 'nlp_keywords_provider.dart';

class NlpKeywordsDialog extends ConsumerStatefulWidget {
  const NlpKeywordsDialog({super.key});

  @override
  ConsumerState<NlpKeywordsDialog> createState() => _NlpKeywordsDialogState();
}

class _NlpKeywordsDialogState extends ConsumerState<NlpKeywordsDialog> {
  final TextEditingController _controller = TextEditingController();
  String _selectedType = 'debt'; // 'debt' | 'receivable'

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(nlpKeywordsNotifierProvider.notifier).addKeyword(text, _selectedType);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final keywordsAsync = ref.watch(nlpKeywordsNotifierProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      backgroundColor: isDarkMode ? AppColors.darkScaffold : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 550),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kata Kunci NLP',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Text(
                'Kata kunci yang digunakan asisten Quick Input untuk mendeteksi transaksi Hutang atau Piutang secara otomatis.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Form Input Baru
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Tambah kata/frasa...',
                        hintStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                      onSubmitted: (_) => _addKeyword(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addKeyword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.white : AppColors.primaryBlack,
                      foregroundColor: isDarkMode ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Type Selector for new keyword
              Row(
                children: [
                  const Text('Tipe: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedType = 'debt'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: _selectedType == 'debt'
                            ? (isDarkMode ? Colors.white : AppColors.primaryBlack)
                            : (isDarkMode ? AppColors.darkCard : const Color(0xFFECEEEE)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Hutang',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'debt'
                              ? (isDarkMode ? Colors.black : Colors.white)
                              : (isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedType = 'receivable'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: _selectedType == 'receivable'
                            ? (isDarkMode ? Colors.white : AppColors.primaryBlack)
                            : (isDarkMode ? AppColors.darkCard : const Color(0xFFECEEEE)),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'Piutang',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _selectedType == 'receivable'
                              ? (isDarkMode ? Colors.black : Colors.white)
                              : (isDarkMode ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Keywords Lists scroll area
              Expanded(
                child: keywordsAsync.when(
                  data: (keywords) {
                    final debts = keywords.where((k) => k.type == 'debt').toList();
                    final receivables = keywords.where((k) => k.type == 'receivable').toList();

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        if (_selectedType == 'debt') ...[
                          // Hutang section
                          _buildSectionHeader('KATA KUNCI HUTANG (Uang Masuk)', AppColors.semanticRed),
                          const SizedBox(height: 8),
                          if (debts.isEmpty)
                            const Text('Belum ada kata kunci khusus.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 2.0,
                              children: debts.map((k) => _buildKeywordChip(k)).toList(),
                            ),
                        ],
                        if (_selectedType == 'receivable') ...[
                          // Piutang section
                          _buildSectionHeader('KATA KUNCI PIUTANG (Uang Keluar)', AppColors.accentTeal),
                          const SizedBox(height: 8),
                          if (receivables.isEmpty)
                            const Text('Belum ada kata kunci khusus.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                          else
                            Wrap(
                              spacing: 6.0,
                              runSpacing: 2.0,
                              children: receivables.map((k) => _buildKeywordChip(k)).toList(),
                            ),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(fontSize: 12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordChip(NlpDebtKeyword kw) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text(kw.keyword, style: const TextStyle(fontSize: 11)),
      backgroundColor: isDarkMode ? AppColors.darkCard : const Color(0xFFF1F3F4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: const BorderSide(color: Colors.transparent),
      ),
      deleteIcon: const Icon(Icons.cancel, size: 14, color: Colors.grey),
      onDeleted: () {
        ref.read(nlpKeywordsNotifierProvider.notifier).deleteKeyword(kw.id!);
      },
    );
  }
}
