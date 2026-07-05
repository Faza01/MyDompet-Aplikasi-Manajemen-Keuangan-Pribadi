import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/category.dart';
import '../../data/models/keyword.dart';
import 'budget_provider.dart';
import 'categories_provider.dart';

class BudgetingScreen extends ConsumerWidget {
  const BudgetingScreen({super.key});

  String _formatRp(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  IconData _getCategoryIcon(String? iconName) {
    switch (iconName) {
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
      case 'remove_circle':
        return Icons.remove_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(categoryBudgetProgressProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran & Kategori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        bottom: false,
        child: progressAsync.when(
          data: (progressList) {
            return ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 8.0, bottom: 100.0),
              itemCount: progressList.length,
              itemBuilder: (context, index) {
                final prog = progressList[index];
                final hasBudget = prog.budget != null;
                final catColor = prog.category.color;

                // Color based on budget percentage
                Color progressColor =
                    Theme.of(context).colorScheme.primary; // Core Ledger Teal
                if (prog.percentage >= 1.0) {
                  progressColor = const Color(0xFFEF4444); // Coral Red
                } else if (prog.percentage >= 0.75) {
                  progressColor = Colors.amber;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.0),
                    onTap: () {
                      _showCategoryDetailBottomSheet(
                          context, ref, prog.category, prog);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Icon(
                                  _getCategoryIcon(prog.category.icon),
                                  color: catColor,
                                  size: 20.0,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prog.category.name,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasBudget)
                                      Text(
                                        'Budget ${prog.budget!.period == 'weekly' ? 'Mingguan' : 'Bulanan'}',
                                        style: TextStyle(
                                          fontSize: 11.0,
                                          color: isDarkMode
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                        ),
                                      )
                                    else
                                      Text(
                                        'Belum diset budget',
                                        style: TextStyle(
                                          fontSize: 11.0,
                                          color: isDarkMode
                                              ? Colors.grey[500]
                                              : Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (hasBudget)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(prog.percentage * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: progressColor,
                                      ),
                                    ),
                                    Text(
                                      '${_formatRp(prog.spentAmount)} / ${_formatRp(prog.limitAmount)}',
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (hasBudget) ...[
                            const SizedBox(height: 16.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: prog.percentage.clamp(0.0, 1.0),
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF12161A)
                                    : Colors.grey[200],
                                color: progressColor,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) =>
              Center(child: Text('Error loading budgets: $err')),
        ),
      ),
    );
  }

  void _showCategoryDetailBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Category category,
    CategoryBudgetProgress prog,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _CategoryDetailPanel(
              category: category,
              prog: prog,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _CategoryDetailPanel extends ConsumerStatefulWidget {
  final Category category;
  final CategoryBudgetProgress prog;
  final ScrollController? scrollController;

  const _CategoryDetailPanel({
    required this.category,
    required this.prog,
    this.scrollController,
  });

  @override
  ConsumerState<_CategoryDetailPanel> createState() =>
      _CategoryDetailPanelState();
}

class _CategoryDetailPanelState extends ConsumerState<_CategoryDetailPanel> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    if (widget.prog.budget != null) {
      _budgetController.text =
          widget.prog.budget!.amountLimit.toStringAsFixed(0);
      _period = widget.prog.budget!.period;
    } else {
      _period = 'monthly';
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final limit = double.tryParse(_budgetController.text) ?? 0.0;
    if (limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal budget harus lebih dari 0')),
      );
      return;
    }

    ref.read(budgetNotifierProvider.notifier).setBudget(
          categoryId: widget.category.id!,
          limit: limit,
          period: _period,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Budget untuk ${widget.category.name} berhasil disimpan')),
    );
    Navigator.pop(context);
  }

  void _removeBudget() {
    if (widget.prog.budget?.id != null) {
      ref
          .read(budgetNotifierProvider.notifier)
          .removeBudget(widget.prog.budget!.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Budget untuk ${widget.category.name} dihapus')),
      );
      Navigator.pop(context);
    }
  }

  void _addKeyword() {
    final kw = _keywordController.text.trim();
    if (kw.isEmpty) return;

    ref
        .read(keywordsNotifierProvider.notifier)
        .addKeyword(widget.category.id!, kw);
    _keywordController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kata kunci "$kw" ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keywordsAsync = ref.watch(keywordsNotifierProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20.0, 12.0, 20.0, MediaQuery.of(context).viewInsets.bottom + 24.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E222B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            // Header Row with Title and Close Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40.0), // Spacer to balance
                Expanded(
                  child: Text(
                    'Detail Kategori: ${widget.category.name}',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // 1. Setting Budget Section
            const Text(
              'Limit Anggaran (Budget)',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nominal Limit',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 10.0),
            DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: InputDecoration(
                labelText: 'Periode Anggaran',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _period = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12.0),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              children: [
                if (widget.prog.budget != null)
                  TextButton(
                    onPressed: _removeBudget,
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: const Text('Hapus Budget'),
                  ),
                ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Budget'),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Divider(height: 1),
            const SizedBox(height: 20.0),

            // 2. Manage Keywords Section
            const Text(
              'Kata Kunci Pemicu Parser NLP',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: 'Tambah kata kunci kustom (cth: indomaret)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  onPressed: _addKeyword,
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // List of keywords
            keywordsAsync.when(
              data: (keywords) {
                final filteredKws = keywords
                    .where((k) => k.categoryId == widget.category.id)
                    .toList();

                if (filteredKws.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'Belum ada kata kunci kustom untuk kategori ini.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: filteredKws.map((kw) {
                      return Chip(
                        label: Text(kw.keyword),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          if (kw.id != null) {
                            ref
                                .read(keywordsNotifierProvider.notifier)
                                .deleteKeyword(kw.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Kata kunci "${kw.keyword}" dihapus')),
                            );
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Text('Error load kata kunci: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
