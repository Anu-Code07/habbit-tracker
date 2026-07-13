import 'package:flutter/material.dart';

import 'package:pulse/core/theme/pulse_colors.dart';
import 'package:pulse/core/theme/pulse_radii.dart';

/// Soft brand shimmer — use for section loaders, not full-screen takeovers.
class PulseShimmer extends StatefulWidget {
  const PulseShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<PulseShimmer> createState() => _PulseShimmerState();
}

class _PulseShimmerState extends State<PulseShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(PulseRadii.lg);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment(-1.2 + 2.4 * _controller.value, 0),
              end: Alignment(-0.2 + 2.4 * _controller.value, 0),
              colors: const [
                PulseColors.canvasSoft,
                Color(0xFFF7FAF3),
                PulseColors.primaryPale,
                PulseColors.canvasSoft,
              ],
              stops: const [0.0, 0.35, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class PulseHabitGridShimmer extends StatelessWidget {
  const PulseHabitGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                PulseShimmer(width: double.infinity, height: 150),
                SizedBox(height: 12),
                PulseShimmer(width: double.infinity, height: 180),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                PulseShimmer(width: double.infinity, height: 180),
                SizedBox(height: 12),
                PulseShimmer(width: double.infinity, height: 150),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PulseTodaySkeleton extends StatelessWidget {
  const PulseTodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      children: [
        const PulseShimmer(width: 220, height: 36),
        const SizedBox(height: 24),
        Row(
          children: [
            const PulseShimmer(width: 100, height: 18),
            const Spacer(),
            PulseShimmer(
              width: 88,
              height: 32,
              borderRadius: BorderRadius.circular(PulseRadii.pill),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => PulseShimmer(
              width: 56,
              height: 72,
              borderRadius: BorderRadius.circular(PulseRadii.lg),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _HabitGridShimmerInner(),
        const SizedBox(height: 120),
      ],
    );
  }
}

class _HabitGridShimmerInner extends StatelessWidget {
  const _HabitGridShimmerInner();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              PulseShimmer(width: double.infinity, height: 150),
              SizedBox(height: 12),
              PulseShimmer(width: double.infinity, height: 180),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              PulseShimmer(width: double.infinity, height: 180),
              SizedBox(height: 12),
              PulseShimmer(width: double.infinity, height: 150),
            ],
          ),
        ),
      ],
    );
  }
}

class PulseInsightsSkeleton extends StatelessWidget {
  const PulseInsightsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        const PulseShimmer(width: 160, height: 36),
        const SizedBox(height: 12),
        const PulseShimmer(width: 220, height: 18),
        const SizedBox(height: 32),
        PulseShimmer(
          width: double.infinity,
          height: 140,
          borderRadius: BorderRadius.circular(PulseRadii.xl),
        ),
        const SizedBox(height: 16),
        PulseShimmer(
          width: double.infinity,
          height: 100,
          borderRadius: BorderRadius.circular(PulseRadii.xl),
        ),
        const SizedBox(height: 16),
        PulseShimmer(
          width: double.infinity,
          height: 180,
          borderRadius: BorderRadius.circular(PulseRadii.xl),
        ),
      ],
    );
  }
}

