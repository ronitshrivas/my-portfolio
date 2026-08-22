import 'package:flutter/material.dart';


class AvatarColors {
  AvatarColors._();

  static const _palettes = <List<Color>>[
    [Color(0xFF4C1D95), Color(0xFF7C3AED)], // violet
    [Color(0xFF1E3A8A), Color(0xFF2563EB)], // blue
    [Color(0xFF0F766E), Color(0xFF14B8A6)], // teal
    [Color(0xFF9F1239), Color(0xFFE11D48)], // rose
    [Color(0xFF0369A1), Color(0xFF38BDF8)], // sky
    [Color(0xFF9A3412), Color(0xFFF97316)], // orange
    [Color(0xFF3F6212), Color(0xFF84CC16)], // lime
    [Color(0xFF6B21A8), Color(0xFFA855F7)], // purple
  ];

  /// A stable 2-color gradient for [key] (falls back to a neutral seed).
  static List<Color> gradientFor(String? key) {
    final seed = (key == null || key.trim().isEmpty) ? 'user' : key.trim();
    final index = seed.hashCode.abs() % _palettes.length;
    return _palettes[index];
  }

  /// A single representative color for [key].
  static Color colorFor(String? key) => gradientFor(key).last;

  /// First letter for the fallback glyph.
  static String letterFor(String? name) {
    final n = (name ?? '').replaceAll('@', '').trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }
}
