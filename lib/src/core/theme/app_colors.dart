import 'package:flutter/material.dart';

/// Paleta fixa pastel: rosa · roxo · amarelo · laranja
abstract final class AppColors {
  // Rosa (base / fundo)
  static const blush = Color(0xFFFFF0F5);
  static const blushDeep = Color(0xFFF8DDE8);
  static const petal = Color(0xFFF4C4D8);
  static const rose = Color(0xFFE891B0);
  static const roseDeep = Color(0xFFD46A92);

  // Roxo pastel
  static const lilac = Color(0xFFE8D4F0);
  static const lilacDeep = Color(0xFFC9A0D8);
  static const purpleInk = Color(0xFF6B4A7A);

  // Amarelo pastel
  static const butter = Color(0xFFFFF3C9);
  static const butterDeep = Color(0xFFF5D98A);
  static const yellowInk = Color(0xFF8A6A20);

  // Laranja pastel
  static const apricot = Color(0xFFFFD8B8);
  static const apricotDeep = Color(0xFFF0B888);
  static const orangeInk = Color(0xFF9A5A32);

  // Neutros
  static const cream = Color(0xFFFFFBFC);
  static const mauve = Color(0xFFC9A0C0);
  static const ink = Color(0xFF5A3A48);
  static const inkSoft = Color(0xFF8B6B78);
  static const success = Color(0xFF8FBF9F);
  static const danger = Color(0xFFE07A8A);
  static const card = Color(0xFFFFFFF8);
  static const chip = Color(0xFFFFE8F0);

  /// Só rosa / roxo / amarelo / laranja
  static Color categoryFill(String? categoria, {required bool selected}) {
    final base = switch (categoria) {
      null || '' => petal, // Todas → rosa
      'Camiseta' => lilac, // roxo
      'Calça' => butter, // amarelo
      'Vestido' => apricot, // laranja
      'Jaqueta' => lilacDeep.withValues(alpha: 0.55), // roxo
      'Sapato' => butterDeep.withValues(alpha: 0.55), // amarelo
      'Acessório' => apricotDeep.withValues(alpha: 0.55), // laranja
      'Outro' => petal.withValues(alpha: 0.75), // rosa
      _ => chip,
    };
    if (!selected) return Color.lerp(base, Colors.white, 0.22)!;
    return base;
  }

  static Color categoryInk(String? categoria, {required bool selected}) {
    if (!selected) return inkSoft;
    return switch (categoria) {
      null || '' => roseDeep,
      'Camiseta' => purpleInk,
      'Calça' => yellowInk,
      'Vestido' => orangeInk,
      'Jaqueta' => purpleInk,
      'Sapato' => yellowInk,
      'Acessório' => orangeInk,
      'Outro' => roseDeep,
      _ => ink,
    };
  }
}
