import 'package:flutter/material.dart';

abstract final class HabitPalette {
  static const List<int> colors = [
    0xFFFFF1C2, // soft yellow
    0xFFE2F6D5, // primary pale
    0xFFFFD6E7, // soft pink
    0xFFD6ECFF, // soft blue
    0xFFFFC091, // accent orange
    0xFFE8EBE6, // canvas soft
    0xFFE8D9FF, // soft lavender
    0xFFD5F5F0, // soft mint
    0xFFFFE0D6, // soft coral
    0xFFE4EDFF, // periwinkle
  ];

  static const List<IconData> icons = [
    Icons.menu_book_rounded,
    Icons.fitness_center_rounded,
    Icons.self_improvement_rounded,
    Icons.water_drop_rounded,
    Icons.nightlight_round,
    Icons.restaurant_rounded,
    Icons.work_outline_rounded,
    Icons.bolt_rounded,
    Icons.music_note_rounded,
    Icons.favorite_rounded,
    Icons.directions_run_rounded,
    Icons.local_cafe_rounded,
    Icons.park_rounded,
    Icons.brush_rounded,
    Icons.pets_rounded,
  ];

  static Color of(int value) => Color(value);
}
