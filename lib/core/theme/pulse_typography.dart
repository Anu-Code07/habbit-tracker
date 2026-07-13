import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pulse/core/theme/pulse_colors.dart';

abstract final class PulseTypography {
  static TextStyle displayXl({Color? color}) => GoogleFonts.outfit(
        fontSize: 44,
        fontWeight: FontWeight.w800,
        height: 0.95,
        letterSpacing: -1.6,
        color: color ?? PulseColors.ink,
      );

  static TextStyle displayMd({Color? color}) => GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.2,
        color: color ?? PulseColors.ink,
      );

  static TextStyle displaySm({Color? color}) => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.6,
        color: color ?? PulseColors.ink,
      );

  static TextStyle displayXs({Color? color}) => GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: color ?? PulseColors.ink,
      );

  static TextStyle timerDisplay({Color? color}) => GoogleFonts.outfit(
        fontSize: 52,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: -2.0,
        color: color ?? PulseColors.ink,
      );

  static TextStyle bodyLg({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: -0.2,
        color: color ?? PulseColors.body,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: -0.15,
        color: color ?? PulseColors.body,
      );

  static TextStyle bodyMdStrong({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.2,
        color: color ?? PulseColors.ink,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: -0.1,
        color: color ?? PulseColors.body,
      );

  static TextStyle bodySmStrong({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.1,
        color: color ?? PulseColors.ink,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.2,
        color: color ?? PulseColors.mute,
      );

  static TextStyle buttonMd({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: color ?? PulseColors.onPrimary,
      );

  static TextStyle navLabel({Color? color, bool selected = false}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.1,
        color: color ?? (selected ? PulseColors.ink : PulseColors.mute),
      );

  /// Distinct brand lockup — Syne, wide tracking. Not used for UI body/display.
  static TextStyle brandMark({Color? color, double fontSize = 15}) =>
      GoogleFonts.syne(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        height: 1,
        letterSpacing: fontSize * 0.28,
        color: color ?? PulseColors.ink,
      );

  static TextStyle splashWordmark({Color? color}) => brandMark(
        color: color ?? PulseColors.ink,
        fontSize: 52,
      );
}
