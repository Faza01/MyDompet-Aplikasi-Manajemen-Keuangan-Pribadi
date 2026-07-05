import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String type; // 'income' | 'expense'
  final String? icon;
  final bool isDefault;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.isDefault = false,
  });

  Color get color {
    switch (icon) {
      // Income Family (nuansa Teal, sesuai brand)
      case 'work':
        return const Color(0xFF0D9488); // Teal — Gaji
      case 'card_giftcard':
        return const Color(0xFF14B8A6); // Teal Light — Bonus
      case 'download':
        return const Color(0xFF2C7A94); // Cyan — Terima Transfer
      case 'add_circle':
        return const Color(0xFF6B7280); // Grey — Lain-lain (Masuk)
      // Expense Family (variasi hangat & netral, selaras Orange brand)
      case 'restaurant':
        return const Color(0xFFB8722E); // Orange — Makanan
      case 'directions_car':
        return const Color(0xFF3B69B3); // Blue — Transportasi
      case 'shopping_bag':
        return const Color(0xFFAE4277); // Pink — Belanja
      case 'receipt_long':
        return const Color(0xFFDC2626); // Red — Tagihan
      case 'sports_esports':
        return const Color(0xFF6C47C0); // Purple — Hiburan
      case 'swap_horiz':
        return const Color(0xFF4C46B9); // Indigo — Transfer
      case 'remove_circle':
        return const Color(0xFF6B7280); // Grey — Lain-lain (Keluar)
      default:
        return const Color(0xFF6B7280); // Grey — fallback
    }
  }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}
