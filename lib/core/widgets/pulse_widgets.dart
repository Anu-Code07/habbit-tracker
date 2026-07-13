import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';
import 'package:pulse/core/theme/pulse_spacing.dart';
import 'package:pulse/core/theme/pulse_typography.dart';
import 'package:pulse/core/widgets/pulse_glass.dart';

class PulsePrimaryButton extends StatelessWidget {
  const PulsePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      child: Text(label, style: PulseTypography.buttonMd()),
    );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class PulseSecondaryButton extends StatelessWidget {
  const PulseSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: PulseColors.canvas.withValues(alpha: 0.55),
        foregroundColor: PulseColors.ink,
      ),
      child: Text(label, style: PulseTypography.buttonMd(color: PulseColors.ink)),
    );
    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class PulseCard extends StatelessWidget {
  const PulseCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.opacity = 0.52,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: color ?? PulseColors.canvas,
      opacity: opacity,
      padding: padding ?? const EdgeInsets.all(PulseSpacing.xl),
      onTap: onTap,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

class PulseEmptyState extends StatelessWidget {
  const PulseEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return PulseCard(
      color: PulseColors.canvas,
      opacity: 0.45,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: PulseTypography.displayXs(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: PulseSpacing.sm),
          Text(
            message,
            style: PulseTypography.bodyMd(),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: PulseSpacing.xl),
            PulsePrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class PulseErrorView extends StatelessWidget {
  const PulseErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PulseSpacing.xl),
        child: PulseCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: PulseTypography.bodyMd(color: PulseColors.negative),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: PulseSpacing.lg),
                PulsePrimaryButton(label: 'Try again', onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PulsePositiveBadge extends StatelessWidget {
  const PulsePositiveBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return PulseGlass(
      tint: PulseColors.primaryPale,
      opacity: 0.7,
      blur: 10,
      borderRadius: BorderRadius.circular(PulseRadii.pill),
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpacing.md,
        vertical: PulseSpacing.xs,
      ),
      child: Text(
        label,
        style: PulseTypography.bodySmStrong(color: PulseColors.positiveDeep),
      ),
    );
  }
}
