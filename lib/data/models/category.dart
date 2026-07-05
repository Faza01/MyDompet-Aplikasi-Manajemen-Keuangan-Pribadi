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
      case 'work':
        return const Color(0xFF10B981); // Emerald Green for Gaji
      case 'card_giftcard':
        return const Color(0xFF14B8A6); // Teal for Bonus
      case 'download':
        return const Color(0xFF06B6D4); // Cyan for Terima Transfer
      case 'restaurant':
        return const Color(0xFFF59E0B); // Amber for Makanan
      case 'directions_car':
        return const Color(0xFF3B82F6); // Blue for Transportasi
      case 'shopping_bag':
        return const Color(0xFFEC4899); // Pink for Belanja
      case 'receipt_long':
        return const Color(0xFFEF4444); // Red/Coral for Tagihan
      case 'sports_esports':
        return const Color(0xFF8B5CF6); // Purple for Hiburan
      case 'swap_horiz':
        return const Color(0xFF0EA5E9); // Sky Blue for Transfer Keluar
      default:
        return const Color(0xFF9CA3AF); // Grey for Lain-lain
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
