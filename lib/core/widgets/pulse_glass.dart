import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';

class PulseGlass extends StatelessWidget {
  const PulseGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.tint,
    this.blur = 18,
    this.opacity = 0.55,
    this.borderOpacity = 0.55,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(PulseRadii.xl);
    final base = tint ?? PulseColors.canvas;
    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                base.withValues(alpha: (opacity + 0.12).clamp(0.0, 1.0)),
                base.withValues(alpha: (opacity - 0.08).clamp(0.0, 1.0)),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: borderOpacity),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: PulseColors.ink.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null && onLongPress == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

class PulseAtmosphere extends StatelessWidget {
  const PulseAtmosphere({
    super.key,
    required this.child,
    this.dark = false,
  });

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF163300),
              PulseColors.ink,
              Color(0xFF0E0F0C),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Blob(
                size: 220,
                color: PulseColors.primary.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -80,
              child: _Blob(
                size: 260,
                color: PulseColors.primaryPale.withValues(alpha: 0.12),
              ),
            ),
            child,
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4F7F0),
            PulseColors.canvasSoft,
            Color(0xFFE2F6D5),
            Color(0xFFE8EBE6),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _Blob(
              size: 180,
              color: PulseColors.primary.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            top: 180,
            left: -70,
            child: _Blob(
              size: 200,
              color: const Color(0xFFFFC091).withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -50,
            child: _Blob(
              size: 220,
              color: const Color(0xFFD6ECFF).withValues(alpha: 0.45),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
