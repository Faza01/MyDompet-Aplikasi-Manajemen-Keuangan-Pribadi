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
        return const Color(0xFF2A735B); // Muted Green for Gaji
      case 'card_giftcard':
        return const Color(0xFF2C736B); // Muted Teal for Bonus
      case 'download':
        return const Color(0xFF297481); // Muted Cyan for Terima Transfer
      case 'restaurant':
        return const Color(0xFF967131); // Amber for Makanan
      case 'directions_car':
        return const Color(0xFF3B69B3); // Blue for Transportasi
      case 'shopping_bag':
        return const Color(0xFFAE4277); // Pink for Belanja
      case 'receipt_long':
        return const Color(0xFFAF4040); // Muted Red for Tagihan
      case 'sports_esports':
        return const Color(0xFF6C47C0); // Muted Purple for Hiburan
      case 'swap_horiz':
        return const Color(0xFF4C46B9); // Indigo for Transfer
      default:
        return const Color(0xFF7A7F88); // Grey for Lain-lain
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
