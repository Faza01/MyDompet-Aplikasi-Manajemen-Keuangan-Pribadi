import 'package:flutter/material.dart';

/// Centralized color palette for the entire app.
/// Based on Aurox-style brand identity: black wallet + orange & teal card gradient.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ── Brand Core ──────────────────────────────────────────────
  static const primaryBlack = Color(0xFF1A1A1A);
  static const background = Color(0xFFF5F6F7);
  static const surface = Color(0xFFFFFFFF);
  static const accentOrange = Color(0xFFF2994A);
  static const accentTeal = Color(0xFF0D9488);

  // ── Transaction ─────────────────────────────────────────────
  static const income = Color(0xFF0D9488);   // Selaras dengan Accent Teal logo
  static const expense = Color(0xFFDC2626);  // Merah standar universal

  // ── Text ────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);

  // ── Category Colors ─────────────────────────────────────────
  // Income Family (nuansa Teal, sesuai brand)
  static const catGaji = Color(0xFF0D9488);
  static const catBonus = Color(0xFF14B8A6);
  static const catTerimaTransfer = Color(0xFF2C7A94);

  // Expense Family (variasi hangat & netral)
  static const catMakanan = Color(0xFFB8722E);       // Selaras Accent Orange logo
  static const catBelanja = Color(0xFFAE4277);
  static const catTagihan = Color(0xFFDC2626);
  static const catHiburan = Color(0xFF6C47C0);
  static const catTransportasi = Color(0xFF3B69B3);

  // Netral
  static const catTransfer = Color(0xFF4C46B9);      // Indigo, beda dari Transportasi
  static const catLainLain = Color(0xFF6B7280);
}
