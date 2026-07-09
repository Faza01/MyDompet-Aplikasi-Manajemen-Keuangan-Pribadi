# Category Keywords Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize category detail keywords list loading and scrolling in the budgeting screen by replacing the global provider with a family FutureProvider and isolating widget rebuilds.

**Architecture:** We will define `categoryKeywordsProvider(categoryId)` in Riverpod to load category-specific keywords directly from the database. We will extract the keywords rendering section into a dedicated stateless `_KeywordsListWidget` wrapped in a `RepaintBoundary` to prevent whole-sheet rebuilds during scrolls and database updates.

**Tech Stack:** Flutter, Riverpod, SQLite (sqflite)

## Global Constraints
- Do not introduce unused local variables or imports.
- Make all changes compilation-warning and error-free.

---

### Task 1: Category-Specific Keywords Provider

**Responsibility:** Implement a family provider that queries keywords specifically for one category and handle invalidation during keyword inserts/deletes.

**Files:**
- Modify: `lib/features/budgeting/categories_provider.dart`

**Interfaces:**
- Produces: `categoryKeywordsProvider(categoryId)` as a `AutoDisposeFutureProviderFamily<List<CategoryKeyword>, int>`.

- [ ] **Step 1: Write the category-specific FutureProvider**
  Open [categories_provider.dart](file:///d:/Mobile%20Project/keuangan-v1/lib/features/budgeting/categories_provider.dart) and add the following at the bottom:
  ```dart
  final categoryKeywordsProvider = FutureProvider.autoDispose.family<List<CategoryKeyword>, int>((ref, categoryId) async {
    return DatabaseHelper.instance.getKeywordsForCategory(categoryId);
  });
  ```

- [ ] **Step 2: Verify compile check**
  Run: `flutter analyze lib/features/budgeting/categories_provider.dart`
  Expected: Clean compile (no errors)

- [ ] **Step 3: Commit**
  ```bash
  git add lib/features/budgeting/categories_provider.dart
  git commit -m "perf: implement categoryKeywordsProvider family provider"
  ```

---

### Task 2: Refactor Budgeting Screen to Isolate Rebuilds & Replace ChoiceChips

**Responsibility:** Move keywords rendering to `_KeywordsListWidget` in `budgeting_screen.dart`, watch `categoryKeywordsProvider`, trigger database operations directly, and invalidate the provider to refresh.

**Files:**
- Modify: `lib/features/budgeting/budgeting_screen.dart`

**Interfaces:**
- Consumes: `categoryKeywordsProvider` from `categories_provider.dart`.

- [ ] **Step 1: Replace keywords loading and rendering block in detail panel**
  Modify [budgeting_screen.dart](file:///d:/Mobile%20Project/keuangan-v1/lib/features/budgeting/budgeting_screen.dart) to:
  1. Remove global `keywordsAsync` watch.
  2. Implement direct insert and delete methods in `_CategoryDetailPanelState` using `DatabaseHelper` and `ref.invalidate(categoryKeywordsProvider(categoryId))`.
  3. Extract the keywords listing section into `_KeywordsListWidget`.

  Here is the code for `_KeywordsListWidget` to append:
  ```dart
  class _KeywordsListWidget extends ConsumerWidget {
    final int categoryId;
    final Function(int) onDelete;

    const _KeywordsListWidget({
      required this.categoryId,
      required this.onDelete,
    });

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final keywordsAsync = ref.watch(categoryKeywordsProvider(categoryId));
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return keywordsAsync.when(
        data: (keywords) {
          if (keywords.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Belum ada kata kunci kustom untuk kategori ini.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: keywords.map((kw) {
                  return Chip(
                    label: Text(kw.keyword),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onDelete(kw.id!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Text('Error load kata kunci: $err'),
      );
    }
  }
  ```

- [ ] **Step 2: Verify project compilation**
  Run: `flutter analyze`
  Expected: Clean compile (0 errors)

- [ ] **Step 3: Commit**
  ```bash
  git add lib/features/budgeting/budgeting_screen.dart
  git commit -m "perf: isolate keywords list in budgeting details sheet and use family provider"
  ```
