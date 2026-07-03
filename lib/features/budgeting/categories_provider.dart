import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/category.dart';
import '../../data/models/keyword.dart';

// Categories Notifier
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  FutureOr<List<Category>> build() async {
    return DatabaseHelper.instance.getAllCategories();
  }

  Future<void> addCategory(String name, String type, String? icon) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.insertCategory(Category(
        name: name,
        type: type,
        icon: icon,
        isDefault: false,
      ));
      return db.getAllCategories();
    });
  }

  Future<void> updateCategory(Category category) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.updateCategory(category);
      return db.getAllCategories();
    });
  }

  Future<void> deleteCategory(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.deleteCategory(id);
      return db.getAllCategories();
    });
  }
}

final categoriesNotifierProvider =
    AsyncNotifierProvider.autoDispose<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

// Keywords Notifier
class KeywordsNotifier extends AsyncNotifier<List<CategoryKeyword>> {
  @override
  FutureOr<List<CategoryKeyword>> build() async {
    return DatabaseHelper.instance.getAllKeywords();
  }

  Future<void> addKeyword(int categoryId, String keyword) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.insertKeyword(CategoryKeyword(
        categoryId: categoryId,
        keyword: keyword.trim().toLowerCase(),
      ));
      return db.getAllKeywords();
    });
  }

  Future<void> deleteKeyword(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final db = DatabaseHelper.instance;
      await db.deleteKeyword(id);
      return db.getAllKeywords();
    });
  }
}

final keywordsNotifierProvider =
    AsyncNotifierProvider.autoDispose<KeywordsNotifier, List<CategoryKeyword>>(
  KeywordsNotifier.new,
);
