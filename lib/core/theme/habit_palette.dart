import 'package:flutter/material.dart';

abstract final class HabitPalette {
  static const List<int> colors = [
    0xFFFFF1C2, // soft yellow
    0xFFE2F6D5, // primary pale
    0xFFFFD6E7, // soft pink
    0xFFD6ECFF, // soft blue
    0xFFFFC091, // accent orange
    0xFFE8EBE6, // canvas soft
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
  ];

  static Color of(int value) => Color(value);
}
