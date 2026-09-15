import 'package:flutter/material.dart';

/// Paleta do mock: rosa, lavanda, amarelo, branco.
abstract final class AppColors {
  static const blush = Color(0xFFFBF7FA);
  static const blushDeep = Color(0xFFF3E6EE);
  static const petal = Color(0xFFF4C2D0);
  static const rose = Color(0xFFF0A0B5);
  static const roseDeep = Color(0xFFE07A9A);
  static const pinkChip = Color(0xFFF28EAD);

  static const lilac = Color(0xFFE8DFF5);
  static const lilacDeep = Color(0xFFC4B0E8);
  static const purpleInk = Color(0xFF5B4B7A);
  static const purpleBar = Color(0xFFB0A4F1);

  static const butter = Color(0xFFFFF1C4);
  static const butterDeep = Color(0xFFF5D98A);
  static const yellowInk = Color(0xFF8A6A20);

  static const apricot = Color(0xFFFFD8B8);
  static const apricotDeep = Color(0xFFF0B888);
  static const orangeInk = Color(0xFF9A5A32);

  static const mint = Color(0xFFB8E8DC);
  static const teal = Color(0xFF5DB8A8);

  static const cream = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2D2A32);
  static const inkSoft = Color(0xFF8A8490);
  static const success = Color(0xFF8FBF9F);
  static const danger = Color(0xFFE07A8A);
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF3F0F4);
  static const navInactive = Color(0xFF9AA0B0);

  static Color categoryFill(String? categoria, {required bool selected}) {
    if (selected) return pinkChip;
    return chip;
  }

  static Color categoryInk(String? categoria, {required bool selected}) {
    if (selected) return Colors.white;
    return ink;
  }

  static Color softTag(String? categoria) {
    return switch (categoria) {
      'Camiseta' => lilac,
      'Calça' => butter,
      'Vestido' => petal,
      'Jaqueta' => butterDeep.withValues(alpha: 0.7),
      'Sapato' => mint,
      'Acessório' => lilacDeep.withValues(alpha: 0.55),
      'Conjunto' => apricot,
      _ => chip,
    };
  }
}
